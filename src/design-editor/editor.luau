--!strict

local UI = require "./ui"

local Compose = require "../core"
local Design = require "../design"
local Canvas = require "./canvas"
local Devices = require "./devices"
local Layers = require "./layers"
local LibraryPanel = require "./library-panel"
local Inspector = require "./inspector"
local Prompt = require "./prompt"
local ThemePanel = require "./theme-panel"
local Stage3D = require "./stage3d"

export type Command =
	{ action: "Read" }
	| { action: "Fit" }
	| { action: "Undo" }
	| { action: "Redo" }
	| { action: "Duplicate" }
	| { action: "Delete" }
	| { action: "Copy" }
	| { action: "Paste" }
	| { action: "Wrap" }
	| { action: "Unwrap" }
	| { action: "Camera", preset: Stage3D.Preset }
	| { action: "Orbit", yaw: number, pitch: number }
	| { action: "Zoom", scale: number }
	| { action: "Select", ids: { string } }
	| { action: "Change", field: string, value: Design.Value }
	| { action: "Insert", kind: string }
	| { action: "Device", id: string }
	| { action: "AllDevices", enabled: boolean }
	| { action: "Preview", name: string, choice: string }

export type Result = {
	ok: boolean,
	action: string,
	design: string,
	commit: string?,
	path: string?,
	files: { string },
	selection: { string },
	device: string,
	previews: { [string]: string },
	camera: Stage3D.CameraState?,
	problem: string?,
	next: string?,
}

export type Editor = {
	root: Compose.Node,
	session: Design.Session,
	canvas: Canvas.Canvas,
	execute: (Command) -> Result,
	dispose: () -> (),
}

export type Device = Devices.Profile

export type Preview = { name: string, choices: { string }, initial: string?, select: (choice: string) -> () }

export type Options = {
	identity: { commit: string, path: string }?,
	scene: Stage3D.Target?,
	stageSize: UI.Point?,
	devices: { Device }?,
	device: string?,
	frame: ((Device, Compose.ReadOnlyValue<number>) -> Canvas.Context)?,
	bindings: { [string]: Design.Resolved }?,
	previews: { Preview }?,
	token: ((name: string) -> Design.Literal)?,
	resolveToken: ((name: string) -> Design.Resolved)?,
	tokens: { string }?,
	slots: { [string]: () -> unknown }?,
	onExport: ((source: string) -> ())?,
	link: Design.LinkStore?,
	prompt: Prompt.Options?,
	theme: ThemePanel.Store?,
	runtime: Compose.Runtime,
}

