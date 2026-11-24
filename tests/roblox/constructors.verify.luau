--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("open Roblox constructors and external custody", function()
	it("constructs an engine-defined class through both cached and dynamic constructors", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		emulator.environment.defineClass("AttributeCarrier", { super = "Folder" })
		local runtime = Compose.createRuntime(emulator.adapter)
		local Host = runtime.constructors
		expect(Host.AttributeCarrier):toBe(runtime.create "AttributeCarrier")
		local node = Compose.withRootOwner(function()
			local parent = Host.AttributeCarrier({ Host.Folder({}, "Child") }, "Carrier")
			expect(Support.instance(parent).Name):toBe "Carrier"
			expect(#Support.instance(parent):GetChildren()):toBe(1)
			return parent
		end, runtime.reactor)
		expect(emulator.environment.isAlive(Support.instance(node))):toBe(false)
	end)

	it("propagates an unsupported class failure without leaving nodes or an active owner", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local before = emulator.environment.liveObjects()
		local ok = pcall(function()
			Compose.withRootOwner(function()
				runtime.constructors.Folder {}
				runtime.constructors.NotACreatableClass {}
			end, runtime.reactor)
		end)
		expect(ok):toBe(false)
		expect(Compose.currentOwner()):toBe(nil)
		expect(emulator.environment.liveObjects()):toBe(before)
	end)

	it("returns a bare borrowed instance that survives its creation scope and runtime", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local before = emulator.environment.liveObjects()
		local node = Compose.withRootOwner(function()
			return runtime.borrow(runtime.constructors.Folder {})
		end, runtime.reactor)
		local instance = Support.instance(node)
		expect(Compose.custodyOf(node)):toBe "borrowed"
		expect(emulator.environment.isAlive(instance)):toBe(true)
		instance.Parent = Support.instance(emulator.root)
		instance:SetAttribute("WrittenLater", 7)
		runtime:dispose()
		expect(instance.Parent):toBe(emulator.root)
		expect(instance:GetAttribute "WrittenLater"):toBe(7)
		expect(emulator.environment.isAlive(instance)):toBe(true)
		instance:Destroy()
		expect(emulator.environment.liveObjects()):toBe(before)
	end)

	it("releases borrowed-node bindings with the creator while preserving the instance", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local title = Compose.cell "First"
		local calls = 0
		local node = Compose.withOwner(owner, function()
			return runtime.borrow(runtime.constructors.TextButton {
				Text = title,
				[Compose.event "Activated"] = function()
					calls += 1
				end,
			})
		end)
		local instance = Support.instance(node)
		emulator.environment.fire(instance, "Activated")
		expect(calls):toBe(1)
		Compose.owner.dispose(owner)
		local after = instance.Text
		title:set "Later"
		runtime:settle()
		emulator.environment.fire(instance, "Activated")
		expect(calls):toBe(1)
		expect(instance.Text):toBe(after)
		expect(emulator.environment.isAlive(instance)):toBe(true)
		instance:Destroy()
	end)

	it("unwinds an owned constructor before a failed build can transfer custody", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local before = emulator.environment.liveObjects()
		local ok = pcall(function()
			Compose.withRootOwner(function()
				return runtime.borrow(runtime.constructors.Folder { false })
			end, runtime.reactor)
		end)
		expect(ok):toBe(false)
		expect(emulator.environment.liveObjects()):toBe(before)
	end)

	it("can adopt a borrowed result after its construction scope has ended", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local node = Compose.withRootOwner(function()
			return runtime.borrow(runtime.constructors.Folder {})
		end, runtime.reactor)
		Compose.withRootOwner(function()
			runtime.adopt(node)
		end, runtime.reactor)
		expect(emulator.environment.isAlive(Support.instance(node))):toBe(false)
	end)

	it("preserves a borrowed constructor child when its same-owner parent ends", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local creator = Compose.createOwner(runtime.reactor)
		local child = Compose.withOwner(creator, function()
			local borrowed = runtime.borrow(runtime.constructors.Folder {})
			runtime.constructors.Folder { borrowed }
			return borrowed
		end)
		Compose.owner.dispose(creator)
		expect(emulator.environment.isAlive(Support.instance(child))):toBe(true)
		expect(Support.instance(child).Parent):toBe(nil)
		Support.instance(child):Destroy()
	end)

	it("preserves a bare result built in a temporary root within another owner", function()
		Compose.__resetForTests()
		local emulator = Support.emulator()
		local runtime = Compose.createRuntime(emulator.adapter)
		local creator = Compose.createOwner(runtime.reactor)
		local node = Compose.withOwner(creator, function()
			return Compose.withRootOwner(function()
				return runtime.borrow(runtime.constructors.Folder {})
			end, runtime.reactor)
		end)
		Compose.owner.dispose(creator)
		expect(emulator.environment.isAlive(Support.instance(node))):toBe(true)
		Support.instance(node):Destroy()
	end)
end)

return nil
