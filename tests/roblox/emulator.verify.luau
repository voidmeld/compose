--!strict

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Emulator = require "../../src/test-scene/roblox"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function fresh(): Emulator.Emulator
	Compose.__resetForTests()
	ComposeRoblox.__resetForTests()
	return Support.emulator()
end

local function operations(emulator: Emulator.Emulator): { string }
	local names: { string } = {}
	for _, entry in emulator.log() do
		table.insert(names, entry.operation)
	end
	return names
end

describe("roblox test scene adapter", function()
	describe("the host", function()
		it("is the adapter's own host, and cannot order children", function()
			local emulator = fresh()
			expect(emulator.adapter.name):toBe "roblox"
			expect(emulator.adapter.render):toBe(emulator.render)
			expect(emulator.render.moveChild):toBeNil()
			expect(Compose.createRuntime(emulator.adapter)):toBeOk()
		end)

		it("logs the render verbs a mount and a disposal issue", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.adapter)
			local Frame = runtime.create "Frame"

			emulator.clearLog()
			local dispose, frame = runtime.mount(function()
				return Frame { Name = "Panel", Attributes = { Tier = 2 } }
			end, emulator.root)

			expect(emulator.environment.propertyOf((frame :: unknown) :: Emulator.Instance, "Name")):toBe "Panel"
			expect(emulator.environment.attributeOf((frame :: unknown) :: Emulator.Instance, "Tier")):toBe(2)
			expect(operations(emulator)):toContain "createNode"
			expect(operations(emulator)):toContain "setProperty"
			expect(operations(emulator)):toContain "setAttribute"
			expect(operations(emulator)):toContain "insertChild"

			local entry = emulator.log()[1]
			expect(entry.operation):toBe "createNode"
			expect(entry.className):toBe "Frame"

			emulator.clearLog()
			dispose()
			expect(operations(emulator)):toContain "destroyNode"
			expect(emulator.environment.childrenOf((emulator.root :: unknown) :: Emulator.Instance)):toEqual {}
		end)

		it("drives the frame loop from step", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.adapter)
			local Frame = runtime.create "Frame"
			local target = Compose.cell(0)

			local dispose, frame = runtime.mount(function()
				local smooth = runtime.spring(function(use)
					return use(target)
				end, { period = 0.1 })
				return Frame {
					LayoutOrder = function(use)
						return math.round(use(smooth))
					end,
				}
			end, emulator.root)

			target:set(10)
			runtime:settle()
			for _ = 1, 200 do
				emulator.environment.step(1 / 60)
			end
			expect(emulator.environment.propertyOf((frame :: unknown) :: Emulator.Instance, "LayoutOrder")):toBe(10)
			expect(emulator.environment.now()):toBeCloseTo(200 / 60, 1e-9)

			dispose()
			expect(emulator.environment.liveConnections()):toBe(0)
		end)
	end)

	describe("failure injection", function()
		it("unwinds a failed node creation and leaves nothing behind", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.adapter)
			local Frame = runtime.create "Frame"
			local before = emulator.environment.liveObjects()

			emulator.failNext "createNode"
			local ok, err: unknown = pcall(function()
				runtime.mount(function()
					return Frame {}
				end, emulator.root)
			end)

			expect(ok):toBe(false)
			expect(tostring(err)):toContain "injected failure in createNode"
			expect(emulator.environment.liveObjects()):toBe(before)
			expect(emulator.environment.childrenOf((emulator.root :: unknown) :: Emulator.Instance)):toEqual {}
		end)

		it("unwinds a failed property write and destroys the node it was writing to", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.adapter)
			local Frame = runtime.create "Frame"
			local before = emulator.environment.liveObjects()

			emulator.failNext "setProperty"
			local ok = pcall(function()
				runtime.mount(function()
					return Frame { Name = "Doomed" }
				end, emulator.root)
			end)

			expect(ok):toBe(false)
			expect(emulator.environment.liveObjects()):toBe(before)
			expect(emulator.environment.childrenOf((emulator.root :: unknown) :: Emulator.Instance)):toEqual {}
		end)

		it("refuses an attribute on demand, and reports it by name", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.adapter)
			local Frame = runtime.create "Frame"

			emulator.failNext "setAttribute"
			local ok, err: unknown = pcall(function()
				runtime.mount(function()
					return Frame { Attributes = { Tier = 1 } }
				end, emulator.root)
			end)

			expect(ok):toBe(false)
			local report = Compose.parseDiagnostic(tostring(err))
			expect(report ~= nil):toBe(true)
			expect((report :: Compose.Diagnostic).code):toBe "props/attribute-value"
			expect(emulator.environment.childrenOf((emulator.root :: unknown) :: Emulator.Instance)):toEqual {}
		end)

		it("counts down the injected failures and then stops", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.adapter)
			local Frame = runtime.create "Frame"

			emulator.failNext("createNode", 2)
			for _ = 1, 2 do
				expect(pcall(function()
					runtime.mount(function()
						return Frame {}
					end, emulator.root)
				end)):toBe(false)
			end

			local dispose = runtime.mount(function()
				return Frame {}
			end, emulator.root)
			expect(#emulator.environment.childrenOf((emulator.root :: unknown) :: Emulator.Instance)):toBe(1)
			dispose()
		end)

		it("clears an injection that was never spent", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.adapter)
			local Frame = runtime.create "Frame"

			emulator.failNext "insertChild"
			emulator.clearFailures()
			local dispose = runtime.mount(function()
				return Frame {}
			end, emulator.root)
			expect(#emulator.environment.childrenOf((emulator.root :: unknown) :: Emulator.Instance)):toBe(1)
			dispose()
		end)
	end)
end)

return nil
