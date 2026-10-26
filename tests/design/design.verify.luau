--!strict

local Design = require "../../src/design"
local Core = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Built = { kind: string, props: { [string]: Design.Resolved }, children: { unknown } }

local built: { Built } = {}

local function builder(kind: string): (props: { [string]: Design.Resolved }, children: { unknown }) -> unknown
	return function(props: { [string]: Design.Resolved }, children: { unknown }): unknown
		local record: Built = { kind = kind, props = props, children = children }
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
		expect(string.find(code, "function(use) return use(current).name end", 1, true) ~= nil):toBe(true)
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
		expect(string.find(code, 'content = function() return UI.Label "Label" {', 1, true) ~= nil):toBe(true)
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

return nil
