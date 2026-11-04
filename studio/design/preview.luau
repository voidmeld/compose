--!strict

local Compose = require "../../src/core"
local Roblox = require "../../src/roblox"
local Design = require "../../src/design"
local Editor = require "../../src/design-editor"
local Verify = require "../../.lute/dependencies/verify/src/core"
local Host = require "../../.lute/dependencies/verify/src/roblox"

local function instance(value: unknown): Instance
	assert(typeof(value) == "Instance")
	return value
end

local function run(context: Verify.Context, direct: boolean, uiDesign: boolean)
	local players = game:GetService "Players"
	local player = assert(players.LocalPlayer)
	if player.Character then
		player.Character:Destroy()
	end
	local gui = Instance.new "ScreenGui"
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild "PlayerGui"
	local camera = assert(workspace.CurrentCamera)
	local lighting = game:GetService "Lighting"
	lighting.ClockTime = 17
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(65, 75, 95)
	local atmosphere = Instance.new "Atmosphere"
	atmosphere.Density = 0.25
	atmosphere.Haze = 1.2
	atmosphere.Parent = lighting
	local runtime = Roblox.createRuntime()
	local environment = Roblox.designEnvironment()
	local library = if uiDesign
		then Editor.robloxLibrary(runtime, environment)
		else Editor.roblox3DLibrary(runtime, environment, {
			numberRange = NumberRange.new,
			numberSequence = function(points: { { number } }): unknown
				local keys = {}
				for _, point in points do
					table.insert(keys, NumberSequenceKeypoint.new(point[1], point[2]))
				end
				return NumberSequence.new(keys)
			end,
			colorSequence = function(points: { { number } }): unknown
				local keys = {}
				for _, point in points do
					table.insert(keys, ColorSequenceKeypoint.new(point[1], Color3.new(point[2], point[3], point[4])))
				end
				return ColorSequence.new(keys)
			end,
		})
	local document = Design.document.new("PreviewComparison", library, if uiDesign then "Stack" else "Model")
	local sample = Compose.cell "ordinary"
	local backdropEnabled = Compose.cell(false)
	local bindings: { [string]: Design.Resolved } = { sample = { readable = sample } }
	local function backdrop(): unknown
		return runtime.constructors.Frame {
			Name = "SceneBackdrop",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Compose.show(backdropEnabled, function(): Compose.Node
				local sceneCamera = runtime.constructors.Camera {
					CFrame = CFrame.lookAt(Vector3.new(0, 2, 12), Vector3.new(0, 2, 0)),
					FieldOfView = 50,
				}
				return runtime.constructors.ViewportFrame {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(18, 20, 26),
					Ambient = Color3.fromRGB(100, 110, 140),
					LightColor = Color3.fromRGB(255, 220, 180),
					CurrentCamera = sceneCamera,
					sceneCamera,
					runtime.constructors.Part {
						Anchored = true,
						Size = Vector3.new(4, 4, 4),
						CFrame = CFrame.new(0, 2, 0),
						Color = Color3.fromRGB(50, 80, 120),
						Material = Enum.Material.Metal,
					},
				}
			end),
		}
	end
	local function change(id: string, key: string, value: Design.Literal)
		document = Design.document.change(document, library, id, key, { literal = value })
	end
	local function insert(parent: string, kind: string, name: string): string
		local id
		document, id = Design.document.insert(document, library, parent, kind)
		document = Design.document.rename(document, library, id, name)
		return id
	end
	if uiDesign then
		document = Design.document.setContract(
			document,
			library,
			{ inputs = { { id = "sample", kind = "readable", type = "string", preview = "ordinary" } }, outputs = {} }
		)
		change("n1", "width", 389)
		change("n1", "height", 762)
		change("n1", "fillWidth", false)
		local text = insert("n1", "Text", "SampleState")
		change(text, "text", "Busy")
		document = Design.document.change(document, library, text, "text", { input = "sample" })
		change(text, "width", 300)
		change(text, "height", 80)
		local button = insert("n1", "Button", "SampleAction")
		change(button, "text", "Please wait")
		change(button, "width", 300)
		change(button, "height", 48)
	else
		local part = insert("n1", "Part", "MaterialSample")
		change(part, "size", { 8, 6, 3 })
		change(part, "position", { 0, 3, 0 })
		change(part, "material", "Metal")
		change(part, "color", "#4477BB")
		local first = insert(part, "Attachment", "BeamStart")
		change(first, "position", { -4, 3, 0 })
		local second = insert(part, "Attachment", "BeamEnd")
		change(second, "position", { 4, 3, 0 })
		local beam = insert(part, "Beam", "LightBeam")
		document = Design.document.change(document, library, beam, "attachment0", { node = first })
		document = Design.document.change(document, library, beam, "attachment1", { node = second })
		change(beam, "width0", 0.5)
		change(beam, "width1", 0.5)
		change(beam, "faceCamera", true)
		change(beam, "color", "#00FFFF")
		local light = insert(second, "PointLight", "WarmLight")
		change(light, "brightness", 4)
		change(light, "range", 30)
		local emitter = insert(first, "ParticleEmitter", "Particles")
		change(emitter, "texture", "rbxasset://textures/particles/sparkles_main.dds")
		change(emitter, "rate", 30)
		change(emitter, "lifetime", { 2, 2 })
		change(emitter, "speed", { 2, 2 })
		change(emitter, "size", 0.5)
	end
	local editor = Editor.create(library, document, gui, {
		runtime = runtime,
		environment = environment,
		devices = { Editor.devices.all[1] },
		bindings = if uiDesign then bindings else nil,
		backdrop = if uiDesign then backdrop else nil,
		scene = if uiDesign then nil else { world = workspace, camera = camera },
		previews = {
			{
				name = "Backdrop",
				choices = { "none", "scene" },
				initial = if uiDesign then "scene" else "none",
				select = function(choice: string)
					backdropEnabled:set(choice == "scene")
				end,
			},
			{
				name = "Environment",
				choices = { "day", "evening" },
				initial = "evening",
				select = function(choice: string)
					lighting.ClockTime = if choice == "day" then 12 else 17
					atmosphere.Density = if choice == "day" then 0.1 else 0.25
				end,
			},
			{
				name = "State",
				choices = { "ordinary", "empty", "busy", "error" },
				select = function(choice: string)
					sample:set(choice)
				end,
			},
		},
	})
	task.wait(2)
	if uiDesign then
		assert(editor.execute({ action = "ActualSize", enabled = true }).ok)
		for _, state in { "ordinary", "empty", "busy", "error", "busy" } do
			assert(editor.execute({ action = "Preview", name = "State", choice = state }).ok)
			task.wait()
			local text = instance(assert(editor.canvas.current().stage).nodes.n2)
			assert(text:IsA "TextLabel" and text.Text == state)
		end
	else
		assert(editor.execute({ action = "Camera", preset = "approach-20" }).ok)
		assert(editor.execute({ action = "Guides", enabled = false }).ok)
		assert(editor.execute({ action = "Select", ids = {} }).ok)
	end
	task.wait(1)
	local viewport = if uiDesign
		then assert(editor.canvas.current().stage).surface
		else assert(editor.canvas.current().scene).viewport
	local region = instance(viewport)
	assert(region:IsA "GuiObject")
	local position, size = region.AbsolutePosition, region.AbsoluteSize
	context:attach("region.txt", "text/plain", `{position.X},{position.Y},{size.X},{size.Y}`)
	if direct then
		local frame, focus, fov = camera.CFrame, camera.Focus, camera.FieldOfView
		editor.dispose()
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame, camera.Focus, camera.FieldOfView = frame, focus, fov
		local parent: Compose.Node = workspace
		if uiDesign then
			local surface = Instance.new "Frame"
			surface.Name = "GameScreen"
			surface.Position = UDim2.fromOffset(position.X, position.Y)
			surface.Size = UDim2.fromOffset(size.X, size.Y)
			surface.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
			surface.ClipsDescendants = true
			surface.Parent = gui
			parent = surface
			runtime.mount(function(): Compose.Node
				return instance(backdrop())
			end, parent)
		end
		runtime.mount(function(): Compose.Node
			return instance(Design.render(document, library, { bindings = if uiDesign then bindings else nil }))
		end, parent)
	end
	task.wait(3)
	local character = player.Character
	if character then
		character.Parent = nil
	end
	if not uiDesign then
		local root =
			assert(workspace:FindFirstChild("PreviewComparison", true) or workspace:FindFirstChild("Model", true))
		local part = assert(root:FindFirstChild("MaterialSample", true))
		assert(part:IsA "Part" and part.Material == Enum.Material.Metal)
		local beam = assert(part:FindFirstChild "LightBeam")
		assert(beam:IsA "Beam" and beam.Attachment0 and beam.Attachment1 and beam.Enabled)
		local emitter = assert(part:FindFirstChild("Particles", true))
		assert(emitter:IsA "ParticleEmitter" and emitter.Enabled and emitter.Rate == 30)
	end
	context:step("same document and native renderer with preset lighting, live effects and camera", function() end)
end

return function(host: Host.CaseHostName): Host.CaseEntry
	local cases: { Verify.NamedCase } = {}
	for _, mode in
		{
			{ id = "editor-3d", direct = false, ui = false },
			{ id = "game-3d", direct = true, ui = false },
			{ id = "editor-ui", direct = false, ui = true },
			{ id = "game-ui", direct = true, ui = true },
		}
	do
		table.insert(cases, {
			id = mode.id,
			name = mode.id,
			requires = { "roblox-engine" },
			timeoutSeconds = 30,
			run = function(context: Verify.Context)
				run(context, mode.direct, mode.ui)
			end,
		})
	end
	return {
		cases = cases,
		now = os.clock,
		options = {
			executor = host,
			capabilities = { "roblox-engine" },
			environment = { version = Host.experienceHost.nativeEngine().version, context = "Client" },
		},
	}
end
