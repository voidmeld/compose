--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("direct property bindings", function()
	it("restores a coalesced setter after an abandoned terminal cascade", function(own)
		local world = Support.world()
		local source = Compose.cell(0)
		local owner = Compose.createOwner(world.runtime.reactor)
		own(function()
			Compose.owner.dispose(owner)
		end)
		local looping = false
		local seen = 0
		Compose.owner.watchTerminal(owner, function(use)
			seen = use(source)
			if looping then
				source:set(seen + 1)
				source:set(seen + 2)
				source:set(seen + 3)
			end
		end)
		looping = true
		expect(function()
			source:set(1)
		end):toThrow "did not settle"
		looping = false
		local nextValue = source:peek() + 1
		source:set(nextValue)
		expect(seen):toBe(nextValue)
		expect(world.pending()):toBe(0)
	end)

	it("writes a function-bound property only when its value changes", function(own)
		local world = Support.world()
		local selected = Compose.cell(1)
		local runs = 0
		own((world.runtime.mount(function()
			return world.create "Label" {
				Value = function(use: Compose.Use)
					runs += 1
					return if use(selected) == 7 then "chosen" else "idle"
				end,
			}
		end, world.root)))
		local node = world.host.childrenOf(world.root)[1]
		world.host.resetCounts()
		for index = 2, 6 do
			selected:set(index)
			world.settle()
		end
		expect(runs):toBe(6)
		expect(world.host.counts().setProperty):toBe(0)
		selected:set(7)
		world.settle()
		expect(world.host.propertyOf(node, "Value")):toBe "chosen"
		expect(world.host.counts().setProperty):toBe(1)
	end)

	it("writes an unchanged function-bound value again after the host changed the property", function(own)
		local world = Support.world()
		local request = Compose.cell(1)
		own((world.runtime.mount(function()
			return world.create "Label" {
				Value = function(use: Compose.Use)
					use(request)
					return 0
				end,
			}
		end, world.root)))
		local node = world.host.childrenOf(world.root)[1]
		world.host.adapter.render.setProperty(node, "Value", 300)
		world.host.resetCounts()
		request:set(2)
		world.settle()
		expect(world.host.propertyOf(node, "Value")):toBe(0)
		expect(world.host.counts().setProperty):toBe(1)
		request:set(3)
		world.settle()
		expect(world.host.counts().setProperty):toBe(1)
	end)

	it("keeps cached setters valid after flushes and value type changes", function(own)
		local world = Support.world()
		local source = Compose.cell(Support.erased(0))
		local saved = source.set
		local comparisons = 0
		local class = {
			__eq = function(_first: {}, _second: {}): boolean
				comparisons += 1
				return false
			end,
		}
		local first, second = setmetatable({}, class), setmetatable({}, class)
		own((world.runtime.mount(function()
			return world.create "Label" {
				Value = function(use: Compose.Use)
					return use(source)
				end,
			}
		end, world.root)))
		local node = world.host.childrenOf(world.root)[1]
		world.batch(function()
			source:set(1)
			source:set(2)
			saved = source.set
			source:set(3)
			source:set(first)
			saved(source, second)
			source:set(first)
		end)
		expect(comparisons):toBe(2)
		expect(rawequal(world.host.propertyOf(node, "Value"), first)):toBe(true)
		saved(source, 4)
		expect(world.host.propertyOf(node, "Value")):toBe(4)
	end)

	it("recovers a queued terminal that fails before reading its source", function(own)
		local world = Support.world()
		local source = Compose.cell(0)
		local failing = false
		own((world.runtime.mount(function()
			return world.create "Label" {
				Value = function(use: Compose.Use)
					if failing then
						error("failed before read", 0)
					end
					return use(source)
				end,
			}
		end, world.root)))
		failing = true
		expect(function()
			world.batch(function()
				source:set(1)
				source:set(2)
				source:set(3)
			end)
		end):toThrow "failed before read"
		failing = false
		source:set(4)
		local node = world.host.childrenOf(world.root)[1]
		expect(world.host.propertyOf(node, "Value")):toBe(4)
		expect(world.pending()):toBe(0)
	end)

	it("restores notifications after a queued body runs, fails or gains another reader", function(own)
		local world = Support.world()
		local source = Compose.cell(0)
		local fail = false
		own((world.runtime.mount(function()
			return world.create "Label" {
				Text = function(use: Compose.Use)
					if fail then
						error("binding failed", 0)
					end
					return tostring(use(source))
				end,
			}
		end, world.root)))
		local node = world.host.childrenOf(world.root)[1]
		world.batch(function()
			source:set(1)
			source:set(2)
			local seen = -1
			own(world.runtime:watch(function(use: Compose.Use)
				seen = use(source)
			end))
			source:set(3)
			expect(seen):toBe(2)
		end)
		expect(world.host.propertyOf(node, "Text")):toBe "3"
		fail = true
		expect(function()
			world.batch(function()
				source:set(4)
				source:set(5)
			end)
		end):toThrow "binding failed"
		fail = false
		source:set(6)
		expect(world.host.propertyOf(node, "Text")):toBe "6"
		expect(world.pending()):toBe(0)
	end)

	it("keeps instrumentation accurate when enabled after a binding is queued", function(own)
		local world = Support.world()
		local source = Compose.cell(0)
		own(function()
			Compose.setWorkCounters(false)
			Compose.setYieldChecking(false)
		end)
		own((world.runtime.mount(function()
			return world.create "Label" {
				Text = function(use: Compose.Use)
					return tostring(use(source))
				end,
			}
		end, world.root)))
		world.batch(function()
			source:set(1)
			source:set(2)
			Compose.setWorkCounters(true)
			Compose.resetWorkCounters()
			source:set(3)
			source:set(3)
		end)
		expect(Compose.readWorkCounters().cellWrites):toBe(1)
		expect(Compose.readWorkCounters().cellWritesSuppressed):toBe(1)
		Compose.setWorkCounters(false)
		world.batch(function()
			source:set(4)
			Compose.setYieldChecking(true)
			source:set(5)
		end)
		local node = world.host.childrenOf(world.root)[1]
		expect(world.host.propertyOf(node, "Text")):toBe "5"
	end)

	it("coalesces cell and body writes through nested batches", function(own)
		local world = Support.world()
		local source = Compose.cell(0)
		own((world.runtime.mount(function()
			return world.create "Label" {
				Value = source,
				Text = function(use: Compose.Use)
					return tostring(use(source))
				end,
			}
		end, world.root)))
		local node = world.host.childrenOf(world.root)[1]
		world.host.resetCounts()
		world.batch(function()
			source:set(1)
			world.batch(function()
				for value = 2, 500 do
					source:set(value)
				end
			end)
			world.settle()
			expect(world.host.propertyOf(node, "Value")):toBe(0)
			expect(world.host.propertyOf(node, "Text")):toBe "0"
			expect(world.host.counts().setProperty):toBe(0)
		end)
		expect(world.host.propertyOf(node, "Value")):toBe(500)
		expect(world.host.propertyOf(node, "Text")):toBe "500"
		expect(world.host.counts().setProperty):toBe(2)
		expect(world.pending()):toBe(0)
	end)

	it("commits coherent formula values in first notification order", function(own)
		local world = Support.world()
		local first, second = Compose.cell(0), Compose.cell(0)
		local order: { string } = {}
		local render = table.clone(world.host.adapter.render)
		local write = render.setProperty
		render.setProperty = function(node, key, value)
			write(node, key, value)
			table.insert(order, key .. "=" .. tostring(value))
		end
		local host = table.clone(world.host.adapter)
		host.render = render
		local runtime = Compose.createRuntime(host)
		own(function()
			runtime:dispose()
		end)
		own((runtime.mount(function()
			local firstNode = runtime.create "Label" { First = first }
			local secondNode = runtime.create "Label" {
				Sum = function(use: Compose.Use)
					return use(first) + use(second)
				end,
			}
			return runtime.create "Frame" { firstNode, secondNode }
		end, world.root)))
		table.clear(order)
		runtime:batch(function()
			first:set(1)
			second:set(2)
			first:set(3)
			expect(order):toEqual {}
		end)
		expect(order):toEqual { "First=3", "Sum=5" }
	end)

	it("stops remaining property writes when disposed during notification", function(own)
		local world = Support.world()
		local source = Compose.cell(0)
		local dispose: () -> () = function() end
		local render = table.clone(world.host.adapter.render)
		local write = render.setProperty
		local writes = 0
		render.setProperty = function(node, key, value)
			write(node, key, value)
			if value == 1 then
				writes += 1
				dispose()
			end
		end
		local host = table.clone(world.host.adapter)
		host.render = render
		local runtime = Compose.createRuntime(host)
		dispose = runtime.mount(function()
			local children = {}
			for index = 1, 3 do
				children[index] = runtime.create "Label" { Value = source }
			end
			return runtime.create "Frame"(children)
		end, world.root)
		own(dispose)
		source:set(1)
		source:set(2)
		expect(writes):toBe(1)
		expect(world.host.childrenOf(world.root)):toEqual {}
		expect(world.pending()):toBe(0)
	end)

	it("retracks a bound formula after its dependencies change inside a batch", function(own)
		local world = Support.world()
		local choose = Compose.cell(true)
		local first, second = Compose.cell(1), Compose.cell(10)
		local derived = Compose.formula(function(use: Compose.Use)
			return if use(choose) then use(first) else use(second)
		end)
		own(function()
			derived:dispose()
		end)
		own((world.runtime.mount(function()
			return world.create "Label" { Value = derived }
		end, world.root)))
		local node = world.host.childrenOf(world.root)[1]
		world.host.resetCounts()
		world.batch(function()
			first:set(2)
			first:set(3)
			expect(derived:peek()):toBe(3)
			first:set(4)
			choose:set(false)
			second:set(20)
			second:set(30)
			expect(derived:peek()):toBe(30)
			second:set(40)
		end)
		expect(world.host.propertyOf(node, "Value")):toBe(40)
		expect(world.host.counts().setProperty):toBe(1)
		first:set(5)
		expect(world.host.counts().setProperty):toBe(1)
		second:set(50)
		expect(world.host.propertyOf(node, "Value")):toBe(50)
	end)
end)

return nil
