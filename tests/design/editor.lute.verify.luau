--!strict

local Design = require "../../src/design"
local Support = require "./editor-support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("host-neutral design editor", function()
	it("unwinds failed Host construction after the stage and layers have mounted", function()
		local w = Support.world()
		local write = w.emulator.render.setProperty
		w.emulator.render.setProperty = function(node: unknown, key: string, value: unknown)
			if key == "Name" and value == "NodeName" then
				error "inspector construction failed"
			end
			write(node, key, value)
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
		local stage = assert(editor.stage)
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
		expect(w.number(assert(editor.stage).nodes[w.second], "LayoutOrder")):toBe(1)
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
				{ name = "Phone", size = { X = 390, Y = 844 } },
				{ name = "Tablet", size = { X = 820, Y = 1180 } },
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
		expect(w.find(editor.root, "ArtboardSize").Text):toBe "820 × 1180"
		w.fire(w.find(editor.root, "Theme"), "Activated")
		w.settle()
		expect(chosen[1]):toBe "Dark"
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
		expect(w.read(assert(editor.stage).nodes[w.first], "Text")):toBe "Edited headlessly"
		editor.dispose()
		w.close()
	end)

	it("previews several resize updates and commits width and height as one undo step", function()
		local w = Support.world()
		local editor = w.mount()
		editor.session.select(w.first)
		local stage = assert(editor.stage)
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
		local w = Support.world()
		local editor = w.mount()
		w.settle()
		local stage = assert(editor.stage)
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
		expect(stage.zoom:peek()):toBe(0.1)
		stage.fit()
		expect(stage.zoom:peek()):toBeCloseTo(
			math.clamp(math.min((size.X - 96) / 480, (size.Y - 120) / 320), 0.1, 1),
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
		local scene = assert(editor.scene)
		expect(editor.stage):toBeNil()
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
		local scene = assert(editor.scene)
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
		local frame = w.read(assert(editor.scene).nodes[w.first], "CFrame")
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
		local part = Support.instance(assert(editor.scene).nodes[w.first])
		expect(part.MaterialVariant):toBe "Moss"
		expect(assert(part:FindFirstChildWhichIsA "SpecialMesh").MeshId):toBe "test-mesh"
		expect(assert(part:FindFirstChildWhichIsA "PointLight").Brightness):toBe(2)
		expect(assert(part:FindFirstChildWhichIsA "Decal").Texture):toBe "test-image"
		editor.dispose()
		w.close()
	end)
end)

return nil
