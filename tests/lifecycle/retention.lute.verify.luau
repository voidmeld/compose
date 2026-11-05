--!strict

local Compose = require "../../src/core"
local TestScene = require "../../src/test-scene"
local Lute = require "../../.lute/dependencies/verify/src/lute"
local Verify = require "../../.lute/dependencies/verify/src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Sample = { run: () -> (), dispose: () -> () }
type Build = (runtime: Compose.Runtime, target: Compose.Node, remember: (Compose.Node) -> ()) -> Sample

local function measure(context: Verify.Context, name: string, build: Build)
	local readings: { number } = {}
	for _, anchored in { false, true } do
		local host = TestScene.create()
		local weak: { Compose.Node } = {}
		setmetatable(weak, { __mode = "v" })
		local count = 0
		local function remember(node: Compose.Node)
			count += 1
			weak[count] = node
		end
		local function rehearse()
			local runtime = Compose.createRuntime(host.adapter)
			local sample = build(runtime, host.root, remember)
			sample.run()
			sample.dispose()
			runtime:dispose()
		end
		for _ = 1, 4 do
			rehearse()
			Lute.memory.settle { cycles = 8, maxAllocations = 2500000, deadlineSeconds = 10 }
		end
		local runtime = Compose.createRuntime(host.adapter)
		local releaseAnchor = if anchored
			then runtime.mount(function()
				return runtime.create "Frame" {}
			end, host.root)
			else function() end
		local result = Lute.memory.measure({
			setup = function(): Sample
				return build(runtime, host.root, remember)
			end,
			run = function(sample: Sample)
				sample.run()
			end,
			teardown = function(sample: Sample)
				sample.dispose()
			end,
			iterations = 1,
		}, { cycles = 8, maxAllocations = 2500000, deadlineSeconds = 10 })
		context:attach(`{name} anchored={anchored}`, "application/json", Lute.encode(result))
		local survivors = 0
		for _ in weak do
			survivors += 1
		end
		releaseAnchor()
		runtime:dispose()
		expect(host.liveNodes()):toBe(1)
		expect(survivors):toBe(0)
		expect(result.mountedKb):toBeGreaterThan(64)
		table.insert(readings, result.teardownRetainedKb)
	end
	for _, retained in readings do
		expect(retained):toBeLessThan(24)
	end
end

describe("teardown heap", function()
	it("does not root unreachable owners through node metadata", function()
		local host = table.clone(TestScene.create().adapter)
		host.render = table.clone(host.render)
		host.render.createNode = function(): Compose.Node
			return {}
		end
		local runtime = Compose.createRuntime(host)
		local weak: { unknown } = {}
		setmetatable(weak, { __mode = "v" })
		local function build()
			local owner = Compose.createOwner()
			weak[1] = owner
			Compose.withOwner(owner, function()
				weak[2] = runtime.create "Frame" {}
			end)
		end
		build()
		Lute.memory.settle { cycles = 8, maxAllocations = 2500000, deadlineSeconds = 10 }
		expect(weak[1]):toBe(nil)
		expect(weak[2]):toBe(nil)
		runtime:dispose()
	end)

	it("releases animation activity storage while its runtime remains alive", function(_own, context)
		local host = TestScene.create()
		local runtime = Compose.createRuntime(host.adapter)
		local target = Compose.cell(0)
		local function source(use: Compose.Use): number
			return use(target)
		end
		local warm = Compose.createOwner(runtime.reactor)
		Compose.withOwner(warm, function()
			runtime.spring(source)
		end)
		Compose.owner.dispose(warm)
		local result = Lute.memory.measure({
			setup = function(): Compose.Owner
				local owner = Compose.createOwner(runtime.reactor)
				Compose.withOwner(owner, function()
					for _ = 1, 1024 do
						runtime.spring(source)
					end
				end)
				return owner
			end,
			run = function(_owner: Compose.Owner)
				target:set(1)
				runtime:settle()
			end,
			teardown = function(owner: Compose.Owner)
				Compose.owner.dispose(owner)
			end,
			iterations = 1,
		}, { cycles = 8, maxAllocations = 2500000, deadlineSeconds = 10 })
		context:attach("animation activity", "application/json", Lute.encode(result))
		expect(result.mountedKb):toBeGreaterThan(64)
		expect(result.teardownRetainedKb):toBeLessThan(48)
		expect(host.counts().frameListeners):toBe(0)
		runtime:dispose()
	end)

	it("releases static child ownership storage", function(_own, context)
		measure(context, "static children", function(runtime, target, remember)
			local Frame = runtime.create "Frame"
			local dispose = runtime.mount(function()
				local children: { Compose.Node } = {}
				for index = 1, 1024 do
					local child = Frame { Frame {} }
					remember(child)
					children[index] = child
				end
				return Frame(children)
			end, target)
			return { run = function() end, dispose = dispose }
		end)
	end)

	it("releases recycled rows and spare rows after changing windows", function(_own, context)
		measure(context, "recycled windows", function(runtime, target, remember)
			local Frame = runtime.create "Frame"
			local items: { number } = {}
			for index = 1, 2048 do
				items[index] = index
			end
			local initial: Compose.OrderedCollectionViewport = { offset = 0, size = 5120 }
			local viewport = Compose.cell(initial)
			local layout: Compose.OrderedCollectionLayout = { itemSize = 10 }
			local dispose = runtime.mount(function()
				return Frame {
					Compose.OrderedCollection {
						from = Compose.cell(items),
						key = function(value: number): number
							return value
						end,
						mode = "windowed",
						viewport = viewport,
						layout = layout,
						overscan = 0,
						recycle = function(value, placement, key)
							local node = Frame {
								Value = value,
								Key = key,
								Offset = function(use)
									return use(placement).offset
								end,
							}
							remember(node)
							return node
						end,
					},
				}
			end, target)
			return {
				dispose = dispose,
				run = function()
					for step = 1, 12 do
						viewport:set { offset = step * 100 + (if step % 2 == 0 then 0 else 5), size = 1280 }
						runtime:settle()
					end
				end,
			}
		end)
	end)

	it("releases keyed rows after updates and replacement", function(_own, context)
		measure(context, "keyed rows", function(runtime, target, remember)
			local Frame = runtime.create "Frame"
			local values: { number } = {}
			for index = 1, 1024 do
				values[index] = index
			end
			local items = Compose.cell(values)
			local dispose = runtime.mount(function()
				return Frame {
					Compose.keyed {
						from = items,
						key = function(value: number): number
							return value
						end,
						render = function(value)
							local node = Frame { Value = value }
							remember(node)
							return node
						end,
					},
				}
			end, target)
			return {
				dispose = dispose,
				run = function()
					local nextValues = table.clone(values)
					for index = 10, #nextValues, 10 do
						nextValues[index] += 2048
					end
					items:set(nextValues)
					runtime:settle()
				end,
			}
		end)
	end)

	it("releases a tree bound to a propagated theme", function(_own, context)
		measure(context, "theme propagation", function(runtime, target, remember)
			local Frame = runtime.create "Frame"
			local tint = Compose.cell(0)
			local theme = Compose.createContext(tint)
			local dispose = runtime.mount(function()
				return theme.provide(tint, function()
					local children: { Compose.Node } = {}
					for index = 1, 1024 do
						local color = theme.read()
						local child = Frame { Tint = color }
						remember(child)
						children[index] = child
					end
					return Frame(children)
				end)
			end, target)
			return {
				dispose = dispose,
				run = function()
					tint:set(1)
					runtime:settle()
				end,
			}
		end)
	end)
end)

return nil
