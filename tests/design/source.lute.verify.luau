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
		"type Controls = {",
		"\tBox: (string) -> ({ Target }) -> Target,",
		"\tFlash: (string) -> ({ target: Core.ReadOnlyValue<Target?> | ((Core.Use) -> Target?) }) -> Target,",
		"}",
	},
	returnType = "Target",
	readable = "Core.ReadOnlyValue",
	cell = "Core.Value",
	newCell = "Core.cell",
	kinds = {
		Box = { fields = {}, children = "list", call = "UI.Box", build = build },
		Flash = { fields = { target = { type = "node" } }, children = "none", call = "UI.Flash", build = build },
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
