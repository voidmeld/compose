--!strict

local Compose = require "../src/core"
local RobloxEmulator = require "../src/test-scene/roblox"
local Engine = require "../src/roblox/engine"
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
	local animator = (Verify.assertInstance(humanoid)):FindFirstChildOfClass "Animator"
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
						(Verify.assertInstance(arm)):SetAttribute("State", "armed")
						tier:set(tier:peek() + 1)
						track = Verify.assertInstance(Engine.invoke(Engine.readMember, animator, "LoadAnimation", clip))
						local playing = Verify.assertInstance(track)
						Engine.invoke(Engine.readMember, playing, "Play")
					end,
				},
			},
		}
	end, emulator.root)

	local gui = Verify.assertInstance(mounted)
	arm = gui:FindFirstChild("Arm", true)
	assert((Verify.assertInstance(arm)):IsA "GuiObject", "the simulated class chain answers IsA")
	assert((Verify.assertInstance(arm)):GetAttribute "Tier" == 1, "the declarative attribute reached the instance")

	emulator.environment.fire(Verify.assertInstance(arm), "Activated")
	runtime:settle()

	assert((Verify.assertInstance(arm)):GetAttribute "State" == "armed", "the handler's own SetAttribute took")
	assert((Verify.assertInstance(track)).IsPlaying, "the loaded track was told to play")
	assert(
		(Verify.assertInstance(track)).ClassName == "AnimationTrack",
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

	local state = tostring((Verify.assertInstance(arm)):GetAttribute "State")
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
