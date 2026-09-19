--!strict

local Compose = require "../src/core"
local RobloxEmulator = require "../src/test-host/roblox"

local function run(): string
	local emulator = RobloxEmulator.create()
	local runtime = Compose.createRuntime(emulator.host)

	local ScreenGui = runtime.create "ScreenGui"
	local Frame = runtime.create "Frame"
	local TextButton = runtime.create "TextButton"

	local rig = emulator.createInstance("Model", {
		Name = "Rig",
		emulator.createInstance("Humanoid", { emulator.createInstance "Animator" }),
		Parent = emulator.root,
	})
	local humanoid = rig:FindFirstChildOfClass "Humanoid"
	local animator = humanoid:FindFirstChildOfClass "Animator"
	local clip = emulator.createInstance "Animation"

	local tier = Compose.cell(1)
	local track: any = nil

	local arm: any = nil

	local dispose, mounted = runtime.mount(function()
		return ScreenGui {
			Name = "Hud",
			Frame {
				Name = "Bar",
				TextButton {
					Name = "Arm",
					Text = "Arm",
					Attributes = {
						Tier = function(use: Compose.Use)
							return use(tier)
						end,
					},

					Activated = function()
						arm:SetAttribute("State", "armed")
						tier:set(tier:peek() + 1)
						track = animator:LoadAnimation(clip)
						track:Play()
					end,
				},
			},
		}
	end, emulator.root)

	local gui: any = mounted
	arm = gui:FindFirstChild("Arm", true)
	assert(arm:IsA "GuiObject", "the emulated class chain answers IsA")
	assert(arm:GetAttribute "Tier" == 1, "the declarative attribute reached the instance")

	emulator.fire(arm, "Activated")
	runtime:settle()

	assert(arm:GetAttribute "State" == "armed", "the handler's own SetAttribute took")
	assert(track.IsPlaying, "the loaded track was told to play")
	assert(track.ClassName == "AnimationTrack", "LoadAnimation returns a track, not a stub table")

	local before = emulator.liveObjects()
	emulator.failNext "setProperty"
	assert(not pcall(function()
		runtime.mount(function()
			return Frame { Name = "Doomed" }
		end, emulator.root)
	end), "the injected failure must surface")
	assert(emulator.liveObjects() == before, "a failed mount leaves no instance behind")

	local state = tostring(arm:GetAttribute "State")
	local reached = tier:peek()

	dispose()
	assert(gui.Parent == nil, "what Compose created is destroyed")
	assert(rig.Parent == emulator.root, "what it was handed is left standing")

	return ("%s tier %d"):format(state, reached)
end

return {
	name = "roblox-emulator",
	what = "an Instance-shaped headless emulator: refs, methods, signals, animation, fault injection",
	expected = "armed tier 2",
	run = run,
}
