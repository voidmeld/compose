--!strict

local fs = require "@std/fs"
local process = require "@lute/process"
local Design = require "../../src/design"
local Core = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function build(_props: { [string]: Design.Resolved }, _children: { unknown }, _name: string): unknown
	return nil
end

local library: Design.Library = {
	name = "Typed",
	parameter = "UI",
	parameterType = "Controls",
	prelude = {
		'local Core = require "../src/core"',
		"type Target = { name: string }",
		"type Tags = { string }",
		'type Choice = { id: string, kind: "button" | "notice" | "stack", text: string, tags: Tags }',
		"type PageRecord = { label: string, content: () -> Target }",
		"type Row = { id: string }",
		"type Page = { id: string, rows: { Row } }",
		"type Dimension = { x: number, y: number }",
		"type Controls = {",
		"\tBox: (string) -> ({ [number]: (Target | (() -> Target))?, Size: Core.Input<Dimension>? }) -> Target,",
		"\tButton: (string) -> ({ label: Core.Input<string> }) -> Target,",
		"\tNotice: (string) -> ({ text: Core.Input<string> }) -> Target,",
		"\tBook: (string) -> ({ pages: { PageRecord } }) -> Target,",
		"\ttag: (Target, Core.Input<string | Tags>) -> Target,",
		"\tFlash: (string) -> ({ target: Core.Source<Target> }) -> Target,",
		"\tTrailing: (string) -> ({ item: Target }) -> Target,",
		"\tPanel: (string) -> ({ content: () -> Target }) -> Target,",
		"\tPages: (",
		"\t\tstring",
		"\t) -> ({ from: Core.Source<{ Page }>, key: string, render: (Core.ReadOnlyValue<Page>) -> Target }) -> Target,",
		"\tRows: (",
		"\t\tstring",
		"\t) -> ({ from: Core.Source<{ Row }>, key: string, render: (Core.ReadOnlyValue<Row>) -> Target }) -> Target,",
		"\tChoices: (",
		"\t\tstring",
		"\t) -> ({ from: Core.Source<{ Choice }>, key: string, render: (Core.ReadOnlyValue<Choice>) -> Target }) -> Target,",
		"}",
	},
	returnType = "Target",
	readable = "Core.ReadOnlyValue",
	cell = "Core.Value",
	newCell = "Core.cell",
	tags = { call = "UI.tag", apply = function() end },
	kinds = {
		Box = {
			fields = { Size = { type = "datatype", datatype = "UDim2" } },
			children = "list",
			call = "UI.Box",
			build = build,
		},
		Flash = { fields = { target = { type = "node" } }, children = "none", call = "UI.Flash", build = build },
		Trailing = {
			fields = { item = { type = "value", luauType = "Target" } },
			children = "none",
			call = "UI.Trailing",
			build = build,
		},
		Button = { fields = { label = { type = "string" } }, children = "none", call = "UI.Button", build = build },
		Notice = { fields = { text = { type = "string" } }, children = "none", call = "UI.Notice", build = build },
		Book = {
			fields = { pages = { type = "value", luauType = "{ PageRecord }" } },
			children = "none",
			call = "UI.Book",
			build = build,
		},
		Panel = { fields = {}, children = "slot", slot = "content", call = "UI.Panel", build = build },
		Pages = {
			fields = {},
			children = "template",
			source = "from",
			key = "key",
			template = "render",
			call = "UI.Pages",
			build = build,
		},
		Rows = {
			fields = {},
			children = "template",
			source = "from",
			key = "key",
			template = "render",
			call = "UI.Rows",
			build = build,
		},
		Choices = {
			fields = {},
			children = "template",
			source = "from",
			key = "key",
			template = "render",
			call = "UI.Choices",
			build = build,
		},
	},
}

local function analyze(code: string)
	fs.createDirectory(".worker-tmp", { makeParents = true })
	local path = ".worker-tmp/design-source-emitted.luau"
	fs.writeStringToFile(path, code)
	local result = process.run {
		"luau-lsp",
		"analyze",
		"--flag:LuauSolverV2=true",
		"--platform=standard",
		"--base-luaurc=.luaurc",
		path,
	}
	expect(string.find(result.stdout .. result.stderr, "TypeError", 1, true)):toBeNil()
	expect(result.ok):toBe(true)
