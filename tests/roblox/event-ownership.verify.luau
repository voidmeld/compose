--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("constructor event ownership", function()
	it("keeps fresh explicit events in the node cleanup batch", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local calls = 0
		local buttons = Compose.withOwner(owner, function()
			local nodes: { Compose.Node } = {}
			for index = 1, 2 do
				nodes[index] = runtime.constructors.TextButton {
					[Compose.event "Activated"] = function()
						calls += 1
					end,
				}
			end
			return nodes
		end)
		expect(Compose.owner.size(owner)):toBe(2)
		expect(emulator.environment.liveConnections()):toBe(2)
		for _, node in buttons do
			emulator.environment.fire(Support.instance(node), "Activated")
			runtime.borrow(node)
		end
		expect(calls):toBe(2)
		Compose.owner.dispose(owner)
		Compose.owner.dispose(owner)
		expect(emulator.environment.liveConnections()):toBe(0)
		for _, node in buttons do
			local instance = Support.instance(node)
			emulator.environment.fire(instance, "Activated")
			expect(emulator.environment.isAlive(instance)):toBe(true)
			instance:Destroy()
		end
		expect(calls):toBe(2)
		runtime:dispose()
	end)

	it("keeps event children in their creating owner's static node batch", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local child = Compose.withOwner(owner, function()
			local button = runtime.constructors.TextButton {
				[Compose.event "Activated"] = function() end,
			}
			runtime.constructors.Frame { button }
			return button
		end)
		expect(Compose.custodyOf(child)):toBe "owned"
		expect(Compose.owner.size(owner)):toBe(2)
		Compose.owner.dispose(owner)
		expect(emulator.environment.liveConnections()):toBe(0)
		expect(emulator.environment.isAlive(Support.instance(child))):toBe(false)
		runtime:dispose()
	end)

	it("preserves event children owned by a different owner", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local creator = Compose.createOwner(runtime.reactor)
		local parentOwner = Compose.createOwner(runtime.reactor)
		local child = Compose.withOwner(creator, function()
			return runtime.constructors.TextButton {
				[Compose.event "Activated"] = function() end,
			}
		end)
		Compose.withOwner(parentOwner, function()
			runtime.constructors.Frame { child }
		end)
		Compose.owner.dispose(parentOwner)
		local instance = Support.instance(child)
		expect(emulator.environment.isAlive(instance)):toBe(true)
		expect(instance.Parent):toBe(nil)
		expect(Compose.custodyOf(child)):toBe "owned"
		expect(emulator.environment.liveConnections()):toBe(1)
		Compose.owner.dispose(creator)
		expect(emulator.environment.liveConnections()):toBe(0)
		expect(emulator.environment.isAlive(instance)):toBe(false)
		runtime:dispose()
	end)

	it("separates same-owner and foreign event children under one parent", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local creator = Compose.createOwner(runtime.reactor)
		local parentOwner = Compose.createOwner(runtime.reactor)
		local function button(): Compose.Node
			return runtime.constructors.TextButton {
				[Compose.event "Activated"] = function() end,
			}
		end
		local foreign = Compose.withOwner(creator, function()
			return { button(), button() }
		end)
		local own = Compose.withOwner(parentOwner, function()
			local first, plain, last = button(), runtime.constructors.Frame {}, button()
			runtime.constructors.Frame { first, foreign[1], plain, foreign[2], last }
			return { first, plain, last }
		end)
		expect(Compose.owner.size(parentOwner)):toBe(5)
		Compose.owner.dispose(parentOwner)
		for _, node in own do
			expect(emulator.environment.isAlive(Support.instance(node))):toBe(false)
		end
		for _, node in foreign do
			local instance = Support.instance(node)
			expect(emulator.environment.isAlive(instance)):toBe(true)
			expect(instance.Parent):toBe(nil)
			expect(Compose.custodyOf(node)):toBe "owned"
		end
		expect(emulator.environment.liveConnections()):toBe(2)
		Compose.owner.dispose(creator)
		expect(emulator.environment.liveConnections()):toBe(0)
		runtime:dispose()
	end)

	it("keeps many same-owner event children out of the static cleanup", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local title = Compose.cell "Row"
		local children = Compose.withOwner(owner, function()
			local nodes: { Compose.Node } = {}
			for index = 1, 200 do
				nodes[index] = runtime.constructors.TextButton {
					Text = title,
					[Compose.event "Activated"] = function() end,
				}
			end
			runtime.constructors.Frame(table.clone(nodes))
			return nodes
		end)
		local held = Compose.owner.size(owner)
		Compose.withOwner(owner, function()
			runtime.constructors.Frame {}
		end)
		expect(Compose.owner.size(owner)):toBe(held + 1)
		Compose.owner.dispose(owner)
		expect(emulator.environment.liveConnections()):toBe(0)
		for _, node in children do
			expect(emulator.environment.isAlive(Support.instance(node))):toBe(false)
		end
		runtime:dispose()
	end)

	it("classifies event children around a directive sibling", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local creator = Compose.createOwner(runtime.reactor)
		local parentOwner = Compose.createOwner(runtime.reactor)
		local visible = Compose.cell(true)
		local foreign = Compose.withOwner(creator, function()
			return runtime.constructors.TextButton {}
		end)
		local own = Compose.withOwner(parentOwner, function()
			local first = runtime.constructors.TextButton {
				[Compose.event "Activated"] = function() end,
			}
			local last = runtime.constructors.TextButton {
				[Compose.event "Activated"] = function() end,
			}
			runtime.constructors.Frame {
				first,
				Compose.show(visible, function()
					Compose.withOwner(creator, function()
						runtime.decorate(foreign, {
							[Compose.event "Activated"] = function() end,
						})
					end)
					return runtime.constructors.TextLabel {}
				end),
				foreign,
				last,
			}
			return { first, last }
		end)
		Compose.owner.dispose(parentOwner)
		for _, node in own do
			expect(emulator.environment.isAlive(Support.instance(node))):toBe(false)
		end
		local instance = Support.instance(foreign)
		expect(emulator.environment.isAlive(instance)):toBe(true)
		expect(instance.Parent):toBe(nil)
		Compose.owner.dispose(creator)
		expect(emulator.environment.isAlive(instance)):toBe(false)
		expect(emulator.environment.liveConnections()):toBe(0)
		runtime:dispose()
	end)

	it("detaches borrowed event children before their same-owner parent is destroyed", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local child = Compose.withOwner(owner, function()
			local button = runtime.borrow(runtime.constructors.TextButton {
				[Compose.event "Activated"] = function() end,
			})
			runtime.constructors.Frame { button }
			return button
		end)
		expect(Compose.custodyOf(child)):toBe "borrowed"
		Compose.owner.dispose(owner)
		local instance = Support.instance(child)
		expect(emulator.environment.isAlive(instance)):toBe(true)
		expect(instance.Parent):toBe(nil)
		expect(emulator.environment.liveConnections()):toBe(0)
		instance:Destroy()
		runtime:dispose()
	end)

	it("preserves cleanup for a borrowed event node with directive children", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local visible = Compose.cell(true)
		local node = Compose.withOwner(owner, function()
			return runtime.borrow(runtime.constructors.TextButton {
				[Compose.event "Activated"] = function() end,
				Compose.show(visible, function()
					return runtime.constructors.TextLabel {}
				end),
			})
		end)
		Compose.owner.dispose(owner)
		local instance = Support.instance(node)
		expect(emulator.environment.isAlive(instance)):toBe(true)
		expect(emulator.environment.childrenOf(instance)):toEqual {}
		expect(emulator.environment.liveConnections()):toBe(0)
		instance:Destroy()
		runtime:dispose()
	end)

	it("releases multiple fast events on a borrowed constructor node", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local calls = 0
		local node = Compose.withOwner(owner, function()
			return runtime.constructors.TextButton {
				[Compose.event "Activated"] = function()
					calls += 1
				end,
				[Compose.event "Destroying"] = function()
					calls += 1
				end,
			}
		end)
		expect(Compose.owner.size(owner)):toBe(1)
		expect(emulator.environment.liveConnections()):toBe(2)
		runtime.borrow(node)
		Compose.owner.dispose(owner)
		expect(emulator.environment.liveConnections()):toBe(0)
		local instance = Support.instance(node)
		emulator.environment.fire(instance, "Activated")
		runtime:dispose()
		expect(emulator.environment.isAlive(instance)):toBe(true)
		instance:Destroy()
		expect(calls):toBe(0)
	end)

	it("preserves event cleanup when decoration retires the last fast binding", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local title = Compose.cell "First"
		local calls = 0
		local node = Compose.withOwner(owner, function()
			local button = runtime.constructors.TextButton {
				Text = title,
				[Compose.event "Activated"] = function()
					calls += 1
				end,
			}
			runtime.decorate(button, { Text = "Replaced" })
			return runtime.borrow(button)
		end)
		local instance = Support.instance(node)
		emulator.environment.fire(instance, "Activated")
		expect(calls):toBe(1)
		Compose.owner.dispose(owner)
		expect(emulator.environment.liveConnections()):toBe(0)
		title:set "Later"
		runtime:settle()
		emulator.environment.fire(instance, "Activated")
		expect(calls):toBe(1)
		expect(instance.Text):toBe "Replaced"
		expect(emulator.environment.isAlive(instance)):toBe(true)
		instance:Destroy()
		runtime:dispose()
	end)

	it("preserves opaque non-reference event tokens alongside reference connections", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local adapter = table.clone(emulator.adapter)
		local events = table.clone(assert(adapter.events))
		adapter.events = events
		local attach, detach = assert(events.attachEvent), assert(events.detachEvent)
		local first: unknown = nil
		local attached, detached = 0, 0
		events.attachEvent = function<Args...>(node: Compose.Node, name: string, handler: (Args...) -> ()): unknown
			local connection = attach(node, name, handler)
			attached += 1
			if attached == 1 then
				first = connection
				return false
			end
			return connection
		end
		events.detachEvent = function(connection: unknown)
			detached += 1
			detach(if connection == false then first else connection)
		end
		local runtime = Compose.createRuntime(adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local node = Compose.withOwner(owner, function()
			return runtime.borrow(runtime.constructors.TextButton {
				[Compose.event "Activated"] = function() end,
				[Compose.event "Destroying"] = function() end,
			})
		end)
		Compose.owner.dispose(owner)
		expect(attached):toBe(2)
		expect(detached):toBe(2)
		expect(emulator.environment.liveConnections()):toBe(0)
		Support.instance(node):Destroy()
		runtime:dispose()
	end)

	it("unwinds fast explicit events when constructor children fail", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local before = emulator.environment.liveObjects()
		local ok = pcall(function()
			Compose.withOwner(owner, function()
				runtime.constructors.TextButton {
					[Compose.event "Activated"] = function() end,
					false,
				}
			end)
		end)
		expect(ok):toBe(false)
		expect(emulator.environment.liveConnections()):toBe(0)
		expect(emulator.environment.liveObjects()):toBe(before)
		Compose.owner.dispose(owner)
		runtime:dispose()
	end)
end)

return nil
