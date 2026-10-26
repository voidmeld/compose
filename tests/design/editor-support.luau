--!strict

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Design = require "../../src/design"
local Editor = require "../../src/design-editor"
local Emulator = require "../../src/test-scene/roblox"
local VerifyRoblox = require "../../.lute/dependencies/verify/src/roblox"
local Lute = require "../../.lute/dependencies/verify/src/lute"

local snapshot = Lute.fixture.load()
local values = VerifyRoblox.reflectionSnapshot.library(snapshot)

type TextParameters = {
	Text: string,
	Size: number,
	Width: number,
	Font: { Family: string, Weight: unknown, Style: unknown },
	RichText: boolean?,
}

local function instance(node: unknown): VerifyRoblox.Instance
	return VerifyRoblox.assertInstance(node)
end

local function world(space: string?)
	Compose.__resetForTests()
	ComposeRoblox.__resetForTests()
	local roots: { VerifyRoblox.Instance } = {}
	local styled: ((VerifyRoblox.Instance, string) -> unknown)? = nil
	local bridge = Lute.fixture.bridge(snapshot, {
		handlerErrors = "raise",
		ui = {
			measureBounds = function(parameters: TextParameters): unknown
				local width = (utf8.len(parameters.Text) or 0) * parameters.Size * 0.6
				return values.Vector2.new(width, parameters.Size * 1.2)
			end,
		},
		layout = {
			read = function(object: VerifyRoblox.Instance, property: string): unknown
				if property == "TextTruncate" then
					return values.Enum.TextTruncate.None
				end
				return assert(styled)(object, property)
			end,
			roots = function(): { VerifyRoblox.Instance }
				return roots
			end,
			viewport = function()
				return { X = 1400, Y = 900 }
			end,
		},
	})
	styled = assert(bridge.ui).styled
	local env = bridge.environment
	local emulator = Emulator.create(env, bridge.engine)
	local runtime: Compose.Runtime = Compose.createRuntime(emulator.adapter)
	local place = bridge.placeEngine()
	local input = place.service "UserInputService"
	local down: { [unknown]: boolean } = {}
	env.fake("UserInputService.IsKeyDown", function(_object: VerifyRoblox.Instance, key: unknown): boolean
		return down[key] == true
	end)
	local environment: Editor.Environment = ComposeRoblox.designEnvironment {
		service = place.service,
		values = {
			vector2 = values.Vector2.new,
			vector3 = values.Vector3.new,
			udim = values.UDim.new,
			udim2 = values.UDim2.new,
			color = values.Color3.new,
			font = function(family: string, weight: string): unknown
				return values.Font.new(family, values.Enum.FontWeight[weight])
			end,
			enum = function(name: string, item: string): unknown
				return values.Enum[name][item]
			end,
			cframe = function(components: { number }): unknown
				return values.CFrame.new(table.unpack(components))
			end,
			raycastParams = function(include: boolean, nodes: { unknown }): unknown
				local params = values.RaycastParams.new()
				params.FilterType = values.Enum.RaycastFilterType[if include then "Include" else "Exclude"]
				params.FilterDescendantsInstances = nodes
				return params
			end,
		},
	}
	local screen = env.createInstance "ScreenGui"
	table.insert(roots, screen)
	screen.Parent = env.root
	local library = if space == "3d"
		then Editor.roblox3DLibrary(runtime, environment)
		else Editor.robloxLibrary(runtime, environment)
	local document = Design.document.new("Headless", library, if space == "3d" then "Model" else "Stack")
	local first, second
	if space == "3d" then
		document, first = Design.document.insert(document, library, "n1", "Part")
		document = Design.document.change(document, library, first, "size", { literal = { 6, 6, 6 } })
		document = Design.document.change(document, library, first, "position", { literal = { 0, 3, 0 } })
		second = first
	else
		document = Design.document.change(document, library, "n1", "fillWidth", { literal = false })
		document = Design.document.change(document, library, "n1", "width", { literal = 400 })
		document = Design.document.change(document, library, "n1", "height", { literal = 240 })
		document, first = Design.document.insert(document, library, "n1", "Text")
		document, second = Design.document.insert(document, library, "n1", "Button")
		for _, id in { first, second } do
			document = Design.document.change(document, library, id, "width", { literal = 120 })
			document = Design.document.change(document, library, id, "height", { literal = 36 })
		end
	end
	local objectsBefore = env.liveObjects()
	local connectionsBefore = env.liveConnections()
	type MountOptions = {
		link: Design.LinkStore?,
		onExport: ((string) -> ())?,
		devices: { Editor.Device }?,
		previews: { Editor.Preview }?,
	}
	local function mount(options: MountOptions?): Editor.Editor
		return Editor.create(library, document, screen, {
			runtime = runtime,
			environment = environment,
			stageSize = { X = 480, Y = 320 },
			link = if options then options.link else nil,
			onExport = if options then options.onExport else nil,
			devices = if options then options.devices else nil,
			previews = if options then options.previews else nil,
		})
	end
	local function settle()
		runtime:settle()
		assert(bridge.layout).step()
		env.step(1 / 60)
		runtime:settle()
		assert(bridge.layout).step()
	end
	local function read(node: unknown, key: string): unknown
		return assert(runtime.host.observation).readProperty(node, key)
	end
	local function number(node: unknown, key: string): number
		local value = read(node, key)
		assert(type(value) == "number")
		return value
	end
	local function point(node: unknown, property: string): Editor.Point
		local value = read(node, property)
		return { X = number(value, "X"), Y = number(value, "Y") }
	end
	local function find(node: unknown, name: string): VerifyRoblox.Instance
		local found = instance(node):FindFirstChild(name, true)
		assert(found, name)
		return found
	end
	local function fire(node: unknown, event: string, ...: unknown)
		env.fire(instance(node), event, ...)
	end
	local function pointer(kind: string, x: number, y: number, z: number?)
		return { UserInputType = values.Enum.UserInputType[kind], Position = values.Vector3.new(x, y, z or 0) }
	end
	return {
		runtime = runtime,
		emulator = emulator,
		env = env,
		screen = screen,
		input = input,
		down = down,
		values = values,
		environment = environment,
		document = document,
		library = library,
		first = first,
		second = second,
		mount = mount,
		settle = settle,
		read = read,
		number = number,
		point = point,
		find = find,
		fire = fire,
		pointer = pointer,
		objectsBefore = objectsBefore,
		connectionsBefore = connectionsBefore,
		close = function()
			runtime:dispose()
			bridge.close()
			env.root:Destroy()
			place.game:Destroy()
		end,
	}
end

return { world = world, instance = instance }
