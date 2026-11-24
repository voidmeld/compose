--!strict

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Emulator = require "../../src/test-scene/roblox"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function serviceWith(preferred: string): (Emulator.Emulator, Emulator.Instance)
	Compose.__resetForTests()
	ComposeRoblox.__resetForTests()
	local emulator = Support.emulator()
	emulator.environment.defineClass("UserInputService", {
		super = "Instance",
		properties = { PreferredInput = preferred },
	})
	return emulator, emulator.createInstance "UserInputService"
end

describe("ComposeRoblox.preferredInput", function()
	it("maps each PreferredInput enum value to its input class and style token", function()
		expect(ComposeRoblox.preferredInputSpec "Enum.PreferredInput.Touch"):toEqual {
			class = "Touch",
			token = "touch",
		}
		expect(ComposeRoblox.preferredInputSpec "Enum.PreferredInput.KeyboardAndMouse"):toEqual {
			class = "KeyboardAndMouse",
			token = "keyboard-and-mouse",
		}
		expect(ComposeRoblox.preferredInputSpec "Enum.PreferredInput.Gamepad"):toEqual {
			class = "Gamepad",
			token = "gamepad",
		}
	end)

	it("updates when PreferredInput changes", function()
		local emulator, service = serviceWith "Enum.PreferredInput.Touch"
		local before = emulator.environment.liveConnections()
		local reactor = Compose.reactor.create()
		local owner = Compose.createOwner(reactor)
		local source = Compose.withOwner(owner, function()
			return ComposeRoblox.preferredInput(service, emulator.engine)
		end)
		expect(emulator.environment.liveConnections()):toBe(before + 1)
		local seen: { string } = {}
		Compose.withOwner(owner, function()
			Compose.watch(function(use)
				table.insert(seen, use(source))
			end)
		end)
		Compose.reactor.settle(reactor)
		service.PreferredInput = "Enum.PreferredInput.Gamepad"
		Compose.reactor.settle(reactor)
		expect(seen):toEqual { "Touch", "Gamepad" }
		Compose.owner.dispose(owner)
		expect(emulator.environment.liveConnections()):toBe(before)
	end)
end)

return nil
