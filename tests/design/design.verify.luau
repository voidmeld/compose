--!strict

local Support = require "../support"
local Design = require "../../src/design"
local Core = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Built = { kind: string, props: { [string]: Design.Resolved }, children: { Built }, name: string }

local built: { Built } = {}

local function builtNode(value: unknown): Built
	for _, record in built do
		if record == value then
			return record
		end
	end
	error("Expected a node made by this fixture", 0)
end

local function builder(
	kind: string
): (props: { [string]: Design.Resolved }, children: { unknown }, name: string) -> unknown
	return function(props: { [string]: Design.Resolved }, children: { unknown }, name: string): unknown
		local nodes: { Built } = {}
		for _, child in children do
			table.insert(nodes, builtNode(child))
		end
		local record: Built = { kind = kind, props = props, children = nodes, name = name }
		table.insert(built, record)
		return record
	end
end

local stackDefaults: { [string]: Design.Literal } = { gap = 4 }
local labelDefaults: { [string]: Design.Literal } = { text = "Label" }
local rowFields: { Design.ItemField } = { { id = "id", type = "string" }, { id = "name", type = "string" } }
local ada: Design.Row = { id = "a", name = "Ada" }
local bo: Design.Row = { id = "b", name = "Bo" }
local rowsPreview: Design.Literal = { ada, bo }

local library: Design.Library = {
	name = "Toy",
	parameter = "UI",
	parameterType = "Toy.Controls",
	prelude = { 'local Toy = require("Toy")' },
	returnType = "Instance",
	readable = "Toy.Readable",
	cell = "Toy.Cell",
	newCell = "Toy.cell",
	token = "UI.token",
	kinds = {
		Stack = {
			fields = { gap = { type = "number", tokens = true }, Visible = { type = "boolean" } },
			defaults = stackDefaults,
			children = "list",
			call = "UI.Stack",
			build = builder "Stack",
		},
		Label = {
			fields = { text = { type = "string" }, tone = { type = "choice", options = { "body", "title" } } },
			defaults = labelDefaults,
			children = "none",
			call = "UI.Label",
			build = builder "Label",
		},
		Button = {
			fields = { label = { type = "string" }, onActivate = { type = "event" } },
			children = "none",
			call = "UI.Button",
			build = builder "Button",
		},
		List = {
			fields = { itemSize = { type = "number" } },
			children = "template",
			template = "render",
			source = "from",
			key = "key",
			call = "UI.List",
			build = builder "List",
		},
		Flash = {
			fields = { target = { type = "node" } },
			children = "none",
			call = "UI.Flash",
			build = builder "Flash",
		},
		Panel = {
			fields = { title = { type = "string" } },
			children = "slot",
			slot = "content",
			call = "UI.Panel",
			build = builder "Panel",
		},
		Slot = {
			fields = { content = { type = "content" } },
			children = "none",
			call = "UI.Slot",
			build = builder "Slot",
		},
	},
}

type Cells = { { render: (Core.ReadOnlyValue<Design.Row>) -> unknown } }
type Actions = (Core.ReadOnlyValue<Design.Row>) -> { { onActivate: () -> () } }

local function sample(): Design.Document
	local value = Design.document.new("Scores", library, "Stack")
	value = Design.document.setContract(value, library, {
		inputs = {
			{ id = "title", kind = "readable", type = "string", preview = "High scores" },
			{
				id = "rows",
				kind = "readable",
				type = "list",
				preview = rowsPreview,
				fields = rowFields,
			},
			{ id = "showClose", kind = "value", type = "boolean", preview = true },
		},
		outputs = { { id = "onClose" } },
	})
	local title, list, row, close
	value, title = Design.document.insert(value, library, "n1", "Label")
	value = Design.document.change(value, library, title, "text", { input = "title" })
	value, list = Design.document.insert(value, library, "n1", "List")
	value = Design.document.bind(value, library, list, { from = "rows", key = "id" })
	value, row = Design.document.insert(value, library, list, "Label")
	value = Design.document.change(value, library, row, "text", { item = "name" })
	value, close = Design.document.insert(value, library, "n1", "Button")
	value = Design.document.change(value, library, close, "onActivate", { output = "onClose", args = { "back" } })
	value = Design.document.change(value, library, "n1", "Visible", { input = "showClose" })
	value = Design.document.change(value, library, "n1", "gap", { token = "space.m" })
	return value
end

local function refused(callback: () -> ()): boolean
	return not pcall(callback)
end

