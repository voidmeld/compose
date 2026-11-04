--!strict

local fs = require "@std/fs"
local process = require "@lute/process"
local Design = require "../../src/design"
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
				expect(Design.parse(code, library).root.children[1].nameField):toBe("id")
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
