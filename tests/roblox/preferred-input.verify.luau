--!strict

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Emulator = require "../../src/test-host/roblox"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function serviceWith(preferred: string): (Emulator.Emulator, any)
	Compose.__resetForTests()
	ComposeRoblox.__resetForTests()
	local emulator = Emulator.create()
	emulator.defineClass("UserInputService", {
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
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local source = Compose.withOwner(owner, function()
			return ComposeRoblox.preferredInput(service, emulator.engine)
		end)
		local seen: { string } = {}
		Compose.withOwner(owner, function()
			Compose.watch(function(use)
				table.insert(seen, use(source))
			end)
		end)
		reactor:settle()
		service.PreferredInput = "Enum.PreferredInput.Gamepad"
		reactor:settle()
		expect(seen):toEqual { "Touch", "Gamepad" }
		owner.dispose()
	end)

	it("releases its property observer with the owner", function()
		local emulator, service = serviceWith "Enum.PreferredInput.KeyboardAndMouse"
		local before = emulator.liveConnections()
		local owner = Compose.createOwner(Compose.reactor())
		Compose.withOwner(owner, function()
			ComposeRoblox.preferredInput(service, emulator.engine)
		end)
		expect(emulator.liveConnections()):toBe(before + 1)
		owner.dispose()
		expect(emulator.liveConnections()):toBe(before)
	end)
end)

return nil
