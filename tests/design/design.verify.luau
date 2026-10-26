--!strict

local Design = require "../../src/design"
local Core = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Built = { kind: string, props: { [string]: Design.Resolved }, children: { unknown }, name: string }

local built: { Built } = {}

local function builder(
	kind: string
): (props: { [string]: Design.Resolved }, children: { unknown }, name: string) -> unknown
	return function(props: { [string]: Design.Resolved }, children: { unknown }, name: string): unknown
		local record: Built = { kind = kind, props = props, children = children, name = name }
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
		local columnsField: Design.Field = { type = "value" }
		local actionsField: Design.Field = { type = "value", perRow = true }
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
			outputs = { { id = "onChoose" } },
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
		local _, itemTypes = string.gsub(code, "\ntype %w+Item = ", "")
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
		local cells = made.props.columns.value :: Cells
		cells[1].render(Core.cell(alpha))
		expect(built[1].kind):toBe "Label"
		local rowActions = made.props.actions.value :: Actions
		rowActions(Core.cell(alpha))[1].onActivate()
		expect(chosen[1]):toBe(alpha)
		library.kinds = kinds
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

	it("emits typed source and reads the same design back", function()
		local value = sample()
		local code = Design.emit(value, library)
		expect(string.find(code, "export type Props", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "title: Toy.Readable<string>?", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "return use(current).name\n", 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, library)
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
	it("builds slot content only when the slot is called and reads it back from source", function()
		local value = Design.document.new("Panel", library, "Panel")
		local body
		value, body = Design.document.insert(value, library, "n1", "Label")
		value = Design.document.change(value, library, body, "text", { literal = "Inside" })
		expect(function()
			Design.document.insert(value, library, "n1", "Label")
		end):toThrow()
		table.clear(built)
		local panel = Design.render(value, library) :: Built
		expect(#built):toBe(1)
		expect(#panel.children):toBe(0)
		local slot = assert(panel.props.content.slot)
		local inside = slot() :: Built
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
		local button = template(Core.cell(bo)) :: Built
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
		expect(string.find(code, "local refs = { " .. label .. " = Toy.cell(nil) }", 1, true) ~= nil):toBe(true)
		expect(string.find(code, `capture(\n\t\t\t"{label}",\n\t\t\tUI.Label "Label"`, 1, true) ~= nil):toBe(true)
		expect(string.find(code, `target = refs.{label},`, 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, library)):toEqual(value)
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
		local root = Design.render(value, library) :: Built
		expect(root.name):toBe(value.root.name)
		local listRecord: Built? = nil
		for _, record in built do
			if record.kind == "List" then
				listRecord = record
			end
		end
		local template = assert(assert(listRecord).props.render.template)
		expect((template(Core.cell(bo)) :: Built).name):toBe "Bo"
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
		expect(string.find(code, "UI.Stack(props.name) {", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "local state = { expanded = Toy.cell(true) }", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "from = props.games,\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "Toy.show(props.offered, function()\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "Visible = state.expanded", 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, toy)
		expect(parsed.root.nameInput):toBe "name"
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
		expect(string.find(code, "games: Toy.Readable<{ { id: string, name: string } }>?", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "onPick: ((string) -> ())?", 1, true) ~= nil):toBe(true)
	end)

	it("renders bound rows, conditional nodes, state and input names", function()
		local value, toy = view()
		table.clear(built)
		local supplied: { [string]: Design.Literal } = { name = "Picker", offered = false }
		local context: Design.RenderContext = { inputs = supplied }
		local root = Design.render(value, toy, context) :: Built
		expect(root.name):toBe "Picker"
		expect(#root.children):toBe(2)
		local rows = root.children[1] :: Built
		expect(#rows.children):toBe(2)
		local toggle = root.children[2] :: Built
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
		expect(string.find(code, "type LabelRowItem = { id: string, name: string }\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "local function LabelRow(current: Toy.Readable<LabelRowItem>)", 1, true) ~= nil):toBe(
			true
		)
		expect(string.find(code, "key = function(row: LabelRowItem): string\n", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "render = LabelRow,", 1, true) ~= nil):toBe(true)
		expect(string.find(code, 'UI.Label "Label" {', 1, true) ~= nil):toBe(true)
		local parsed = Design.parse(code, toy)
		expect(#parsed.root.children[1].children):toBe(2)
		expect(Design.emit(parsed, toy, options)):toBe(code)
		table.clear(built)
		local supplied: { [string]: Design.Literal } = { name = "Picker" }
		local context: Design.RenderContext = { inputs = supplied }
		local root = Design.render(value, toy, context) :: Built
		expect(#(root.children[1] :: Built).children):toBe(3)
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
		expect(string.find(code, "local named = { Rewards = refs.n3, Stage = refs.n2 }", 1, true) ~= nil):toBe(true)
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

return nil
