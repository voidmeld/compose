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
		"type Row = { id: string }",
		"type Page = { id: string, rows: { Row } }",
		"type Dimension = { x: number, y: number }",
		"type Controls = {",
		"\tBox: (string) -> ({ [number]: Target, Size: Core.Input<Dimension>? }) -> Target,",
		"\tFlash: (string) -> ({ target: Core.ReadOnlyValue<Target?> | ((Core.Use) -> Target?) }) -> Target,",
		"\tPanel: (string) -> ({ content: () -> Target }) -> Target,",
		"\tPages: (string) -> ({ from: Core.Source<{ Page }>, key: string, render: (Core.ReadOnlyValue<Page>) -> Target }) -> Target,",
		"\tRows: (string) -> ({ from: Core.Source<{ Row }>, key: string, render: (Core.ReadOnlyValue<Row>) -> Target }) -> Target,",
		"}",
	},
	returnType = "Target",
	readable = "Core.ReadOnlyValue",
	cell = "Core.Value",
	newCell = "Core.cell",
	kinds = {
		Box = {
			fields = { Size = { type = "datatype", datatype = "UDim2" } },
			children = "list",
			call = "UI.Box",
			build = build,
		},
		Flash = { fields = { target = { type = "node" } }, children = "none", call = "UI.Flash", build = build },
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
end)

return nil
