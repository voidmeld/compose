--!strict

local Compose = require "../src/core"
local RobloxEmulator = require "../src/test-scene/roblox"
local Verify = require "../.lute/dependencies/verify/src/roblox"

local function run(): string
	local environment = Verify.testEnvironment()
	local emulator = RobloxEmulator.create(environment, Verify.environmentEngine(environment))
	local runtime = Compose.createRuntime(emulator.adapter)
	local Host = runtime.constructors

	local rig = emulator.createInstance("Model", {
		Name = "Rig",
		emulator.createInstance("Humanoid", { emulator.createInstance "Animator" }),
		Parent = emulator.root,
	})
	local humanoid = rig:FindFirstChildOfClass "Humanoid"
	local animator = (humanoid :: RobloxEmulator.Instance):FindFirstChildOfClass "Animator"
	local clip = emulator.createInstance "Animation"

	local tier = Compose.cell(1)
	local track: RobloxEmulator.Instance? = nil

	local arm: RobloxEmulator.Instance? = nil

	local dispose, mounted = runtime.mount(function()
		return Host.ScreenGui {
			Name = "Hud",
			Host.Frame {
				Name = "Bar",
				Host.TextButton {
					Name = "Arm",
					Text = "Arm",
					Attributes = {
						Tier = function(use: Compose.Use)
							return use(tier)
						end,
					},

					Activated = function()
						(arm :: RobloxEmulator.Instance):SetAttribute("State", "armed")
						tier:set(tier:peek() + 1)
						track = ((animator :: RobloxEmulator.Instance).LoadAnimation :: (
							RobloxEmulator.Instance,
							RobloxEmulator.Instance
						) -> RobloxEmulator.Instance)(animator :: RobloxEmulator.Instance, clip)
						local playing = track :: RobloxEmulator.Instance
						(playing.Play :: (RobloxEmulator.Instance) -> ())(playing)
					end,
				},
			},
		}
	end, emulator.root)

	local gui = mounted :: RobloxEmulator.Instance
	arm = gui:FindFirstChild("Arm", true)
	assert((arm :: RobloxEmulator.Instance):IsA "GuiObject", "the simulated class chain answers IsA")
	assert((arm :: RobloxEmulator.Instance):GetAttribute "Tier" == 1, "the declarative attribute reached the instance")

	emulator.environment.fire(arm :: RobloxEmulator.Instance, "Activated")
	runtime:settle()

	assert((arm :: RobloxEmulator.Instance):GetAttribute "State" == "armed", "the handler's own SetAttribute took")
	assert((track :: RobloxEmulator.Instance).IsPlaying, "the loaded track was told to play")
	assert(
		(track :: RobloxEmulator.Instance).ClassName == "AnimationTrack",
		"LoadAnimation returns a track, not a stub table"
	)

	local before = emulator.environment.liveObjects()
	emulator.failNext "setProperty"
	assert(not pcall(function()
		runtime.mount(function()
			return Host.Frame { Name = "Doomed" }
		end, emulator.root)
	end), "the injected failure must surface")
	assert(emulator.environment.liveObjects() == before, "a failed mount leaves no instance behind")

	local state = tostring((arm :: RobloxEmulator.Instance):GetAttribute "State")
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