end

local function canonical(code: string)
	fs.createDirectory(".worker-tmp", { makeParents = true })
	local path = ".worker-tmp/design-source-format.luau"
	fs.writeStringToFile(path, code)
	local result = process.run { "stylua", path }
	expect(result.ok):toBe(true)
	expect(fs.readFileToString(path)):toBe(code)
end

describe("Design emitted source", function()
	it("types and round trips ordered row actions and executes the emitted callbacks", function()
		local typed = table.clone(library)
		typed.prelude = {
			'local Core = require "../src/core"',
			"type Row = { id: string }",
			"type Target = { name: string }",
			"type InputProps = { onChange: (string) -> (), onFocus: () -> (), onMixed: (string, boolean) -> () }",
			"type Controls = {",
			"\tInput: (string) -> (InputProps) -> Target,",
			"\tRows: (",
			"\t\tstring",
			"\t) -> ({ from: Core.Source<{ Row }>, key: string, render: (Core.ReadOnlyValue<Row>) -> Target }) -> Target,",
			"}",
		}
		typed.kinds = table.clone(library.kinds)
		local inputKind: Design.Kind = {
			fields = { onChange = { type = "event" }, onFocus = { type = "event" }, onMixed = { type = "event" } },
			children = "none",
			call = "UI.Input",
			build = build,
		}
		typed.kinds.Input = inputKind
		local value = Design.document.setContract(Design.document.new("Editable", typed, "Rows"), typed, {
			inputs = {
				{
					id = "rows",
					kind = "readable",
					type = "list",
					required = true,
					fields = { { id = "id", type = "string" } },
				},
			},
			outputs = {
				{ id = "onChange", args = { "string", "string" } },
				{ id = "onFocus", args = { "string" } },
				{ id = "onMixed", args = { "boolean", "string", "string" } },
			},
		})
		value = Design.document.bind(value, typed, "n1", { from = "rows", key = "id" })
		value = Design.document.insert(value, typed, "n1", "Input")
		local actions: { [string]: { Design.ActionArgument } } = {
			onChange = { { item = "id" }, { event = 1 } },
			onFocus = { { item = "id" } },
			onMixed = { { event = 2 }, { item = "id" }, { event = 1 } },
		}
		for name, arguments in actions do
			value = Design.document.change(value, typed, "n2", name, { output = name, arguments = arguments })
		end
		local code = Design.emit(value, typed)
		expect(Design.emit(Design.parse(code, typed), typed)):toBe(code)
		analyze(code)
		canonical(code)
		fs.writeStringToFile(".worker-tmp/typed-row.luau", code)
		fs.writeStringToFile(
			".worker-tmp/typed-row-run.luau",
			[[
--!strict
local Core = require "../src/core"
local editable = require "./typed-row"
local calls = {}
local row = Core.cell { id = "stable" }
local input
editable({
    Rows = function(name)
        return function(props)
            props.render(row)
            return { name = name }
        end
    end,
    Input = function(name)
        return function(props)
            input = props
            return { name = name }
        end
    end,
}, {
    rows = Core.cell { { id = "stable" } },
    onChange = function(key, text) table.insert(calls, { key, text }) end,
    onFocus = function(key) table.insert(calls, { key }) end,
    onMixed = function(flag, key, text) table.insert(calls, { flag, key, text }) end,
})
assert(input)
input.onChange("new")
input.onFocus()
input.onMixed("changed", false)
row:set { id = "retained" }
input.onChange("again")
assert(calls[1][1] == "stable" and calls[1][2] == "new")
assert(calls[2][1] == "stable" and #calls[2] == 1)
assert(calls[3][1] == false and calls[3][2] == "stable" and calls[3][3] == "changed")
assert(calls[4][1] == "retained" and calls[4][2] == "again")
]]
		)
		local ran = process.run { "lute", "run", ".worker-tmp/typed-row-run.luau" }
		expect(ran.ok, ran.stdout .. ran.stderr):toBe(true)
	end)

	it("round trips typed imported components with named slots without expanding their trees", function()
		local nested = Design.document.setContract(Design.document.new("Reusable", library, "Box"), library, {
			inputs = {
				{ id = "name", kind = "value", type = "string", required = true },
				{ id = "text", kind = "readable", type = "string", required = true },
				{ id = "body", kind = "value", type = "slot" },
			},
			outputs = {},
		})
		nested.root.nameInput = "name"
		nested = Design.document.insert(nested, library, "n1", "Button")
		nested = Design.document.change(nested, library, "n2", "label", { input = "text" })
		nested = Design.document.insertSlot(nested, library, "n1", "body")
		local nestedCode = Design.emit(nested, library)
		canonical(nestedCode)
		analyze(nestedCode)
		local imported = Design.imports(library, {
			Reusable = {
				source = Core.cell(nestedCode),
				call = "ReusableRow",
				prelude = {
					"local function ReusableRow(",
					"\t_ui: Controls,",
					"\tprops: { name: string, text: Core.ReadOnlyValue<string>, body: (() -> Target)? }",
					"): Target",
					"\treturn { name = props.name }",
					"end",
				},
			},
		})
		local assembly = Design.document.setContract(Design.document.new("Assembly", imported, "Box"), imported, {
			inputs = { { id = "text", kind = "readable", type = "string", required = true } },
			outputs = {},
		})
		for _, name in { "Left", "Right" } do
			local id
			assembly, id = Design.document.insert(assembly, imported, "n1", "Reusable")
			assembly = Design.document.rename(assembly, imported, id, name)
			assembly = Design.document.change(assembly, imported, id, "text", { input = "text" })
			assembly = Design.document.content(assembly, imported, id, "body", "Box")
		end
		local code = Design.emit(assembly, imported)
		expect(string.find(code, "ReusableRow(UI, {", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "label =", 1, true)):toBeNil()
		expect(Design.emit(Design.parse(code, imported), imported)):toBe(code)
		expect(Design.emit(Design.parse(nestedCode, library), library)):toBe(nestedCode)
		canonical(code)
		analyze(code)
		local rows = Design.document.setContract(Design.document.new("Rows", imported, "Choices"), imported, {
			inputs = {
				{ id = "text", kind = "readable", type = "string", required = true },
				{
					id = "rows",
					kind = "readable",
					type = "list",
					required = true,
					fields = {
						{ id = "id", type = "string" },
						{ id = "kind", type = "string", options = { "button", "notice", "stack" } },
						{ id = "text", type = "string" },
						{ id = "tags", type = "list", luauType = "Tags" },
					},
				},
			},
			outputs = {},
		})
		rows = Design.document.bind(rows, imported, "n1", { from = "rows", key = "id" })
		rows = Design.document.insert(rows, imported, "n1", "Reusable")
		rows = Design.document.change(rows, imported, "n2", "text", { input = "text" })
		rows.root.children[1].nameField = "id"
		for _, named in { false, true } do
			local options: Design.EmitOptions = { rowFunctions = named }
			local rowCode = Design.emit(rows, imported, options)
			expect(Design.emit(Design.parse(rowCode, imported), imported, options)):toBe(rowCode)
			canonical(rowCode)
			analyze(rowCode)
		end
	end)

	it("strictly types one authored node passed directly to a value field", function()
		local value, child = Design.document.content(
			Design.document.new("Navigation", library, "Trailing"),
			library,
			"n1",
			"item",
			"Button"
		)
		value = Design.document.change(value, library, child, "label", { literal = "Next" })
		local code = Design.emit(value, library)
		expect(string.find(code, 'item = UI.Button "Button"', 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		canonical(code)
		analyze(code)
	end)

	it("strictly types native constructors with prepared static and reactive input components", function()
		local value = Design.document.setContract(Design.document.new("Components", library, "Box"), library, {
			inputs = {
				{ id = "offset", kind = "value", type = "number", required = true },
				{ id = "rise", kind = "readable", type = "number", required = true },
			},
			outputs = {},
		})
		value = Design.document.change(
			value,
			library,
			"n1",
			"Size",
			{ literal = Design.datatype.literal { 1, { input = "offset" }, 0, { input = "rise" } } }
		)
		local options: Design.EmitOptions = {
			prelude = {
				"local UDim2 = { new = function(_xs: number, xo: number, _ys: number, yo: number): Dimension return { x = xo, y = yo } end }",
			},
		}
		local code = Design.emit(value, library, options)
		expect(Design.parse(code, library)):toEqual(value)
		expect(Design.emit(Design.parse(code, library), library, options)):toBe(code)
		analyze(code)
	end)

	it("strictly types qualified outer row lists in inline and named row functions", function()
		local fields: { Design.ItemField } = { { id = "id", type = "string" } }
		local pageFields: { Design.ItemField } =
			{ { id = "id", type = "string" }, { id = "rows", type = "list", fields = fields } }
		local value = Design.document.setContract(Design.document.new("Nested", library, "Pages"), library, {
			inputs = { { id = "pages", kind = "readable", type = "list", fields = pageFields, required = true } },
			outputs = {},
		})
		value = Design.document.bind(value, library, "n1", { from = "pages", key = "id" })
		local page, rows
		value, page = Design.document.insert(value, library, "n1", "Box")
		value, rows = Design.document.insert(value, library, page, "Rows")
		value = Design.document.bind(value, library, rows, { from = "pages.rows", key = "id" })
		value = Design.document.insert(value, library, rows, "Box")
		for _, rowFunctions in { false, true } do
			local options: Design.EmitOptions = { rowFunctions = rowFunctions }
			local code = Design.emit(value, library, options)
			expect(Design.emit(Design.parse(code, library), library, options)):toBe(code)
			analyze(code)
		end
	end)

	it("strictly types both static root wrappers around one shared content function", function()
		local value = Design.document.setContract(Design.document.new("Roots", library, "Box"), library, {
			inputs = {
				{
					id = "presentation",
					kind = "value",
					type = "string",
					options = { "inline", "panel" },
					required = true,
				},
			},
			outputs = {},
		})
		value = Design.document.insert(value, library, "n1", "Box")
		value = Design.document.setRootVariant(
			value,
			library,
			{ input = "presentation", value = "panel", kind = "Panel", props = {} }
		)
		local code = Design.emit(value, library)
		expect(Design.parse(code, library)):toEqual(value)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		analyze(code)
	end)

	it("strictly types forward node references and selected node bindings without casts", function()
		local value = Design.document.setContract(Design.document.new("References", library, "Box"), library, {
			inputs = { { id = "selected", kind = "readable", type = "string", required = true } },
			outputs = {},
		})
		local flash, target, selected
		value, flash = Design.document.insert(value, library, "n1", "Flash")
		value, target = Design.document.insert(value, library, "n1", "Box")
		value, selected = Design.document.insert(value, library, "n1", "Flash")
		value = Design.document.change(value, library, flash, "target", { node = target })
		value =
			Design.document.change(value, library, selected, "target", { nodeFrom = "selected", nodes = { target } })
		local code = Design.emit(value, library)
		expect(Design.parse(code, library)):toEqual(value)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		expect(string.find(code, "::", 1, true)):toBeNil()
		analyze(code)
	end)

	it("emits two typed reference cells with formatter stable bytes", function()
		local typed = table.clone(library)
		typed.returnType = "CapturedTarget"
		typed.prelude = table.clone(library.prelude)
		table.insert(typed.prelude, "type CapturedTarget = Target")
		local value = Design.document.new("References", typed, "Box")
		for _ = 1, 2 do
			local flash, target
			value, flash = Design.document.insert(value, library, "n1", "Flash")
			value, target = Design.document.insert(value, library, "n1", "Box")
			value = Design.document.change(value, library, flash, "target", { node = target })
		end
		local code = Design.emit(value, typed)
		expect(Design.parse(code, typed)):toEqual(value)
		expect(Design.emit(Design.parse(code, typed), typed)):toBe(code)
		canonical(code)
		analyze(code)
	end)

	it("strictly types distinct root content trees with formatter stable bytes", function()
		local value = Design.document.setContract(Design.document.new("Roots", library, "Box"), library, {
			inputs = {
				{
					id = "presentation",
					kind = "value",
					type = "string",
					options = { "inline", "panel" },
					required = true,
				},
			},
			outputs = {},
		})
		value = Design.document.insert(value, library, "n1", "Box")
		value = Design.document.insert(value, library, "n2", "Box")
		value.nextId = 5
		value = Design.document.setRootVariant(value, library, {
			input = "presentation",
			value = "panel",
			kind = "Panel",
			props = {},
			children = {
				{ id = "n4", kind = "Box", name = "Plain", props = {}, children = {}, hidden = true, locked = true },
			},
		})
		local code = Design.emit(value, library)
		expect(Design.parse(code, library)):toEqual(value)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		canonical(code)
		analyze(code)
	end)

	it("strictly types enum row roots and bound item tags in inline and named rows", function()
		local fields: { Design.ItemField } = {
			{ id = "id", type = "string" },
			{ id = "kind", type = "string", options = { "button", "notice", "stack" } },
			{ id = "text", type = "string" },
			{ id = "tags", type = "list", luauType = "Tags" },
		}
		local value = Design.document.setContract(Design.document.new("Rows", library, "Choices"), library, {
			inputs = { { id = "rows", kind = "readable", type = "list", fields = fields, required = true } },
			outputs = {},
		})
		value = Design.document.bind(value, library, "n1", { from = "rows", key = "id" })
		value = Design.document.insert(value, library, "n1", "Button")
		value = Design.document.change(value, library, "n2", "label", { item = "text" })
		value.root.children[1].nameField = "id"
		value = Design.document.bindTags(value, library, "n2", { item = "tags" })
		value.nextId = 4
		value = Design.document.setRowVariant(value, library, "n2", {
			item = "kind",
			cases = {
				{ value = "notice", kind = "Notice", props = { text = { item = "text" } }, children = {} },
				{
					value = "stack",
					kind = "Box",
					props = {},
					children = {
						{ id = "n3", kind = "Box", name = "Content", props = {}, children = {}, hidden = true },
					},
				},
			},
		})
		for _, tagField in { "tags", "text" } do
			value = Design.document.bindTags(value, library, "n2", { item = tagField })
			for _, rowFunctions in { false, true } do
				local options: Design.EmitOptions = { rowFunctions = rowFunctions }
				local code = Design.emit(value, library, options)
				expect(Design.parse(code, library)):toEqual(value)
				expect(Design.emit(Design.parse(code, library), library, options)):toBe(code)
				canonical(code)
				analyze(code)
			end
		end
	end)

	it("strictly types input tags and caller slots at their layout positions", function()
		local value = Design.document.setContract(Design.document.new("Slots", library, "Box"), library, {
			inputs = {
				{ id = "body", kind = "value", type = "slot", required = true },
				{ id = "paint", kind = "readable", type = "string", required = true },
			},
			outputs = {},
		})
		value = Design.document.insert(value, library, "n1", "Box")
		value = Design.document.insertSlot(value, library, "n1", "body")
		value = Design.document.insert(value, library, "n1", "Box")
		value = Design.document.bindTags(value, library, "n1", { input = "paint" })
		for _, list in { false, true } do
			value.contract.inputs[2].type = if list then "list" else "string"
			value.contract.inputs[2].luauType = if list then "Tags" else nil
			for _, required in { true, false } do
				value.contract.inputs[1].required = if required then true else nil
				local code = Design.emit(value, library)
				expect(Design.parse(code, library)):toEqual(value)
				expect(Design.emit(Design.parse(code, library), library)):toBe(code)
				canonical(code)
				analyze(code)
			end
		end
	end)

	it("strictly types input labels beside document owned page factories", function()
		local value = Design.document.setContract(Design.document.new("Pages", library, "Book"), library, {
			inputs = { { id = "title", kind = "value", type = "string", required = true } },
			outputs = {},
		})
		value.root.children = { { id = "n2", name = "Page", kind = "Box", props = {}, children = {} } }
		value.nextId = 3
		value = Design.document.change(
			value,
			library,
			"n1",
			"pages",
			{ literal = {
				{ label = { ["$input"] = "title" }, content = { ["$template"] = "n2" } },
			} }
		)
		local code = Design.emit(value, library)
		expect(Design.parse(code, library)):toEqual(value)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		canonical(code)
		analyze(code)
	end)
end)

return nil
