--!strict

local Design = require "../../src/design"
local DesignEditor = require "../../src/design-editor"
local EditorUI = require "../../src/design-editor/ui"
local Compose = require "../../src/core"
local Support = require "./editor-support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("host-neutral design editor", function()
	it("exposes the active UI stage and mounted root through public create across device selections", function()
		local w = Support.world(nil, true)
		local devices = { DesignEditor.devices.all[1], DesignEditor.devices.all[2] }
		local editor = DesignEditor.create(w.library, w.document, w.screen, {
			runtime = w.runtime,
			environment = w.environment,
			devices = devices,
		})
		local first = assert(editor.stage)
		expect(first):toBe(editor.canvas.current().stage)
		expect(editor.scene):toBeNil()
		expect(w.read(first.nodes[w.document.root.id], "Parent")):toBe(first.surface)
		editor.canvas.select(devices[2].id)
		local second = assert(editor.stage)
		expect(second):toBe(editor.canvas.current().stage)
		expect(second == first):toBe(false)
		expect(w.read(second.nodes[w.document.root.id], "Parent")):toBe(second.surface)
		editor.canvas.showAll(true)
		w.fire(first.overlay, "InputBegan", w.pointer("MouseButton1", 0, 0))
		expect(editor.stage):toBe(first)
		expect(editor.scene):toBeNil()
		expect(editor.execute({ action = "Read" }).device):toBe(devices[1].id)
		editor.dispose()
		w.settle()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("exposes the 3D scene and mounted root through public create without a scene target", function()
		local w = Support.world "3d"
		local editor = DesignEditor.create(w.library, w.document, w.screen, {
			runtime = w.runtime,
			environment = w.environment,
		})
		local scene = assert(editor.scene)
		expect(scene):toBe(editor.canvas.current().scene)
		expect(editor.stage):toBeNil()
		expect(w.read(scene.nodes[w.document.root.id], "Parent")):toBe(scene.world)
		expect(w.read(scene.world, "Parent")):toBe(scene.viewport)
		expect(w.read(scene.viewport, "CurrentCamera")):toBe(scene.camera)
		w.settle()
		expect(editor.session.problem:peek()):toBeNil()
		expect(editor.execute({ action = "Camera", preset = "fit" }).ok):toBe(true)
		local at, size = w.point(scene.viewport, "AbsolutePosition"), w.point(scene.viewport, "AbsoluteSize")
		expect(scene.pick { X = at.X + size.X / 2, Y = at.Y + size.Y / 2 }):toBe(w.first)
		editor.dispose()
		w.settle()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("delivers native text changes and focus with stable row keys in the editor and direct rendering", function()
		local w = Support.world()
		local inputKind: Design.Kind = {
			fields = { onChange = { type = "event" }, onFocus = { type = "event" } },
			children = "none",
			call = "UI.Input",
			build = function(props: { [string]: Design.Resolved }, _children: { unknown }, name: string): unknown
				local input = w.runtime.constructors.TextBox {
					Name = name,
					Text = "initial",
					Size = w.values.UDim2.new(0, 120, 0, 36),
				}
				w.runtime.connect(input, "Changed", function(property: unknown)
					if property == "Text" then
						local text = w.read(input, "Text")
						assert(type(text) == "string")
						assert(props.onChange.callback)(text)
					end
				end)
				w.runtime.connect(input, "Focused", function()
					assert(props.onFocus.callback)()
				end)
				return input
			end,
		}
		local rowsKind: Design.Kind = {
			fields = {},
			children = "template",
			call = "UI.Rows",
			source = "from",
			key = "key",
			template = "render",
			build = function(props: { [string]: Design.Resolved }, _children: { unknown }, name: string): unknown
				local key = assert(props.from.key)
				local render = assert(props.render.template)
				return w.runtime.constructors.Frame {
					Name = name,
					Size = w.values.UDim2.new(0, 400, 0, 240),
					Compose.keyed {
						from = assert(props.from.rows),
						key = function(row: Design.Row): Design.Literal
							return assert(row[key])
						end,
						render = function(row: Compose.ReadOnlyValue<Design.Row>): Compose.Node
							return Support.node(render(row))
						end,
					},
				}
			end,
		}
		local library = Design.extend(w.library, { kinds = { Input = inputKind, Rows = rowsKind } })
		local value = Design.document.setContract(Design.document.new("Editable", library, "Rows"), library, {
			inputs = { { id = "rows", kind = "readable", type = "list", fields = { { id = "id", type = "string" } } } },
			outputs = { { id = "onChange", args = { "string", "string" } }, { id = "onFocus", args = { "string" } } },
		})
		value = Design.document.bind(value, library, "n1", { from = "rows", key = "id" })
		value = Design.document.insert(value, library, "n1", "Input")
		value.root.children[1].nameField = "id"
		value = Design.document.change(value, library, "n2", "onChange", {
			output = "onChange",
			arguments = { { item = "id" }, { event = 1 } },
		})
		value = Design.document.change(value, library, "n2", "onFocus", {
			output = "onFocus",
			arguments = { { item = "id" } },
		})
		local source = Design.emit(value, library)
		value = Design.parse(source, library)
		expect(Design.emit(value, library)):toBe(source)
		local rows = Compose.cell<<{ Design.Row }>> { { id = "stable" } }
		local events: { { Design.Literal } } = {}
		local function receive(args: { Design.Literal })
			table.insert(events, args)
		end
		local bindings: { [string]: Design.Resolved } = { rows = { rows = rows } }
		local outputs = { onChange = receive, onFocus = receive }
		local stop, direct = w.runtime.mount(function(): Compose.Node
			return Support.node(Design.render(value, library, { bindings = bindings, outputs = outputs }))
		end, w.screen)
		local editor = DesignEditor.create(library, value, w.screen, {
			runtime = w.runtime,
			environment = w.environment,
			bindings = bindings,
			outputs = outputs,
			devices = { DesignEditor.devices.all[1], DesignEditor.devices.all[2] },
		})
		editor.execute { action = "Select", ids = {} }
		editor.execute { action = "AllDevices", enabled = true }
		w.settle()
		local function exercise(root: Compose.Node)
			table.clear(events)
			local input = w.find(root, "stable")
			input.Text = "new text"
			w.fire(input, "Focused")
			expect(events):toEqual { { "stable", "new text" }, { "stable" } }
		end
		exercise(direct)
		for _, frame in editor.canvas.frames() do
			exercise(frame.root)
		end
		stop()
		editor.dispose()
		w.settle()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it(
		"populates parent slot samples with live child Designs on every device and shares capture and close controls",
		function()
			local w = Support.world(nil, true)
			local child = Design.document.setContract(Design.document.new("Child", w.library, "Stack"), w.library, {
				inputs = {
					{ id = "name", kind = "value", type = "string", required = true },
					{ id = "text", kind = "readable", type = "string", preview = "ordinary" },
				},
				outputs = {},
			})
			child.root.nameInput = "name"
			child = Design.document.insert(child, w.library, "n1", "Text")
			child = Design.document.rename(child, w.library, "n2", "SampleText")
			child = Design.document.change(child, w.library, "n2", "text", { input = "text" })
			child = Design.document.change(child, w.library, "n2", "textSize", { literal = 100 })
			local canonical = Compose.cell(Design.emit(child, w.library))
			local library = Design.imports(w.library, {
				Child = {
					source = canonical,
					call = "Child",
					save = function(expected: string, generated: string): boolean
						if canonical:peek() ~= expected then
							return false
						end
						canonical:set(generated)
						return true
					end,
				},
			})
			local parent = Design.document.setContract(Design.document.new("Parent", library, "Stack"), library, {
				inputs = { { id = "body", kind = "value", type = "slot", required = true } },
				outputs = {},
			})
			parent = Design.document.insertSlot(parent, library, "n1", "body")
			local instance = Design.document.setContract(Design.document.new("Instance", library, "Child"), library, {
				inputs = { { id = "text", kind = "readable", type = "string", preview = "ordinary" } },
				outputs = {},
			})
			instance = Design.document.change(instance, library, "n1", "text", { input = "text" })
			local state = Compose.cell<<Design.Literal?>> "ordinary"
			local backdrop = Compose.cell(false)
			local captures: { string } = {}
			local closed = 0
			local editor = DesignEditor.create(library, parent, w.screen, {
				runtime = w.runtime,
				environment = w.environment,
				identity = { commit = "revision", path = "Parent.luau" },
				devices = DesignEditor.devices.all,
				slotSamples = {
					body = function(frameLibrary: Design.Library, device: DesignEditor.Device): unknown
						local value = Design.document.rename(instance, frameLibrary, "n1", device.id)
						return Design.render(value, frameLibrary, { bindings = { text = { readable = state } } })
					end,
				},
				backdrop = function(): unknown
					return w.runtime.constructors.Frame {
						Name = "SampleBackdrop",
						Visible = backdrop,
					}
				end,
				previews = {
					{
						name = "State",
						choices = { "ordinary", "empty", "busy", "error" },
						select = function(choice: string)
							state:set(choice)
						end,
					},
					{
						name = "Backdrop",
						choices = { "none", "scene" },
						select = function(choice: string)
							backdrop:set(choice == "scene")
						end,
					},
				},
				capture = function(name: string, frame: DesignEditor.Frame): { string }
					table.insert(captures, name .. "/" .. frame.device.id)
					return { name .. ".png" }
				end,
				onClose = function()
					closed += 1
				end,
			})
			editor.execute { action = "Select", ids = {} }
			expect(editor.execute({ action = "AllDevices", enabled = true }).ok):toBe(true)
			for _, choice in { "ordinary", "empty", "busy", "error" } do
				local result = editor.execute { action = "Preview", name = "State", choice = choice }
				w.settle()
				expect(result.previews.State):toBe(choice)
				expect(w.find(editor.root, "State").Text):toBe(choice)
				expect(#editor.canvas.frames()):toBe(#DesignEditor.devices.all)
				local seen: { [unknown]: boolean } = {}
				for _, frame in editor.canvas.frames() do
					local text = w.find(frame.root, "SampleText")
					expect(text.Text):toBe(choice)
					expect(seen[text]):toBe(nil)
					seen[text] = true
				end
			end
			editor.execute { action = "Preview", name = "Backdrop", choice = "scene" }
			w.settle()
			expect(w.find(editor.root, "Backdrop").Text):toBe "scene"
			for _, frame in editor.canvas.frames() do
				expect(w.find(frame.root, "SampleBackdrop").Visible):toBe(true)
			end
			local device = DesignEditor.devices.all[2]
			editor.execute { action = "Device", id = device.id }
			w.settle()
			expect(w.find(editor.root, "Device").Text):toBe(device.name)
			local result = editor.execute { action = "Capture", name = "busy" }
			expect({ result.ok, result.target, result.commit, result.files[1] }):toEqual {
				true,
				"Parent.luau",
				"revision",
				"busy.png",
			}
			w.fire(w.find(editor.root, "Capture"), "Activated")
			expect(captures):toEqual { "busy/" .. device.id, "Parent/" .. device.id }
			w.fire(w.find(editor.root, "Close"), "Activated")
			expect(editor.execute({ action = "Read" }).closed):toBe(true)
			expect(editor.execute({ action = "Close" }).ok):toBe(true)
			expect(editor.execute({ action = "Undo" }).ok):toBe(false)
			expect(closed):toBe(1)
			editor.dispose()
			w.settle()
			expect(w.env.liveConnections()):toBe(w.connectionsBefore)
			expect(w.env.liveObjects()):toBe(w.objectsBefore)
			w.close()
		end
	)

	it("inspects required slot leaves and edits children of declared slot kinds", function()
		local w = Support.world()
		local stack = w.library.kinds.Stack
		local panel = table.clone(stack)
		panel.children = "slot"
		panel.slot = "content"
		panel.call = "Design.Panel"
		panel.build = function(props: { [string]: Design.Resolved }, _children: { unknown }, name: string): unknown
			return stack.build(props, { assert(props.content.slot)() }, name)
		end
		local library = Design.extend(w.library, { kinds = { Panel = panel } })
		local document = Design.document.setContract(Design.document.new("Parent", library, "Stack"), library, {
			inputs = { { id = "body", kind = "value", type = "slot", required = true } },
			outputs = {},
		})
		local slot, container, text
		document, slot = Design.document.insertSlot(document, library, "n1", "body")
		document, container = Design.document.insert(document, library, "n1", "Panel")
		document, text = Design.document.insert(document, library, container, "Text")
		local child = Design.document.new("Child", library, "Text")
		child = Design.document.rename(child, library, "n1", "SampleText")
		child = Design.document.change(child, library, "n1", "text", { literal = "Sample" })
		local editor = DesignEditor.create(library, document, w.screen, {
			runtime = w.runtime,
			environment = w.environment,
			stageSize = { X = 480, Y = 320 },
			slotSamples = {
				body = function(library: Design.Library, _device: DesignEditor.Device): unknown
					return Design.render(child, library)
				end,
			},
		})
		w.settle()
		expect(w.find(editor.root, "SampleText").Text):toBe "Sample"
		local inspector = w.find(editor.root, "DesignInspector")
		local layers = w.find(editor.root, "DesignLayers")
		w.fire(w.find(layers, slot), "Activated")
		w.settle()
		expect(editor.session.selected:peek()):toBe(slot)
		expect(w.find(inspector, "NodeName").Text):toBe "body"
		expect(inspector:FindFirstChild "Data"):toBeNil()
		expect(inspector:FindFirstChild "text"):toBeNil()
		for _, ids in { { text, slot }, { slot, text } } do
			editor.session.selectMany(ids)
			w.settle()
			expect(w.find(inspector, "NodeName").Text):toBe "2 selected"
			expect(inspector:FindFirstChild "text"):toBeNil()
		end
		w.fire(w.find(layers, text), "Activated")
		w.settle()
		local input = assert(w.find(inspector, "text"):FindFirstChildWhichIsA("TextBox", true))
		expect(input.Text):toBe "Text"
		input.Text = "Edited"
		w.fire(input, "FocusLost")
		w.settle()
		local edited = assert((Design.document.find(editor.session.document:peek().root, text)))
		expect(edited.props.text.literal):toBe "Edited"
		expect(w.read(assert(editor.stage).nodes[text], "Text")):toBe "Edited"
		expect(editor.session.undo()):toBe(true)
		w.settle()
		expect(assert(w.find(inspector, "text"):FindFirstChildWhichIsA("TextBox", true)).Text):toBe "Text"
		expect(Design.emit(editor.session.document:peek(), library)):toBe(Design.emit(document, library))
		expect(editor.session.problem:peek()):toBeNil()
		editor.dispose()
		w.settle()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("rejects unknown slot samples and unwinds a child sample that fails during construction", function()
		local w = Support.world()
		local function mount(name: string): DesignEditor.Editor
			local value = Design.document.setContract(w.document, w.library, {
				inputs = { { id = "body", kind = "value", type = "slot" } },
				outputs = {},
			})
			value = Design.document.insertSlot(value, w.library, "n1", "body")
			return DesignEditor.create(w.library, value, w.screen, {
				runtime = w.runtime,
				environment = w.environment,
				slotSamples = {
					[name] = function(): unknown
						w.runtime.constructors.Frame { Name = "FailedSample" }
						error("sample failed", 0)
					end,
				},
			})
		end
		expect(function()
			mount "missing"
		end):toThrow "Unknown slot sample: missing"
		expect(function()
			mount "body"
		end):toThrow "sample failed"
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		local editor = w.mount()
		expect(function()
			w.mount { previews = { { name = "Device", choices = { "test" }, select = function() end } } }
		end):toThrow "Preview name conflicts with an editor control: Device"
		local result = editor.execute { action = "Capture", name = "sample" }
		expect(result.ok):toBe(false)
		expect(string.find(assert(result.problem), "host capture callback", 1, true) ~= nil):toBe(true)
		editor.dispose()
		w.close()
	end)

	it("projects imported layer collectors with the active frame library", function()
		local w = Support.world(nil, true)
		local base = Design.extend(w.library, {
			kinds = {
				Surface = {
					fields = {},
					children = "none",
					call = "UI.Surface",
					build = function(
						_props: { [string]: Design.Resolved },
						_children: { unknown },
						name: string
					): unknown
						return w.runtime.constructors.ScreenGui { Name = name, Enabled = true }
					end,
				},
			},
		})
		local value = Design.document.setContract(Design.document.new("Screen", base, "Surface"), base, {
			inputs = { { id = "name", kind = "value", type = "string", required = true } },
			outputs = {},
		})
		value.root.nameInput = "name"
		local library =
			Design.imports(base, { Screen = { source = Compose.cell(Design.emit(value, base)), call = "Screen" } })
		local editor = DesignEditor.create(library, Design.document.new("Imported", library, "Screen"), w.screen, {
			runtime = w.runtime,
			environment = w.environment,
			devices = { DesignEditor.devices.all[1] },
		})
		w.settle()
		local stage = assert(editor.canvas.current().stage)
		expect(w.read(stage.nodes.n1, "ClassName")):toBe "Frame"
		expect(w.read(stage.nodes.n1, "Parent")):toBe(stage.surface)
		editor.dispose()
		w.settle()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("unwinds an authored value node when its receiving kind fails and disposes successful builds once", function()
		local w = Support.world()
		local fail = true
		local library = Design.extend(w.library, {
			kinds = {
				Trailing = {
					fields = { item = { type = "value" } },
					children = "none",
					call = "UI.Trailing",
					build = function(
						props: { [string]: Design.Resolved },
						_children: { unknown },
						name: string
					): unknown
						if fail then
							error("receiver rejected the node", 0)
						end
						return w.runtime.constructors.Frame { Name = name, EditorUI.node(props.item.value) }
					end,
				},
			},
		})
		local value =
			Design.document.content(Design.document.new("Direct", library, "Trailing"), library, "n1", "item", "Text")
		expect(function()
			w.runtime.mount(function(): Compose.Node
				return EditorUI.node(Design.render(value, library))
			end, w.screen)
		end):toThrow "receiver rejected the node"
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		fail = false
		local stop = w.runtime.mount(function(): Compose.Node
			return EditorUI.node(Design.render(value, library))
		end, w.screen)
		stop()
		stop()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it(
		"edits canonical nested 3D Designs and refreshes an assembly from one readable source while preserving selection",
		function()
			local w = Support.world "3d"
			local function canonical(name: string, collision: boolean): Design.Document
				local value = Design.document.setContract(Design.document.new(name, w.library, "Model"), w.library, {
					inputs = {
						{ id = "name", kind = "value", type = "string", required = true },
						{ id = "fade", kind = "readable", type = "number", required = true, preview = 0.2 },
						{ id = "offset", kind = "value", type = "vector3", required = true, preview = { 0, 0, 0 } },
						{ id = "detail", kind = "value", type = "slot" },
					},
					outputs = {},
				})
				value.root.nameInput = "name"
				value = Design.document.change(value, w.library, "n1", "position", { input = "offset" })
				local part
				value, part = Design.document.insert(value, w.library, "n1", "Part")
				value = Design.document.rename(value, w.library, part, "Geometry")
				value = Design.document.change(value, w.library, part, "size", { literal = { 2, 4, 6 } })
				value = Design.document.change(value, w.library, part, "position", { literal = { 1, 2, 3 } })
				value = Design.document.change(value, w.library, part, "canCollide", { literal = collision })
				value = Design.document.change(value, w.library, part, "transparency", { input = "fade" })
				value = Design.document.insertSlot(value, w.library, "n1", "detail")
				return value
			end
			local wall, brace = canonical("Wall", true), canonical("Brace", false)
			local texts: { [string]: string } =
				{ Wall = Design.emit(wall, w.library), Brace = Design.emit(brace, w.library) }
			local sources = Compose.cell(texts)
			local function imported(name: string): Design.Import
				return {
					source = Compose.formula(function(use: Compose.Use): string
						return use(sources)[name]
					end),
					call = "Pieces." .. name,
					save = function(expected: string, generated: string): boolean
						if sources:peek()[name] ~= expected then
							return false
						end
						local nextSources = table.clone(sources:peek())
						nextSources[name] = generated
						sources:set(nextSources)
						return true
					end,
				}
			end
			local library = Design.imports(w.library, { Wall = imported "Wall", Brace = imported "Brace" })
			local assembly = Design.document.setContract(Design.document.new("Assembly", library, "Model"), library, {
				inputs = { { id = "fade", kind = "readable", type = "number", required = true, preview = 0.2 } },
				outputs = {},
			})
			local ids: { string } = {}
			for index, kind in { "Wall", "Brace" } do
				local id
				assembly, id = Design.document.insert(assembly, library, "n1", kind)
				assembly = Design.document.rename(assembly, library, id, kind .. "Instance")
				assembly = Design.document.change(assembly, library, id, "fade", { input = "fade" })
				assembly = Design.document.change(assembly, library, id, "offset", { literal = { index * 10, 0, 0 } })
				assembly = Design.document.content(assembly, library, id, "detail", "Part")
				table.insert(ids, id)
			end
			local assemblySource = Design.emit(assembly, library)
			local fade = Compose.cell<<Design.Literal?>>(0.2)
			local notify: (() -> ())? = nil
			local editor = DesignEditor.create(library, assembly, w.screen, {
				runtime = w.runtime,
				environment = w.environment,
				bindings = { fade = { readable = fade } },
				link = {
					read = function(): string
						return assemblySource
					end,
					write = function(): boolean
						return false
					end,
					watch = function(changed: () -> ()): () -> ()
						notify = changed
						return function()
							notify = nil
						end
					end,
				},
			})
			w.settle()
			local scene = assert(editor.canvas.current().scene)
			for index, id in ids do
				local model = Support.instance(scene.nodes[id])
				expect(model.Name):toBe(({ "WallInstance", "BraceInstance" })[index])
				expect(w.find(model, "Geometry").CanCollide):toBe(index == 1)
				expect(w.find(model, "Geometry").Size):toBe(w.values.Vector3.new(2, 4, 6))
				expect(w.find(model, "Geometry").CFrame):toBe(w.values.CFrame.new(index * 10 + 1, 2, 3))
				expect(w.find(model, "Pivot").CFrame):toBe(w.values.CFrame.new(index * 10, 0, 0))
				expect(w.find(model, "Pivot").CanCollide):toBe(false)
				expect(#model:GetChildren()):toBe(3)
			end
			local retained = scene.nodes[ids[1]]
			fade:set(0.6)
			w.settle()
			expect(scene.nodes[ids[1]]):toBe(retained)
			expect(w.find(retained, "Geometry").Transparency):toBe(0.6)
			editor.session.select(ids[1])
			expect(editor.execute({ action = "OpenDesign" }).ok):toBe(true)
			local nested = assert(editor.nested())
			expect(w.find(editor.root, "ComposeDesignShortcuts").Enabled):toBe(false)
			nested.session.select "n2"
			expect(nested.execute({ action = "Change", field = "size", value = { literal = { 8, 4, 6 } } }).ok):toBe(
				true
			)
			w.settle()
			expect(w.find(scene.nodes[ids[1]], "Geometry").Size):toBe(w.values.Vector3.new(8, 4, 6))
			local changedSource = sources:peek().Wall
			expect(nested.execute({ action = "Undo" }).ok):toBe(true)
			w.settle()
			expect(sources:peek().Wall):toBe(texts.Wall)
			expect(nested.execute({ action = "Redo" }).ok):toBe(true)
			w.settle()
			expect(sources:peek().Wall):toBe(changedSource)
			expect(Design.emit(Design.parse(changedSource, w.library), w.library)):toBe(changedSource)
			expect(editor.session.selection:peek()):toEqual { ids[1] }
			expect(nested.session.selection:peek()):toEqual { "n2" }
			local external = Design.parse(sources:peek().Wall, w.library)
			local extra
			external, extra = Design.document.insert(external, w.library, "n1", "Part", 1)
			external = Design.document.rename(external, w.library, extra, "Extra")
			local nextSources = table.clone(sources:peek())
			nextSources.Wall = Design.emit(external, w.library)
			sources:set(nextSources)
			w.settle()
			expect(nested.session.selected:peek()):toBe "n3"
			expect(editor.session.selection:peek()):toEqual { ids[1] }
			expect(w.find(scene.nodes[ids[1]], "Extra").Parent):toBe(Support.instance(scene.nodes[ids[1]]))
			expect(Design.emit(Design.parse(sources:peek().Wall, w.library), w.library)):toBe(sources:peek().Wall)
			expect(editor.execute({ action = "CloseDesign" }).ok):toBe(true)
			expect(w.find(editor.root, "ComposeDesignShortcuts").Enabled):toBe(true)
			assembly = Design.document.change(assembly, library, ids[1], "offset", { literal = { 30, 0, 0 } })
			assemblySource = Design.emit(assembly, library)
			assert(notify)()
			w.settle()
			expect(w.find(scene.nodes[ids[1]], "Pivot").CFrame):toBe(w.values.CFrame.new(30, 0, 0))
			expect(editor.session.selection:peek()):toEqual { ids[1] }
			expect(Design.emit(Design.parse(assemblySource, library), library)):toBe(assemblySource)
			expect(Design.emit(Design.parse(texts.Brace, w.library), w.library)):toBe(texts.Brace)
			expect(#editor.session.document:peek().root.children):toBe(2)
			editor.dispose()
			w.settle()
			expect(w.env.liveConnections()):toBe(w.connectionsBefore)
			w.close()
		end
	)

	it("keeps actual size per device through switches, grid layout and command-driven fits", function()
		local w = Support.world(nil, true)
		local editor = w.mount { devices = { DesignEditor.devices.all[1], DesignEditor.devices.all[5] } }
		w.settle()
		local first = editor.canvas.current()
		expect(editor.execute({ action = "ActualSize", enabled = true }).ok):toBe(true)
		w.settle()
		expect(first.scale:peek()):toBe(1)
		expect(w.find(editor.root, "ActualSize").Text):toBe "Fit size"
		expect(editor.execute({ action = "Device", id = "monitor" }).ok):toBe(true)
		w.settle()
		expect(editor.execute({ action = "Read" }).actualSize):toBe(false)
		expect(editor.execute({ action = "Device", id = "phone-portrait" }).ok):toBe(true)
		w.settle()
		expect(first.scale:peek()):toBe(1)
		expect(editor.execute({ action = "Read" }).actualSize):toBe(true)
		editor.execute { action = "AllDevices", enabled = true }
		w.settle()
		expect(first.scale:peek()):toBe(1)
		expect(w.find(editor.root, "AllDevices").Text):toBe "Single device"
		expect(editor.execute({ action = "Fit" }).actualSize):toBe(false)
		w.settle()
		expect(first.scale:peek() < 1):toBe(true)
		expect(editor.execute({ action = "Zoom", scale = math.nan }).ok):toBe(false)
		expect(first.scale:peek() == first.scale:peek()):toBe(true)
		editor.dispose()
		w.close()
	end)

	it("applies initial sample states before rendering and preserves a rejected preview choice", function()
		local w = Support.world()
		local state = Compose.cell "ordinary"
		local document = Design.document.setContract(w.document, w.library, {
			inputs = { { id = "sample", kind = "readable", type = "string", preview = "ordinary" } },
			outputs = {},
		})
		document = Design.document.change(document, w.library, w.first, "text", { input = "sample" })
		local calls = 0
		local invalid = pcall(function()
			w.mount {
				previews = {
					{
						name = "State",
						choices = { "ordinary", "ordinary" },
						select = function()
							calls += 1
						end,
					},
				},
			}
		end)
		expect(invalid):toBe(false)
		expect(calls):toBe(0)
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		local backdrop: Compose.Node? = nil
		local editor = w.mount {
			document = document,
			previews = {
				{
					name = "State",
					choices = { "ordinary", "empty", "busy", "error" },
					initial = "empty",
					select = function(choice: string)
						if choice == "error" then
							error "unavailable sample"
						end
						calls += 1
						state:set(choice)
					end,
				},
			},
			frame = function(): DesignEditor.FrameContext
				expect(state:peek()):toBe "empty"
				return {
					bindings = { sample = { readable = state } },
					backdrop = function(): unknown
						backdrop = w.runtime.constructors.Frame {
							Name = "SceneBackdrop",
							Size = w.values.UDim2.fromScale(1, 1),
						}
						return backdrop
					end,
				}
			end,
		}
		w.settle()
		expect(calls):toBe(1)
		expect(w.read(assert(editor.canvas.current().stage).nodes[w.first], "Text")):toBe "empty"
		expect(w.read(assert(backdrop), "Parent")):toBe(assert(editor.canvas.current().stage).surface)
		local read = editor.execute { action = "Read" }
		expect(read.previewChoices.State):toEqual { "ordinary", "empty", "busy", "error" }
		read.previewChoices.State[1] = "changed"
		expect(editor.execute({ action = "Read" }).previewChoices.State[1]):toBe "ordinary"
		expect(editor.execute({ action = "Preview", name = "State", choice = "busy" }).ok):toBe(true)
		w.settle()
		expect(w.read(assert(editor.canvas.current().stage).nodes[w.first], "Text")):toBe "busy"
		expect(editor.execute({ action = "Pan", x = 30, y = 10 }).ok):toBe(true)
		local rejected = editor.execute { action = "Preview", name = "State", choice = "error" }
		expect(rejected.ok):toBe(false)
		expect(rejected.previews.State):toBe "busy"
		expect(editor.session.problem:peek()):toBe(rejected.problem)
		expect(w.find(editor.root, "State").Text):toBe "busy"
		expect(editor.execute({ action = "Preview", name = "State", choice = "missing" }).ok):toBe(false)
		editor.dispose()
		expect(w.read(assert(backdrop), "Parent")):toBe(nil)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("reports rejected edits and exposes layer, inspector, navigation and export commands", function()
		local w = Support.world()
		local exported = ""
		local editor = w.mount {
			onExport = function(source: string)
				exported = source
			end,
		}
		expect(editor.execute({ action = "Select", ids = { w.first } }).ok):toBe(true)
		local rejected = editor.execute { action = "Change", field = "missing", value = { literal = 3 } }
		expect(rejected.ok):toBe(false)
		expect(rejected.problem ~= nil):toBe(true)
		expect(rejected.next):toBe 'execute({ action = "Read" })'
		expect(editor.execute({ action = "Rename", name = "SampleTitle" }).ok):toBe(true)
		expect(
			editor.execute({ action = "ChangeMany", changes = { width = { literal = 200 }, height = { literal = 40 } } }).ok
		):toBe(true)
		expect(editor.execute({ action = "Hide", id = w.first, hidden = true }).ok):toBe(true)
		expect(editor.execute({ action = "Lock", id = w.first, locked = true }).ok):toBe(true)
		local node = assert((Design.document.find(editor.session.document:peek().root, w.first)))
		expect({ node.name, node.hidden, node.locked }):toEqual { "SampleTitle", true, true }
		expect(editor.execute({ action = "Shift", step = 1 }).ok):toBe(true)
		expect(editor.session.document:peek().root.children[2].id):toBe(w.first)
		expect(editor.execute({ action = "Move", id = w.first, destination = "n1", before = 1 }).ok):toBe(true)
		expect(editor.execute({ action = "SelectRelative", direction = "next" }).selection):toEqual { w.second }
		expect(editor.execute({ action = "TextSize", size = 17 }).textSize):toBe(17)
		expect(w.find(editor.root, "TextSize").Text):toBe "Text 17"
		expect(editor.execute({ action = "TextSize", size = 100 }).ok):toBe(false)
		expect(editor.execute({ action = "Pan", x = math.huge, y = 0 }).ok):toBe(false)
		local result = editor.execute { action = "Export" }
		expect(result.ok):toBe(true)
		expect(result.source):toBe(exported)
		expect(exported):toBe(Design.emit(editor.session.document:peek(), w.library))
		expect(result.files):toEqual {}
		expect(editor.execute({ action = "Play", sequence = "missing" }).ok):toBe(false)
		expect(editor.execute({ action = "Select", ids = { "missing" } }).ok):toBe(false)
		expect(editor.execute({ action = "Replace", document = w.document }).ok):toBe(true)
		expect(editor.execute({ action = "Contract", contract = w.document.contract }).ok):toBe(true)
		editor.dispose()
		w.close()
	end)

	it("renders beams with forward attachment references and preserves attachment children", function()
		local w = Support.world "3d"
		local document, beam = Design.document.insert(w.document, w.library, w.first, "Beam")
		local first, second, light
		document, first = Design.document.insert(document, w.library, w.first, "Attachment")
		document, second = Design.document.insert(document, w.library, w.first, "Attachment")
		document = Design.document.rename(document, w.library, first, "BeamStart")
		document = Design.document.rename(document, w.library, second, "BeamEnd")
		document, light = Design.document.insert(document, w.library, second, "PointLight")
		document = Design.document.change(document, w.library, beam, "attachment0", { node = first })
		document = Design.document.change(document, w.library, beam, "attachment1", { node = second })
		document = Design.document.change(document, w.library, beam, "width0", { literal = 0.7 })
		document = Design.document.change(document, w.library, beam, "color", { literal = "#00FF00" })
		document = Design.document.change(document, w.library, beam, "transparency", { literal = 0.2 })
		local editor = DesignEditor.create(w.library, document, w.screen, {
			runtime = w.runtime,
			environment = w.environment,
		})
		w.settle()
		local part = Support.instance(assert(editor.canvas.current().scene).nodes[w.first])
		local built = assert(part:FindFirstChildWhichIsA "Beam")
		expect(built.Attachment0):toBe(part:FindFirstChild(assert((Design.document.find(document.root, first))).name))
		expect(built.Attachment1):toBe(part:FindFirstChild(assert((Design.document.find(document.root, second))).name))
		expect(built.Width0):toBeCloseTo(0.7, 0.0001)
		expect(built.Color):toBe(w.values.ColorSequence.new(w.values.Color3.new(0, 1, 0)))
		expect(built.Transparency):toBe(w.values.NumberSequence.new(0.2))
		expect(w.find(part, assert((Design.document.find(document.root, light))).name).Parent):toBe(built.Attachment1)
		local source = Design.emit(document, w.library)
		expect(Design.emit(Design.parse(source, w.library), w.library)):toBe(source)
		expect(editor.execute({ action = "Guides", enabled = false }).ok):toBe(true)
		expect(editor.execute({ action = "Pan", x = 20, y = 10 }).ok):toBe(true)
		expect(editor.execute({ action = "ActualSize", enabled = true }).ok):toBe(false)
		editor.dispose()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		local pending = w.mount { document = document }
		pending.dispose()
		w.settle()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("renders three isolated drafts and commits only the chosen source through its pick callback", function()
		local w = Support.world()
		local source = Design.emit(w.document, w.library)
		local original = source
		local notify: (() -> ())? = nil
		local writes, picks = 0, 0
		local variants: { { title: string, source: string } } = {}
		for index = 1, 3 do
			table.insert(variants, {
				title = "Variant " .. index,
				source = Design.emit(
					Design.document.change(w.document, w.library, "n1", "width", { literal = 300 + index * 60 }),
					w.library
				),
			})
		end
		local editor = w.mount {
			link = {
				read = function(): string
					return source
				end,
				write = function(): boolean
					writes += 1
					return false
				end,
				watch = function(listener: () -> ()): () -> ()
					notify = listener
					return function()
						notify = nil
					end
				end,
			},
			prompt = {
				designPath = "designs/Sample.luau",
				submit = function(request: DesignEditor.PromptRequest): DesignEditor.PromptResult
					expect(request.count):toBe(3)
					return {
						message = "Choose a draft",
						variants = variants,
						pick = function(index: number): string
							picks += 1
							source = variants[index].source
							assert(notify)()
							return "Source updated"
						end,
					}
				end,
			},
		}
		local submitted = editor.execute { action = "Prompt", text = "Make variants with different spacing", count = 3 }
		expect(submitted.ok):toBe(true)
		expect(assert(submitted.prompt).busy):toBe(true)
		w.settle()
		local comparison = w.find(editor.root, "DesignDrafts")
		for index = 1, 3 do
			local card = w.find(comparison, "Draft" .. index)
			local rendered = w.find(card, w.document.root.name)
			expect(w.number(w.read(w.read(rendered, "Size"), "X"), "Offset")):toBe(300 + index * 60)
		end
		expect(source):toBe(original)
		expect(writes):toBe(0)
		expect(editor.session.document:peek().root.props.width.literal):toBe(400)
		expect(editor.execute({ action = "ChooseDraft", index = 4 }).ok):toBe(false)
		expect(editor.execute({ action = "ChooseDraft", index = 2 }).ok):toBe(true)
		w.settle()
		expect(picks):toBe(1)
		expect(source):toBe(variants[2].source)
		expect(editor.session.document:peek().root.props.width.literal):toBe(420)
		expect(writes):toBe(0)
		expect(editor.execute({ action = "Prompt", text = "More spacing", count = 4 }).ok):toBe(false)
		expect(editor.execute({ action = "Prompt", text = "More spacing", count = 3 }).ok):toBe(true)
		w.settle()
		expect(assert(editor.execute({ action = "Read" }).prompt).drafts):toBe(true)
		expect(editor.execute({ action = "DiscardDrafts" }).ok):toBe(true)
		w.settle()
		expect(assert(editor.execute({ action = "Read" }).prompt).drafts):toBe(false)
		expect(picks):toBe(1)
		editor.dispose()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("edits a shared theme value and updates every open device frame", function()
		local w = Support.world(nil, true)
		w.library.kinds.Stack.fields.width.tokens = true
		local spacing = Compose.cell(24)
		local editor = w.mount {
			devices = DesignEditor.devices.all,
			frame = function(device: DesignEditor.Device): DesignEditor.FrameContext
				return {
					resolveToken = function(): Design.Resolved
						return {
							readable = Compose.formula(function(use: Compose.Use): Design.Literal
								return device.size.X - use(spacing) * 2
							end),
						}
					end,
				}
			end,
			theme = {
				fields = {
					{
						id = "spacing.gutter",
						label = "Gutter",
						kind = "spacing",
						maximum = 128,
						read = function(use: Compose.Use): number
							return use(spacing)
						end,
					},
				},
				write = function(id: string, value: DesignEditor.ThemeValue): boolean
					expect(id):toBe "spacing.gutter"
					assert(type(value) == "number")
					spacing:set(value)
					return true
				end,
			},
		}
		editor.session.select "n1"
		expect(editor.session.change("width", { token = "frame.width" })):toBe(true)
		editor.canvas.showAll(true)
		w.settle()
		w.fire(w.find(editor.root, "Theme"), "Activated")
		local panel = w.find(editor.root, "DesignTheme")
		expect(panel.Visible):toBe(true)
		local input = w.find(w.find(panel, "spacing.gutter"), "TokenValue")
		input.Text = "48"
		w.fire(input, "FocusLost", false)
		w.settle()
		expect(spacing:peek()):toBe(48)
		for _, frame in editor.canvas.frames() do
			local stage = assert(frame.stage)
			expect(w.point(stage.nodes.n1, "AbsoluteSize").X / stage.zoom:peek()):toBeCloseTo(
				frame.device.size.X - 96,
				0.01
			)
		end
		input.Text = "999"
		w.fire(input, "FocusLost", false)
		w.settle()
		expect(spacing:peek()):toBe(48)
		expect(editor.execute({ action = "ThemeValue", id = "spacing.gutter", value = 64 }).ok):toBe(true)
		expect(spacing:peek()):toBe(64)
		expect(editor.execute({ action = "ThemeValue", id = "spacing.gutter", value = 200 }).ok):toBe(false)
		expect(editor.execute({ action = "ThemeValue", id = "missing", value = 1 }).ok):toBe(false)
		expect(spacing:peek()):toBe(64)
		editor.dispose()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("snapshots the selected node and frame before a deferred prompt submission", function()
		local w = Support.world()
		w.library.kinds.Stack.fields.width.tokens = true
		local requests: { DesignEditor.PromptRequest } = {}
		local themes: { DesignEditor.PromptRequest } = {}
		local editor = w.mount {
			devices = DesignEditor.devices.all,
			frame = function(): DesignEditor.FrameContext
				return {
					token = function(): Design.Literal
						return 400
					end,
				}
			end,
			prompt = {
				designPath = "designs/Sample.luau",
				submit = function(request: DesignEditor.PromptRequest): string
					table.insert(requests, request)
					return "Source updated"
				end,
				theme = function(request: DesignEditor.PromptRequest): string
					table.insert(themes, request)
					return "Theme saved"
				end,
			},
		}
		editor.session.select "n1"
		expect(editor.session.change("width", { token = "frame.width" })):toBe(true)
		editor.canvas.select "tv"
		w.find(editor.root, "PromptRequest").Text = "Give this node more breathing room"
		w.fire(w.find(editor.root, "SendPrompt"), "Activated")
		editor.session.change("width", { literal = 240 })
		editor.canvas.select "phone-portrait"
		w.settle()
		expect(#requests):toBe(1)
		local request = requests[1]
		expect(request.designPath):toBe "designs/Sample.luau"
		expect(request.nodePath[#request.nodePath].id):toBe "n1"
		expect(request.props.width.token):toBe "frame.width"
		expect(request.tokens):toEqual { "frame.width" }
		expect(request.frame.id):toBe "tv"
		expect(Design.parse(request.source, w.library).root.props.width.token):toBe "frame.width"
		expect(w.find(editor.root, "PromptStatus").Text):toBe "Source updated"
		w.fire(w.find(editor.root, "PromptScope"), "Activated")
		w.find(editor.root, "PromptRequest").Text = "Warm the shared accent colour"
		w.fire(w.find(editor.root, "SendPrompt"), "Activated")
		w.settle()
		expect(#requests):toBe(1)
		expect(#themes):toBe(1)
		expect(themes[1].frame.id):toBe "phone-portrait"
		expect(w.find(editor.root, "PromptStatus").Text):toBe "Theme saved"
		editor.dispose()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("keeps prompt failures generic and rejects an empty request without invoking the adapter", function()
		local w = Support.world()
		local calls = 0
		local editor = w.mount {
			prompt = {
				designPath = "designs/Sample.luau",
				submit = function(): string
					calls += 1
					error "private adapter diagnostic"
				end,
			},
		}
		local send = w.find(editor.root, "SendPrompt")
		w.fire(send, "Activated")
		w.settle()
		expect(calls):toBe(0)
		w.find(editor.root, "PromptRequest").Text = "Make it taller"
		w.fire(send, "Activated")
		w.settle()
		expect(calls):toBe(1)
		expect(w.find(editor.root, "PromptStatus").Text):toBe "Prompt failed; source preserved"
		editor.dispose()
		w.close()
	end)

	it("matches captured device facts through Verify's simulated Studio device service", function()
		local w = Support.world()
		w.devices()
		local workspace = w.service "Workspace"
		local camera = workspace:FindFirstChildOfClass "Camera" or w.env.createInstance "Camera"
		camera.Parent = workspace
		local profiles = table.clone(DesignEditor.devices.all)
		table.insert(profiles, DesignEditor.devices.get "generic_handheld_720")
		local simulator = w.service "StudioDeviceSimulatorService"
		for _, device in profiles do
			if device.verifyId == nil then
				continue
			end
			w.environment.invoke(simulator, "SetDeviceAsync", device.verifyId)
			if device.orientation then
				w.environment.invoke(
					simulator,
					"SetOrientationAsync",
					w.values.Enum.ScreenOrientation[device.orientation]
				)
			end
			expect(w.point(camera, "ViewportSize")):toEqual(device.size)
			local first, last = w.environment.invoke(w.service "GuiService", "GetGuiInset")
			expect(device.guiInset):toEqual {
				left = w.number(first, "X"),
				top = w.number(first, "Y"),
				right = w.number(last, "X"),
				bottom = w.number(last, "Y"),
			}
			for _, mode in { "None", "CoreUISafeInsets", "DeviceSafeInsets" } do
				local actual =
					w.environment.invoke(w.service "GuiService", "GetInsetArea", w.values.Enum.ScreenInsets[mode])
				local low, high = w.read(actual, "Min"), w.read(actual, "Max")
				expect(DesignEditor.devices.area(device, mode)):toEqual {
					x = w.number(low, "X") + device.guiInset.left,
					y = w.number(low, "Y") + device.guiInset.top,
					width = w.number(high, "X") - w.number(low, "X"),
					height = w.number(high, "Y") - w.number(low, "Y"),
				}
			end
			local expected = if device.inputMode == "touch"
				then "Touch"
				elseif device.inputMode == "mouse" then "KeyboardAndMouse"
				else "Gamepad"
			expect(tostring(w.read(w.input, "PreferredInput"))):toBe("Enum.PreferredInput." .. expected)
		end
		w.close()
	end)

	it("keeps live token resolution and selection shared while laying out every device independently", function()
		local w = Support.world(nil, true)
		w.library.kinds.Stack.fields.width.tokens = true
		local factor = Compose.cell(1)
		local editor = w.mount {
			devices = DesignEditor.devices.all,
			frame = function(device: DesignEditor.Device): DesignEditor.FrameContext
				return {
					resolveToken = function(): Design.Resolved
						return {
							readable = Compose.formula(function(use: Compose.Use): Design.Literal
								return (device.size.X - device.safeArea.left - device.safeArea.right) * use(factor)
							end),
						}
					end,
				}
			end,
		}
		editor.session.select "n1"
		expect(editor.session.change("width", { token = "frame.width" })):toBe(true)
		expect(editor.session.insert "Frame"):toBe(true)
		local detail = editor.session.selected:peek()
		expect(editor.session.change("width", { literal = 3 })):toBe(true)
		expect(editor.session.change("height", { literal = 16 })):toBe(true)
		editor.session.select "n1"
		editor.canvas.showAll(true)
		w.settle()
		expect(#editor.canvas.frames()):toBe(#DesignEditor.devices.all)
		for _, multiplier in { 1, 0.5 } do
			factor:set(multiplier)
			w.settle()
			for _, frame in editor.canvas.frames() do
				local stage = assert(frame.stage)
				local extent = w.point(stage.nodes[detail], "AbsoluteSize")
				expect(extent.X / stage.zoom:peek()):toBeCloseTo(3, 0.01)
				expect(extent.Y / stage.zoom:peek()):toBeCloseTo(16, 0.01)
				local width = w.point(stage.nodes.n1, "AbsoluteSize").X / stage.zoom:peek()
				expect(width):toBeCloseTo(
					math.floor(
						(frame.device.size.X - frame.device.safeArea.left - frame.device.safeArea.right) * multiplier
					),
					0.01
				)
				expect(w.read(w.find(stage.overlay, "DesignSelected"), "Visible")):toBe(true)
			end
		end
		editor.canvas.select "tv"
		editor.canvas.showAll(false)
		w.settle()
		for _, frame in editor.canvas.frames() do
			expect(w.read(frame.root, "Visible")):toBe(frame.device.id == "tv")
		end
		expect(w.find(editor.root, "Device").Text):toBe(DesignEditor.devices.get("tv").name)
		w.fire(w.find(editor.root, "Device"), "Activated")
		w.settle()
		expect(editor.canvas.current().device.id):toBe "vr"
		editor.dispose()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	for _, class in { "ScreenGui", "BillboardGui" } do
		it("projects " .. class .. " layout into every named device frame", function()
			local w = Support.world(nil, true)
			local library = Design.extend(w.library, {
				kinds = {
					Surface = {
						fields = {},
						children = "list",
						call = "UI.Surface",
						build = function(
							_props: { [string]: Design.Resolved },
							children: { unknown },
							name: string
						): unknown
							local props: Compose.Props = { Name = name, Enabled = true }
							if class == "BillboardGui" then
								props.Size = w.values.UDim2.new(0, 300, 0, 120)
							else
								props.ScreenInsets = w.values.Enum.ScreenInsets.CoreUISafeInsets
							end
							for index, child in children do
								props[index] = Support.node(child)
							end
							return w.runtime.constructors[class](props)
						end,
					},
				},
			})
			local document = Design.document.new("Surface", library, "Surface")
			local editor = DesignEditor.create(library, document, w.screen, {
				runtime = w.runtime,
				environment = w.environment,
				devices = DesignEditor.devices.all,
			})
			editor.canvas.showAll(true)
			w.settle()
			for _, frame in editor.canvas.frames() do
				local stage = assert(frame.stage)
				local root = stage.nodes.n1
				local size = w.point(root, "AbsoluteSize")
				local expected = DesignEditor.devices.area(frame.device, "CoreUISafeInsets")
				expect(size.X / stage.zoom:peek()):toBeCloseTo(
					if class == "ScreenGui" then expected.width else 300,
					0.01
				)
				expect(size.Y / stage.zoom:peek()):toBeCloseTo(
					if class == "ScreenGui" then expected.height else 120,
					0.01
				)
			end
			editor.dispose()
			w.close()
		end)
	end

	it("keeps one full-size 3D scene when all devices is requested", function()
		local w = Support.world "3d"
		local editor = w.mount { devices = DesignEditor.devices.all }
		editor.canvas.showAll(true)
		w.settle()
		editor.canvas.fit()
		expect(#editor.canvas.frames()):toBe(1)
		local scene = assert(editor.canvas.current().scene)
		local size, position = w.point(scene.viewport, "AbsoluteSize"), w.point(scene.viewport, "AbsolutePosition")
		expect(size):toEqual(w.point(editor.canvas.root, "AbsoluteSize"))
		expect(scene.pick { X = position.X + size.X / 2, Y = position.Y + size.Y / 2 }):toBe(w.first)
		editor.dispose()
		w.close()
	end)

	it("renders into a borrowed world and restores its camera without destroying foreign content", function()
		local w = Support.world "3d"
		w.devices()
		local world = w.service "Workspace"
		local camera = Support.instance(assert(world.CurrentCamera))
		local before = { camera.CFrame, camera.Focus, camera.FieldOfView, camera.CameraType }
		local foreign = w.env.createInstance "Folder"
		foreign.Parent = world
		local editor = w.mount {
			scene = { world = world, camera = camera },
			identity = {
				commit = "fixture",
				path = "Scene.luau",
			},
		}
		w.settle()
		local scene = assert(editor.canvas.current().scene)
		expect(w.read(scene.world, "Parent")):toBe(world)
		local changed = editor.execute { action = "Camera", preset = "approach-20" }
		expect(changed.ok):toBe(true)
		expect(changed.commit):toBe "fixture"
		expect(assert(changed.camera).preset):toBe "approach-20"
		expect(w.find(editor.root, "Camera").Text):toBe "Camera · Approach at 20 studs"
		local eye = assert(editor.execute({ action = "Camera", preset = "eye-height" }).camera)
		local frame, extent = w.environment.invoke(scene.nodes.n1, "GetBoundingBox")
		expect(eye.focus.Y):toBeCloseTo(
			w.number(w.read(frame, "Position"), "Y") - w.number(extent, "Y") / 2 + 5.5,
			0.001
		)
		expect(eye.pitch):toBe(0)
		local close = assert(editor.execute({ action = "Camera", preset = "close-up" }).camera)
		local top = assert(editor.execute({ action = "Camera", preset = "top-down" }).camera)
		expect(top.pitch):toBeCloseTo(-90, 0.001)
		expect(close.distance < top.distance):toBe(true)
		local orbit = editor.execute { action = "Orbit", yaw = 60, pitch = -20 }
		expect(assert(orbit.camera).yaw):toBeCloseTo(60, 0.001)
		expect(editor.execute({ action = "Orbit", yaw = math.nan, pitch = 0 }).ok):toBe(false)
		local size, position = w.point(scene.viewport, "AbsoluteSize"), w.point(scene.viewport, "AbsolutePosition")
		editor.execute { action = "Fit" }
		expect(scene.pick { X = position.X + size.X / 2, Y = position.Y + size.Y / 2 }):toBe(w.first)
		editor.dispose()
		expect({ camera.CFrame, camera.Focus, camera.FieldOfView, camera.CameraType }):toEqual(before)
		expect(foreign.Parent):toBe(world)
		expect(Support.instance(scene.world).Parent):toBe(nil)
		w.close()
	end)

	it("shares named preview choices and undoable edits between commands and controls", function()
		local w = Support.world()
		local chosen = "ordinary"
		local editor = w.mount {
			previews = {
				{
					name = "State",
					choices = { "ordinary", "empty", "busy", "error" },
					select = function(choice)
						chosen = choice
					end,
				},
			},
		}
		editor.execute { action = "Preview", name = "State", choice = "busy" }
		expect(chosen):toBe "busy"
		w.fire(w.find(editor.root, "State"), "Activated")
		expect(chosen):toBe "error"
		expect(editor.execute({ action = "Read" }).previews.State):toBe "error"
		editor.execute { action = "Select", ids = { w.first } }
		editor.execute { action = "Change", field = "width", value = { literal = 180 } }
		expect(assert((Design.document.find(editor.session.document:peek().root, w.first))).props.width.literal):toBe(
			180
		)
		editor.execute { action = "Undo" }
		expect(assert((Design.document.find(editor.session.document:peek().root, w.first))).props.width.literal):toBe(
			120
		)
		local invalid = editor.execute { action = "Device", id = "missing" }
		expect(invalid.ok):toBe(false)
		expect(invalid.next):toBe 'execute({ action = "Read" })'
		editor.dispose()
		w.close()
	end)

	it("remembers readable chrome sizing across edits and reopening without changing the canvas", function()
		local w = Support.world()
		local editor = w.mount()
		w.settle()
		local surface = w.point(assert(editor.canvas.current().stage).surface, "AbsoluteSize")
		local designText = w.number(assert(editor.canvas.current().stage).nodes[w.first], "TextSize")
		local function chrome()
			return {
				w.find(w.find(editor.root, "DesignLibrary"), "Search"),
				w.find(w.find(w.find(editor.root, "DesignLayers"), "n1"), "Title"),
				w.find(w.find(editor.root, "InspectorPanel"), "Caption"),
			}
		end
		for _, control in chrome() do
			expect(w.number(control, "TextSize") >= 14):toBe(true)
		end
		w.fire(w.find(editor.root, "TextSize"), "Activated")
		expect(w.screen:GetAttribute "ComposeDesignTextSize"):toBe(17)
		expect(w.find(w.find(editor.root, "DesignLibrary"), "Search").TextSize):toBe(17)
		editor.session.insert "Text"
		w.settle()
		expect(w.number(w.find(w.find(w.find(editor.root, "DesignLayers"), "n1"), "Title"), "TextSize")):toBe(17)
		editor.dispose()
		editor = w.mount()
		w.settle()
		expect(w.find(editor.root, "TextSize").Text):toBe "Text 17"
		expect(w.find(w.find(editor.root, "DesignLibrary"), "Search").TextSize):toBe(17)
		expect(w.point(assert(editor.canvas.current().stage).surface, "AbsoluteSize")):toEqual(surface)
		expect(w.number(assert(editor.canvas.current().stage).nodes[w.first], "TextSize")):toBe(designText)
		for _, chosen in { 19, 15 } do
			w.fire(w.find(editor.root, "TextSize"), "Activated")
			expect(w.screen:GetAttribute "ComposeDesignTextSize"):toBe(chosen)
		end
		editor.dispose()
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("reads native vector components without treating the value as an Instance", function()
		local w = Support.world()
		local ui = EditorUI.create(w.runtime, w.environment)
		local value = vector.create(3, 4, 5)
		expect(ui.vector(value)):toEqual { X = 3, Y = 4, Z = 5 }
		expect(ui.point(value)):toEqual { X = 3, Y = 4 }
		ui.dispose()
		w.close()
	end)

	it("renders resolved datatype components through the host and releases reactive bindings", function()
		local w = Support.world()
		local kind = w.library.kinds[w.document.root.kind]
		kind.fields.Size = { type = "datatype", datatype = "UDim2", tokens = true }
		kind.build = function(props: { [string]: Design.Resolved }, _children: { unknown }, name: string): unknown
			local size = props.Size
			return w.runtime.create "Frame" {
				Name = name,
				Size = function(use: Compose.Use): unknown
					local readable = size.readable
					local literal = if readable then use(readable) else size.literal
					assert(type(literal) == "table")
					local xScale, xOffset, yScale, yOffset = literal[1], literal[2], literal[3], literal[4]
					assert(type(xScale) == "number" and type(xOffset) == "number")
					assert(type(yScale) == "number" and type(yOffset) == "number")
					return w.values.UDim2.new(xScale, xOffset, yScale, yOffset)
				end,
			}
		end
		local value =
			Design.document.setContract(Design.document.new("Geometry", w.library, w.document.root.kind), w.library, {
				inputs = { { id = "width", kind = "readable", type = "number", required = true } },
				outputs = {},
			})
		value = Design.document.change(value, w.library, "n1", "Size", {
			literal = Design.datatype.literal { 0, { input = "width" }, 0, { token = "size.pill" } },
		})
		local initial: Design.Literal? = 48
		local height = Compose.cell(initial)
		local width = Compose.cell<<Design.Literal?>>(240)
		local dispose, root = w.runtime.mount(function(): Compose.Node
			return Support.node(Design.render(value, w.library, {
				bindings = { width = { readable = width } },
				resolveToken = function(name: string): Design.Resolved
					return if name == "size.pill" then { readable = height } else { literal = 240 }
				end,
			}))
		end, w.screen)
		w.settle()
		expect(w.point(root, "AbsoluteSize")):toEqual { X = 240, Y = 48 }
		height:set(64)
		w.settle()
		expect(w.point(root, "AbsoluteSize")):toEqual { X = 240, Y = 64 }
		width:set(280)
		w.settle()
		expect(w.point(root, "AbsoluteSize")):toEqual { X = 280, Y = 64 }
		dispose()
		width:set(300)
		expect(width:peek()):toBe(300)
		height:set(72)
		expect(height:peek()):toBe(72)
		w.close()
	end)

	it("shows and selects tokens per datatype component with undo and numeric edits", function()
		local w = Support.world()
		local kind = w.library.kinds[w.document.root.kind]
		kind.fields.Size = { type = "datatype", datatype = "UDim2", tokens = true }
		kind.fields.Anchor = { type = "datatype", datatype = "Vector2", tokens = true }
		kind.fields.Padding = { type = "datatype", datatype = "UDim", tokens = true }
		local initial = Design.datatype.literal { 1, 0, 0, { token = "size.pill" } }
		local value = Design.document.change(w.document, w.library, "n1", "Size", { literal = initial })
		local editor = DesignEditor.create(w.library, value, w.screen, {
			runtime = w.runtime,
			environment = w.environment,
			stageSize = { X = 480, Y = 320 },
			tokens = { "size.pill", "size.minimumTouch" },
			token = function(name: string): Design.Literal
				return if name == "size.pill" then 32 else 48
			end,
		})
		w.settle()
		local inspector = w.find(editor.root, "DesignInspector")
		local function component(key: string, index: number)
			return w.find(w.find(inspector, key), `Component{index}`)
		end
		local function box(key: string, index: number)
			return assert(component(key, index):FindFirstChildWhichIsA("TextBox", true))
		end
		expect(box("Size", 4).Text):toBe "size.pill"
		expect(box("Size", 1).Text):toBe "1"
		w.fire(w.find(component("Size", 4), "Bind"), "Activated")
		w.settle()
		expect(box("Size", 4).Text):toBe "size.minimumTouch"
		expect(editor.session.document:peek().root.props.Size.literal):toEqual(
			Design.datatype.literal { 1, 0, 0, { token = "size.minimumTouch" } }
		)
		expect(editor.session.undo()):toBe(true)
		w.settle()
		expect(box("Size", 4).Text):toBe "size.pill"
		for index = 1, 4 do
			w.fire(w.find(component("Size", index), "Bind"), "Activated")
			w.settle()
			expect(box("Size", index).Text):toBe(if index == 4 then "size.minimumTouch" else "size.pill")
		end
		local height = box("Size", 4)
		height.Text = "64"
		w.fire(height, "FocusLost")
		w.settle()
		expect(box("Size", 4).Text):toBe "64"
		expect(editor.session.document:peek().root.props.Size.literal):toEqual(
			Design.datatype.literal { { token = "size.pill" }, { token = "size.pill" }, { token = "size.pill" }, 64 }
		)
		for _, key in { "Anchor", "Padding" } do
			w.fire(w.find(component(key, 2), "Bind"), "Activated")
			w.settle()
			expect(box(key, 2).Text):toBe "size.pill"
			expect(editor.session.document:peek().root.props[key].literal):toEqual(
				Design.datatype.literal { 0, { token = "size.pill" } }
			)
		end
		local code = Design.emit(editor.session.document:peek(), w.library)
		expect(Design.emit(Design.parse(code, w.library), w.library)):toBe(code)
		editor.dispose()
		w.close()
	end)

	it("opens a kit with its native live tokens, token choices and preview slots", function()
		local w = Support.world()
		local tint = Compose.cell(w.values.Color3.new(0.2, 0.4, 0.6))
		local library = Design.extend(w.library, {
			kinds = {
				Surface = {
					fields = { tint = { type = "value", tokens = true }, content = { type = "content" } },
					children = "none",
					call = "UI.Surface",
					build = function(
						props: { [string]: Design.Resolved },
						_children: { unknown },
						name: string
					): unknown
						local color = props.tint
						local content = props.content
						local slot = if content then content.slot else nil
						return w.runtime.create "Frame" {
							Name = name,
							BackgroundColor3 = if color then color.value else nil,
							if slot then slot() else nil,
						}
					end,
				},
			},
		})
		local value = Design.document.setContract(Design.document.new("Preview", library, "Surface"), library, {
			inputs = { { id = "content", kind = "value", type = "slot" } },
			outputs = {},
		})
		value = Design.document.change(value, library, "n1", "tint", { token = "surface" })
		value = Design.document.change(value, library, "n1", "content", { input = "content" })
		value = Design.document.rename(value, library, "n1", "TokenSurface")
		local source = Design.emit(value, library)
		local kit = DesignEditor.kit("Cards", function(): DesignEditor.Workspace
			return {
				runtime = w.runtime,
				environment = w.environment,
				library = library,
				root = "Surface",
				tokens = { "surface" },
				resolveToken = function(name: string): Design.Resolved
					expect(name):toBe "surface"
					return { value = tint }
				end,
				slots = {
					content = function(): unknown
						return w.runtime.constructors.TextLabel "PreviewSlot" { Text = "Slot" }
					end,
				},
			}
		end)
		local stopped = false
		local editor = kit.edit(w.screen, "Preview", {
			read = function(): string
				return source
			end,
			write = function(_expected: string, generated: string): boolean
				source = generated
				return true
			end,
			watch = function(_changed: () -> ()): () -> ()
				return function()
					stopped = true
				end
			end,
		})
		w.settle()
		local surface = w.find(w.screen, "TokenSurface")
		expect(w.find(surface, "PreviewSlot")):toBeOk()
		expect(w.read(surface, "BackgroundColor3")):toBe(tint:peek())
		tint:set(w.values.Color3.new(0.6, 0.4, 0.2))
		w.settle()
		expect(w.read(surface, "BackgroundColor3")):toBe(tint:peek())
		editor.dispose()
		expect(stopped):toBe(true)
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)
	it("renders live card bindings, keyed input, opaque geometry, attributes and owned slots", function()
		local w = Support.world()
		local function build(kind: string)
			return function(props: { [string]: Design.Resolved }, children: { unknown }, name: string): unknown
				local fields: { [unknown]: unknown } = {}
				for key, prop in props do
					fields[key] = prop.value or prop.readable or prop.callback or prop.literal
					if prop.slot then
						fields[#fields + 1] = prop.slot()
						fields[key] = nil
					end
				end
				for _, child in children do
					fields[#fields + 1] = child
				end
				fields.Name = name
				return w.runtime.create(kind)(fields)
			end
		end
		local library: Design.Library = {
			name = "Cards",
			parameter = "UI",
			parameterType = "Controls",
			prelude = {},
			returnType = "GuiObject",
			readable = "Compose.ReadOnlyValue",
			cell = "Compose.Cell",
			show = "Compose.show",
			keyed = "Compose.keyed",
			kinds = {
				Card = {
					fields = {
						Size = { type = "datatype", datatype = "UDim2" },
						Attributes = { type = "value" },
						content = { type = "content" },
					},
					children = "list",
					call = "UI.Card",
					build = build "Frame",
				},
				Choice = {
					fields = { Text = { type = "string" }, Activated = { type = "event" } },
					children = "none",
					call = "UI.Choice",
					build = build "TextButton",
				},
			},
		}
		local itemFields: { Design.ItemField } = {
			{ id = "id", type = "string" },
			{ id = "label", type = "string" },
			{ id = "index", type = "number" },
		}
		local args: { Design.InputType } = { "number" }
		local value = Design.document.setContract(Design.document.new("Card", library, "Card"), library, {
			inputs = {
				{ id = "size", kind = "readable", type = "record", luauType = "UDim2" },
				{
					id = "rows",
					kind = "readable",
					type = "list",
					fields = itemFields,
				},
				{ id = "hint", kind = "readable", type = "boolean" },
				{ id = "overlay", kind = "value", type = "slot" },
			},
			outputs = { { id = "onSelect", args = args } },
		})
		value = Design.document.change(value, library, "n1", "Size", { input = "size" })
		local attributes: { [string | number]: Design.Literal } = { Occluder = true }
		value = Design.document.change(value, library, "n1", "Attributes", { literal = attributes })
		value = Design.document.change(value, library, "n1", "content", { input = "overlay" })
		local row, hint
		value, row = Design.document.insert(value, library, "n1", "Choice")
		value = Design.document.bind(value, library, "n1", { from = "rows", key = "id", row = row })
		value = Design.document.nameFrom(value, library, row, "id")
		value = Design.document.change(value, library, row, "Text", { item = "label" })
		value = Design.document.change(value, library, row, "Activated", { output = "onSelect", fields = { "index" } })
		value, hint = Design.document.insert(value, library, "n1", "Choice")
		value = Design.document.rename(value, library, hint, "Hint")
		value = Design.document.showWhen(value, library, hint, "hint")
		local rows = Compose.cell { { id = "a", label = "First", index = 1 } }
		local shown = Compose.cell(true)
		local width = Compose.cell(200)
		local selected: Design.Literal? = nil
		local function render(): Compose.Node
			return Support.node(Design.render(value, library, {
				bindings = {
					size = {
						value = function(use: Compose.Use): unknown
							return w.values.UDim2.fromOffset(use(width), 120)
						end,
					},
					rows = { rows = rows },
					hint = { readable = shown },
				},
				slots = {
					overlay = function(): unknown
						return w.runtime.constructors.Frame "Overlay" {}
					end,
				},
				outputs = {
					onSelect = function(args: { Design.Literal })
						selected = args[1]
					end,
				},
			}))
		end
		local dispose, root = w.runtime.mount(render, w.screen)
		w.settle()
		local first = w.find(root, "a")
		expect(w.read(first, "Text")):toBe "First"
		expect(Support.instance(root):GetAttribute "Occluder"):toBe(true)
		expect(w.point(root, "AbsoluteSize").X):toBe(200)
		rows:set { { id = "a", label = "Changed", index = 3 }, { id = "b", label = "Second", index = 2 } }
		width:set(300)
		shown:set(false)
		w.settle()
		expect(w.find(root, "a")):toBe(first)
		expect(w.read(first, "Text")):toBe "Changed"
		expect(w.find(root, "b")):toBeOk()
		expect(Support.instance(root):FindFirstChild "Hint"):toBeNil()
		expect(w.point(root, "AbsoluteSize").X):toBe(300)
		w.fire(first, "Activated")
		expect(selected):toBe(3)
		rows:set { { id = "b", label = "Only", index = 1 } }
		shown:set(true)
		w.settle()
		expect(w.env.isAlive(first)):toBe(false)
		expect(w.find(root, "Hint")):toBeOk()
		dispose()
		dispose()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.emulator.failNext "setAttribute"
		expect(function()
			w.runtime.mount(render, w.screen)
		end):toThrow()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)
	it("unwinds failed Host construction after the stage and layers have mounted", function()
		local w = Support.world()
		local write = w.emulator.render.setProperty
		w.emulator.render.setProperty = function(node: unknown, key: string, value: unknown)
			if key == "Name" and value == "NodeName" then
				error "inspector construction failed"
			end
			write(Support.node(node), key, value)
		end
		expect(function()
			w.mount()
		end):toThrow "inspector construction failed"
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		expect(w.env.isAlive(w.screen)):toBe(true)
		w.close()
	end)

	it("unwinds a refused design attribute without retaining any editor nodes or connections", function()
		local w = Support.world()
		w.emulator.failNext "setAttribute"
		expect(function()
			w.mount()
		end):toThrow()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("releases the other panels when a mount cleanup raises", function()
		local w = Support.world()
		local editor = w.mount()
		w.settle()
		w.emulator.failNext "removeChild"
		expect(editor.dispose):toThrow "injected failure"
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		expect(w.env.isAlive(w.screen)):toBe(true)
		editor.dispose()
		w.close()
	end)
	it("mounts through Host and releases owned objects and subscriptions while preserving its parent", function()
		local w = Support.world()
		local editor = w.mount()
		w.settle()
		expect(w.find(editor.root, "Toolbar")):toBeOk()
		expect(w.find(editor.root, "DesignLayers")):toBeOk()
		expect(w.find(editor.root, "DesignInspector")):toBeOk()
		expect(w.find(editor.root, "StatusBar")):toBeOk()
		local created = 0
		for _, entry in w.emulator.log() do
			if entry.operation == "createNode" then
				created += 1
			end
		end
		expect(created > 100):toBe(true)
		editor.dispose()
		editor.dispose()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		expect(w.env.isAlive(w.screen)):toBe(true)
		w.close()
	end)

	it("places selection outlines and constant-screen-size grips at 100% and 200%", function()
		local w = Support.world()
		local editor = w.mount()
		local stage = assert(editor.canvas.current().stage)
		editor.session.select(w.first)
		for _, zoom in { 1, 2 } do
			stage.zoomTo(zoom)
			w.settle()
			local node = stage.nodes[w.first]
			local outline = w.find(stage.overlay, "DesignSelected")
			local a, b = w.point(node, "AbsolutePosition"), w.point(outline, "AbsolutePosition")
			local size, extent = w.point(node, "AbsoluteSize"), w.point(outline, "AbsoluteSize")
			expect(w.read(outline, "Visible")):toBe(true)
			expect(a.X):toBeCloseTo(b.X, 0.01)
			expect(a.Y):toBeCloseTo(b.Y, 0.01)
			expect(size.X):toBeCloseTo(extent.X, 0.01)
			expect(size.Y):toBeCloseTo(extent.Y, 0.01)
			local handle = w.find(outline, "Handle")
			expect(w.point(handle, "AbsoluteSize").X):toBeCloseTo(7, 1.01)
			local ring = assert(outline:FindFirstChildWhichIsA "UIStroke")
			expect(w.number(ring, "Thickness") * zoom):toBeCloseTo(1.5, 0.01)
			expect(w.read(w.find(outline, "SizeBadge"), "Text")):toBe "120 × 36"
		end
		editor.dispose()
		w.close()
	end)

	it("reflects session.move in layer order and rendered child layout order, including undo", function()
		local w = Support.world()
		local editor = w.mount()
		expect(editor.session.move(w.second, "n1", 1)):toBe(true)
		w.settle()
		local layers = w.find(editor.root, "DesignLayers")
		expect(w.number(w.find(layers, w.second), "LayoutOrder")):toBe(2)
		expect(w.number(w.find(layers, w.first), "LayoutOrder")):toBe(3)
		expect(w.number(assert(editor.canvas.current().stage).nodes[w.second], "LayoutOrder")):toBe(1)
		expect(editor.session.undo()):toBe(true)
		w.settle()
		expect(w.number(w.find(layers, w.first), "LayoutOrder")):toBe(2)
		editor.dispose()
		w.close()
	end)

	it("drags a layer before its sibling through the injected input service", function()
		local w = Support.world()
		local editor = w.mount()
		w.settle()
		local layers = w.find(editor.root, "DesignLayers")
		local moving, target = w.find(layers, w.second), w.find(layers, w.first)
		local from, to = w.point(moving, "AbsolutePosition"), w.point(target, "AbsolutePosition")
		w.fire(moving, "InputBegan", w.pointer("MouseButton1", from.X + 20, from.Y + 14))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", to.X + 20, to.Y + 1))
		expect(w.read(w.find(editor.root, "DropIndicator"), "Visible")):toBe(true)
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", to.X + 20, to.Y + 1))
		w.settle()
		expect(editor.session.document:peek().root.children[1].id):toBe(w.second)
		expect(editor.session.selected:peek()):toBe(w.second)
		expect(w.read(w.find(editor.root, "DropIndicator"), "Visible")):toBe(false)
		editor.dispose()
		w.close()
	end)

	it("lists library kinds by category, filters them by search and inserts the activated kind", function()
		local w = Support.world()
		local editor = w.mount()
		local panel = w.find(editor.root, "DesignLibrary")
		local kinds = w.find(panel, "Kinds")
		local before = #editor.session.document:peek().root.children
		local search = w.find(panel, "Search")
		search.Text = "butt"
		w.settle()
		expect(w.find(kinds, "Button").Visible):toBe(true)
		expect(w.find(kinds, "Text").Visible):toBe(false)
		w.fire(w.find(kinds, "Button"), "Activated")
		w.settle()
		local root = editor.session.document:peek().root
		expect(#root.children):toBe(before + 1)
		expect(root.children[#root.children].kind):toBe "Button"
		search.Text = ""
		w.settle()
		expect(w.find(kinds, "Text").Visible):toBe(true)
		editor.dispose()
		w.close()
	end)

	it("switches devices and previews from the toolbar and folds advanced fields", function()
		local w = Support.world()
		local chosen: { string } = {}
		local editor = w.mount {
			devices = {
				DesignEditor.devices.custom("Phone", { X = 390, Y = 844 }),
				DesignEditor.devices.custom("Tablet", { X = 820, Y = 1180 }),
			},
			previews = {
				{
					name = "Theme",
					choices = { "Light", "Dark" },
					select = function(choice: string)
						table.insert(chosen, choice)
					end,
				},
			},
		}
		w.settle()
		local device = w.find(editor.root, "Device")
		expect(device.Text):toBe "Phone"
		w.fire(device, "Activated")
		w.settle()
		expect(device.Text):toBe "Tablet"
		expect(w.find(editor.canvas.current().root, "ArtboardSize").Text):toBe "820 × 1180"
		w.fire(w.find(editor.root, "Theme"), "Activated")
		w.settle()
		expect(chosen):toEqual { "Light", "Dark" }
		editor.dispose()
		w.close()
	end)

	it("opens a kit workspace on an empty linked module, seeds it and releases it", function()
		local w = Support.world()
		local released = 0
		local source = ""
		local kit = DesignEditor.kit("Test", function(): DesignEditor.Workspace
			return {
				runtime = w.runtime,
				environment = w.environment,
				library = w.library,
				root = w.document.root.kind,
				devices = { DesignEditor.devices.custom("Phone", { X = 390, Y = 844 }) },
				dispose = function()
					released += 1
				end,
			}
		end)
		local editor = kit.edit(w.screen, "Seeded", {
			read = function(): string
				return source
			end,
			write = function(expected: string, generated: string): boolean
				if source ~= expected then
					return false
				end
				source = generated
				return true
			end,
			watch = function(_changed: () -> ()): () -> ()
				return function() end
			end,
		})
		w.settle()
		expect(string.find(source, "local _design", 1, true) ~= nil):toBe(true)
		expect(string.find(source, '"Seeded"', 1, true) ~= nil):toBe(true)
		expect(w.find(w.screen, "ArtboardSize").Text):toBe "390 × 844"
		editor.dispose()
		expect(released):toBe(1)
		w.close()
	end)

	it("lets a library provide the surroundings of the staged design", function()
		local w = Support.world()
		local rootKind = w.library.kinds[w.document.root.kind]
		local provided: { unknown } = {}
		w.library.provide = function(content: unknown): unknown
			table.insert(provided, content)
			return rootKind.build({}, { content }, "Provided")
		end
		local editor = w.mount()
		w.settle()
		local surround = w.find(editor.root, "Provided")
		expect(#provided):toBe(1)
		expect(w.read(provided[1], "Parent")):toBe(surround)
		editor.dispose()
		w.close()
	end)

	it("edits value fields as Luau literals and node fields by choosing a node", function()
		local w = Support.world()
		local rootKind = w.library.kinds[w.document.root.kind]
		local valued = table.clone(rootKind.fields.width)
		valued.type = "value"
		rootKind.fields.width = valued
		rootKind.fields.follow = { type = "node", group = "Layout", order = 99 }
		local editor = w.mount()
		w.settle()
		local inspector = w.find(editor.root, "DesignInspector")
		local box = assert(w.find(inspector, "width"):FindFirstChildWhichIsA("TextBox", true))
		box.Text = "320"
		w.fire(box, "FocusLost")
		w.settle()
		local root = editor.session.document:peek().root
		expect(root.props.width.literal):toBe(320)
		inspector = w.find(editor.root, "DesignInspector")
		box = assert(w.find(inspector, "width"):FindFirstChildWhichIsA("TextBox", true))
		expect(box.Text):toBe "320"
		box.Text = "{ 1,"
		w.fire(box, "FocusLost")
		w.settle()
		expect(editor.session.problem:peek() ~= nil):toBe(true)
		expect(editor.session.document:peek().root.props.width.literal):toBe(320)
		w.fire(w.find(w.find(inspector, "follow"), "Bind"), "Activated")
		w.settle()
		expect(editor.session.document:peek().root.props.follow.node):toBe "n1"
		editor.dispose()
		w.close()
	end)

	it("reports a design that fails to render and keeps editing", function()
		local w = Support.world()
		local rootKind = w.library.kinds[w.document.root.kind]
		local build = rootKind.build
		local editor = w.mount()
		w.settle()
		rootKind.build = function(): unknown
			error "broken control"
		end
		editor.session.change("Visible", { literal = false })
		w.settle()
		expect(string.find(editor.session.problem:peek() or "", "broken control", 1, true) ~= nil):toBe(true)
		rootKind.build = build
		editor.session.change("Visible", { literal = true })
		w.settle()
		expect(assert(editor.canvas.current().stage).nodes[w.document.root.id] ~= nil):toBe(true)
		editor.dispose()
		w.close()
	end)

	it("labels inspector rows and folds advanced fields until asked", function()
		local w = Support.world()
		local rootKind = w.library.kinds[w.document.root.kind]
		local labelled = table.clone(rootKind.fields.width)
		labelled.label = "Box width"
		local folded = table.clone(rootKind.fields.Visible)
		folded.advanced = true
		rootKind.fields.width = labelled
		rootKind.fields.Visible = folded
		local editor = w.mount()
		w.settle()
		local inspector = w.find(editor.root, "DesignInspector")
		expect(w.find(w.find(inspector, "width"), "Label").Text):toBe "Box width"
		expect(inspector:FindFirstChild("Visible", true)):toBe(nil)
		w.fire(w.find(inspector, "Advanced"), "Activated")
		w.settle()
		expect(inspector:FindFirstChild("Visible", true) ~= nil):toBe(true)
		editor.dispose()
		w.close()
	end)

	it("commits inspector text, numeric, toggle, segmented and colour controls", function()
		local w = Support.world()
		local editor = w.mount()
		local inspector = w.find(editor.root, "DesignInspector")
		local function edit(key: string, text: string)
			local row = w.find(inspector, key)
			local box = assert(row:FindFirstChildWhichIsA("TextBox", true))
			box.Text = text
			w.fire(box, "FocusLost")
			w.settle()
		end
		edit("width", "320")
		expect(editor.session.document:peek().root.props.width.literal):toBe(320)
		local toggle = w.find(w.find(inspector, "Visible"), "Toggle")
		w.fire(toggle, "Activated")
		w.settle()
		expect(editor.session.document:peek().root.props.Visible.literal):toBe(false)
		w.fire(w.find(w.find(inspector, "direction"), "horizontal"), "Activated")
		w.settle()
		expect(editor.session.document:peek().root.props.direction.literal):toBe "horizontal"
		edit("background", "#336699")
		expect(editor.session.document:peek().root.props.background.literal):toBe "#336699"
		editor.session.select(w.first)
		w.settle()
		edit("text", "Edited headlessly")
		expect(w.read(assert(editor.canvas.current().stage).nodes[w.first], "Text")):toBe "Edited headlessly"
		editor.dispose()
		w.close()
	end)

	it("previews several resize updates and commits width and height as one undo step", function()
		local w = Support.world()
		local editor = w.mount()
		editor.session.select(w.first)
		local stage = assert(editor.canvas.current().stage)
		stage.zoomTo(1)
		w.settle()
		local outline = w.find(stage.overlay, "DesignSelected")
		local handle = w.find(outline, "Handle")
		local at, size = w.point(handle, "AbsolutePosition"), w.point(handle, "AbsoluteSize")
		local x, y = at.X + size.X / 2, at.Y + size.Y / 2
		w.fire(stage.overlay, "InputBegan", w.pointer("MouseButton1", x, y))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", x - 10, y - 8))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", x - 30, y - 20))
		expect(editor.session.canUndo:peek()):toBe(false)
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", x - 30, y - 20))
		w.settle()
		local changed = assert((Design.document.find(editor.session.document:peek().root, w.first)))
		expect(changed.props.width.literal):toBe(150)
		expect(changed.props.height.literal):toBe(56)
		expect(editor.session.undo()):toBe(true)
		local restored = assert((Design.document.find(editor.session.document:peek().root, w.first)))
		expect(restored.props.width.literal):toBe(120)
		expect(restored.props.height.literal):toBe(36)
		expect(editor.session.canUndo:peek()):toBe(false)
		editor.dispose()
		w.close()
	end)

	it("drags a node on the canvas past its sibling and drops it there as one undo step", function()
		local w = Support.world()
		local editor = w.mount()
		local stage = assert(editor.canvas.current().stage)
		stage.zoomTo(1)
		w.settle()
		local first, second = stage.nodes[w.first], stage.nodes[w.second]
		local at, size = w.point(first, "AbsolutePosition"), w.point(first, "AbsoluteSize")
		local x, y = at.X + size.X / 2, at.Y + size.Y / 2
		local below = w.point(second, "AbsolutePosition").Y + w.point(second, "AbsoluteSize").Y - 2
		w.fire(stage.overlay, "InputBegan", w.pointer("MouseButton1", x, y))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", x, y + 10))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", x, below))
		expect(w.read(w.find(stage.overlay, "DesignDropMarker"), "Visible")):toBe(true)
		expect(editor.session.canUndo:peek()):toBe(false)
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", x, below))
		w.settle()
		local root = editor.session.document:peek().root
		expect(root.children[1].id):toBe(w.second)
		expect(root.children[2].id):toBe(w.first)
		expect(w.read(w.find(stage.overlay, "DesignDropMarker"), "Visible")):toBe(false)
		expect(editor.session.undo()):toBe(true)
		expect(editor.session.document:peek().root.children[1].id):toBe(w.first)
		editor.dispose()
		w.close()
	end)

	it("keeps a short press on a node a selection, not a move", function()
		local w = Support.world()
		local editor = w.mount()
		local stage = assert(editor.canvas.current().stage)
		stage.zoomTo(1)
		w.settle()
		local second = stage.nodes[w.second]
		local at, size = w.point(second, "AbsolutePosition"), w.point(second, "AbsoluteSize")
		local x, y = at.X + size.X / 2, at.Y + size.Y / 2
		w.fire(stage.overlay, "InputBegan", w.pointer("MouseButton1", x, y))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", x + 2, y + 1))
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", x + 2, y + 1))
		w.settle()
		expect(editor.session.selected:peek()):toBe(w.second)
		expect(editor.session.document:peek().root.children[2].id):toBe(w.second)
		expect(editor.session.canUndo:peek()):toBe(false)
		editor.dispose()
		w.close()
	end)

	it("scrubs an inspector number with Shift and commits only when the pointer is released", function()
		local w = Support.world()
		local editor = w.mount()
		w.settle()
		local row = w.find(w.find(editor.root, "DesignInspector"), "width")
		w.fire(w.find(row, "Label"), "InputBegan", w.pointer("MouseButton1", 100, 100))
		w.down[w.values.Enum.KeyCode.LeftShift] = true
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", 104, 100))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", 110, 100))
		expect(editor.session.document:peek().root.props.width.literal):toBe(400)
		expect(editor.session.canUndo:peek()):toBe(false)
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", 110, 100))
		w.settle()
		expect(editor.session.document:peek().root.props.width.literal):toBe(450)
		expect(editor.session.undo()):toBe(true)
		expect(editor.session.document:peek().root.props.width.literal):toBe(400)
		expect(editor.session.canUndo:peek()):toBe(false)
		editor.dispose()
		w.close()
	end)

	it("runs toolbar and keyboard actions and exports the current source", function()
		local w = Support.world()
		local exported = ""
		local editor = w.mount {
			onExport = function(source: string)
				exported = source
			end,
		}
		editor.session.select(w.first)
		w.fire(w.find(editor.root, "Duplicate"), "Activated")
		w.settle()
		expect(#editor.session.document:peek().root.children):toBe(3)
		local context = w.find(editor.root, "ComposeDesignShortcuts")
		w.fire(w.find(context, "Undo"), "Pressed")
		w.settle()
		expect(#editor.session.document:peek().root.children):toBe(2)
		w.fire(w.find(editor.root, "Export"), "Activated")
		expect(exported):toBe(Design.emit(editor.session.document:peek(), w.library))
		editor.dispose()
		w.close()
	end)

	it("keeps the source-link status bar synchronized and imports external changes", function()
		local w = Support.world()
		local source = Design.emit(w.document, w.library)
		local notify: (() -> ())? = nil
		local stops = 0
		local store: Design.LinkStore = {
			read = function(): string
				return source
			end,
			write = function(expected: string, generated: string): boolean
				if source ~= expected then
					return false
				end
				source = generated
				return true
			end,
			watch = function(changed: () -> ()): () -> ()
				notify = changed
				return function()
					stops += 1
					notify = nil
				end
			end,
		}
		local editor = w.mount { link = store }
		w.settle()
		local sync = w.find(editor.root, "Sync")
		expect(w.read(sync, "Text")):toBe "● Source synced"
		editor.session.change("width", { literal = 360 })
		w.settle()
		expect(Design.parse(source, w.library).root.props.width.literal):toBe(360)
		source = "return 1"
		assert(notify)()
		w.settle()
		expect(w.read(sync, "Text")):toBe "○ Custom source · Import"
		source = Design.emit(w.document, w.library)
		w.fire(sync, "Activated")
		w.settle()
		expect(w.read(sync, "Text")):toBe "● Source synced"
		editor.dispose()
		editor.dispose()
		expect(stops):toBe(1)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("keeps the cursor anchor during zoom, clamps scale and fits the available stage room", function()
		local w = Support.world(nil, true)
		local editor = w.mount()
		w.settle()
		local stage = assert(editor.canvas.current().stage)
		local panel = w.find(editor.root, "StagePanel")
		local holder = w.find(panel, "DesignStage")
		stage.zoomTo(1)
		local at, size = w.point(panel, "AbsolutePosition"), w.point(panel, "AbsoluteSize")
		local around = { X = at.X + size.X / 2 + 40, Y = at.Y + size.Y / 2 + 30 }
		stage.zoomTo(2, around)
		local position = w.read(holder, "Position")
		expect(w.number(w.read(position, "X"), "Offset")):toBeCloseTo(-40, 0.001)
		expect(w.number(w.read(position, "Y"), "Offset")):toBeCloseTo(-30, 0.001)
		stage.zoomTo(100)
		expect(stage.zoom:peek()):toBe(8)
		stage.zoomTo(0)
		expect(stage.zoom:peek()):toBe(0.02)
		stage.fit()
		expect(stage.zoom:peek()):toBeCloseTo(
			math.clamp(math.min((size.X - 96) / 480, (size.Y - 120) / 320), 0.02, 1),
			0.001
		)
		position = w.read(holder, "Position")
		expect(w.number(w.read(position, "X"), "Offset")):toBe(0)
		expect(w.number(w.read(position, "Y"), "Offset")):toBe(0)
		editor.dispose()
		w.close()
	end)

	it("renders a 3D scene, raycasts the centre and commits a vector3 inspector edit", function()
		local w = Support.world "3d"
		local editor = w.mount()
		w.settle()
		local scene = assert(editor.canvas.current().scene)
		expect(editor.canvas.current().stage):toBeNil()
		scene.fit()
		local at, size = w.point(scene.viewport, "AbsolutePosition"), w.point(scene.viewport, "AbsoluteSize")
		expect(scene.pick { X = at.X + size.X / 2, Y = at.Y + size.Y / 2 }):toBe(w.first)
		editor.session.select(w.first)
		w.settle()
		local inspector = w.find(editor.root, "DesignInspector")
		local x = w.find(w.find(inspector, "position"), "X")
		x.Text = "4"
		w.fire(x, "FocusLost")
		w.settle()
		local frame = w.read(scene.nodes[w.first], "CFrame")
		expect(w.number(w.read(frame, "Position"), "X")):toBeCloseTo(4, 0.001)
		expect(editor.session.undo()):toBe(true)
		w.settle()
		frame = w.read(scene.nodes[w.first], "CFrame")
		expect(w.number(w.read(frame, "Position"), "X")):toBeCloseTo(0, 0.001)
		editor.dispose()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("translates through a raycast gizmo, commits once, and orbits without changing the document", function()
		local w = Support.world "3d"
		local editor = w.mount()
		local scene = assert(editor.canvas.current().scene)
		for _, selection in { w.first, "n1" } do
			editor.session.select(selection)
			w.settle()
			scene.fit()
			local tip = w.find(scene.world, "TipX")
			local position = w.read(w.read(tip, "CFrame"), "Position")
			local projected = w.environment.invoke(w.read(scene.camera, "CFrame"), "PointToObjectSpace", position)
			local at, size = w.point(scene.viewport, "AbsolutePosition"), w.point(scene.viewport, "AbsoluteSize")
			local tanY = math.tan(math.rad(w.number(scene.camera, "FieldOfView")) / 2)
			local tanX = tanY * size.X / size.Y
			local z = -w.number(projected, "Z")
			local x = at.X + (w.number(projected, "X") / z / tanX + 1) * size.X / 2
			local y = at.Y + (1 - w.number(projected, "Y") / z / tanY) * size.Y / 2
			w.emulator.clearLog()
			w.fire(scene.viewport, "InputBegan", w.pointer("MouseButton1", x, y))
			w.fire(w.input, "InputChanged", w.pointer("MouseMovement", x + 60, y))
			local written = false
			for _, entry in w.emulator.log() do
				if
					entry.operation == "setProperty"
					and entry.key == "CFrame"
					and entry.node == scene.nodes[w.first]
				then
					written = true
				end
			end
			expect(written):toBe(true)
			expect(editor.session.canUndo:peek()):toBe(false)
			w.fire(w.input, "InputEnded", w.pointer("MouseButton1", x + 60, y))
			w.settle()
			local moved = w.number(w.read(w.read(scene.nodes[w.first], "CFrame"), "Position"), "X")
			expect(moved > 0):toBe(true)
			expect(editor.session.undo()):toBe(true)
			w.settle()
			expect(w.number(w.read(w.read(scene.nodes[w.first], "CFrame"), "Position"), "X")):toBeCloseTo(0, 0.001)
			expect(editor.session.canUndo:peek()):toBe(false)
			local before = w.number(w.read(w.read(scene.camera, "CFrame"), "Position"), "X")
			w.fire(scene.viewport, "InputBegan", w.pointer("MouseButton2", x, y))
			w.fire(w.input, "InputChanged", w.pointer("MouseMovement", x + 30, y + 10))
			w.fire(w.input, "InputEnded", w.pointer("MouseButton2", x + 30, y + 10))
			local after = w.number(w.read(w.read(scene.camera, "CFrame"), "Position"), "X")
			expect(math.abs(after - before) > 0.1):toBe(true)
			expect(editor.session.canUndo:peek()):toBe(false)
		end
		editor.dispose()
		w.close()
	end)

	it("preserves YXZ rotation when the 3D library builds through Host", function()
		local w = Support.world "3d"
		local editor = w.mount()
		editor.session.select(w.first)
		editor.session.change("rotation", { literal = { 30, 45, 60 } })
		w.settle()
		local frame = w.read(assert(editor.canvas.current().scene).nodes[w.first], "CFrame")
		local expected = w.values.CFrame.new(0, 3, 0)
			* w.values.CFrame.fromEulerAnglesYXZ(math.rad(30), math.rad(45), math.rad(60))
		local actual = { w.environment.invoke(frame, "GetComponents") }
		for index, component in { expected:GetComponents() } do
			local value = actual[index]
			assert(type(value) == "number")
			expect(value):toBeCloseTo(component, 1e-5)
		end
		editor.dispose()
		w.close()
	end)

	it("builds lights, surface images, material variants and meshes on a 3D part", function()
		local w = Support.world "3d"
		local editor = w.mount()
		editor.session.select(w.first)
		editor.session.change("materialVariant", { literal = "Moss" })
		editor.session.change("meshId", { literal = "test-mesh" })
		expect(editor.session.insert "PointLight"):toBe(true)
		editor.session.change("brightness", { literal = 2 })
		editor.session.select(w.first)
		expect(editor.session.insert "Decal"):toBe(true)
		editor.session.change("image", { literal = "test-image" })
		w.settle()
		local part = Support.instance(assert(editor.canvas.current().scene).nodes[w.first])
		expect(part.MaterialVariant):toBe "Moss"
		expect(assert(part:FindFirstChildWhichIsA "SpecialMesh").MeshId):toBe "test-mesh"
		expect(assert(part:FindFirstChildWhichIsA "PointLight").Brightness):toBe(2)
		expect(assert(part:FindFirstChildWhichIsA "Decal").Texture):toBe "test-image"
		editor.dispose()
		w.close()
	end)

	it("tiles and offsets a texture on a 3D part", function()
		local w = Support.world "3d"
		local editor = w.mount()
		editor.session.select(w.first)
		expect(editor.session.insert "Texture"):toBe(true)
		editor.session.change("tileU", { literal = 27.2 })
		editor.session.change("tileV", { literal = 13.6 })
		editor.session.change("offsetU", { literal = 8.5 })
		editor.session.change("offsetV", { literal = 2 })
		w.settle()
		local part = Support.instance(assert(editor.canvas.current().scene).nodes[w.first])
		local texture = assert(part:FindFirstChildWhichIsA "Texture")
		expect(texture.StudsPerTileU):toBe(27.2)
		expect(texture.StudsPerTileV):toBe(13.6)
		expect(texture.OffsetStudsU):toBe(8.5)
		expect(texture.OffsetStudsV):toBe(2)
		local document = editor.session.document:peek()
		local source = Design.emit(document, w.library)
		expect(Design.emit(Design.parse(source, w.library), w.library)):toBe(source)
		editor.dispose()
		w.close()
	end)

	it("builds physics flags, attributes, attachments, emitters and sounds, and round-trips them", function()
		local w = Support.world "3d"
		local editor = w.mount()
		editor.session.select(w.first)
		editor.session.change("canCollide", { literal = false })
		editor.session.change("canQuery", { literal = false })
		editor.session.change("castShadow", { literal = false })
		editor.session.change("attributes", { literal = { PoiId = "gate" } })
		expect(editor.session.insert "Attachment"):toBe(true)
		editor.session.select(w.first)
		expect(editor.session.insert "ParticleEmitter"):toBe(true)
		editor.session.change("size", { literal = { { 0, 0.25 }, { 1, 0 } } })
		editor.session.change("color", { literal = { { 0, "#FF0000" }, { 1, "#0000FF" } } })
		editor.session.change("lifetime", { literal = { 1, 2 } })
		editor.session.change("spreadAngle", { literal = { 10, 20 } })
		editor.session.change("shape", { literal = "Sphere" })
		editor.session.select(w.first)
		expect(editor.session.insert "PointLight"):toBe(true)
		editor.session.change("enabled", { literal = false })
		editor.session.select(w.first)
		expect(editor.session.insert "Sound"):toBe(true)
		editor.session.change("volume", { literal = 0.5 })
		w.settle()
		local part = Support.instance(assert(editor.canvas.current().scene).nodes[w.first])
		expect(part.CanCollide):toBe(false)
		expect(part.CanQuery):toBe(false)
		expect(part.CanTouch):toBe(true)
		expect(part.CastShadow):toBe(false)
		expect(part:GetAttribute "PoiId"):toBe "gate"
		expect(assert(part:FindFirstChildWhichIsA "Attachment").Name):toBe "Attachment"
		local emitter = assert(part:FindFirstChildWhichIsA "ParticleEmitter")
		local V = w.values
		expect(tostring(emitter.Size)):toBe(
			tostring(V.NumberSequence.new { V.NumberSequenceKeypoint.new(0, 0.25), V.NumberSequenceKeypoint.new(1, 0) })
		)
		expect(tostring(emitter.Color)):toBe(tostring(V.ColorSequence.new {
			V.ColorSequenceKeypoint.new(0, V.Color3.new(1, 0, 0)),
			V.ColorSequenceKeypoint.new(1, V.Color3.new(0, 0, 1)),
		}))
		expect(tostring(emitter.Lifetime)):toBe(tostring(V.NumberRange.new(1, 2)))
		expect(tostring(emitter.SpreadAngle)):toBe(tostring(V.Vector2.new(10, 20)))
		expect(tostring(emitter.Shape)):toBe "Enum.ParticleEmitterShape.Sphere"
		expect(assert(part:FindFirstChildWhichIsA "PointLight").Enabled):toBe(false)
		expect(assert(part:FindFirstChildWhichIsA "Sound").Volume):toBe(0.5)
		local source = Design.emit(editor.session.document:peek(), w.library)
		expect(Design.emit(Design.parse(source, w.library), w.library)):toBe(source)
		expect(string.find(source, "canTouch", 1, true)):toBe(nil)
		editor.dispose()
		w.close()
	end)

	it("parses and emits a 3D design from the schema without a runtime", function()
		local schema = DesignEditor.roblox3DSchema()
		for name, kind in schema.kinds do
			expect(kind.call):toBe("Design." .. name)
		end
		local document = Design.document.new("Fixture", schema, "Model")
		local folder
		document, folder = Design.document.insert(document, schema, "n1", "Folder")
		local part
		document, part = Design.document.insert(document, schema, folder, "MeshPart")
		document = Design.document.change(document, schema, part, "canCollide", { literal = false })
		local source = Design.emit(document, schema)
		expect(Design.emit(Design.parse(source, schema), schema)):toBe(source)
		expect(string.find(source, "Design.MeshPart", 1, true) ~= nil):toBe(true)
	end)
end)

describe("design editor selection sets", function()
	local function click(w: typeof(Support.world()), editor: DesignEditor.Editor, id: string)
		local stage = assert(editor.canvas.current().stage)
		local instance = stage.nodes[id]
		local at, extent = w.point(instance, "AbsolutePosition"), w.point(instance, "AbsoluteSize")
		local input = w.pointer("MouseButton1", at.X + extent.X / 2, at.Y + extent.Y / 2)
		w.fire(stage.overlay, "InputBegan", input)
		w.fire(w.input, "InputEnded", input)
		w.settle()
	end

	it("toggles stage selections, draws their union and individual outlines, and clears with Escape", function()
		local w = Support.world()
		local editor = w.mount()
		local stage = assert(editor.canvas.current().stage)
		w.settle()
		stage.zoomTo(1)
		w.settle()
		click(w, editor, w.first)
		w.down[w.values.Enum.KeyCode.LeftShift] = true
		click(w, editor, w.second)
		w.down[w.values.Enum.KeyCode.LeftShift] = nil
		expect(editor.session.selection:peek()):toEqual { w.first, w.second }
		expect(w.read(w.find(stage.overlay, `DesignSelected_{w.first}`), "Visible")):toBe(true)
		expect(w.read(w.find(stage.overlay, `DesignSelected_{w.second}`), "Visible")):toBe(true)
		local union = w.find(stage.overlay, "DesignSelected")
		local firstAt = w.point(stage.nodes[w.first], "AbsolutePosition")
		local secondAt = w.point(stage.nodes[w.second], "AbsolutePosition")
		local secondSize = w.point(stage.nodes[w.second], "AbsoluteSize")
		local at, extent = w.point(union, "AbsolutePosition"), w.point(union, "AbsoluteSize")
		expect(math.abs(at.X - firstAt.X) < 1):toBe(true)
		expect(math.abs(at.Y - firstAt.Y) < 1):toBe(true)
		expect(math.abs(extent.Y - (secondAt.Y + secondSize.Y - firstAt.Y)) < 1):toBe(true)
		w.down[w.values.Enum.KeyCode.LeftControl] = true
		click(w, editor, w.first)
		w.down[w.values.Enum.KeyCode.LeftControl] = nil
		expect(editor.session.selection:peek()):toEqual { w.second }
		local context = w.find(editor.root, "ComposeDesignShortcuts")
		w.fire(w.find(context, "Parent"), "Pressed")
		w.settle()
		expect(editor.session.selection:peek()):toEqual {}
		expect(w.read(union, "Visible")):toBe(false)
		editor.dispose()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("ranges siblings in layers and applies mixed shared inspector fields to every selected kind", function()
		local w = Support.world()
		local editor = w.mount()
		local layers = w.find(editor.root, "DesignLayers")
		w.fire(w.find(layers, w.first), "Activated")
		w.down[w.values.Enum.KeyCode.LeftShift] = true
		w.fire(w.find(layers, w.second), "Activated")
		w.down[w.values.Enum.KeyCode.LeftShift] = nil
		w.settle()
		expect(editor.session.selection:peek()):toEqual { w.first, w.second }
		local inspector = w.find(editor.root, "DesignInspector")
		local textRow = w.find(inspector, "text")
		expect(w.read(w.find(textRow, "Label"), "Text")):toBe "Text (Mixed)"
		local box = assert(textRow:FindFirstChildWhichIsA("TextBox", true))
		expect(w.read(box, "PlaceholderText")):toBe "Mixed"
		expect(Support.instance(inspector):FindFirstChild("onActivate", true)):toBe(nil)
		local before = editor.session.document:peek()
		Support.instance(box).Text = "Shared"
		w.fire(box, "FocusLost", true)
		w.settle()
		for _, node in editor.session.document:peek().root.children do
			expect(node.props.text.literal):toBe "Shared"
		end
		expect(editor.session.undo()):toBe(true)
		expect(editor.session.document:peek()):toBe(before)
		expect(editor.session.redo()):toBe(true)
		w.down[w.values.Enum.KeyCode.LeftMeta] = true
		w.fire(w.find(layers, w.first), "Activated")
		w.down[w.values.Enum.KeyCode.LeftMeta] = nil
		expect(editor.session.selection:peek()):toEqual { w.second }
		editor.dispose()
		w.close()
	end)

	it("marquees intersecting bounds from empty canvas at multiple zoom levels", function()
		local w = Support.world()
		local editor = w.mount()
		local stage = assert(editor.canvas.current().stage)
		w.settle()
		for _, zoom in { 0.5, 1, 2 } do
			stage.zoomTo(zoom)
			w.settle()
			local at = w.point(stage.nodes[w.first], "AbsolutePosition")
			local last = w.point(stage.nodes[w.second], "AbsolutePosition")
			local extent = w.point(stage.nodes[w.second], "AbsoluteSize")
			local x = at.X - 10
			local y = at.Y - 10
			w.fire(stage.overlay, "InputBegan", w.pointer("MouseButton1", x, y))
			w.fire(w.input, "InputChanged", w.pointer("MouseMovement", last.X + extent.X / 2, last.Y + 1))
			expect(w.read(w.find(stage.overlay, "DesignMarquee"), "Visible")):toBe(true)
			w.fire(w.input, "InputEnded", w.pointer("MouseButton1", last.X + extent.X / 2, last.Y + 1))
			w.settle()
			expect(editor.session.selection:peek()):toEqual { w.first, w.second }
			expect(w.read(w.find(stage.overlay, "DesignMarquee"), "Visible")):toBe(false)
		end
		expect(editor.session.canUndo:peek()):toBe(false)
		editor.dispose()
		w.close()
	end)

	it("drags the selected siblings together in one undoable stage move", function()
		local w = Support.world()
		local editor = w.mount()
		local session = editor.session
		session.select "n1"
		expect(session.insert "Text"):toBe(true)
		local third = session.selected:peek()
		session.changeMany { width = { literal = 120 }, height = { literal = 36 } }
		session.selectMany { w.first, w.second }
		w.settle()
		local stage = assert(editor.canvas.current().stage)
		local at, extent =
			w.point(stage.nodes[w.first], "AbsolutePosition"), w.point(stage.nodes[w.first], "AbsoluteSize")
		local last, size = w.point(stage.nodes[third], "AbsolutePosition"), w.point(stage.nodes[third], "AbsoluteSize")
		local before = session.document:peek()
		w.fire(stage.overlay, "InputBegan", w.pointer("MouseButton1", at.X + extent.X / 2, at.Y + extent.Y / 2))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", last.X + 20, last.Y + size.Y + 5))
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", last.X + 20, last.Y + size.Y + 5))
		w.settle()
		expect(session.document:peek().root.children[1].id):toBe(third)
		expect(session.document:peek().root.children[2].id):toBe(w.first)
		expect(session.document:peek().root.children[3].id):toBe(w.second)
		expect(session.undo()):toBe(true)
		expect(session.document:peek()):toBe(before)
		expect(session.redo()):toBe(true)
		editor.dispose()
		w.close()
	end)

	it("wraps and unwraps from shortcuts and the layer context menu with history and source parity", function()
		local w = Support.world()
		local editor = w.mount()
		local session = editor.session
		session.selectMany { w.first, w.second }
		local before = session.document:peek()
		local shortcuts = w.find(editor.root, "ComposeDesignShortcuts")
		w.fire(w.find(shortcuts, "Wrap"), "Pressed")
		w.settle()
		local wrapped = session.document:peek()
		local container = wrapped.root.children[1]
		expect(container.kind):toBe "Stack"
		expect(#container.children):toBe(2)
		expect(session.undo()):toBe(true)
		expect(session.document:peek()):toBe(before)
		expect(session.redo()):toBe(true)
		w.settle()
		local layers = w.find(editor.root, "DesignLayers")
		local row = w.find(layers, container.id)
		local point = w.point(row, "AbsolutePosition")
		w.fire(row, "InputBegan", w.pointer("MouseButton2", point.X + 30, point.Y + 12))
		local menu = w.find(editor.root, "LayerContextMenu")
		expect(w.read(menu, "Visible")):toBe(true)
		w.fire(w.find(menu, "Unwrap"), "Activated")
		w.settle()
		expect(session.selection:peek()):toEqual { w.first, w.second }
		expect(#session.document:peek().root.children):toBe(2)
		expect(session.undo()):toBe(true)
		expect(session.document:peek()):toBe(wrapped)
		expect(session.redo()):toBe(true)
		w.settle()
		w.fire(w.find(layers, w.first), "InputBegan", w.pointer("MouseButton2", point.X + 30, point.Y + 12))
		w.fire(w.find(menu, "Wrap"), "Activated")
		w.settle()
		w.down[w.values.Enum.KeyCode.LeftShift] = true
		w.fire(w.find(shortcuts, "Wrap"), "Pressed")
		w.fire(w.find(shortcuts, "Unwrap"), "Pressed")
		w.down[w.values.Enum.KeyCode.LeftShift] = nil
		w.settle()
		expect(#session.document:peek().root.children):toBe(2)
		local code = Design.emit(session.document:peek(), w.library)
		expect(Design.emit(Design.parse(code, w.library), w.library)):toBe(code)
		editor.dispose()
		w.close()
	end)

	it("hides and locks layer rows while preserving layer selection, history and header round trips", function()
		local w = Support.world()
		local editor = w.mount()
		w.settle()
		local session, stage = editor.session, assert(editor.canvas.current().stage)
		local layers = w.find(editor.root, "DesignLayers")
		w.fire(w.find(w.find(layers, w.first), "Hide"), "Activated")
		w.settle()
		expect(stage.nodes[w.first]):toBe(nil)
		expect(w.find(layers, w.first)):toBeOk()
		expect(session.undo()):toBe(true)
		w.settle()
		expect(stage.nodes[w.first]):toBeOk()
		expect(session.redo()):toBe(true)
		w.settle()
		w.fire(w.find(w.find(layers, w.second), "Lock"), "Activated")
		w.settle()
		click(w, editor, w.second)
		expect(session.selection:peek()):toEqual {}
		w.fire(w.find(layers, w.second), "Activated")
		w.settle()
		expect(session.selection:peek()):toEqual { w.second }
		local before = session.document:peek()
		local at, extent =
			w.point(stage.nodes[w.second], "AbsolutePosition"), w.point(stage.nodes[w.second], "AbsoluteSize")
		w.fire(stage.overlay, "InputBegan", w.pointer("MouseButton1", at.X + extent.X / 2, at.Y + extent.Y / 2))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", at.X + 40, at.Y + 80))
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", at.X + 40, at.Y + 80))
		expect(session.document:peek()):toBe(before)
		local code = Design.emit(before, w.library)
		local parsed = Design.parse(code, w.library)
		expect(parsed.root.children[1].hidden):toBe(true)
		expect(parsed.root.children[2].locked):toBe(true)
		expect(Design.emit(parsed, w.library)):toBe(code)
		expect(session.undo()):toBe(true)
		w.settle()
		click(w, editor, w.second)
		expect(session.selection:peek()):toEqual { w.second }
		editor.dispose()
		w.close()
	end)

	it("runs clipboard, reorder and delete shortcuts on the whole selection", function()
		local w = Support.world()
		local editor = w.mount()
		local session = editor.session
		local shortcuts = w.find(editor.root, "ComposeDesignShortcuts")
		session.selectMany { w.first, w.second }
		local before = session.document:peek()
		w.fire(w.find(shortcuts, "Duplicate"), "Pressed")
		expect(#session.document:peek().root.children):toBe(4)
		expect(#session.selection:peek()):toBe(2)
		w.fire(w.find(shortcuts, "MoveUp"), "Pressed")
		expect(session.document:peek().root.children[1].id):toBe(session.selection:peek()[1])
		expect(session.undo()):toBe(true)
		w.fire(w.find(shortcuts, "Copy"), "Pressed")
		w.fire(w.find(shortcuts, "Paste"), "Pressed")
		expect(#session.document:peek().root.children):toBe(6)
		w.fire(w.find(shortcuts, "Delete"), "Pressed")
		expect(#session.document:peek().root.children):toBe(4)
		expect(session.undo()):toBe(true)
		expect(#session.selection:peek()):toBe(2)
		expect(session.undo()):toBe(true)
		expect(session.undo()):toBe(true)
		expect(session.document:peek()):toBe(before)
		editor.dispose()
		w.close()
	end)

	it("keeps scene selection offsets through a group gizmo move and respects hidden and locked subtrees", function()
		local w = Support.world "3d"
		local editor = w.mount()
		local session, scene = editor.session, assert(editor.canvas.current().scene)
		session.select "n1"
		expect(session.insert "Part"):toBe(true)
		local second = session.selected:peek()
		expect(session.change("position", { literal = { 10, 3, 0 } })):toBe(true)
		session.selectMany { w.first, second }
		w.settle()
		scene.fit()
		w.settle()
		expect(w.find(scene.world, `Selected_{w.first}`)):toBeOk()
		expect(w.find(scene.world, `Selected_{second}`)):toBeOk()
		local tip = w.find(scene.world, "TipX")
		local position = w.read(w.read(tip, "CFrame"), "Position")
		local projected = w.environment.invoke(w.read(scene.camera, "CFrame"), "PointToObjectSpace", position)
		local at, size = w.point(scene.viewport, "AbsolutePosition"), w.point(scene.viewport, "AbsoluteSize")
		local tanY = math.tan(math.rad(w.number(scene.camera, "FieldOfView")) / 2)
		local tanX = tanY * size.X / size.Y
		local z = -w.number(projected, "Z")
		local x = at.X + (w.number(projected, "X") / z / tanX + 1) * size.X / 2
		local y = at.Y + (1 - w.number(projected, "Y") / z / tanY) * size.Y / 2
		local before = session.document:peek()
		w.fire(scene.viewport, "InputBegan", w.pointer("MouseButton1", x, y))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", x + 60, y))
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", x + 60, y))
		w.settle()
		local function positionX(id: string): number
			return w.number(w.read(w.read(scene.nodes[id], "CFrame"), "Position"), "X")
		end
		expect(positionX(w.first) > 0):toBe(true)
		expect(positionX(second) - positionX(w.first)):toBeCloseTo(10, 0.001)
		expect(session.undo()):toBe(true)
		expect(session.document:peek()):toBe(before)
		expect(session.redo()):toBe(true)
		expect(session.hide(w.first, true)):toBe(true)
		expect(session.lock("n1", true)):toBe(true)
		w.settle()
		expect(scene.nodes[w.first]):toBe(nil)
		expect(scene.pick { X = at.X + size.X / 2, Y = at.Y + size.Y / 2 }):toBe(nil)
		session.select(second)
		w.settle()
		expect(w.read(w.find(scene.world, "TipX"), "CanQuery")):toBe(false)
		local code = Design.emit(session.document:peek(), w.library)
		expect(Design.emit(Design.parse(code, w.library), w.library)):toBe(code)
		editor.dispose()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)

	it("toggles scene picks and marquees projected bounds without adding an edit", function()
		local w = Support.world "3d"
		local editor = w.mount()
		local scene = assert(editor.canvas.current().scene)
		w.settle()
		scene.fit()
		local at, size = w.point(scene.viewport, "AbsolutePosition"), w.point(scene.viewport, "AbsoluteSize")
		editor.session.selectMany {}
		w.down[w.values.Enum.KeyCode.LeftShift] = true
		w.fire(scene.viewport, "InputBegan", w.pointer("MouseButton1", at.X + size.X / 2, at.Y + size.Y / 2))
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", at.X + size.X / 2, at.Y + size.Y / 2))
		expect(editor.session.selection:peek()):toEqual { w.first }
		w.fire(scene.viewport, "InputBegan", w.pointer("MouseButton1", at.X + size.X / 2, at.Y + size.Y / 2))
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", at.X + size.X / 2, at.Y + size.Y / 2))
		expect(editor.session.selection:peek()):toEqual {}
		w.down[w.values.Enum.KeyCode.LeftShift] = nil
		w.fire(scene.viewport, "InputBegan", w.pointer("MouseButton1", at.X + 5, at.Y + 5))
		w.fire(w.input, "InputChanged", w.pointer("MouseMovement", at.X + size.X - 5, at.Y + size.Y - 5))
		expect(w.read(w.find(scene.viewport, "DesignMarquee"), "Visible")):toBe(true)
		w.fire(w.input, "InputEnded", w.pointer("MouseButton1", at.X + size.X - 5, at.Y + size.Y - 5))
		expect(editor.session.selection:peek()):toEqual { w.first }
		expect(editor.session.canUndo:peek()):toBe(false)
		editor.dispose()
		expect(w.env.liveObjects()):toBe(w.objectsBefore)
		expect(w.env.liveConnections()):toBe(w.connectionsBefore)
		w.close()
	end)
end)

return nil
