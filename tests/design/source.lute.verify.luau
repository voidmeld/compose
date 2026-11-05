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
	it("preserves static type import paths and deduplicates library declarations", function()
		local value = Design.document.new("Imports", library, "Button")
		for _, declaration in
			{
				'local Roles = require "./button-roles"',
				"local Roles = require(script.Parent.Button)",
				'local Roles = require(script.Parent["button-roles"])',
				'local Roles = require(game:GetService("ReplicatedStorage").Controls.Button)',
			}
		do
			local code = Design.emit(value, library, { prelude = { declaration } })
			local parsed = Design.parse(code, library)
			expect(parsed.typeImports):toEqual { declaration }
			expect(Design.emit(parsed, library)):toBe(code)
			canonical(code)
		end
		local code = Design.emit(value, library)
		local parenthesized = string.gsub(code, 'require "../src/core"', 'require("../src/core")')
		expect(Design.parse(parenthesized, library).typeImports):toBeNil()
		expect(Design.emit(Design.parse(parenthesized, library), library)):toBe(code)
		local configured = table.clone(library)
		configured.prelude = table.clone(library.prelude)
		table.insert(configured.prelude, "local Config = require(resolveConfig())")
		local configuredCode = Design.emit(value, configured)
		expect(Design.parse(configuredCode, configured).typeImports):toBeNil()
		expect(Design.emit(Design.parse(configuredCode, configured), configured)):toBe(configuredCode)
		for _, declaration in
			{
				"local Roles = require(resolveRoles())",
				'local Roles = require(script:FindFirstChild("Roles"))',
				'local Roles = require("./button-roles").choose()',
			}
		do
			local custom = string.gsub(code, "export type Props", declaration .. "\n\nexport type Props", 1)
			expect(function()
				Design.parse(custom, library)
			end):toThrow "Type imports require a static module path"
		end
	end)

	it("keeps public role type imports through linked edits and reactive control updates", function()
		fs.createDirectory(".worker-tmp", { makeParents = true })
		fs.writeStringToFile(
			".worker-tmp/button-roles.luau",
			'--!strict\n\nexport type ButtonRole = "ordinary" | "primary"\n\nreturn {}\n'
		)
		fs.writeStringToFile(
			".worker-tmp/role-controls.luau",
			[[
--!strict

local Core = require "../src/core"
local Roles = require "./button-roles"

export type Target = { name: string, role: Roles.ButtonRole }
export type Controls = { Button: (string) -> ({ role: Core.ReadOnlyValue<Roles.ButtonRole> }) -> Target }

local calls = 0
local controls: Controls = {
	Button = function(name: string)
		return function(props: { role: Core.ReadOnlyValue<Roles.ButtonRole> }): Target
			calls += 1
			local target: Target = { name = name, role = props.role:peek() }
			Core.watch(function(use: Core.Use)
				target.role = use(props.role)
			end)
			return target
		end
	end,
}

return { controls = controls, calls = function(): number return calls end }
]]
		)
		local controls: Design.Library = {
			name = "Roles",
			parameter = "UI",
			parameterType = "Facade.Controls",
			prelude = { 'local Core = require "../src/core"', 'local Facade = require "./role-controls"' },
			returnType = "Facade.Target",
			readable = "Core.ReadOnlyValue",
			cell = "Core.Value",
			kinds = {
				Button = {
					fields = { role = { type = "choice", options = { "ordinary", "primary" } } },
					children = "none",
					call = "UI.Button",
					build = build,
				},
			},
		}
		local value = Design.document.setContract(Design.document.new("Action", controls, "Button"), controls, {
			inputs = {
				{ id = "role", kind = "readable", type = "string", luauType = "Roles.ButtonRole", required = true },
			},
			outputs = {},
		})
		value = Design.document.change(value, controls, "n1", "role", { input = "role" })
		local declaration = 'local Roles = require "./button-roles"'
		local code = Design.emit(value, controls, { prelude = { declaration } })
		local parsed = Design.parse(code, controls)
		expect(parsed.typeImports):toEqual { declaration }
		expect(parsed.root.kind):toBe "Button"
		expect(parsed.root.props.role.input):toBe "role"
		expect(Design.emit(parsed, controls)):toBe(code)
		expect(Design.emit(parsed, controls, { prelude = { declaration } })):toBe(code)
		local copied = Design.document.copy(parsed)
		table.clear(assert(copied.typeImports))
		expect(parsed.typeImports):toEqual { declaration }
		Core.withRootOwner(function()
			local session = Design.session(controls, value)
			local link = Design.link(session, {
				read = function(): string
					return code
				end,
				write = function(expected: string, generated: string): boolean
					expect(expected):toBe(code)
					code = generated
					return true
				end,
				watch = function(_callback: () -> ()): () -> ()
					return function() end
				end,
			})
			expect(link.status:peek()):toBe "synchronized"
			session.select "n1"
			expect(session.rename "Confirm"):toBe(true)
			expect(link.status:peek()):toBe "synchronized"
			expect(Design.parse(code, controls).root.name):toBe "Confirm"
			expect(Design.emit(Design.parse(code, controls), controls)):toBe(code)
			link.dispose()
		end)
		canonical(code)
		analyze(code)
		fs.writeStringToFile(".worker-tmp/role-design.luau", code)
		local runner = [[
--!strict

local Core = require "../src/core"
local Roles = require "./button-roles"
local Facade = require "./role-controls"
local action = require "./role-design"

local role = Core.cell<<Roles.ButtonRole>>("ordinary")
local owner = Core.createRootOwner(function()
	local target = action(Facade.controls, { role = role })
	assert(target.name == "Confirm" and target.role == "ordinary")
	assert(Facade.calls() == 1)
	role:set "primary"
	assert(target.role == "primary")
	assert(Facade.calls() == 1)
end)
owner.dispose()
role:set "ordinary"
role:dispose()
]]
		analyze(runner)
		fs.writeStringToFile(".worker-tmp/role-design-run.luau", runner)
		local ran = process.run { "lute", "run", ".worker-tmp/role-design-run.luau" }
		expect(ran.ok, ran.stdout .. ran.stderr):toBe(true)
	end)

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

	it("emits narrowed native anchors with exact identity and formatter stable bytes", function()
		local typed = table.clone(library)
		typed.prelude = table.clone(library.prelude)
		table.insert(typed.prelude, "type NativeControls = Controls & {")
		table.insert(typed.prelude, "\tCallout: (string) -> ({ anchor: Target, onRetire: (() -> ())? }) -> Target,")
		table.insert(typed.prelude, "}")
		typed.parameterType = "NativeControls"
		typed.kinds = table.clone(library.kinds)
		local calloutKind: Design.Kind = {
			fields = { anchor = { type = "node", reference = "native" }, onRetire = { type = "event" } },
			children = "none",
			call = "UI.Callout",
			build = build,
		}
		typed.kinds.Callout = calloutKind
		local value = Design.document.setContract(Design.document.new("Anchored", typed, "Box"), typed, {
			inputs = { { id = "selected", kind = "value", type = "string" } },
			outputs = { { id = "onRetire", args = {} } },
		})
		local trigger, callout
		value, trigger = Design.document.insert(value, typed, "n1", "Button")
		value = Design.document.change(value, typed, trigger, "label", { literal = "Help" })
		value, callout = Design.document.insert(value, typed, "n1", "Callout")
		value = Design.document.change(value, typed, callout, "anchor", { node = trigger })
		value = Design.document.change(value, typed, callout, "onRetire", { output = "onRetire" })
		local code = Design.emit(value, typed)
		expect(string.find(code, `assert(refs.{trigger}:peek(), "Node reference is not captured")`, 1, true) ~= nil):toBe(
			true
		)
		expect(string.find(code, "::", 1, true)):toBeNil()
		expect(Design.parse(code, typed)):toEqual(value)
		expect(Design.emit(Design.parse(code, typed), typed)):toBe(code)
		canonical(code)
		analyze(code)
		fs.writeStringToFile(".worker-tmp/native-anchor.luau", code)
		expect(function()
			Design.parse((string.gsub(code, '"Node reference is not captured"', '"Missing"')), typed)
		end):toThrow "assert their capture"
		local moved = Design.document.move(value, typed, callout, "n1", 1)
		fs.writeStringToFile(".worker-tmp/native-anchor-missing.luau", Design.emit(moved, typed))
		fs.writeStringToFile(
			".worker-tmp/native-anchor-run.luau",
			[[
--!strict
local anchored = require "./native-anchor"
local missing = require "./native-anchor-missing"
local trigger = { name = "trigger" }
local calls, retired = 0, 0
local controls = {
    Box = function(name)
        return function() return { name = name } end
    end,
    Button = function()
        return function() return trigger end
    end,
    Callout = function(name)
        return function(props)
            assert(props.anchor == trigger)
            calls += 1
            props.onRetire()
            return { name = name }
        end
    end,
}
anchored(controls, { onRetire = function() retired += 1 end })
assert(calls == 1 and retired == 1)
local ok, problem = pcall(function() missing(controls, {}) end)
assert(not ok and string.find(tostring(problem), "Node reference is not captured", 1, true))
assert(calls == 1)
]]
		)
		local ran = process.run { "lute", "run", ".worker-tmp/native-anchor-run.luau" }
		expect(ran.ok, ran.stdout .. ran.stderr):toBe(true)
		local current = value
		local calloutId: string = callout
		local triggerId: string = trigger
		expect(function()
			Design.document.change(
				current,
				typed,
				calloutId,
				"anchor",
				{ nodeFrom = "selected", nodes = { triggerId } }
			)
		end):toThrow "direct node reference"
		local parent = "n1"
		for _ = 1, 10 do
			value, parent = Design.document.insert(value, typed, parent, "Box")
		end
		value = Design.document.move(value, typed, callout, parent)
		code = Design.emit(value, typed)
		expect(Design.emit(Design.parse(code, typed), typed)):toBe(code)
		canonical(code)
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

	it("types native slot results independently of the UI root and preserves optional factories", function()
		local typed = table.clone(library)
		typed.prelude = table.clone(library.prelude)
		table.insert(typed.prelude, "type Model = { parts: number }")
		table.insert(typed.prelude, "type StageControls = Controls & {")
		table.insert(typed.prelude, "\tStage: (string) -> ({ model: (() -> Model)?, content: () -> Model }) -> Target,")
		table.insert(typed.prelude, "}")
		typed.parameterType = "StageControls"
		typed.kinds = table.clone(library.kinds)
		local stageKind: Design.Kind = {
			fields = { model = { type = "content" }, content = { type = "content" } },
			children = "none",
			call = "UI.Stage",
			build = build,
		}
		typed.kinds.Stage = stageKind
		local value = Design.document.setContract(Design.document.new("Stage", typed, "Box"), typed, {
			inputs = {
				{ id = "model", kind = "value", type = "slot", luauType = "Model" },
				{ id = "content", kind = "value", type = "slot", luauType = "Model", required = true },
			},
			outputs = {},
		})
		value = Design.document.insert(value, typed, "n1", "Stage")
		value = Design.document.change(value, typed, "n2", "model", { input = "model" })
		value = Design.document.change(value, typed, "n2", "content", { input = "content" })
		local code = Design.emit(value, typed)
		expect(string.find(code, "model: (() -> Model)?", 1, true) ~= nil):toBe(true)
		expect(string.find(code, "content: () -> Model", 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, typed)):toEqual(value)
		expect(Design.emit(Design.parse(code, typed), typed)):toBe(code)
		canonical(code)
		analyze(code)
		local bad = Design.document.copy(value)
		bad.contract.inputs[1].kind = "readable"
		expect(function()
			Design.document.validate(bad, typed)
		end):toThrow "must be a value"
		bad = Design.document.copy(value)
		bad.contract.inputs[1].luauType = "Model | Target"
		expect(function()
			Design.document.validate(bad, typed)
		end):toThrow()
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
