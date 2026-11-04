--!strict

local Compose = require "../core"
local Design = require "../design"
local Devices = require "./devices"
local Canvas = require "./canvas"
local UI = require "./ui"

export type Segment = { id: string, name: string, kind: string }
export type Request = {
	designPath: string,
	nodePath: { Segment },
	props: { [string]: Design.Value },
	tokens: { string },
	frame: Devices.Profile,
	source: string,
	request: string,
}
export type Options = { designPath: string, submit: (Request) -> string }

local function snapshot(session: Design.Session, device: Devices.Profile, path: string, text: string): Request
	local document = Design.document.copy(session.document:peek())
	local selected = session.selected:peek()
	local route: { Segment } = {}
	local target: Design.Node? = nil
	local function visit(node: Design.Node): boolean
		table.insert(route, { id = node.id, name = node.name, kind = node.kind })
		if node.id == selected then
			target = node
			return true
		end
		for _, child in node.children do
			if visit(child) then
				return true
			end
		end
		table.remove(route)
		return false
	end
	assert(visit(document.root), "Select a Design node first")
	local props = assert(target).props
	local tokens: { string } = {}
	local function token(name: string)
		if not table.find(tokens, name) then
			table.insert(tokens, name)
		end
	end
	local function literal(value: Design.Literal)
		if type(value) ~= "table" then
			return
		end
		if type(value.token) == "string" then
			token(value.token)
		end
		for _, child in value do
			literal(child)
		end
	end
	for _, value in props do
		if value.token then
			token(value.token)
		end
		if value.literal ~= nil then
			literal(value.literal)
		end
	end
	table.sort(tokens)
	return {
		designPath = path,
		nodePath = route,
		props = props,
		tokens = tokens,
		frame = device,
		source = Design.emit(document, session.library),
		request = text,
	}
end

local function create(ui: UI.UI, session: Design.Session, canvas: Canvas.Canvas, parent: Compose.Node, options: Options)
	local Theme = require "./theme"(ui)
	local panel = Theme.frame("DesignPrompt", Theme.color.panel)
	ui.set(panel, "AnchorPoint", ui.values.vector2(0, 1))
	ui.set(panel, "Position", ui.values.udim2(0, 0, 1, 0))
	ui.set(panel, "Size", ui.values.udim2(1, 0, 0, 140))
	ui.set(panel, "Parent", parent)
	ui.set(canvas.root, "Size", ui.values.udim2(1, 0, 1, -140))
	local caption = Theme.label("", Theme.color.secondary, Theme.size.small)
	ui.set(caption, "Name", "PromptTarget")
	ui.set(caption, "Position", ui.values.udim2(0, 12, 0, 4))
	ui.set(caption, "Size", ui.values.udim2(1, -24, 0, 24))
	ui.set(caption, "Parent", panel)
	local field = Theme.field ""
	ui.set(field, "Name", "PromptRequest")
	ui.set(field, "PlaceholderText", "Describe a change to the selected node")
	ui.set(field, "MultiLine", true)
	ui.set(field, "TextWrapped", true)
	ui.set(field, "TextYAlignment", ui.values.enum("TextYAlignment", "Top"))
	ui.set(field, "Position", ui.values.udim2(0, 12, 0, 32))
	ui.set(field, "Size", ui.values.udim2(1, -24, 0, 56))
	ui.set(field, "Parent", panel)
	local send = Theme.button("SendPrompt", "Apply prompt", Theme.color.white)
	ui.set(send, "BackgroundTransparency", 0)
	ui.set(send, "BackgroundColor3", Theme.color.accent)
	ui.set(send, "Position", ui.values.udim2(1, -152, 0, 100))
	ui.set(send, "Size", ui.values.udim2(0, 140, 0, 32))
	ui.set(send, "Parent", panel)
	Theme.corner(send, 6)
	local status = Theme.label("", Theme.color.secondary, Theme.size.small)
	ui.set(status, "Name", "PromptStatus")
	ui.set(status, "Position", ui.values.udim2(0, 12, 0, 100))
	ui.set(status, "Size", ui.values.udim2(1, -176, 0, 32))
	ui.set(status, "Parent", panel)
	local disposed, busy = false, false
	local connection = ui.connect(send, "Activated", function()
		if busy then
			return
		end
		local text = ui.text(field, "Text")
		if not string.find(text, "%S") or #text > 8000 then
			ui.set(status, "Text", "Enter a request of up to 8000 characters")
			return
		end
		local ok, request = pcall(snapshot, session, canvas.current().device, options.designPath, text)
		if not ok then
			ui.set(status, "Text", "Select a Design node first")
			return
		end
		busy = true
		ui.set(send, "Text", "Working...")
		ui.set(status, "Text", "Capturing the selected frame")
		ui.runtime.scheduler(ui.owner).after(0, function()
			if disposed then
				return
			end
			local submitted, message = pcall(options.submit, request)
			if disposed then
				return
			end
			busy = false
			ui.set(send, "Text", "Apply prompt")
			ui.set(status, "Text", if submitted then message else "Prompt failed; source preserved")
		end)
	end)
	local owner = Compose.createRootOwner(function()
		Compose.watch(function(use: Compose.Use)
			local value, selected = use(session.document), use(session.selected)
			local node = Design.document.find(value.root, selected)
			ui.set(
				caption,
				"Text",
				if node then `Selected: {node.name} · {node.kind}` else "Select a node on the canvas"
			)
		end)
	end, ui.runtime.reactor)
	local release = Compose.owner.own(ui.owner, owner.dispose)
	return {
		dispose = function()
			disposed = true
			connection:Disconnect()
			release()
			ui.destroy(panel)
		end,
	}
end

return { snapshot = snapshot, create = create }