return function(ui: UI.UI)
	local Theme = require "./theme"(ui)
	local color = Theme.color
	local size = Theme.size

	local function chip(name: string, text: string, primary: boolean): Compose.Node
		local button = Theme.button(name, text, if primary then color.white else color.text)
		ui.set(button, "AutomaticSize", ui.values.enum("AutomaticSize", "X"))
		ui.set(button, "Size", ui.values.udim2(0, 0, 0, 30))
		ui.set(button, "BackgroundTransparency", if primary then 0 else 1)
		ui.set(button, "FontFace", if primary then Theme.font.bold else Theme.font.medium)
		Theme.corner(button, 6)
		Theme.pad(button, if primary then 14 else 10)
		return button
	end

	local function divider(order: number): Compose.Node
		local line = Theme.frame("Divider", color.raised)
		ui.set(line, "Size", ui.values.udim2(0, 1, 0, 20))
		ui.set(line, "LayoutOrder", order)
		return line
	end

	local function group(name: string, order: number, alignment: unknown): Compose.Node
		local frame = Theme.frame(name)
		ui.set(frame, "AutomaticSize", ui.values.enum("AutomaticSize", "X"))
		ui.set(frame, "Size", ui.values.udim2(0, 0, 0, size.toolbar / 2))
		ui.set(frame, "LayoutOrder", order)
		local layout = Theme.list(
			frame,
			ui.values.enum("FillDirection", "Horizontal"),
			2,
			ui.values.enum("VerticalAlignment", "Center")
		)
		ui.set(layout, "HorizontalAlignment", alignment)
		return frame
	end

	return function(library: Design.Library, initial: Design.Document, parent: Compose.Node, options: Options): Editor
		local remembered = ui.call(parent, "GetAttribute", "ComposeDesignTextSize")
		local textSize = if type(remembered) == "number" and remembered == remembered
			then math.clamp(remembered, 15, 19)
			else 15
		ui.setTextSize(textSize)
		local session = Design.session(library, initial)
		local root = Theme.frame("ComposeDesign", color.canvas)
		if options.scene and library.space == "3d" then
			ui.set(root, "BackgroundTransparency", 1)
		end
		ui.set(root, "Size", ui.values.udim2(1, 0, 1, 0))
		local toolbar = Theme.frame("Toolbar", color.panel)
		Theme.place(toolbar, root, ui.values.udim2(1, 0, 0, size.toolbar))
		local toolRule = Theme.frame("Rule", color.divider)
		ui.set(toolRule, "AnchorPoint", ui.values.vector2(0, 1))
		Theme.place(toolRule, toolbar, ui.values.udim2(1, 0, 0, 1), ui.values.udim2(0, 0, 1, 0))
		local leftTools = group("Insert", 1, ui.values.enum("HorizontalAlignment", "Left"))
		ui.set(leftTools, "Position", ui.values.udim2(0, size.gutter, 0, size.toolbar / 2))
		ui.set(leftTools, "Parent", toolbar)
		local brand = Theme.label("◆", color.accent, 18, Theme.font.bold)
		ui.set(brand, "Name", "Brand")
		ui.set(brand, "Size", ui.values.udim2(0, 24, 0, 30))
		ui.set(brand, "TextXAlignment", ui.values.enum("TextXAlignment", "Center"))
		ui.set(brand, "LayoutOrder", 0)
		ui.set(brand, "Parent", leftTools)
		local rightTools = group("Actions", 3, ui.values.enum("HorizontalAlignment", "Right"))
		ui.set(rightTools, "AnchorPoint", ui.values.vector2(1, 0))
		ui.set(rightTools, "Position", ui.values.udim2(1, -size.gutter, 0, 0))
		ui.set(rightTools, "Parent", toolbar)
		local function side(name: string, title: string, anchor: number): (Compose.Node, Compose.Node)
			local frame = Theme.frame(name, color.panel)
			ui.set(frame, "AnchorPoint", ui.values.vector2(anchor, 0))
			ui.set(frame, "Position", ui.values.udim2(anchor, 0, 0, size.toolbar))
			Theme.place(frame, root, ui.values.udim2(0, size.side, 1, -size.toolbar - size.status))
			local rule = Theme.frame("Rule", color.divider)
			ui.set(rule, "AnchorPoint", ui.values.vector2(1 - anchor, 0))
			Theme.place(rule, frame, ui.values.udim2(0, 1, 1, 0), ui.values.udim2(1 - anchor, 0, 0, 0))
			local caption = Theme.label(title, color.text, size.small, Theme.font.bold)
			ui.set(caption, "Name", "Caption")
			ui.set(caption, "Position", ui.values.udim2(0, size.gutter + 4, 0, 0))
			Theme.place(caption, frame, ui.values.udim2(1, -2 * size.gutter, 0, size.header))
			local body = Theme.frame "Body"
			Theme.place(body, frame, ui.values.udim2(1, -1, 1, -size.header), ui.values.udim2(0, 0, 0, size.header))
			return frame, body
		end
		local libraryFrame, libraryBody = side("LibraryPanel", "Library", 0)
		ui.set(libraryFrame, "Size", ui.values.udim2(0, size.side, 0.45, -size.toolbar))
		local layersFrame, left = side("LayersPanel", "Layers", 0)
		ui.set(layersFrame, "Position", ui.values.udim2(0, 0, 0.45, 0))
		ui.set(layersFrame, "Size", ui.values.udim2(0, size.side, 0.55, -size.status))
		local _, right = side("InspectorPanel", "Design", 1)
		local center = Theme.frame("StagePanel", color.canvas)
		if options.scene and library.space == "3d" then
			ui.set(center, "BackgroundTransparency", 1)
		end
		ui.set(center, "Position", ui.values.udim2(0, size.side, 0, size.toolbar))
		ui.set(center, "Size", ui.values.udim2(1, -2 * size.side, 1, -size.toolbar - size.status))
		ui.set(center, "ClipsDescendants", true)
		ui.set(center, "Parent", root)
		local status = Theme.frame("StatusBar", color.panel)
		ui.set(status, "AnchorPoint", ui.values.vector2(0, 1))
		Theme.place(status, root, ui.values.udim2(1, 0, 0, size.status), ui.values.udim2(0, 0, 1, 0))
		local statusRule = Theme.frame("Rule", color.divider)
		Theme.place(statusRule, status, ui.values.udim2(1, 0, 0, 1))
		local problem = Theme.label("", color.tertiary, size.small)
		ui.set(problem, "Name", "Problem")
		ui.set(problem, "Position", ui.values.udim2(0, size.gutter, 0, 0))
		ui.set(problem, "Size", ui.values.udim2(0.5, -size.gutter - 40, 1, 0))
		ui.set(problem, "TextTruncate", ui.values.enum("TextTruncate", "AtEnd"))
		ui.set(problem, "Parent", status)
		local zoomLabel = Theme.button("Zoom", "", color.secondary, size.small)
		ui.set(zoomLabel, "AnchorPoint", ui.values.vector2(0.5, 0))
		ui.set(zoomLabel, "Position", ui.values.udim2(0.5, 0, 0, 0))
		ui.set(zoomLabel, "Size", ui.values.udim2(0, 64, 0, size.status))
		ui.set(zoomLabel, "FontFace", Theme.font.bold)
		ui.set(zoomLabel, "Parent", status)
		local heading = Theme.label("", color.text, size.small, Theme.font.bold)
		ui.set(heading, "Name", "DocumentTitle")
		ui.set(heading, "AnchorPoint", ui.values.vector2(1, 0))
		ui.set(heading, "Position", ui.values.udim2(1, -size.gutter, 0, 0))
		ui.set(heading, "Size", ui.values.udim2(0.25, 0, 1, 0))
		ui.set(heading, "TextXAlignment", ui.values.enum("TextXAlignment", "Right"))
		ui.set(heading, "RichText", true)
		ui.set(heading, "Parent", status)
		local syncButton = Theme.button("Sync", "", nil, size.small)
		ui.set(syncButton, "AnchorPoint", ui.values.vector2(0, 0))
		ui.set(syncButton, "Position", ui.values.udim2(0.5, 40, 0, 0))
		ui.set(syncButton, "Size", ui.values.udim2(0, 160, 0, size.status))
		ui.set(syncButton, "FontFace", Theme.font.bold)
		ui.set(syncButton, "Parent", status)
		ui.set(root, "Parent", parent)
		local devices = if library.space == "3d"
			then { Devices.custom("Scene", options.stageSize or { X = 1280, Y = 720 }) }
			else options.devices or if options.stageSize
				then { Devices.custom("Canvas", options.stageSize) }
				else Devices.all
		local canvasOptions: Canvas.Options = {
			scene = options.scene,
			devices = devices,
			device = options.device,
			frame = options.frame,
			bindings = options.bindings,
			token = options.token,
			resolveToken = options.resolveToken,
			slots = options.slots,
		}
		local view = Canvas(ui, session, center, canvasOptions)
		local previewCommands: { [string]: (string) -> () } = {}
		local previewValues: { [string]: string } = {}
		local ordinary: { [string]: () -> ...unknown } = {
			Read = function() end,
			Fit = view.fit,
			Undo = session.undo,
			Redo = session.redo,
			Duplicate = session.duplicate,
			Delete = session.remove,
			Copy = session.copy,
			Paste = session.paste,
			Wrap = session.wrap,
			Unwrap = session.unwrap,
		}
		local function execute(request: Command): Result
			local ok, failure = pcall(function()
				local run = ordinary[request.action]
				if run then
					run()
				elseif request.action == "Camera" then
					assert(view.current().scene, "Open a 3D Design before Camera").setCamera(request.preset)
				elseif request.action == "Orbit" then
					assert(view.current().scene, "Open a 3D Design before Orbit").orbit(request.yaw, request.pitch)
				elseif request.action == "Zoom" then
					view.zoomTo(request.scale)
				elseif request.action == "Select" then
					session.selectMany(request.ids)
				elseif request.action == "Change" then
					session.change(request.field, request.value)
				elseif request.action == "Insert" then
					session.insert(request.kind)
				elseif request.action == "Device" then
					view.select(request.id)
				elseif request.action == "AllDevices" then
					view.showAll(request.enabled)
				elseif request.action == "Preview" then
					assert(previewCommands[request.name], "Unknown Preview; Read lists available previews")(
						request.choice
					)
				else
					error "Unknown editor action; use Read"
				end
			end)
			local scene = view.current().scene
			local identity = options.identity
			return {
				ok = ok,
				action = request.action,
				design = session.document:peek().name,
				commit = if identity then identity.commit else nil,
				path = if identity then identity.path else nil,
				files = {},
				selection = table.clone(session.selection:peek()),
				device = view.device:peek().id,
				previews = table.clone(previewValues),
				camera = if scene then scene.readCamera() else nil,
				problem = if ok then session.problem:peek() else tostring(failure),
				next = if ok then nil else 'execute({ action = "Read" })',
			}
		end
		local layers = Layers(ui)(session, left)
		local prompt = if options.prompt
			then Prompt.create(
				ui,
				session,
				view,
				center,
				options.prompt,
				function(source: string, device: Device, parent: Compose.Node): () -> ()
					return Compose.withOwner(ui.owner, function(): () -> ()
						local draft = Design.session(library, Design.parse(source, library))
						draft.selectMany {}
						local frame = table.clone(canvasOptions)
						frame.devices, frame.device, frame.readOnly = { device }, device.id, true
						return Canvas(ui, draft, parent, frame).dispose
					end)
				end
			)
			else nil
		local libraryPanel = LibraryPanel(ui)(session, libraryBody)
		local theme = if options.theme then ThemePanel.create(ui, libraryBody, options.theme) else nil
		local inspector = Inspector(ui)(session, right, {
			tokens = options.tokens,
			play = function(sequence: string)
				local flat = view.current().stage
				if flat then
					flat.play(sequence)
				end
			end,
			measure = function(id: string, key: string): number?
				local flat = view.current().stage
				local instance: Compose.Node? = if flat then flat.nodes[id] else nil
				if instance == nil then
					return nil
				end
				local scale = view.zoom:peek()
				if key == "width" then
					return ui.xy(instance, "AbsoluteSize").X / scale
				elseif key == "height" then
					return ui.xy(instance, "AbsoluteSize").Y / scale
				end
				return nil
			end,
		})
		local connections: { UI.Connection } = {}
		local function action(
			name: string,
			text: string,
			order: number,
			container: Compose.Node,
			primary: boolean,
			run: () -> ...unknown
		): Compose.Node
			local button = chip(name, text, primary)
			ui.set(button, "LayoutOrder", order)
			local rest = if primary then color.accent else color.panel
			local over = if primary then ui.rgb(56, 172, 255) else color.hover
			ui.set(button, "BackgroundColor3", rest)
			for _, connection in Theme.hover(button, rest, over, if primary then 0 else 1) do
				table.insert(connections, connection)
			end
			table.insert(
				connections,
				ui.connect(button, "Activated", function()
					run()
				end)
			)
			ui.set(button, "Parent", container)
			return button
		end
		local previewOrder = 10
		local function cycling(name: string, choices: { string }, initial: string?, select: (choice: string) -> ())
			if #choices == 0 then
				return
			end
			previewValues[name] = initial or choices[1]
			local button: Compose.Node? = nil
			previewCommands[name] = function(choice: string)
				assert(table.find(choices, choice), "Unknown choice for " .. name .. "; Read returns current previews")
				previewValues[name] = choice
				ui.set(assert(button), "Text", choice)
				select(choice)
			end
			button = action(name, previewValues[name], previewOrder, leftTools, false, function()
				local at = table.find(choices, previewValues[name]) or 1
				execute { action = "Preview", name = name, choice = choices[at % #choices + 1] }
			end)
			previewOrder += 1
		end
		local deviceButton: Compose.Node? = nil
		local cameraButton: Compose.Node? = nil
		local scene = view.current().scene
		if scene then
			local presets: { Stage3D.Preset } = { "fit", "eye-height", "approach-20", "close-up", "top-down" }
			cameraButton = action("Camera", "Camera", previewOrder, leftTools, false, function()
				local at = 1
				for index, preset in presets do
					if preset == scene.preset:peek() then
						at = index
						break
					end
				end
				execute { action = "Camera", preset = presets[at % #presets + 1] }
			end)
			previewOrder += 1
		end
		if #devices > 1 then
			ui.set(divider(previewOrder), "Parent", leftTools)
			previewOrder += 1
			deviceButton = action("Device", view.current().device.name, previewOrder, leftTools, false, function()
				local at = table.find(devices, view.device:peek()) or 1
				view.select(devices[at % #devices + 1].id)
			end)
			previewOrder += 1
			local gridButton: Compose.Node? = nil
			gridButton = action("AllDevices", "All devices", previewOrder, leftTools, false, function()
				view.showAll(not view.all:peek())
				ui.set(assert(gridButton), "Text", if view.all:peek() then "Single device" else "All devices")
			end)
			previewOrder += 1
		end
		local previews = options.previews
		if previews then
			for _, preview in previews do
				cycling(preview.name, preview.choices, preview.initial, preview.select)
			end
		end
		local undo = action("Undo", "Undo", 1, rightTools, false, session.undo)
		local redo = action("Redo", "Redo", 2, rightTools, false, session.redo)
		ui.set(divider(3), "Parent", rightTools)
		local _ = action("Duplicate", "Duplicate", 4, rightTools, false, session.duplicate)
		local _ = action("Delete", "Delete", 5, rightTools, false, session.remove)
		local textControl: Compose.Node? = nil
		if theme then
			local opened = false
			local _ = action("Theme", "Theme", 9, rightTools, false, function()
				opened = not opened
				ui.set(theme.root, "Visible", opened)
				ui.set(libraryPanel.root, "Visible", not opened)
			end)
		end
		textControl = action("TextSize", `Text {textSize}`, 8, rightTools, false, function()
			local chosen = if textSize < 17 then 17 elseif textSize < 19 then 19 else 15
			local changed =
				assert(options.runtime.host.render.setAttribute, "Design text size requires host attributes")
			local ok, failure = changed(parent, "ComposeDesignTextSize", chosen)
			assert(ok, failure)
			textSize = chosen
			ui.setTextSize(chosen)
			ui.set(assert(textControl), "Text", `Text {chosen}`)
		end)
		local exportHandler = options.onExport
		if exportHandler then
			local onExport = exportHandler
			local spacer = Theme.frame "Spacer"
			ui.set(spacer, "Size", ui.values.udim2(0, 6, 0, 1))
			ui.set(spacer, "LayoutOrder", 6)
			ui.set(spacer, "Parent", rightTools)
			local _ = action("Export", "Export", 7, rightTools, true, function()
				onExport(Design.emit(session.document:peek(), library))
			end)
		end
		local context = ui.new "InputContext"
		ui.set(context, "Name", "ComposeDesignShortcuts")
		ui.set(context, "Sink", true)
		local function bind(name: string, run: () -> ...unknown, keys: { { unknown } })
			local inputAction = ui.new "InputAction"
			ui.set(inputAction, "Name", name)
			for _, combo in keys do
				local binding = ui.new "InputBinding"
				ui.set(binding, "KeyCode", combo[1])
				if combo[2] then
					ui.set(binding, "PrimaryModifier", combo[2])
				end
				if combo[3] then
					ui.set(binding, "SecondaryModifier", combo[3])
				end
				ui.set(binding, "Parent", inputAction)
			end
			table.insert(
				connections,
				ui.connect(inputAction, "Pressed", function()
					local UserInputService = ui.service "UserInputService"
					local focused = ui.optionalNode(ui.call(UserInputService, "GetFocusedTextBox"))
					if not focused then
						run()
					end
				end)
			)
			ui.set(inputAction, "Parent", context)
		end
		bind(
			"Delete",
			session.remove,
			{ { ui.values.enum("KeyCode", "Delete") }, { ui.values.enum("KeyCode", "Backspace") } }
		)
		local function command(key: string, shifted: boolean?): { { unknown } }
			local chords: { { unknown } } = {}
			for _, modifier in { "LeftControl", "RightControl", "LeftMeta", "RightMeta", "LeftSuper", "RightSuper" } do
				local chord = { ui.values.enum("KeyCode", key), ui.values.enum("KeyCode", modifier) }
				if shifted then
					table.insert(chord, ui.values.enum("KeyCode", "LeftShift"))
					local rightChord = {
						ui.values.enum("KeyCode", key),
						ui.values.enum("KeyCode", modifier),
						ui.values.enum("KeyCode", "RightShift"),
					}
					table.insert(chords, rightChord)
				end
				table.insert(chords, chord)
			end
			return chords
		end
		bind("Duplicate", session.duplicate, command "D")
		bind("Undo", session.undo, command "Z")
		bind("Copy", session.copy, command "C")
		bind("Paste", session.paste, command "V")
		bind("Wrap", function()
			if not ui.keyDown { "LeftShift", "RightShift" } then
				session.wrap()
			end
		end, command "G")
		bind("Unwrap", session.unwrap, command("G", true))
		bind("MoveUp", function()
			session.shift(-1)
		end, { { ui.values.enum("KeyCode", "Up"), ui.values.enum("KeyCode", "LeftAlt") } })
		bind("MoveDown", function()
			session.shift(1)
		end, { { ui.values.enum("KeyCode", "Down"), ui.values.enum("KeyCode", "LeftAlt") } })
		local redoKeys = command("Z", true)
		table.insert(redoKeys, { ui.values.enum("KeyCode", "Y"), ui.values.enum("KeyCode", "LeftControl") })
		bind("Redo", session.redo, redoKeys)
		bind("Fit", view.fit, { { ui.values.enum("KeyCode", "One"), ui.values.enum("KeyCode", "LeftShift") } })
		bind("Actual", function()
			view.zoomTo(1)
		end, { { ui.values.enum("KeyCode", "Zero"), ui.values.enum("KeyCode", "LeftShift") } })
		bind("ZoomIn", function()
			view.zoomTo(view.zoom:peek() * 1.25)
		end, command "Equals")
		bind("ZoomOut", function()
			view.zoomTo(view.zoom:peek() / 1.25)
		end, command "Minus")
		bind("Parent", function()
			session.selectMany {}
		end, { { ui.values.enum("KeyCode", "Escape") } })
		bind("Child", function()
			session.selectRelative "child"
		end, { { ui.values.enum("KeyCode", "Return") } })
		bind("Next", function()
			session.selectRelative "next"
		end, { { ui.values.enum("KeyCode", "Tab") } })
		bind("Previous", function()
			session.selectRelative "previous"
		end, { { ui.values.enum("KeyCode", "Tab"), ui.values.enum("KeyCode", "LeftShift") } })
		ui.set(context, "Parent", root)
		table.insert(connections, ui.connect(zoomLabel, "Activated", view.fit))
		local scheduler = options.runtime.scheduler(ui.owner)
		scheduler.after(0, view.fit)
		local linkStore = options.link
		local link = if linkStore then Design.link(session, linkStore) else nil
		local unlink = if link then Compose.owner.own(ui.owner, link.dispose) else nil
		if link then
			local active = link
			table.insert(
				connections,
				ui.connect(syncButton, "Activated", function()
					if active.status:peek() ~= "synchronized" then
						active.import()
					end
				end)
			)
		end
		local owner = Compose.createRootOwner(function()
			if cameraButton and scene then
				local button = cameraButton
				local activeScene = scene
				local names: { [string]: string } = {
					fit = "Fit",
					["eye-height"] = "Player eye height",
					["approach-20"] = "Approach at 20 studs",
					["close-up"] = "Close-up",
					["top-down"] = "Top-down",
					orbit = "Orbit",
					custom = "Custom",
				}
				Compose.watch(function(use: Compose.Use)
					local chosen = use(activeScene.preset)
					ui.set(button, "Text", "Camera · " .. (names[chosen] or chosen))
				end)
			end
			if deviceButton then
				local button = deviceButton
				Compose.watch(function(use: Compose.Use)
					ui.set(button, "Text", use(view.device).name)
				end)
			end
			if link then
				local active = link
				Compose.watch(function(use: Compose.Use)
					local state = use(active.status)
					ui.set(
						syncButton,
						"Text",
						if state == "synchronized"
							then "● Source synced"
							elseif state == "conflict" then "▲ Source changed · Import"
							else "○ Custom source · Import"
					)
					ui.set(
						syncButton,
						"TextColor3",
						if state == "synchronized"
							then ui.rgb(80, 200, 120)
							elseif state == "conflict" then color.danger
							else color.tertiary
					)
				end)
			end
			Compose.watch(function(use: Compose.Use)
				local message = use(session.problem)
				ui.set(problem, "Text", message or "Ready")
				ui.set(problem, "TextColor3", if message then color.danger else color.tertiary)
			end)
			Compose.watch(function(use: Compose.Use)
				ui.set(zoomLabel, "Text", `{math.round(use(view.zoom) * 100)}%`)
			end)
			Compose.watch(function(use: Compose.Use)
				local value = use(session.document)
				ui.set(heading, "Text", `{value.name}  <font color="#78787E">· {library.name}</font>`)
			end)
			Compose.watch(function(use: Compose.Use)
				ui.set(undo, "TextColor3", if use(session.canUndo) then color.text else color.tertiary)
				ui.set(redo, "TextColor3", if use(session.canRedo) then color.text else color.tertiary)
			end)
		end, ui.runtime.reactor)
		local release = Compose.owner.own(ui.owner, owner.dispose)
		return {
			root = root,
			session = session,
			canvas = view,
			execute = execute,
			dispose = function()
				release()
				if unlink then
					unlink()
				end
				for _, connection in connections do
					connection:Disconnect()
				end
				if prompt then
					prompt.dispose()
				end
				view.dispose()
				layers.dispose()
				libraryPanel.dispose()
				if theme then
					theme.dispose()
				end
				inspector.dispose()
				ui.destroy(root)
			end,
		}
	end
end
