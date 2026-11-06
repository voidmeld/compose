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
	it("names the caller input form for computed metric calls", function()
		local metrics = table.clone(library)
		metrics.kinds = table.clone(library.kinds)
		metrics.kinds.Button = table.clone(library.kinds.Button)
		metrics.kinds.Button.fields = { textSize = { type = "number", tokens = true } }
		metrics.token = "UI.token"
		local value = Design.document.new("Metrics", metrics, "Button")
		value = Design.document.change(value, metrics, "n1", "textSize", { literal = 17 })
		local code = Design.emit(value, metrics)
		for _, call in { 'Metrics.size(UI, 17, "control")', "Metrics.size(UI, 48)" } do
			local custom = string.gsub(code, "textSize = 17", function(): string
				return "textSize = " .. call
			end)
			expect(function()
				Design.parse(custom, metrics)
			end):toThrow "Metrics.size is custom code; compute it in the caller and bind props.<input> or a library token"
		end
		value = Design.document.change(value, metrics, "n1", "textSize", { token = "controlSize" })
		local tokenCode = Design.emit(value, metrics)
		expect(Design.emit(Design.parse(tokenCode, metrics), metrics)):toBe(tokenCode)
	end)

	it("names typed readable inputs for environment layout functions", function()
		local value = Design.document.setContract(Design.document.new("Layout", library, "Box"), library, {
			inputs = { { id = "size", kind = "readable", type = "record", luauType = "Dimension", required = true } },
			outputs = {},
		})
		value = Design.document.change(value, library, "n1", "Size", { input = "size" })
		local code = Design.emit(value, library)
		for _, binding in
			{
				"function(use: Core.Use): Dimension return use(environment.safeInsets) end",
				"function(use) return UDim2.fromOffset(use(environment.safeInsets).left, 0) end",
				"function(use: Core.Use): Dimension local insets = use(environment.safeInsets) return UDim2.fromOffset(insets.left, insets.top) end",
				"function(use: Core.Use): Dimension refreshLayout() return use(environment.safeInsets) end",
			}
		do
			local custom = string.gsub(code, "Size = props.size", function(): string
				return "Size = " .. binding
			end)
			expect(function()
				Design.parse(custom, library)
			end):toThrow "Layout functions use a typed readable input: compute the value in the caller and bind props.<input>"
		end
		for _, helper in { "Position", "Size", "frame" } do
			for _, declaration in
				{
					`local function {helper}(use) return use(environment.safeInsets) end`,
					`local function {helper}(use: Core.Use): Dimension return use(environment.safeInsets) end`,
					`local {helper}: (Core.Use) -> Dimension = function(use) return use(environment.safeInsets) end`,
				}
			do
				local custom = string.gsub(code, "\n\treturn UI.Box", function(): string
					return `\n\t{declaration}\n\treturn UI.Box`
				end)
				expect(function()
					Design.parse(custom, library)
				end):toThrow "Layout functions use a typed readable input: compute the value in the caller and bind props.<input>"
			end
		end
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
		analyze(code)
	end)

	it("reads declared row parameters in button glyphs and item fields", function()
		local content = table.clone(library)
		content.kinds = table.clone(library.kinds)
		content.kinds.Button = table.clone(library.kinds.Button)
		content.kinds.Button.fields = {
			label = { type = "string" },
			item = { type = "string" },
			glyph = { type = "content" },
		}
		local value = Design.document.setContract(Design.document.new("Buttons", content, "Choices"), content, {
			inputs = {
				{
					id = "rows",
					kind = "readable",
					type = "list",
					required = true,
					fields = { { id = "id", type = "string" }, { id = "text", type = "string" } },
				},
			},
			outputs = {},
		})
		value = Design.document.bind(value, content, "n1", { from = "rows", key = "id" })
		value = Design.document.insert(value, content, "n1", "Button")
		value = Design.document.change(value, content, "n2", "label", { item = "text" })
		value = Design.document.change(value, content, "n2", "item", { item = "id" })
		local glyph
		value, glyph = Design.document.content(value, content, "n2", "glyph", "Notice")
		value = Design.document.change(value, content, glyph, "text", { item = "text" })
		for _, named in { false, true } do
			local options: Design.EmitOptions = { rowFunctions = named }
			local code = Design.emit(value, content, options)
			local custom = string.gsub(code, "current", "entry")
			custom = string.gsub(custom, "function%(use%)", "function(use: Core.Use): string")
			local parsed = Design.parse(custom, content)
			expect(parsed):toEqual(value)
			expect(Design.emit(parsed, content, options)):toBe(code)
			local edited = Design.document.change(parsed, content, glyph, "text", { literal = "Edited" })
			expect(Design.parse(Design.emit(edited, content, options), content)):toEqual(edited)
			expect(edited.root.children[1].props.item):toEqual { item = "id" }
			local shadowed = string.gsub(custom, "entry", "props")
			expect(function()
				Design.parse(shadowed, content)
			end):toThrow "Row parameters must not shadow Design inputs"
		end
	end)

	it("names the current item form for external row lookups", function()
		local code = [[
local _design = { name = "Rows", contract = { inputs = {}, outputs = {} } }
return function(UI, props)
    return UI.Button "Row" {
        label = function(use) return use(external).label end,
    }
end
]]
		expect(function()
			Design.parse(code, library)
		end):toThrow "Item bindings read the declared row parameter; use function(use) return use(current).field end and prepare computed fields in the caller"
	end)

	it("round trips readable button row inputs and glyph content", function()
		local content = table.clone(library)
		content.kinds = table.clone(library.kinds)
		content.kinds.Button = table.clone(library.kinds.Button)
		content.kinds.Button.fields = {
			label = { type = "string" },
			row = { type = "value" },
			glyph = { type = "content" },
		}
		local imageKind: Design.Kind = {
			fields = {
				Visible = { type = "boolean" },
				failureLabel = { type = "string" },
				source = { type = "string" },
			},
			children = "none",
			call = "UI.AsyncImage",
			build = build,
		}
		content.kinds.AsyncImage = imageKind
		local value = Design.document.setContract(Design.document.new("Reward", content, "Button"), content, {
			inputs = {
				{ id = "label", kind = "readable", type = "string", required = true },
				{ id = "image", kind = "readable", type = "image", required = true },
				{ id = "hasImage", kind = "cell", type = "boolean", required = true },
			},
			outputs = {},
		})
		value = Design.document.change(value, content, "n1", "label", { input = "label" })
		value = Design.document.change(value, content, "n1", "row", {
			literal = { title = { ["$input"] = "label" } },
		})
		local glyph
		value, glyph = Design.document.content(value, content, "n1", "glyph", "AsyncImage")
		value = Design.document.rename(value, content, glyph, "ItemIconImage")
		value = Design.document.change(value, content, glyph, "Visible", { input = "hasImage" })
		value = Design.document.change(value, content, glyph, "failureLabel", { literal = "" })
		value = Design.document.change(value, content, glyph, "source", { input = "image" })
		local code = Design.emit(value, content)
		expect(Design.emit(Design.parse(code, content), content)):toBe(code)
		local custom = string.gsub(code, "label = props.label", "label = function(use) return use(props.label) end")
		custom = string.gsub(custom, "source = props.image", "source = function(use) return use(props.image) end")
		custom =
			string.gsub(custom, "Visible = props.hasImage", "Visible = function(use) return use(props.hasImage) end")
		local parsed = Design.parse(custom, content)
		expect(parsed):toEqual(value)
		expect(Design.emit(parsed, content)):toBe(code)
		local edited = Design.document.change(parsed, content, glyph, "failureLabel", { literal = "Missing" })
		expect(Design.parse(Design.emit(edited, content), content)):toEqual(edited)
		local static = Design.document.copy(value)
		static.contract.inputs[1].kind = "value"
		local staticCode = Design.emit(static, content)
		staticCode = string.gsub(staticCode, "label = props.label", "label = function(use) return use(props.label) end")
		expect(function()
			Design.parse(staticCode, content)
		end):toThrow "Input formulas read a declared readable or cell input"
	end)

	it("restores the enclosing row after nested row content", function()
		local code = [[
local _design = {
    name = "Nested",
    contract = {
        inputs = {
            { id = "pages", kind = "readable", type = "list", required = true, fields = {
                { id = "id", type = "string" },
                { id = "rows", type = "list", fields = { { id = "id", type = "string" } } },
            } },
        },
        outputs = {},
    },
}
return function(UI, props)
    return UI.Pages "Pages" {
        from = props.pages,
        key = "id",
        render = function(page)
            return UI.Box "Page" {
                UI.Rows "Rows" {
                    from = function(use) return use(page).rows end,
                    key = "id",
                    render = function(entry)
                        return UI.Button "Item" { label = function(use) return use(entry).id end }
                    end,
                },
                UI.Button "PageId" { label = function(use) return use(page).id end },
            }
        end,
    }
end
]]
		local parsed = Design.parse(code, library)
		local canonicalCode = Design.emit(parsed, library)
		expect(Design.parse(canonicalCode, library)):toEqual(parsed)
		expect(parsed.root.children[1].children[2].props.label):toEqual { item = "id" }
		local external = string.gsub(code, "use%(entry%)", "use(page)")
		expect(function()
			Design.parse(external, library)
		end):toThrow "Item bindings read the declared row parameter"
	end)

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