describe("Compose Design documents", function()
	it("retains enum selected row roots and disposes removed alternatives", function()
		local world = Support.world()
		local toy = table.clone(library)
		toy.keyed = "Toy.keyed"
		toy.kinds = table.clone(library.kinds)
		for _, kind in { "Stack", "Label" } do
			toy.kinds[kind] = table.clone(library.kinds[kind])
			toy.kinds[kind].build = function(
				props: { [string]: Design.Resolved },
				children: { unknown },
				name: string
			): unknown
				local properties: Core.Props = {}
				for index, child in children do
					properties[index] = child
				end
				local text = props.text
				if text then
					properties.Text = text.readable or text.literal
				end
				return world.create(if kind == "Stack" then "Frame" else "TextLabel")(name)(properties)
			end
		end
		local fields: { Design.ItemField } = {
			{ id = "id", type = "string" },
			{ id = "kind", type = "string", options = { "frame", "notice" } },
			{ id = "name", type = "string" },
		}
		local value = Design.document.setContract(Design.document.new("Rows", toy, "Stack"), toy, {
			inputs = { { id = "rows", kind = "readable", type = "list", fields = fields } },
			outputs = {},
		})
		value = Design.document.insert(value, toy, "n1", "Stack")
		value = Design.document.bind(value, toy, "n1", { from = "rows", key = "id" })
		value = Design.document.setRowVariant(value, toy, "n2", {
			item = "kind",
			cases = { { value = "notice", kind = "Label", props = { text = { item = "name" } }, children = {} } },
		})
		local rows = Core.cell<<{ Design.Row }>> {
			{ id = "a", kind = "frame", name = "A" },
			{ id = "b", kind = "notice", name = "B" },
		}
		local dispose, root = world.runtime.mount(function(): Core.Node
			return Support.node(Design.render(value, toy, { bindings = { rows = { rows = rows } } }))
		end, world.root)
		local before = world.host.childrenOf(root)
		expect(world.host.kindOf(before[1])):toBe "Frame"
		expect(world.host.kindOf(before[2])):toBe "TextLabel"
		rows:set { { id = "b", kind = "notice", name = "Updated" } }
		world.settle()
		expect(world.host.childrenOf(root)):toEqual { before[2] }
		expect(world.host.propertyOf(before[2], "Text")):toBe "Updated"
		expect(world.host.isAlive(before[1])):toBe(false)
		dispose()
		expect(world.host.isAlive(before[2])):toBe(false)
		expect(world.host.liveSubscriptions()):toBe(0)
		rows:set {}
		expect(rows:peek()):toEqual {}
		world.runtime:dispose()
	end)

	it("selects independent root trees and builds only the selected content", function()
		local value = Design.document.setContract(Design.document.new("Content", library, "Stack"), library, {
			inputs = {
				{
					id = "presentation",
					kind = "value",
					type = "string",
					required = true,
					options = { "inline", "panel" },
				},
			},
			outputs = {},
		})
		value = Design.document.insert(value, library, "n1", "Stack")
		value = Design.document.insert(value, library, "n2", "Label")
		value.nextId = 5
		value = Design.document.setRootVariant(value, library, {
			input = "presentation",
			value = "panel",
			kind = "Panel",
			props = { title = { literal = "Separate" } },
			children = {
				{ id = "n4", kind = "Label", name = "Plain", props = { text = { literal = "Plain" } }, children = {} },
			},
		})
		table.clear(built)
		local inline = builtNode(Design.render(value, library, { inputs = { presentation = "inline" } }))
		expect(inline.children[1].kind):toBe "Stack"
		expect(#built):toBe(3)
		table.clear(built)
		local panel = builtNode(Design.render(value, library, { inputs = { presentation = "panel" } }))
		expect(#built):toBe(1)
		expect(panel.name):toBe(inline.name)
		local plain = builtNode(assert(panel.props.content.slot)())
		expect(plain.name):toBe "Plain"
		expect(plain.props.text.literal):toBe "Plain"
		expect(#built):toBe(2)
		local copy = Design.document.copy(value)
		assert(copy.rootVariant).children = {}
		expect(#assert(assert(value.rootVariant).children)):toBe(1)
	end)

	it("selects row kinds props and trees from a declared enum field", function()
		local fields: { Design.ItemField } = {
			{ id = "id", type = "string" },
			{ id = "kind", type = "string", options = { "button", "notice", "stack" } },
			{ id = "name", type = "string" },
		}
		local value = Design.document.setContract(Design.document.new("Rows", library, "List"), library, {
			inputs = { { id = "rows", kind = "readable", type = "list", fields = fields, required = true } },
			outputs = {},
		})
		value = Design.document.bind(value, library, "n1", { from = "rows", key = "id" })
		value = Design.document.insert(value, library, "n1", "Button")
		value = Design.document.change(value, library, "n2", "label", { item = "name" })
		value.nextId = 4
		value = Design.document.setRowVariant(value, library, "n2", {
			item = "kind",
			cases = {
				{ value = "notice", kind = "Label", props = { text = { item = "name" } }, children = {} },
				{
					value = "stack",
					kind = "Stack",
					props = {},
					children = { { id = "n3", kind = "Label", name = "Nested", props = {}, children = {} } },
				},
			},
		})
		local list = builtNode(Design.render(value, library))
		local render = assert(list.props.render.template)
		for _, kind in { "button", "notice", "stack" } do
			local item = Core.cell<<Design.Row>> { id = kind, kind = kind, name = "Prepared" }
			local row = builtNode(render(item))
			expect(row.name):toBe "Button"
			if kind == "button" then
				expect(row.kind):toBe "Button"
				expect(assert(row.props.label.readable):peek()):toBe "Prepared"
			elseif kind == "notice" then
				expect(row.kind):toBe "Label"
				expect(assert(row.props.text.readable):peek()):toBe "Prepared"
			else
				expect(row.kind):toBe "Stack"
				expect(row.children[1].name):toBe "Nested"
			end
		end
		for _, rowFunctions in { false, true } do
			local options: Design.EmitOptions = { rowFunctions = rowFunctions }
			local code = Design.emit(value, library, options)
			expect(Design.parse(code, library)):toEqual(value)
			expect(Design.emit(Design.parse(code, library), library, options)):toBe(code)
		end
		local invalid = Design.document.copy(value)
		assert(invalid.root.children[1].rowVariant).item = "name"
		expect(function()
			Design.document.validate(invalid, library)
		end):toThrow "text enum"
		invalid = Design.document.copy(value)
		assert(invalid.root.children[1].rowVariant).cases[1].value = "unknown"
		expect(function()
			Design.document.validate(invalid, library)
		end):toThrow "enum options"
	end)

	it("updates prepared input and item tags and releases their watches", function()
		local toy = table.clone(library)
		local applied: { { string } } = {}
		toy.tags = {
			call = "UI.tag",
			apply = function(_node: unknown, tags: { string })
				table.insert(applied, tags)
			end,
		}
		local value = Design.document.setContract(Design.document.new("Tags", toy, "List"), toy, {
			inputs = {
				{ id = "paint", kind = "readable", type = "string", required = true },
				{
					id = "rows",
					kind = "readable",
					type = "list",
					fields = { { id = "id", type = "string" }, { id = "paint", type = "list", luauType = "Tags" } },
				},
			},
			outputs = {},
		})
		value = Design.document.bind(value, toy, "n1", { from = "rows", key = "id" })
		value = Design.document.insert(value, toy, "n1", "Label")
		value = Design.document.bindTags(value, toy, "n1", { input = "paint" })
		value = Design.document.bindTags(value, toy, "n2", { item = "paint" })
		local owner = Core.createOwner()
		local paint = Core.cell<<Design.Literal?>> "compact"
		local item = Core.cell<<Design.Row>> { id = "a", paint = { "incoming", "accent" } }
		Core.withOwner(owner, function()
			local list = builtNode(Design.render(value, toy, { bindings = { paint = { readable = paint } } }))
			assert(list.props.render.template)(item)
		end)
		expect(applied):toEqual { { "compact" }, { "incoming", "accent" } }
		paint:set "wide"
		item:set { id = "a", paint = { "outgoing" } }
		expect(applied[3]):toEqual { "wide" }
		expect(applied[4]):toEqual { "outgoing" }
		Core.owner.dispose(owner)
		paint:set "borrowed"
		item:set { id = "a", paint = {} }
		expect(#applied):toBe(4)
		expect(paint:peek()):toBe "borrowed"
		local invalid = Design.document.copy(value)
		invalid.root.tagBinding = { item = "paint" }
		expect(function()
			Design.document.validate(invalid, toy)
		end):toThrow()
	end)

	it("keeps slot factories in layout order and unwinds failed slot builds", function()
		local world = Support.world()
		local toy = table.clone(library)
		toy.kinds = table.clone(library.kinds)
		toy.kinds.Stack = table.clone(library.kinds.Stack)
		toy.kinds.Stack.build = function(
			_props: { [string]: Design.Resolved },
			children: { unknown },
			name: string
		): unknown
			local props: Core.Props = {}
			for index, child in children do
				props[index] = child
			end
			return world.create "Frame"(name)(props)
		end
		local value = Design.document.setContract(Design.document.new("Layout", toy, "Stack"), toy, {
			inputs = { { id = "body", kind = "value", type = "slot", required = true } },
			outputs = {},
		})
		value = Design.document.insert(value, toy, "n1", "Stack")
		value = Design.document.rename(value, toy, "n2", "Before")
		value = Design.document.insertSlot(value, toy, "n1", "body")
		value = Design.document.insert(value, toy, "n1", "Stack")
		value = Design.document.rename(value, toy, "n4", "After")
		local calls, cleanups = 0, 0
		local fail = false
		local context: Design.RenderContext = {
			slots = {
				body = function(): unknown
					calls += 1
					Core.cleanup(function()
						cleanups += 1
					end)
					local node = world.create "Frame" "Supplied" {}
					if fail then
						error("slot failure", 0)
					end
					return node
				end,
			},
		}
		local dispose, root = world.runtime.mount(function(): Core.Node
			return Support.node(Design.render(value, toy, context))
		end, world.root)
		expect(calls):toBe(1)
		local children = world.host.childrenOf(root)
		expect(#children):toBe(3)
		expect(world.host.nameOf(children[1])):toBe "Before"
		expect(world.host.nameOf(children[2])):toBe "Supplied"
		expect(world.host.nameOf(children[3])):toBe "After"
		dispose()
		expect(cleanups):toBe(1)
		value.contract.inputs[1].required = nil
		local disposeOptional, optional = world.runtime.mount(function(): Core.Node
			return Support.node(Design.render(value, toy))
		end, world.root)
		expect(#world.host.childrenOf(optional)):toBe(2)
		expect(calls):toBe(1)
		disposeOptional()
		value.contract.inputs[1].required = true
		expect(function()
			world.runtime.mount(function(): Core.Node
				return Support.node(Design.render(value, toy))
			end, world.root)
		end):toThrow "required slot"
		expect(world.host.liveNodes()):toBe(1)
		fail = true
		expect(function()
			world.runtime.mount(function(): Core.Node
				return Support.node(Design.render(value, toy, context))
			end, world.root)
		end):toThrow "slot failure"
		expect(calls):toBe(2)
		expect(cleanups):toBe(2)
		expect(world.host.liveNodes()):toBe(1)
		world.runtime:dispose()
	end)

	it("reads inputs inside page records beside lazy document content", function()
		local toy = table.clone(library)
		toy.kinds = table.clone(library.kinds)
		local bookKind: Design.Kind =
			{ fields = { pages = { type = "value" } }, children = "none", call = "UI.Book", build = builder "Book" }
		toy.kinds.Book = bookKind
		local value = Design.document.setContract(Design.document.new("Pages", toy, "Book"), toy, {
			inputs = { { id = "title", kind = "value", type = "string", required = true } },
			outputs = {},
		})
		value.root.children = { { id = "n2", kind = "Label", name = "Content", props = {}, children = {} } }
		value.nextId = 3
		value = Design.document.change(
			value,
			toy,
			"n1",
			"pages",
			{ literal = { { label = { ["$input"] = "title" }, content = { ["$template"] = "n2" } } } }
		)
		table.clear(built)
		local book = builtNode(Design.render(value, toy, { inputs = { title = "Prepared title" } }))
		expect(#built):toBe(1)
		local pages = Support.record(book.props.pages.value)
		local page = Support.record(pages[1])
		expect(page.label):toBe "Prepared title"
		local content = page.content
		assert(type(content) == "function")
		expect(builtNode(Support.invoke(content)).name):toBe "Content"
		expect(#built):toBe(2)
		local invalid = Design.document.copy(value)
		invalid.root.props.pages = { literal = { { label = { ["$input"] = "unknown" } } } }
		expect(function()
			Design.document.validate(invalid, toy)
		end):toThrow "record input"
	end)

	it("retains nested keyed row ownership when an outer row replaces its qualified list", function()
		local world = Support.world()
		local toy = table.clone(library)
		toy.keyed = "Toy.keyed"
		toy.kinds = table.clone(library.kinds)
		toy.kinds.Stack = table.clone(library.kinds.Stack)
		toy.kinds.Stack.build = function(
			props: { [string]: Design.Resolved },
			children: { unknown },
			name: string
		): unknown
			local properties: Core.Props = {}
			for index, child in children do
				properties[index] = child
			end
			local text = props.Visible
			if text then
				properties.Visible = text.readable or text.literal
			end
			return world.create "Frame"(name)(properties)
		end
		local fields: { Design.ItemField } = { { id = "id", type = "string" }, { id = "visible", type = "boolean" } }
		local pageFields: { Design.ItemField } =
			{ { id = "id", type = "string" }, { id = "rows", type = "list", fields = fields } }
		local value = Design.document.setContract(Design.document.new("Nested", toy, "Stack"), toy, {
			inputs = { { id = "pages", kind = "readable", type = "list", fields = pageFields, required = true } },
			outputs = {},
		})
		local page, row
		value, page = Design.document.insert(value, toy, "n1", "Stack")
		value = Design.document.bind(value, toy, "n1", { from = "pages", key = "id" })
		value, row = Design.document.insert(value, toy, page, "Stack")
		value = Design.document.bind(value, toy, page, { from = "pages.rows", key = "id" })
		value = Design.document.change(value, toy, row, "Visible", { item = "visible" })
		local first: Design.Row = { id = "a", visible = true }
		local second: Design.Row = { id = "b", visible = false }
		local pages = Core.cell<<{ Design.Row }>> { { id = "page", rows = { first, second } } }
		local dispose, root = world.runtime.mount(function(): Core.Node
			return Support.node(Design.render(value, toy, { bindings = { pages = { rows = pages } } }))
		end, world.root)
		world.settle()
		local pageNode = world.host.childrenOf(root)[1]
		local before = world.host.childrenOf(pageNode)
		expect(#before):toBe(2)
		local changed: Design.Row = { id = "b", visible = true }
		pages:set { { id = "page", rows = { changed } } }
		world.settle()
		expect(world.host.childrenOf(root)[1]):toBe(pageNode)
		expect(world.host.childrenOf(pageNode)):toEqual { before[2] }
		expect(world.host.propertyOf(before[2], "Visible")):toBe(true)
		expect(world.host.isAlive(before[1])):toBe(false)
		pages:set {}
		world.settle()
		expect(world.host.isAlive(pageNode)):toBe(false)
		expect(world.host.isAlive(before[2])):toBe(false)
		dispose()
		pages:set { { id = "borrowed", rows = {} } }
		expect(#pages:peek()):toBe(1)
		expect(world.host.liveNodes()):toBe(1)
		expect(world.host.liveSubscriptions()):toBe(0)
		world.runtime:dispose()
	end)

	it("selects static root kinds with one direct name and shared content", function()
		local value = Design.document.setContract(Design.document.new("Details", library, "Stack"), library, {
			inputs = {
				{
					id = "presentation",
					kind = "value",
					type = "string",
					options = { "inline", "panel" },
					required = true,
					preview = "inline",
				},
				{ id = "name", kind = "value", type = "string", required = true },
				{ id = "rows", kind = "readable", type = "list", fields = rowFields },
			},
			outputs = {},
		})
		value = Design.document.nameFromInput(value, library, "n1", "name")
		local content, label, flash
		value, content = Design.document.insert(value, library, "n1", "Stack")
		value, label = Design.document.insert(value, library, content, "Label")
		value, flash = Design.document.insert(value, library, content, "Flash")
		value = Design.document.change(value, library, flash, "target", { node = label })
		local list
		value, list = Design.document.insert(value, library, content, "List")
		value = Design.document.bind(value, library, list, { from = "rows", key = "id" })
		value = Design.document.insert(value, library, list, "Label")
		value = Design.document.setRootVariant(
			value,
			library,
			{ input = "presentation", value = "panel", kind = "Panel", props = { title = { literal = "Details" } } }
		)
		local code = Design.emit(value, library)
		expect(string.find(code, 'presentation: "inline" | "panel"', 1, true) ~= nil):toBe(true)
		expect(string.find(code, "local function rootContent(): Instance", 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, library)):toEqual(value)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		local named = Design.emit(value, library, { rowFunctions = true })
		expect(Design.parse(named, library)):toEqual(value)
		expect(Design.emit(Design.parse(named, library), library, { rowFunctions = true })):toBe(named)
		local inline = builtNode(Design.render(value, library, { inputs = { name = "Direct" } }))
		expect(inline.kind):toBe "Stack"
		expect(inline.name):toBe "Direct"
		expect(inline.children[1].children[1].kind):toBe "Label"
		local panel = builtNode(
			Design.render(
				value,
				library,
				{ bindings = { presentation = { value = "panel" } }, inputs = { name = "Direct" } }
			)
		)
		expect(panel.kind):toBe "Panel"
		expect(panel.name):toBe "Direct"
		expect(panel.props.title.literal):toBe "Details"
		expect(panel.children):toEqual {}
		local shared = builtNode(assert(panel.props.content.slot)())
		expect(shared.children[1].kind):toBe "Label"
		expect(assert(shared.children[2].props.target.node):peek()):toBe(shared.children[1])
		local invalid = Design.document.copy(value)
		invalid.contract.inputs[1].kind = "readable"
		expect(function()
			Design.document.validate(invalid, library)
		end):toThrow "static text enum"
		invalid = Design.document.copy(value)
		assert(invalid.rootVariant).value = "unknown"
		expect(function()
			Design.document.validate(invalid, library)
		end):toThrow "enum option"
		expect(function()
			Design.render(value, library, { inputs = { presentation = "unknown" } })
		end):toThrow "enum option"
	end)

	it("passes live rows to template kinds without snapshotting them", function()
		local rows = Core.cell { ada }
		local value = sample()
		table.clear(built)
		Design.render(value, library, {
			bindings = { rows = { rows = rows } },
			token = function(_name: string): Design.Literal
				return 8
			end,
		})
		local list: Built? = nil
		for _, record in built do
			if record.kind == "List" then
				list = record
			end
		end
		local source = assert(assert(list).props.from.rows)
		expect(#source:peek()):toBe(1)
		rows:set { bo, ada }
		expect(#source:peek()):toBe(2)
		expect(source:peek()[1].name):toBe "Bo"
	end)
	it("round trips host input types and nested row shapes with typed outputs and slots", function()
		local nested: { Design.ItemField } = { { id = "label", type = "string" } }
		local fields: { Design.ItemField } = {
			{ id = "id", type = "string" },
			{ id = "name", type = "string" },
			{ id = "size", type = "record", luauType = "Vector2" },
			{ id = "children", type = "list", fields = nested },
		}
		local args: { Design.InputType } = { "number" }
		local value = Design.document.setContract(sample(), library, {
			inputs = {
				{ id = "title", kind = "readable", type = "string", luauType = "UI.Caption" },
				{ id = "showClose", kind = "value", type = "boolean" },
				{ id = "geometry", kind = "readable", type = "record", luauType = "UDim2" },
				{ id = "overlay", kind = "value", type = "slot" },
				{
					id = "rows",
					kind = "readable",
					type = "list",
					fields = fields,
				},
			},
			outputs = { { id = "onClose", args = args }, { id = "onPick", row = "rows" } },
		})
		local code = Design.emit(value, library)
		expect(string.find(code, "title: Toy.Readable<UI.Caption>?", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "geometry: Toy.Readable<UDim2>?", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "overlay: (() -> Instance)?", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "size: Vector2, children: { { label: string } }", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "onPick: ((RowsItem) -> ())?", 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		local bad = Design.document.copy(value)
		bad.contract.inputs[1].luauType = "UI..Caption"
		expect(function()
			Design.document.validate(bad, library)
		end):toThrow()
	end)
	it("rejects values the kind and contract do not declare", function()
		local value = sample()
		expect(refused(function()
			Design.document.change(value, library, "n2", "text", { input = "missing" })
		end)):toBe(true)
		expect(refused(function()
			Design.document.change(value, library, "n2", "text", { item = "name" })
		end)):toBe(true)
		expect(refused(function()
			Design.document.change(value, library, "n2", "tone", { literal = "loud" })
		end)):toBe(true)
		expect(refused(function()
			Design.document.change(value, library, "n2", "text", { token = "space.m" })
		end)):toBe(true)
		expect(refused(function()
			Design.document.change(value, library, "n5", "label", { output = "onClose" })
		end)):toBe(true)
		expect(refused(function()
			Design.document.change(value, library, "n2", "text", { literal = "a", input = "title" })
		end)):toBe(true)
		expect(refused(function()
			Design.document.change(value, library, "n5", "onActivate", { output = "onClose" })
		end)):toBe(false)
	end)

	it("reads back every literal it writes", function()
		local nested: Design.Row = { nested = true }
		local words: Design.Row = { "a", nested }
		local record: Design.Row = { top = 4, ["two words"] = words }
		local components: Design.Row = { 0, 10, 0, -20 }
		local values: { Design.Literal } = { -4.5, 'line\n"quoted"', false, components, record }
		for _, value in values do
			local text = Design.literal(value)
			expect(Design.literal(Design.parseLiteral(text))):toBe(text)
		end
		expect(function()
			Design.parseLiteral "{ 1, 2"
		end):toThrow()
		expect(function()
			Design.parseLiteral "1 2"
		end):toThrow()
	end)

	it("inserts a kind with the children it seeds", function()
		local panel = library.kinds.Panel
		local labelProps: { [string]: Design.Literal } = { text = "Seeded" }
		panel.seeds = { { kind = "Label", props = labelProps } }
		local value, id = Design.document.insert(Design.document.new("Seeds", library, "Stack"), library, "n1", "Panel")
		panel.seeds = nil
		local found = Design.document.find(value.root, id)
		local inserted = assert(found)
		expect(#inserted.children):toBe(1)
		expect(inserted.children[1].kind):toBe "Label"
		expect(inserted.children[1].props.text.literal):toBe "Seeded"
	end)

	it("applies a field only when the fields it requires allow it", function()
		local label = library.kinds.Label
		local fields = label.fields
		local titles: { Design.Literal } = { "title" }
		local emphasis: Design.Field = { type = "boolean", requires = { tone = titles } }
		label.fields = table.clone(fields)
		label.fields.emphasis = emphasis
		local value, id = Design.document.insert(Design.document.new("Needs", library, "Stack"), library, "n1", "Label")
		expect(function()
			Design.document.change(value, library, id, "emphasis", { literal = true })
		end):toThrow "emphasis applies only when tone is title"
		value = Design.document.change(value, library, id, "tone", { literal = "title" })
		value = Design.document.change(value, library, id, "emphasis", { literal = true })
		local found = Design.document.find(value.root, id)
		expect(assert(found).props.emphasis.literal):toBe(true)
		value = Design.document.change(value, library, id, "tone", { literal = "body" })
		found = Design.document.find(value.root, id)
		expect(assert(found).props.emphasis):toBe(nil)
		label.fields = fields
	end)

	it("tags nodes for style rules and reads the tags back", function()
		local applied: { [unknown]: { string } } = {}
		library.tags = {
			call = "UI.tag",
			apply = function(built: unknown, tags: { string })
				applied[built] = tags
			end,
		}
		local value, id = Design.document.insert(Design.document.new("Tags", library, "Stack"), library, "n1", "Label")
		value = Design.document.tag(value, library, id, { "amigos-stat", "amigos-feature" })
		expect(function()
			Design.document.tag(value, library, id, { "not a tag" })
		end):toThrow()
		local code = Design.emit(value, library)
		expect(string.find(code, "UI.tag(", 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, library)
		expect(Design.emit(parsed, library)):toBe(code)
		local found = Design.document.find(parsed.root, id)
		expect(table.concat(assert(assert(found).tags), " ")):toBe "amigos-stat amigos-feature"
		Design.render(parsed, library)
		local tagged = 0
		for _, tags in applied do
			if table.concat(tags, " ") == "amigos-stat amigos-feature" then
				tagged += 1
			end
		end
		expect(tagged):toBe(1)
		library.tags = nil
	end)

	it("moves a bound value with a motion role and reads the role back", function()
		local moved: { string } = {}
		library.motion = {
			call = "UI.follow",
			roles = { "move", "fade" },
			animate = function(
				source: Core.ReadOnlyValue<Design.Literal?>,
				role: string
			): Core.ReadOnlyValue<Design.Literal?>
				table.insert(moved, role)
				return source
			end,
		}
		local value, id =
			Design.document.insert(Design.document.new("Moving", library, "Stack"), library, "n1", "Stack")
		local spread: { Design.State } = { { id = "spread", type = "number", initial = 8 } }
		value = Design.document.setState(value, library, spread)
		value = Design.document.change(value, library, id, "gap", { state = "spread", motion = "move" })
		expect(function()
			Design.document.change(value, library, id, "gap", { state = "spread", motion = "bounce" })
		end):toThrow "gap moves with unknown motion role bounce"
		expect(function()
			Design.document.change(value, library, id, "gap", { literal = 4, motion = "move" })
		end):toThrow "gap moves only when it follows an input, state or item"
		local code = Design.emit(value, library)
		expect(string.find(code, 'gap = UI.follow(state.spread, "move")', 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, library)
		expect(Design.emit(parsed, library)):toBe(code)
		local found = Design.document.find(parsed.root, id)
		local gap = assert(found).props.gap
		expect(gap.motion):toBe "move"
		expect(gap.state):toBe "spread"
		Design.render(parsed, library)
		expect(table.concat(moved, " ")):toBe "move"
		library.motion = nil
	end)

	it("keeps sequences as design data and plays them from events", function()
		local plays: { string } = {}
		library.sequence = {
			call = "UI.sequence",
			toward = "UI.toward",
			build = function(
				sequence: Design.Sequence,
				states: { [string]: Core.Value<Design.Literal?> },
				outputs: { [string]: () -> () }
			): Design.Player
				return {
					play = function()
						table.insert(plays, sequence.id)
						for _, step in sequence.steps do
							local target, to = step.state, step.to
							if target ~= nil and to ~= nil then
								states[target]:set(to)
							end
							local output = step.output
							if output ~= nil then
								outputs[output]()
							end
						end
					end,
				}
			end,
		}
		local value, id =
			Design.document.insert(Design.document.new("Reveal", library, "Stack"), library, "n1", "Button")
		value = Design.document.setContract(value, library, { inputs = {}, outputs = { { id = "onRevealed" } } })
		local glow: { Design.State } = {
			{ id = "glow", type = "number", initial = 0 },
			{ id = "open", type = "boolean", initial = false },
		}
		value = Design.document.setState(value, library, glow)
		expect(function()
			local missing: { Design.Sequence } = { { id = "reveal", steps = { { state = "missing", to = 1 } } } }
			Design.document.setSequences(value, library, missing)
		end):toThrow "Sequence reveal moves unknown state missing"
		local sequences: { Design.Sequence } = {
			{
				id = "reveal",
				steps = {
					{ duration = "glide", easing = "standard", state = "glow", to = 1 },
					{ delay = "short", state = "open", to = true, output = "onRevealed" },
				},
			},
			{ id = "intro", autoplay = true, steps = { { duration = "glide", state = "glow", to = 0.5 } } },
		}
		value = Design.document.setSequences(value, library, sequences)
		value = Design.document.change(value, library, id, "onActivate", { play = "reveal" })
		expect(function()
			Design.document.change(value, library, id, "label", { play = "reveal" })
		end):toThrow "label cannot play a sequence"
		local code = Design.emit(value, library)
		expect(string.find(code, "onActivate = sequences.reveal.play", 1, true) ~= nil):toBe(true)
		expect(
			string.find(
				code,
				'{ duration = "glide", easing = "standard", sample = UI.toward(state.glow, 1) },',
				1,
				true
			) ~= nil
		):toBe(true)
		expect(
			string.find(
				code,
				'{ delay = "short", onStart = function() state.open:set(true) end, onEnd = props.onRevealed },',
				1,
				true
			) ~= nil
		):toBe(true)
		expect(string.find(code, "sequences.intro.play()", 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, library)
		expect(parsed.sequences):toEqual(sequences)
		expect(parsed.state):toEqual(glow)
		expect(Design.emit(parsed, library)):toBe(code)
		local revealed = 0
		table.clear(built)
		Design.render(parsed, library, {
			outputs = {
				onRevealed = function(_: { Design.Literal })
					revealed += 1
				end,
			},
		})
		expect(table.concat(plays, " ")):toBe "intro"
		local activate: ((...Design.Literal) -> ())? = nil
		for _, record in built do
			if record.kind == "Button" then
				activate = record.props.onActivate.callback
			end
		end
		assert(activate, "the Button gets a play callback")()
		expect(table.concat(plays, " ")):toBe "intro reveal"
		expect(revealed):toBe(1)
		library.sequence = nil
	end)

	it("binds a row's own list and shows row content by an item field", function()
		library.show = "Toy.show"
		local rowFields: { Design.ItemField } = { { id = "id", type = "string" }, { id = "label", type = "string" } }
		local pageFields: { Design.ItemField } = {
			{ id = "id", type = "string" },
			{ id = "sent", type = "boolean" },
			{ id = "rows", type = "list", fields = rowFields },
		}
		local first: Design.Row = { id = "a", label = "Alpha" }
		local second: Design.Row = { id = "b", label = "Beta" }
		local entries: Design.Row = { first, second }
		local sentPage: Design.Row = { id = "p1", sent = true, rows = entries }
		local quietPage: Design.Row = { id = "p2", sent = false, rows = entries }
		local pages: Design.Row = { sentPage, quietPage }
		local value = Design.document.new("Board", library, "Stack")
		value = Design.document.setContract(value, library, {
			inputs = { { id = "pages", kind = "readable", type = "list", preview = pages, fields = pageFields } },
			outputs = {},
		})
		local outer, page, sent, inner, entry
		value, outer = Design.document.insert(value, library, "n1", "List")
		value = Design.document.bind(value, library, outer, { from = "pages", key = "id" })
		value, page = Design.document.insert(value, library, outer, "Stack")
		value, sent = Design.document.insert(value, library, page, "Label")
		value = Design.document.change(value, library, sent, "text", { literal = "Sent" })
		value = Design.document.showWhen(value, library, sent, "sent")
		value, inner = Design.document.insert(value, library, page, "List")
		value = Design.document.bind(value, library, inner, { from = "rows", key = "id" })
		value, entry = Design.document.insert(value, library, inner, "Label")
		value = Design.document.change(value, library, entry, "text", { item = "label" })
		local code = Design.emit(value, library)
		expect(string.find(code, "use(current).rows", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "use(current).sent == true", 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		value = Design.document.bind(value, library, inner, { from = "pages.rows", key = "id" })
		code = Design.emit(value, library)
		expect(string.find(code, "local row_pages = current", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "use(row_pages).rows", 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, library)):toEqual(value)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		local named = Design.emit(value, library, { rowFunctions = true })
		expect(Design.emit(Design.parse(named, library), library, { rowFunctions = true })):toBe(named)
		local current = value
		local innerId: string = inner
		expect(function()
			Design.document.bind(current, library, innerId, { from = "other.rows", key = "id" })
		end):toThrow "unknown input"
		expect(function()
			Design.document.bind(current, library, "n1", { from = "pages.rows", key = "id" })
		end):toThrow "repeat"
		table.clear(built)
		Design.render(value, library)
		local lists: { Built } = {}
		for _, record in built do
			if record.kind == "List" then
				table.insert(lists, record)
			end
		end
		table.clear(built)
		for _, record in lists do
			local resolved = record.props.render
			local template = if resolved then resolved.template else nil
			if template then
				template(Core.cell(sentPage))
				template(Core.cell(quietPage))
			end
		end
		local shown, innerRows = 0, 0
		for _, record in built do
			local text = record.props.text
			if record.kind == "Label" and text ~= nil and text.literal == "Sent" then
				shown += 1
			elseif record.kind == "List" then
				local rows = assert(record.props.from.rows)
				innerRows += #rows:peek()
			end
		end
		expect(shown):toBe(1)
		expect(innerRows):toBe(4)
		library.show = nil
	end)

	it("renders column cells and row actions for each item of a repeated list", function()
		local kinds = library.kinds
		local columnsField: Design.Field = { type = "value", luauType = "{ Toy.Column<$Item, $Key> }" }
		local actionsField: Design.Field = { type = "value", perRow = true, luauType = "Toy.Actions" }
		library.kinds = table.clone(kinds)
		library.kinds.Table = {
			fields = { columns = columnsField, actions = actionsField },
			children = "template",
			source = "from",
			key = "key",
			call = "UI.Table",
			build = builder "Table",
		}
		local alpha: Design.Row = { id = "a", label = "Alpha", score = 3 }
		local rowsPreview: Design.Row = { alpha }
		local fields: { Design.ItemField } = {
			{ id = "id", type = "string" },
			{ id = "label", type = "string" },
			{ id = "score", type = "number" },
		}
		local value = Design.document.new("Cells", library, "Stack")
		value = Design.document.setContract(value, library, {
			inputs = { { id = "rows", kind = "readable", type = "list", preview = rowsPreview, fields = fields } },
			outputs = { { id = "onChoose", row = "rows" } },
		})
		local tableId, cellId
		value, tableId = Design.document.insert(value, library, "n1", "Table")
		value = Design.document.bind(value, library, tableId, { from = "rows", key = "id" })
		value, cellId = Design.document.insert(value, library, tableId, "Label")
		value = Design.document.change(value, library, cellId, "text", { item = "label" })
		local scoreId
		value, scoreId = Design.document.insert(value, library, tableId, "Label")
		value = Design.document.change(value, library, scoreId, "text", { item = "score" })
		local render: Design.Row = { ["$template"] = cellId }
		local scoreRender: Design.Row = { ["$template"] = scoreId }
		local column: Design.Row = { id = "label", render = render }
		local scoreColumn: Design.Row = { id = "score", render = scoreRender }
		local columns: Design.Row = { column, scoreColumn }
		value = Design.document.change(value, library, tableId, "columns", { literal = columns })
		local activate: Design.Row = { ["$output"] = "onChoose", ["$row"] = true }
		local action: Design.Row = { id = "choose", label = "Choose", onActivate = activate }
		local actions: Design.Row = { action }
		value = Design.document.change(value, library, tableId, "actions", { literal = actions })
		local code = Design.emit(value, library)
		expect(string.find(code, "props.onChoose(current:peek())", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "tostring(use(current).score)", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "Columns: { Toy.Column<RowsItem, string> } = {", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "onChoose: ((RowsItem) -> ())?", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "actions = function(current: Toy.Readable<RowsItem>): Toy.Actions", 1, true) ~= nil):toBe(
			true
		)
		local _, itemTypes = string.gsub(code, "type %w+Item = ", "")
		expect(itemTypes):toBe(1)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		local chosen: { Design.Literal } = {}
		table.clear(built)
		Design.render(value, library, {
			outputs = {
				onChoose = function(args: { Design.Literal })
					table.insert(chosen, args[1])
				end,
			},
		})
		local grid: Built? = nil
		for _, record in built do
			if record.kind == "Table" then
				grid = record
			end
		end
		local made = assert(grid)
		expect(#made.children):toBe(0)
		table.clear(built)
		local cells = Support.record(made.props.columns.value)
		Support.invoke(Support.read(cells[1], "render"), Core.cell(alpha))
		expect(built[1].kind):toBe "Label"
		table.clear(built)
		Support.invoke(Support.read(cells[2], "render"), Core.cell(alpha))
		local scoreText = assert(built[1].props.text.readable)
		expect(scoreText:peek()):toBe "3"
		local rowActions = made.props.actions.value
		local rowChoices = Support.record(Support.invoke(rowActions, Core.cell(alpha)))
		Support.invoke(Support.read(rowChoices[1], "onActivate"))
		expect(chosen[1]):toBe(alpha)
		library.kinds = kinds
	end)

	it("builds a value field's authored node once before its receiver and remaps copied children", function()
		local extended = Design.extend(library, {
			kinds = {
				Trailing = {
					fields = { item = { type = "value" } },
					children = "none",
					call = "UI.Trailing",
					build = builder "Trailing",
				},
			},
		})
		local value, receiver =
			Design.document.insert(Design.document.new("Navigation", extended, "Stack"), extended, "n1", "Trailing")
		local child
		value, child = Design.document.content(value, extended, receiver, "item", "Label")
		table.clear(built)
		local root = builtNode(Design.render(value, extended))
		expect(#built):toBe(3)
		expect(built[1].kind):toBe "Label"
		expect(#root.children[1].children):toBe(0)
		expect(root.children[1].props.item.value):toBe(built[1])
		local code = Design.emit(value, extended)
		expect(Design.emit(Design.parse(code, extended), extended)):toBe(code)
		local session = Design.session(extended, value)
		session.select(receiver)
		session.copy()
		session.select "n1"
		session.paste()
		local pasted = session.document:peek().root.children[2]
		expect(pasted.props.item.literal):toEqual { ["$template"] = pasted.children[1].id }
		expect(pasted.children[1].id == child):toBe(false)
		value = Design.document.change(value, extended, receiver, "item", nil)
		local remaining = Design.document.find(value.root, receiver)
		expect(#assert(remaining).children):toBe(0)
	end)

	it("holds a content field's subtree as a child and writes it as a builder", function()
		local kinds = library.kinds
		local iconField: Design.Field = { type = "content" }
		library.kinds = table.clone(kinds)
		local button = table.clone(kinds.Button)
		button.fields = table.clone(button.fields)
		button.fields.icon = iconField
		library.kinds.Button = button
		local value, buttonId =
			Design.document.insert(Design.document.new("Content", library, "Stack"), library, "n1", "Button")
		local glyphId
		value, glyphId = Design.document.content(value, library, buttonId, "icon", "Label")
		value = Design.document.change(value, library, glyphId, "text", { literal = "Menu" })
		local code = Design.emit(value, library)
		expect(string.find(code, "icon = function()", 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		table.clear(built)
		Design.render(value, library)
		local icon: unknown = nil
		for _, record in built do
			if record.kind == "Button" then
				icon = record.props.icon.value
			end
		end
		expect(type(icon)):toBe "function"
		table.clear(built)
		local builder = icon
		Support.invoke(builder)
		expect(built[1].kind):toBe "Label"
		value = Design.document.change(value, library, buttonId, "icon", nil)
		local found = Design.document.find(value.root, buttonId)
		expect(#assert(found).children):toBe(0)
		library.kinds = kinds
	end)

	it("writes tokens as a table path when the library names a path prefix", function()
		local call = library.token
		library.token = "T."
		local value = Design.document.new("Tokens", library, "Stack")
		value = Design.document.change(value, library, "n1", "gap", { token = "space.md" })
		local code = Design.emit(value, library)
		expect(string.find(code, "gap = T.space.md,", 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, library)
		expect(parsed.root.props.gap.token):toBe "space.md"
		expect(Design.emit(parsed, library)):toBe(code)
		library.token = call
	end)

	it("undoes and redoes whole edits", function()
		local first = sample()
		local history = Design.history(first)
		history.commit(Design.document.remove(first, library, "n2"))
		expect(#history.current().root.children):toBe(2)
		expect(history.undo()):toBe(true)
		expect(history.current()):toBe(first)
		expect(history.redo()):toBe(true)
		expect(#history.current().root.children):toBe(2)
		expect(history.redo()):toBe(false)
	end)

	it("isolates nested literals and output arguments across document edits", function()
		local value = sample()
		local nested: Design.Row = { 1, false }
		value = Design.document.change(value, library, "n5", "onActivate", {
			output = "onClose",
			args = { nested },
		})
		local changed = Design.document.change(value, library, "n1", "gap", { literal = 8 })
		local original = assert(value.root.children[3].props.onActivate.args)[1]
		local copied = assert(changed.root.children[3].props.onActivate.args)[1]
		assert(type(original) == "table" and type(copied) == "table")
		copied[1] = 9
		expect(original):toEqual { 1, false }
		expect(nested):toEqual { 1, false }
	end)

	it("emits typed source and reads the same design back", function()
		local value = sample()
		value.contract.inputs[1].required = false
		value.contract.inputs[3].preview = false
		local code = Design.emit(value, library)
		expect(string.find(code, "export type Props", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "title: Toy.Readable<string>?", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "return use(current).name\n", 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, library)
		expect(parsed.contract.inputs[1].required):toBeNil()
		expect(parsed.contract.inputs[3].preview):toBe(false)
		expect(Design.emit(parsed, library)):toBe(code)
		expect(parsed.root.children[2].bind):toEqual { from = "rows", key = "id" }
		expect(parsed.root.children[3].props.onActivate.output):toBe "onClose"
		expect(parsed.root.children[3].props.onActivate.args):toEqual { "back" }
		expect(parsed.root.props.gap.token):toBe "space.m"
	end)

	it("renders bindings, outputs, tokens and keyed templates", function()
		local value = sample()
		local closed: { { Design.Literal } } = {}
		table.clear(built)
		Core.withRootOwner(function()
			Design.render(value, library, {
				outputs = {
					onClose = function(args: { Design.Literal })
						table.insert(closed, args)
					end,
				},
				token = function(name: string): Design.Literal
					return if name == "space.m" then 12 else 0
				end,
			})
			local byKind: { [string]: Built } = {}
			for _, record in built do
				byKind[record.kind] = byKind[record.kind] or record
			end
			expect(byKind.Stack.props.gap.literal):toBe(12)
			expect(byKind.Stack.props.Visible.literal):toBe(true)
			expect(byKind.Label.props.text.literal):toBe "High scores"
			local rows = byKind.List.props.from
			expect(rows.key):toBe "id"
			expect(#assert(rows.rows):peek()):toBe(2)
			local template = assert(byKind.List.props.render.template)
			local sampleRow: Design.Row = { id = "c", name = "Cy" }
			template(Core.cell(sampleRow))
			local text = assert(built[#built].props.text.readable)
			expect(text:peek()):toBe "Cy"
			assert(byKind.Button.props.onActivate.callback)()
			expect(closed):toEqual { { "back" } }
		end)
	end)
	it("switches between prepared slot inputs and authored content without duplicate properties", function()
		local extended = table.clone(library)
		extended.kinds = table.clone(library.kinds)
		extended.kinds.Panel = table.clone(library.kinds.Panel)
		extended.kinds.Panel.fields = { content = { type = "content" }, icon = { type = "content" } }
		local value = Design.document.setContract(Design.document.new("Prepared", extended, "Panel"), extended, {
			inputs = { { id = "body", kind = "value", type = "slot", required = true } },
			outputs = {},
		})
		value = Design.document.insert(value, extended, "n1", "Label")
		local iconId
		value, iconId = Design.document.content(value, extended, "n1", "icon", "Label")
		value = Design.document.change(value, extended, "n1", "content", { input = "body" })
		expect(#value.root.children):toBe(1)
		expect(value.root.children[1].id):toBe(iconId)
		local calls = 0
		local panel = builtNode(Design.render(value, extended, {
			slots = {
				body = function(): unknown
					calls += 1
					return "Prepared"
				end,
			},
		}))
		expect(calls):toBe(0)
		expect(assert(panel.props.content.slot)()):toBe "Prepared"
		expect(calls):toBe(1)
		local code = Design.emit(value, extended)
		expect(string.find(code, "content = props.body", 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, extended), extended)):toBe(code)
		value = Design.document.change(value, extended, "n1", "icon", nil)
		value = Design.document.insert(value, extended, "n1", "Label")
		expect(value.root.props.content):toBe(nil)
		code = Design.emit(value, extended)
		expect(Design.emit(Design.parse(code, extended), extended)):toBe(code)
		value = Design.document.content(value, extended, "n1", "content", "Label")
		expect(#value.root.children):toBe(1)
		code = Design.emit(value, extended)
		expect(Design.emit(Design.parse(code, extended), extended)):toBe(code)
	end)

	it("builds slot content only when the slot is called and reads it back from source", function()
		local value = Design.document.new("Panel", library, "Panel")
		local body
		value, body = Design.document.insert(value, library, "n1", "Label")
		value = Design.document.change(value, library, body, "text", { literal = "Inside" })
		expect(function()
			Design.document.insert(value, library, "n1", "Label")
		end):toThrow()
		table.clear(built)
		local panel = builtNode(Design.render(value, library))
		expect(#built):toBe(1)
		expect(#panel.children):toBe(0)
		local slot = assert(panel.props.content.slot)
		local inside = builtNode(slot())
		expect(inside.kind):toBe "Label"
		expect(inside.props.text.literal):toBe "Inside"
		local code = Design.emit(value, library)
		expect(string.find(code, 'content = function()\n\t\t\treturn UI.Label "Label" {', 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, library)
		expect(parsed.root.children[1].kind):toBe "Label"
		expect(parsed.root.children[1].props.text.literal):toBe "Inside"
	end)

	it("passes item fields as output arguments from a row template", function()
		local value = Design.document.new("Pick", library, "Stack")
		value = Design.document.setContract(value, library, {
			inputs = {
				{ id = "rows", kind = "readable", type = "list", preview = rowsPreview, fields = rowFields },
			},
			outputs = { { id = "onPick" } },
		})
		local list, row
		value, list = Design.document.insert(value, library, "n1", "List")
		value = Design.document.bind(value, library, list, { from = "rows", key = "id" })
		value, row = Design.document.insert(value, library, list, "Button")
		value = Design.document.change(value, library, row, "onActivate", { output = "onPick", fields = { "id" } })
		local picker: string = row
		local current = value
		expect(function()
			Design.document.change(
				current,
				library,
				picker,
				"onActivate",
				{ output = "onPick", fields = { "missing" } }
			)
		end):toThrow "unknown item field missing"
		local picked: { Design.Literal } = {}
		table.clear(built)
		Design.render(value, library, {
			outputs = {
				onPick = function(args: { Design.Literal })
					table.insert(picked, args[1])
				end,
			},
		})
		local listRecord: Built? = nil
		for _, record in built do
			if record.kind == "List" then
				listRecord = record
			end
		end
		local template = assert(assert(listRecord).props.render.template)
		local button = builtNode(template(Core.cell(bo)))
		assert(button.props.onActivate.callback)()
		expect(picked):toEqual { "b" }
		local code = Design.emit(value, library)
		expect(string.find(code, "props.onPick(current:peek().id)", 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, library)):toEqual(value)
	end)

	it("references another node by id through render and source", function()
		local value = Design.document.new("Pulse", library, "Stack")
		local label, flash
		value, label = Design.document.insert(value, library, "n1", "Label")
		value, flash = Design.document.insert(value, library, "n1", "Flash")
		value = Design.document.change(value, library, flash, "target", { node = label })
		local current = value
		local flashId: string = flash
		expect(function()
			Design.document.change(current, library, flashId, "target", { node = "n99" })
		end):toThrow "references unknown node n99"
		expect(function()
			Design.document.change(current, library, flashId, "target", { literal = "n2" })
		end):toThrow "references another node"
		table.clear(built)
		Design.render(value, library)
		local labelRecord: Built? = nil
		local flashRecord: Built? = nil
		for _, record in built do
			if record.kind == "Label" then
				labelRecord = record
			elseif record.kind == "Flash" then
				flashRecord = record
			end
		end
		expect(assert(assert(flashRecord).props.target.node):peek()):toBe(labelRecord)
		local code = Design.emit(value, library)
		expect(
			string.find(
				code,
				"local refs: { [string]: Toy.Cell<Instance?> } = { " .. label .. " = Toy.cell<<Instance?>>(nil) }",
				1,
				true
			) ~= nil
		):toBe(true)
		expect(string.find(code, "local function capture(id: string, node: Instance): Instance", 1, true) ~= nil):toBe(
			true
		)
		expect(string.find(code, `capture(\n\t\t\t"{label}",\n\t\t\tUI.Label "Label"`, 1, true) ~= nil):toBe(true)
		expect(string.find(code, `assert(use(refs.{label}), "Node reference is not captured")`, 1, true) ~= nil):toBe(
			true
		)
		expect(Design.parse(code, library)):toEqual(value)
	end)

	it("reads forward captures after construction and rejects uncaptured node references", function()
		local value = Design.document.new("Forward", library, "Stack")
		local flash, label
		value, flash = Design.document.insert(value, library, "n1", "Flash")
		value, label = Design.document.insert(value, library, "n1", "Label")
		value = Design.document.change(value, library, flash, "target", { node = label })
		local root = builtNode(Design.render(value, library))
		expect(assert(root.children[1].props.target.node):peek()):toBe(root.children[2])
		local missing = builtNode(Design.render(value, library, {
			exclude = function(node: Design.Node): boolean
				return node.id == label
			end,
		}))
		expect(function()
			assert(missing.children[1].props.target.node):peek()
		end):toThrow "Node reference is not captured"
		value = Design.document.setContract(
			value,
			library,
			{ inputs = { { id = "selected", kind = "value", type = "string", required = true } }, outputs = {} }
		)
		value = Design.document.change(value, library, flash, "target", { nodeFrom = "selected", nodes = { label } })
		local unknown = builtNode(Design.render(value, library, { inputs = { selected = "Missing" } }))
		expect(function()
			assert(unknown.children[1].props.target.node):peek()
		end):toThrow "Node reference is not captured"
	end)

	it("names built nodes and names template rows from an item field", function()
		local value = Design.document.new("Roster", library, "Stack")
		value = Design.document.setContract(value, library, {
			inputs = {
				{ id = "rows", kind = "readable", type = "list", preview = rowsPreview, fields = rowFields },
			},
			outputs = {},
		})
		local list, row
		value, list = Design.document.insert(value, library, "n1", "List")
		value = Design.document.bind(value, library, list, { from = "rows", key = "id" })
		value, row = Design.document.insert(value, library, list, "Label")
		value = Design.document.nameFrom(value, library, row, "name")
		local named: string = row
		local current = value
		expect(function()
			Design.document.nameFrom(current, library, named, "missing")
		end):toThrow "unknown item field missing"
		expect(function()
			Design.document.nameFrom(current, library, "n1", "name")
		end):toThrow "outside a collection template"
		table.clear(built)
		local root = builtNode(Design.render(value, library))
		expect(root.name):toBe(value.root.name)
		local listRecord: Built? = nil
		for _, record in built do
			if record.kind == "List" then
				listRecord = record
			end
		end
		local template = assert(assert(listRecord).props.render.template)
		expect(builtNode(template(Core.cell(bo))).name):toBe "Bo"
		local code = Design.emit(value, library)
		expect(string.find(code, "UI.Label(tostring(current:peek().name)) {", 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, library)):toEqual(value)
	end)

	it("emits a named component and reads it back", function()
		local value = sample()
		local code = Design.emit(value, library, { name = "Scores" })
		expect(string.find(code, "local function Scores(UI: Toy.Controls, props: Props): Instance", 1, true) ~= nil):toBe(
			true
		)
		expect(string.find(code, "\nreturn Scores\n", 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, library)):toEqual(Design.parse(Design.emit(value, library), library))
		expect(function()
			Design.emit(value, library, { name = "not a name" })
		end):toThrow "identifier"
	end)

	it("extends a library with game kinds and their prelude", function()
		local extended = Design.extend(library, {
			kinds = {
				Tile = {
					fields = { label = { type = "string" } },
					children = "none",
					call = "Chrome.Tile",
					build = builder "Tile",
				},
			},
			prelude = { 'local Chrome = require("Chrome")', 'local Toy = require("Toy")' },
		})
		expect(extended.kinds.Tile.call):toBe "Chrome.Tile"
		expect(extended.kinds.Label ~= nil):toBe(true)
		expect(library.kinds.Tile):toBe(nil)
		expect(#extended.prelude):toBe(2)
		local value = Design.document.new("Tiles", extended, "Stack")
		value = Design.document.insert(value, extended, "n1", "Tile")
		local code = Design.emit(value, extended)
		expect(string.find(code, 'Chrome.Tile "Tile"', 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, extended).root.children[1].kind):toBe "Tile"
		local perCall: Design.EmitOptions =
			{ name = "Tiles", controls = "local UI = Toy.controls()", localControls = true }
		local scoped = Design.emit(value, extended, perCall)
		expect(
			string.find(scoped, "local function Tiles(props: Props): Instance\n\tlocal UI = Toy.controls()", 1, true)
				~= nil
		):toBe(true)
		expect(string.find(scoped, 'Chrome.Tile "Tile"', 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(scoped, extended), extended, perCall)):toBe(scoped)
		expect(function()
			Design.extend(library, { kinds = { Label = library.kinds.Label } })
		end):toThrow "already has a kind named Label"
	end)

	it("edits through a session that tracks selection, problems and history", function()
		Core.withRootOwner(function()
			local session = Design.session(library, sample())
			session.select "n2"
			expect(session.insert "Label"):toBe(true)
			local inserted = session.selected:peek()
			local _, parent = Design.document.find(session.document:peek().root, inserted)
			expect(assert(parent).id):toBe "n1"
			expect(session.change("text", { input = "missing" })):toBe(false)
			expect(session.problem:peek() ~= nil):toBe(true)
			expect(session.remove()):toBe(true)
			expect(session.selected:peek()):toBe "n1"
			expect(session.canUndo:peek()):toBe(true)
			expect(session.undo()):toBe(true)
			expect(Design.document.find(session.document:peek().root, inserted) ~= nil):toBe(true)
			session.select "n3"
			session.selectRelative "child"
			expect(session.selected:peek()):toBe "n4"
			session.selectRelative "parent"
			session.selectRelative "next"
			expect(session.selected:peek()):toBe "n5"
		end)
	end)

	it("applies several property changes as one undo step", function()
		Core.withRootOwner(function()
			local session = Design.session(library, sample())
			session.select "n1"
			local initial = session.document:peek().root
			expect(session.changeMany { gap = { literal = 12 }, Visible = { literal = false } }):toBe(true)
			local root = session.document:peek().root
			expect(root.props.gap.literal):toBe(12)
			expect(root.props.Visible.literal):toBe(false)
			expect(session.undo()):toBe(true)
			local restored = session.document:peek().root
			expect(restored == initial):toBe(true)
			expect(session.changeMany { missing = { literal = 1 } }):toBe(false)
			expect(session.document:peek().root == restored):toBe(true)
		end)
	end)
end)

type Memory = { store: Design.LinkStore, source: { text: string }, edit: (text: string) -> () }

local function memory(text: string): Memory
	local source = { text = text }
	local listeners: { () -> () } = {}
	local store: Design.LinkStore = {
		read = function(): string
			return source.text
		end,
		write = function(expected: string, generated: string): boolean
			if source.text ~= expected then
				return false
			end
			source.text = generated
			return true
		end,
		watch = function(changed: () -> ()): () -> ()
			table.insert(listeners, changed)
			return function()
				table.clear(listeners)
			end
		end,
	}
	return {
		store = store,
		source = source,
		edit = function(next: string)
			source.text = next
			for _, listener in listeners do
				listener()
			end
		end,
	}
end

describe("Compose Design insert placement", function()
	it("inserts beside a leaf and after the selected control", function()
		Core.withRootOwner(function()
			local session = Design.session(library, Design.document.new("Leaves", library, "Stack"))
			expect(session.insert "Stack"):toBe(true)
			local inner = session.selected:peek()
			session.select "n1"
			expect(session.insert "Label"):toBe(true)
			local last = session.selected:peek()
			session.select(inner)
			library.kinds.Stack.leaf = true
			expect(session.insert "Button"):toBe(true)
			library.kinds.Stack.leaf = nil
			local root = session.document:peek().root
			expect(#root.children):toBe(3)
			expect(root.children[1].id):toBe(inner)
			expect(root.children[2].kind):toBe "Button"
			expect(root.children[3].id):toBe(last)
			expect(#root.children[1].children):toBe(0)
			session.select(root.children[2].id)
			expect(session.insert "Label"):toBe(true)
			expect(session.document:peek().root.children[3].kind):toBe "Label"
			expect(#session.document:peek().root.children):toBe(4)
		end)
	end)
end)

describe("Compose Design clipboard and reorder", function()
	it("copies a subtree, pastes it after a control or into a container, and shifts nodes among siblings", function()
		Core.withRootOwner(function()
			local session = Design.session(library, Design.document.new("Clip", library, "Stack"))
			expect(session.insert "Stack"):toBe(true)
			local inner = session.selected:peek()
			expect(session.insert "Label"):toBe(true)
			session.select(inner)
			expect(session.copy()):toBe(true)
			session.select "n1"
			expect(session.paste()):toBe(true)
			local root = session.document:peek().root
			expect(#root.children):toBe(2)
			expect(root.children[2].kind):toBe "Stack"
			expect(#root.children[2].children):toBe(1)
			expect(root.children[2].id ~= inner):toBe(true)
			expect(root.children[2].children[1].id ~= root.children[1].children[1].id):toBe(true)
			local pasted = session.selected:peek()
			expect(pasted):toBe(root.children[2].id)
			expect(session.shift(-1)):toBe(true)
			root = session.document:peek().root
			expect(root.children[1].id):toBe(pasted)
			expect(session.shift(-1)):toBe(false)
			session.select(root.children[1].children[1].id)
			expect(session.copy()):toBe(true)
			expect(session.paste()):toBe(true)
			expect(#session.document:peek().root.children[1].children):toBe(2)
			session.select "n1"
			expect(session.copy()):toBe(false)
		end)
	end)
end)

describe("Compose Design source link", function()
	it("imports linked source and writes visual edits back", function()
		Core.withRootOwner(function()
			local code = Design.emit(sample(), library)
			local file = memory(code)
			local session = Design.session(library, Design.document.new("Empty", library, "Stack"))
			local link = Design.link(session, file.store)
			expect(link.status:peek()):toBe "synchronized"
			expect(session.document:peek().name):toBe "Scores"
			expect(file.source.text):toBe(code)
			session.select "n1"
			expect(session.change("gap", { literal = 12 })):toBe(true)
			expect(file.source.text ~= code):toBe(true)
			expect(Design.parse(file.source.text, library).root.props.gap.literal):toBe(12)
			link.dispose()
		end)
	end)

	it("follows source edits and refuses to overwrite a changed file", function()
		Core.withRootOwner(function()
			local file = memory(Design.emit(sample(), library))
			local session = Design.session(library, sample())
			local link = Design.link(session, file.store)
			local edited = Design.document.rename(sample(), library, "n1", "Board")
			file.edit(Design.emit(edited, library))
			expect(session.document:peek().root.name):toBe "Board"
			local external = file.source.text
			file.source.text = external .. "\n"
			session.select "n1"
			session.change("gap", { literal = 3 })
			expect(link.status:peek()):toBe "conflict"
			expect(file.source.text):toBe(external .. "\n")
			expect(session.problem:peek() ~= nil):toBe(true)
			expect(link.import()):toBe(true)
			expect(link.status:peek()):toBe "synchronized"
			link.dispose()
		end)
	end)

	it("keeps custom source untouched", function()
		Core.withRootOwner(function()
			local file = memory "return 1"
			local session = Design.session(library, sample())
			local link = Design.link(session, file.store)
			session.select "n1"
			session.change("gap", { literal = 5 })
			expect(link.status:peek()):toBe "custom"
			expect(file.source.text):toBe "return 1"
			link.dispose()
		end)
	end)
end)

local function outputCall(name: string): Design.Literal
	local record: { [string | number]: Design.Literal } = {}
	record["$output"] = name
	return record
end

describe("Compose Design views as code", function()
	local function viewLibrary(): Design.Library
		local copied = table.clone(library)
		copied.show = "Toy.show"
		copied.keyed = "Toy.keyed"
		return copied
	end

	local function view(): (Design.Document, Design.Library)
		local toy = viewLibrary()
		local value = Design.document.new("ChooseGame", toy, "Stack")
		local pickArgs: { Design.InputType } = { "string" }
		local pick: Design.Output = { id = "onPick", args = pickArgs }
		local expanded: Design.State = { id = "expanded", type = "boolean", initial = true }
		value = Design.document.setContract(value, toy, {
			inputs = {
				{ id = "name", kind = "value", type = "string", required = true },
				{ id = "games", kind = "readable", type = "list", fields = rowFields, preview = rowsPreview },
				{ id = "offered", kind = "readable", type = "boolean", preview = false },
			},
			outputs = { pick },
		})
		value = Design.document.setState(value, toy, { expanded })
		value = Design.document.nameFromInput(value, toy, "n1", "name")
		local games, row, offer, toggle
		value, games = Design.document.insert(value, toy, "n1", "Stack")
		value, row = Design.document.insert(value, toy, games, "Label")
		value = Design.document.bind(value, toy, games, { from = "games", key = "id" })
		value = Design.document.change(value, toy, row, "text", { item = "name" })
		value, offer = Design.document.insert(value, toy, "n1", "Label")
		value = Design.document.showWhen(value, toy, offer, "offered")
		value, toggle = Design.document.insert(value, toy, "n1", "Stack")
		value = Design.document.change(value, toy, toggle, "Visible", { state = "expanded" })
		return value, toy
	end

	it("emits a props-only view with typed contract, state and conditional rows", function()
		local value, toy = view()
		local code = Design.emit(value, toy, {
			name = "ChooseGame",
			controls = "local UI = Toy.controls()",
			propsType = "Types.ChooseGameProps",
			prelude = { 'local Types = require("Types")' },
		})
		expect(string.find(code, "local function ChooseGame(props: Types.ChooseGameProps): Instance", 1, true) ~= nil):toBe(
			true
		)
		expect(string.find(code, "local UI = Toy.controls()", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "export type Props", 1, true)):toBe(nil)
		expect(string.find(code, "UI.Stack(props.name) ", 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, toy).root.name):toBe(value.root.name)
		expect(string.find(code, "local state = { expanded = Toy.cell(true) }", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "from = props.games,\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "Toy.show(props.offered, function()\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "Visible = state.expanded", 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, toy)
		expect(parsed.root.nameInput):toBe "name"
		local callback =
			string.gsub(code, "Toy.show%(props.offered,", "Toy.show(function() return props.offered == true end,")
		expect(Design.parse(callback, toy)):toEqual(parsed)
		expect(assert(parsed.root.children[1].bind).from):toBe "games"
		expect(parsed.root.children[2].when):toBe "offered"
		expect(parsed.state and parsed.state[1].id):toBe "expanded"
		expect(Design.emit(parsed, toy, {
			name = "ChooseGame",
			controls = "local UI = Toy.controls()",
			propsType = "Types.ChooseGameProps",
			prelude = { 'local Types = require("Types")' },
		})):toBe(code)
	end)

	it("types required inputs, list rows and output arguments in the emitted props", function()
		local value, toy = view()
		local code = Design.emit(value, toy)
		expect(string.find(code, "\tname: string,", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "export type GamesItem = { id: string, name: string }\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "games: Toy.Readable<{ GamesItem }>?", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "onPick: ((string) -> ())?", 1, true) ~= nil):toBe(true)
	end)

	it("renders bound rows, conditional nodes, state and input names", function()
		local value, toy = view()
		table.clear(built)
		local supplied: { [string]: Design.Literal } = { name = "Picker", offered = false }
		local context: Design.RenderContext = { inputs = supplied }
		local root = builtNode(Design.render(value, toy, context))
		expect(root.name):toBe "Picker"
		expect(#root.children):toBe(2)
		local rows = root.children[1]
		expect(#rows.children):toBe(2)
		local toggle = root.children[2]
		local visible = toggle.props.Visible.readable
		expect(visible ~= nil and visible:peek()):toBe(true)
	end)

	it("writes Roblox datatype literals as constructors and reads them back", function()
		local toy = viewLibrary()
		local boxFields: { [string]: Design.Field } = {
			Size = { type = "datatype", datatype = "UDim2" },
			AutomaticSize = { type = "datatype", datatype = "Enum.AutomaticSize" },
			TextColor3 = { type = "color", datatype = "Color3" },
		}
		toy.kinds = table.clone(toy.kinds)
		toy.kinds.Box = { fields = boxFields, children = "none", call = "UI.Box", build = builder "Box" }
		local value, box = Design.document.insert(Design.document.new("Sized", toy, "Stack"), toy, "n1", "Box")
		local size: Design.Literal = { 1, 0, 0, 48 }
		value = Design.document.change(value, toy, box, "Size", { literal = size })
		value = Design.document.change(value, toy, box, "AutomaticSize", { literal = "Y" })
		value = Design.document.change(value, toy, box, "TextColor3", { literal = "#986325" })
		local code = Design.emit(value, toy)
		expect(string.find(code, "Size = UDim2.new(1, 0, 0, 48)", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "AutomaticSize = Enum.AutomaticSize.Y", 1, true) ~= nil):toBe(true)
		expect(string.find(code, 'TextColor3 = Color3.fromHex "986325"', 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, toy), toy)):toBe(code)
		local short: Design.Literal = { 1, 0 }
		expect(refused(function()
			Design.document.change(value, toy, box, "Size", { literal = short })
		end)):toBe(true)
	end)

	it("names row functions, mixes rows with static children and keeps the header used", function()
		local value, toy = view()
		value = Design.document.bind(value, toy, "n2", { from = "games", key = "id", row = "n3" })
		local archived
		value, archived = Design.document.insert(value, toy, "n2", "Label")
		value = Design.document.change(value, toy, archived, "text", { literal = "Archived" })
		local options: Design.EmitOptions = { name = "ChooseGame", rowFunctions = true }
		local code = Design.emit(value, toy, options)
		expect(string.find(code, "local _design = ", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "export type GamesItem = { id: string, name: string }\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "local function LabelRow(current: Toy.Readable<GamesItem>)", 1, true) ~= nil):toBe(
			true
		)
		expect(string.find(code, "key = function(row: GamesItem): string\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "render = LabelRow,", 1, true) ~= nil):toBe(true)
		expect(string.find(code, 'UI.Label "Label" {', 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, toy)
		expect(#parsed.root.children[1].children):toBe(2)
		expect(Design.emit(parsed, toy, options)):toBe(code)
		table.clear(built)
		local supplied: { [string]: Design.Literal } = { name = "Picker" }
		local context: Design.RenderContext = { inputs = supplied }
		local root = builtNode(Design.render(value, toy, context))
		expect(#(root.children[1]).children):toBe(3)
	end)

	it("preserves dynamic row names through inline and named source round trips", function()
		for _, templated in { false, true } do
			local value, toy = view()
			local row, index = "n3", 1
			if templated then
				value, toy, row, index = sample(), library, "n4", 2
			end
			value = Design.document.rename(value, toy, row, "Letter Row!")
			value = Design.document.nameFrom(value, toy, row, "id")
			for _, rowFunctions in { false, true } do
				local options: Design.EmitOptions = { rowFunctions = rowFunctions }
				local code = Design.emit(value, toy, options)
				local parsed = Design.parse(code, toy)
				expect(parsed.root.children[index].children[1].name):toBe "Letter Row!"
				expect(parsed.root.children[index].children[1].nameField):toBe "id"
				expect(Design.emit(parsed, toy, options)):toBe(code)
			end
		end
	end)

	it("keeps fallback names for optional inputs", function()
		local value, toy = view()
		local contract = Design.document.copy(value).contract
		contract.inputs[1].required = nil
		value = Design.document.setContract(value, toy, contract)
		local code = Design.emit(value, toy)
		expect(string.find(code, 'UI.Stack(props.name or "Stack") ', 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, toy), toy)):toBe(code)
	end)

	it("binds outputs inside literal records and accepts declared extra literal kinds", function()
		local toy = viewLibrary()
		local menuFields: { [string]: Design.Field } = {
			items = { type = "value", also = { "table" } },
			gap = { type = "choice", options = { "s", "m" }, also = { "number" } },
		}
		toy.kinds = table.clone(toy.kinds)
		toy.kinds.Menu = { fields = menuFields, children = "none", call = "UI.Menu", build = builder "Menu" }
		local value, menu = Design.document.insert(Design.document.new("Report", toy, "Stack"), toy, "n1", "Menu")
		local reportArgs: { Design.InputType } = {}
		local report: Design.Output = { id = "onReport", args = reportArgs }
		value = Design.document.setContract(value, toy, { inputs = {}, outputs = { report } })
		local item: { [string | number]: Design.Literal } = { label = "Report" }
		item.onSelect = outputCall "onReport"
		local items: Design.Literal = { item }
		value = Design.document.change(value, toy, menu, "items", { literal = items })
		value = Design.document.change(value, toy, menu, "gap", { literal = 12 })
		local code = Design.emit(value, toy)
		expect(string.find(code, "onSelect = function(...)\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "gap = 12", 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, toy), toy)):toBe(code)
		local handlers: { [string]: (args: { Design.Literal }) -> () } = {
			onReport = function() end,
		}
		local context: Design.RenderContext = { outputs = handlers }
		table.clear(built)
		Design.render(value, toy, context)
		expect(type(built[1].props.items.value)):toBe "table"
		local missing: Design.Literal = { outputCall "onMissing" }
		expect(refused(function()
			Design.document.change(value, toy, menu, "items", { literal = missing })
		end)):toBe(true)
		expect(refused(function()
			Design.document.change(value, toy, menu, "gap", { literal = true })
		end)):toBe(true)
	end)

	it("types table literals, creates controls per call and calls cells without parentheses", function()
		local toy = viewLibrary()
		local pickerFields: { [string]: Design.Field } = {
			options = { type = "value", also = { "table" }, luauType = "{ Toy.Option<string> }" },
		}
		toy.kinds = table.clone(toy.kinds)
		toy.kinds.Picker = { fields = pickerFields, children = "none", call = "UI.Picker", build = builder "Picker" }
		local value, picker = Design.document.insert(Design.document.new("Settings", toy, "Stack"), toy, "n1", "Picker")
		value = Design.document.rename(value, toy, picker, "Difficulty")
		local first: { [string | number]: Design.Literal } = { value = "Medium", label = "Standard" }
		local choices: Design.Literal = { first }
		value = Design.document.change(value, toy, picker, "options", { literal = choices })
		local detent: Design.State = { id = "detent", type = "string", initial = "hug" }
		value = Design.document.setState(value, toy, { detent })
		value = Design.document.change(value, toy, "n1", "gap", { literal = 4 })
		value = Design.document.change(value, toy, picker, "options", { literal = choices })
		local options: Design.EmitOptions =
			{ name = "Settings", controls = "local UI = Toy.controls()", localControls = true }
		local code = Design.emit(value, toy, options)
		local signature = "local function Settings(props: Props): Instance\n\tlocal UI = Toy.controls()\n"
		expect(string.find(code, signature, 1, true) ~= nil):toBe(true)
		expect(
			string.find(
				code,
				'local difficultyOptions: { Toy.Option<string> } = { { label = "Standard", value = "Medium" } }',
				1,
				true
			) ~= nil
		):toBe(true)
		expect(string.find(code, "options = difficultyOptions,", 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, toy), toy, options)):toBe(code)
		local stateful, label = Design.document.insert(value, toy, "n1", "Label")
		stateful = Design.document.change(stateful, toy, label, "text", { state = "detent" })
		local withState = Design.emit(stateful, toy, options)
		expect(string.find(withState, 'local state = { detent = Toy.cell "hug" }', 1, true) ~= nil):toBe(true)
	end)

	it("keeps static children beside a template row", function()
		local value = sample()
		value = Design.document.bind(value, library, "n3", { from = "rows", key = "id", row = "n4" })
		local empty
		value, empty = Design.document.insert(value, library, "n3", "Label")
		value = Design.document.change(value, library, empty, "text", { literal = "No rows yet" })
		local code = Design.emit(value, library)
		expect(string.find(code, 'text = "No rows yet"', 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, library)
		expect(#parsed.root.children[2].children):toBe(2)
		expect(Design.emit(parsed, library)):toBe(code)
		table.clear(built)
		local tokens: Design.RenderContext = {
			token = function(_name: string): Design.Literal
				return 8
			end,
		}
		Design.render(value, library, tokens)
		local list: Built? = nil
		for _, record in built do
			if record.kind == "List" then
				list = record
			end
		end
		expect(#assert(list).children):toBe(1)
	end)

	it("follows a node chosen by name through state", function()
		local toy = viewLibrary()
		local source: Design.State = { id = "source", type = "string", initial = "Stage" }
		local value = Design.document.setState(Design.document.new("Lucky", toy, "Stack"), toy, { source })
		local stage: string, rewards: string, flash: string
		value, stage = Design.document.insert(value, toy, "n1", "Label")
		value = Design.document.rename(value, toy, stage, "Stage")
		value, rewards = Design.document.insert(value, toy, "n1", "Label")
		value = Design.document.rename(value, toy, rewards, "Rewards")
		value, flash = Design.document.insert(value, toy, "n1", "Flash")
		value = Design.document.change(value, toy, flash, "target", { nodeFrom = "source", nodes = { stage, rewards } })
		local code = Design.emit(value, toy)
		expect(
			string.find(
				code,
				"local named: { [string]: Toy.Readable<Instance?> } = { Rewards = refs.n3, Stage = refs.n2 }",
				1,
				true
			) ~= nil
		):toBe(true)
		expect(string.find(code, "local chosen = named[use(state.source)]", 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, toy), toy)):toBe(code)
		table.clear(built)
		Design.render(value, toy)
		local target: Built? = nil
		local chosen: unknown = nil
		for _, record in built do
			if record.kind == "Flash" then
				local resolved = record.props.target.node
				chosen = if resolved then resolved:peek() else nil
			elseif record.name == "Stage" then
				target = record
			end
		end
		expect(chosen == target and target ~= nil):toBe(true)
		local unknownState: Design.Value = { nodeFrom = "missing", nodes = { stage } }
		expect(refused(function()
			Design.document.change(value, toy, flash, "target", unknownState)
		end)):toBe(true)
	end)

	it("refuses conditions, names and state the contract cannot back", function()
		local value, toy = view()
		expect(refused(function()
			Design.document.showWhen(value, toy, "n4", "name")
		end)):toBe(true)
		expect(refused(function()
			Design.document.nameFromInput(value, toy, "n1", "games")
		end)):toBe(true)
		expect(refused(function()
			Design.document.change(value, toy, "n2", "gap", { state = "missing" })
		end)):toBe(true)
		expect(refused(function()
			Design.document.showWhen(value, library, "n4", "offered")
		end)):toBe(true)
	end)
end)

describe("Compose Design selection sets", function()
	local function siblings(): Design.Document
		local value = Design.document.new("Selection", library, "Stack")
		for _ = 1, 4 do
			value = Design.document.insert(value, library, "n1", "Label")
		end
		return value
	end

	it("toggles, ranges and clears an ordered selection without adding history", function()
		Core.withRootOwner(function()
			local session = Design.session(library, siblings())
			session.select "n2"
			session.select("n4", "toggle")
			expect(session.selection:peek()):toEqual { "n2", "n4" }
			session.select("n2", "toggle")
			expect(session.selection:peek()):toEqual { "n4" }
			session.select "n2"
			session.select("n5", "range")
			expect(session.selection:peek()):toEqual { "n2", "n3", "n4", "n5" }
			session.select("n3", "range")
			expect(session.selection:peek()):toEqual { "n2", "n3" }
			session.selectMany { "n5", "missing", "n2", "n2" }
			expect(session.selection:peek()):toEqual { "n2", "n5" }
			session.selectMany {}
			expect(session.selected:peek()):toBe ""
			expect(session.selection:peek()):toEqual {}
			expect(session.canUndo:peek()):toBe(false)
		end)
	end)

	it("changes every selected node atomically and restores the selection through undo and redo", function()
		Core.withRootOwner(function()
			local session = Design.session(library, siblings())
			session.selectMany { "n2", "n4" }
			local before = session.document:peek()
			expect(session.change("text", { literal = "Together" })):toBe(true)
			local after = session.document:peek()
			expect(after.root.children[1].props.text.literal):toBe "Together"
			expect(after.root.children[3].props.text.literal):toBe "Together"
			expect(after.root.children[2].props.text.literal):toBe "Label"
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(before)
			expect(session.selection:peek()):toEqual { "n2", "n4" }
			expect(session.canUndo:peek()):toBe(false)
			expect(session.redo()):toBe(true)
			expect(session.document:peek()):toBe(after)
			session.selectMany { "n2", "n1" }
			expect(session.change("text", { literal = "Refused" })):toBe(false)
			expect(session.document:peek()):toBe(after)
		end)
	end)

	it("duplicates, copies, pastes and deletes forests in one step per command", function()
		Core.withRootOwner(function()
			local session = Design.session(library, siblings())
			session.selectMany { "n2", "n4" }
			local before = session.document:peek()
			expect(session.duplicate()):toBe(true)
			expect(#session.document:peek().root.children):toBe(6)
			expect(session.selection:peek()):toEqual { "n6", "n7" }
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(before)
			expect(session.selection:peek()):toEqual { "n2", "n4" }
			expect(session.redo()):toBe(true)
			expect(session.copy()):toBe(true)
			session.select "n1"
			local copied = session.document:peek()
			expect(session.paste()):toBe(true)
			expect(#session.document:peek().root.children):toBe(8)
			expect(#session.selection:peek()):toBe(2)
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(copied)
			expect(session.redo()):toBe(true)
			local pasted = session.document:peek()
			expect(session.remove()):toBe(true)
			expect(#session.document:peek().root.children):toBe(6)
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(pasted)
			expect(#session.selection:peek()):toBe(2)
			expect(session.redo()):toBe(true)
			expect(#session.document:peek().root.children):toBe(6)
		end)
	end)

	it("moves and reorders selected siblings in document order with atomic refusals", function()
		Core.withRootOwner(function()
			local session = Design.session(library, siblings())
			session.selectMany { "n4", "n3" }
			local before = session.document:peek()
			expect(session.shift(-1)):toBe(true)
			local moved = session.document:peek()
			expect(moved.root.children[1].id):toBe "n3"
			expect(moved.root.children[2].id):toBe "n4"
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(before)
			expect(session.redo()):toBe(true)
			expect(session.shift(-1)):toBe(false)
			expect(session.document:peek()):toBe(moved)
			expect(session.move("n3", "n1", 3)):toBe(true)
			expect(session.document:peek().root.children[3].id):toBe "n3"
			expect(session.document:peek().root.children[4].id):toBe "n4"
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(moved)
			expect(session.redo()):toBe(true)
			expect(session.move("n3", "n4")):toBe(false)
			expect(session.document:peek().root.children[3].id):toBe "n3"
		end)
	end)

	it("wraps noncontiguous siblings at the first position and unwraps in order", function()
		Core.withRootOwner(function()
			local session = Design.session(library, siblings())
			session.selectMany { "n4", "n2" }
			local before = session.document:peek()
			expect(session.wrap()):toBe(true)
			local wrapped = session.document:peek()
			local container = wrapped.root.children[1]
			expect(container.kind):toBe "Stack"
			expect(container.children[1].id):toBe "n2"
			expect(container.children[2].id):toBe "n4"
			expect(wrapped.root.children[2].id):toBe "n3"
			expect(session.selection:peek()):toEqual { container.id }
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(before)
			expect(session.selection:peek()):toEqual { "n2", "n4" }
			expect(session.redo()):toBe(true)
			expect(session.unwrap()):toBe(true)
			expect(session.selection:peek()):toEqual { "n2", "n4" }
			expect(session.document:peek().root.children[2].id):toBe "n4"
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(wrapped)
			expect(session.redo()):toBe(true)
			local code = Design.emit(session.document:peek(), library)
			expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		end)
	end)

	it("normalizes overlapping selections and refuses invalid wrap and unwrap without history", function()
		Core.withRootOwner(function()
			local value, container = Design.document.insert(siblings(), library, "n1", "Stack")
			local child
			value, child = Design.document.insert(value, library, container, "Label")
			local session = Design.session(library, value)
			session.selectMany { container, child }
			expect(session.copy()):toBe(true)
			expect(session.remove()):toBe(true)
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(value)
			session.selectMany { "n2", child }
			expect(session.wrap()):toBe(false)
			expect(session.document:peek()):toBe(value)
			expect(session.canUndo:peek()):toBe(false)
			session.select "n2"
			expect(session.unwrap()):toBe(false)
			session.select "n1"
			expect(session.wrap()):toBe(false)
			expect(session.unwrap()):toBe(false)
			expect(session.document:peek()):toBe(value)
		end)
	end)

	it("remaps references across a copied selection and keeps failed group edits out of history", function()
		Core.withRootOwner(function()
			local value, target = Design.document.insert(siblings(), library, "n1", "Flash")
			value = Design.document.change(value, library, target, "target", { node = "n2" })
			local session = Design.session(library, value)
			session.selectMany { "n2", target }
			expect(session.duplicate()):toBe(true)
			local selection = session.selection:peek()
			local flash = assert(Design.document.find(session.document:peek().root, selection[2]), "Flash")
			expect(flash.props.target.node):toBe(selection[1])
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(value)
			expect(session.copy()):toBe(true)
			session.select "n1"
			expect(session.paste()):toBe(true)
			selection = session.selection:peek()
			flash = assert(Design.document.find(session.document:peek().root, selection[2]), "Flash")
			expect(flash.props.target.node):toBe(selection[1])
			expect(session.undo()):toBe(true)
			session.selectMany { "n2", target }
			expect(session.remove()):toBe(true)
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(value)
			session.select "n2"
			expect(session.remove()):toBe(false)
			expect(session.document:peek()):toBe(value)
			expect(session.canUndo:peek()):toBe(false)
		end)
	end)

	it("keeps hidden and locked flags in the header across edits, history and source round trips", function()
		Core.withRootOwner(function()
			local session = Design.session(library, siblings())
			local before = session.document:peek()
			expect(session.hide("n3", true)):toBe(true)
			local hidden = session.document:peek()
			expect(session.lock("n3", true)):toBe(true)
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(hidden)
			expect(session.redo()):toBe(true)
			session.select "n3"
			expect(session.rename "HiddenLabel"):toBe(true)
			local code = Design.emit(session.document:peek(), library)
			local parsed = Design.parse(code, library)
			expect(parsed.root.children[2].hidden):toBe(true)
			expect(parsed.root.children[2].locked):toBe(true)
			expect(parsed.root.children[2].name):toBe "HiddenLabel"
			expect(parsed.root.children[2].props.text.literal):toBe "Label"
			expect(Design.emit(parsed, library)):toBe(code)
			table.clear(built)
			Design.render(parsed, library)
			expect(#built):toBe(5)
			table.clear(built)
			Design.render(parsed, library, {
				exclude = function(node: Design.Node): boolean
					return node.hidden == true
				end,
			})
			expect(#built):toBe(4)
			expect(session.undo()):toBe(true)
			expect(session.undo()):toBe(true)
			expect(session.undo()):toBe(true)
			expect(session.document:peek()):toBe(before)
		end)
	end)

	it("attaches editor flags to their content fields when source orders templates differently", function()
		Core.withRootOwner(function()
			local extended = Design.extend(library, {
				kinds = {
					Pair = {
						fields = { left = { type = "content" }, right = { type = "content" } },
						children = "list",
						call = "UI.Pair",
						build = builder "Pair",
					},
				},
			})
			local value, right = Design.document.content(
				Design.document.new("Slots", extended, "Pair"),
				extended,
				"n1",
				"right",
				"Label"
			)
			local left
			value, left = Design.document.content(value, extended, "n1", "left", "Label")
			value = Design.document.rename(value, extended, right, "Right")
			value = Design.document.rename(value, extended, left, "Left")
			local session = Design.session(extended, value)
			expect(session.hide(right, true)):toBe(true)
			expect(session.lock(left, true)):toBe(true)
			local code = Design.emit(session.document:peek(), extended)
			local parsed = Design.parse(code, extended)
			for _, node in parsed.root.children do
				expect(node.hidden == true):toBe(node.name == "Right")
				expect(node.locked == true):toBe(node.name == "Left")
			end
			expect(Design.emit(parsed, extended)):toBe(code)
		end)
	end)
end)

return nil
