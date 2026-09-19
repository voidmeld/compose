--!strict

local Test = require "../harness"
local fs = require "@std/fs"
local process = require "@lute/process"

local describe, it, expect = Test.describe, Test.it, Test.expect

local CONFIG = "lint.config.luau"
local ROOTS = { "src", "authoring", "tests", "tools", "bench", "examples", "verification" }

local NAN_IDIOM_WITNESS = "tests/animation/timeline.verify.luau"

local function codesFor(source: string, gated: boolean): { string }
	local argv = { "lute", "lint" }
	if gated then
		table.insert(argv, "-c")
		table.insert(argv, CONFIG)
	end
	table.insert(argv, "-s")
	table.insert(argv, source)

	local result = process.run(argv)
	local codes: { string } = {}
	for code in string.gmatch(result.stdout, "\n?%a+%[([%a_]+)%]:") do
		table.insert(codes, code)
	end
	table.sort(codes)
	return codes
end

local function gateCodes(source: string): { string }
	return codesFor(source, true)
end

local function defaultCodes(source: string): { string }
	return codesFor(source, false)
end

local function codesForPath(path: string, gated: boolean): { string }
	local argv = { "lute", "lint" }
	if gated then
		table.insert(argv, "-c")
		table.insert(argv, CONFIG)
	end
	table.insert(argv, path)

	local result = process.run(argv)
	local codes: { string } = {}
	for code in string.gmatch(result.stdout, "\n?%a+%[([%a_]+)%]:") do
		table.insert(codes, code)
	end
	table.sort(codes)
	return codes
end

local DEFECTS: { { rule: string, source: string } } = {
	{ rule = "almost_swapped", source = "local a, b = 1, 2\na = b\nb = a\nreturn a + b\n" },
	{ rule = "constant_table_comparison", source = "local q: any = nil\nreturn q == {}\n" },
	{ rule = "duplicate_keys", source = "return { alpha = 1, alpha = 2 }\n" },
	{ rule = "empty_if_block", source = "local q: any = nil\nif q then\nend\nreturn q\n" },
	{ rule = "parenthesized_conditions", source = "local q: any = nil\nif (q) then\n\treturn 1\nend\nreturn 0\n" },
	{ rule = "divide_by_zero", source = "local ratio = 5 / 0\nreturn ratio\n" },
	{ rule = "global_table_usage", source = "return _G\n" },
	{ rule = "type_check_inside_call", source = "local a, b = 1, 2\nreturn type(a == b)\n" },
	{ rule = "bad_string_escape", source = 'return "\\q"\n' },
}

local OWNED_RULES: { { rule: string, file: string } } = {
	{ rule = "global_table_usage", file = "tools/lint-rules/global_table_usage.luau" },
	{ rule = "type_check_inside_call", file = "tools/lint-rules/type_check_inside_call.luau" },
	{ rule = "bad_string_escape", file = "tools/lint-rules/bad_string_escape.luau" },
}

local GLOBAL_TABLE_EXEMPT = "tests/tools/fixtures/global-table-allowed.luau"

local FORWARD_DECLARED_RECURSION = table.concat({
	"local function build()",
	"\tlocal step: (number) -> number",
	"\tfunction step(n: number): number",
	"\t\treturn if n <= 0 then 0 else step(n - 1)",
	"\tend",
	"\treturn step",
	"end",
	"return build",
}, "\n") .. "\n"

local ASSIGNMENT_TARGET_BASE = "local held = {}\nlocal alias = held\nalias.field = 1\nreturn held\n"

local NESTED_ASSIGNMENT_TARGET_BASE = "local held = { a = {} }\nlocal alias = held\nalias.a.c = 1\nreturn held\n"

local COMPOUND_INDEX_ASSIGNMENT =
	'local held = {}\nlocal alias = held :: { [string]: number }\nalias["key"] += 1\nreturn held\n'

local UNDERSCORE_UNUSED = "local _deliberate = 1\nreturn nil\n"

describe("lint contract", function()
	describe("the gate policy reports the defects it claims to report", function()
		for _, defect in DEFECTS do
			it(("reports %s"):format(defect.rule), function()
				expect(gateCodes(defect.source)):toEqual { defect.rule }
			end)
		end
	end)

	describe("the gate policy accepts what this repository writes on purpose", function()
		it("accepts the 0 / 0 NaN idiom on the one spec that manufactures poison values", function()
			expect(codesForPath(NAN_IDIOM_WITNESS, false)):toContain "divide_by_zero"
			expect(codesForPath(NAN_IDIOM_WITNESS, true)):toEqual {}
		end)

		it("still reports a literal zero divisor outside that one path", function()
			expect(gateCodes "local ratio = 5 / 0\nreturn ratio\n"):toEqual { "divide_by_zero" }
		end)

		it("accepts forward-declared recursion inside a nested scope", function()
			expect(gateCodes(FORWARD_DECLARED_RECURSION)):toEqual {}
		end)

		it("accepts a local used only as an assignment-target base", function()
			expect(gateCodes(ASSIGNMENT_TARGET_BASE)):toEqual {}
		end)

		it("accepts a local used only as a nested assignment-target base", function()
			expect(gateCodes(NESTED_ASSIGNMENT_TARGET_BASE)):toEqual {}
		end)

		it("accepts a local mutated only through a compound index assignment", function()
			expect(gateCodes(COMPOUND_INDEX_ASSIGNMENT)):toEqual {}
		end)

		it("accepts an underscore-prefixed deliberately unused binding", function()
			expect(gateCodes(UNDERSCORE_UNUSED)):toEqual {}
		end)
	end)

	describe("repository-owned rules", function()
		describe("global_table_usage", function()
			it("reports a read of _G", function()
				expect(gateCodes "local held = _G\nreturn held\n"):toEqual { "global_table_usage" }
			end)

			it("reports a write through _G", function()
				expect(gateCodes "_G.slot = 1\nreturn nil\n"):toEqual { "global_table_usage" }
			end)

			it("reports shared as well as _G", function()
				expect(gateCodes "return shared\n"):toEqual { "global_table_usage" }
			end)

			it("reports every occurrence rather than the first", function()
				expect(gateCodes "_G.slot = 1\nreturn shared\n"):toEqual {
					"global_table_usage",
					"global_table_usage",
				}
			end)

			it("accepts a table record key spelled _G", function()
				expect(gateCodes "return { _G = {} }\n"):toEqual {}
			end)

			it("accepts a local named shared", function()
				expect(gateCodes "local shared = 1\nreturn shared\n"):toEqual {}
			end)

			it("exempts the one path named in options.allow", function()
				expect(fs.exists(GLOBAL_TABLE_EXEMPT)):toBe(true)
				expect(codesForPath(GLOBAL_TABLE_EXEMPT, true)):toEqual {}
			end)

			it("keeps that exemption narrow to the named path", function()
				expect(gateCodes(fs.readFileToString(GLOBAL_TABLE_EXEMPT))):toEqual {
					"global_table_usage",
					"global_table_usage",
				}
			end)
		end)

		describe("type_check_inside_call", function()
			it("reports a comparison inside type", function()
				expect(gateCodes "local a, b = 1, 2\nreturn type(a == b)\n"):toEqual { "type_check_inside_call" }
			end)

			it("reports a comparison inside typeof", function()
				expect(gateCodes "local a, b = 1, 2\nreturn typeof(a ~= b)\n"):toEqual { "type_check_inside_call" }
			end)

			it("sees through redundant parentheses", function()
				expect(gateCodes "local a, b = 1, 2\nreturn type((a < b))\n"):toEqual { "type_check_inside_call" }
			end)

			it("accepts the comparison written outside the call", function()
				expect(gateCodes 'local a = 1\nreturn type(a) == "number"\n'):toEqual {}
			end)

			it("accepts a two-argument call, which is luau-lsp's arity finding", function()
				expect(gateCodes "local a, b = 1, 2\nreturn type(a, b)\n"):toEqual {}
			end)

			it("does not claim an and/or argument", function()
				expect(gateCodes "local a, b = 1, 2\nreturn type(a and b)\n"):toEqual {}
			end)

			it("does not claim a shadowed local named type", function()
				expect(gateCodes "local type = tostring\nlocal a, b = 1, 2\nreturn type(a == b)\n"):toEqual {}
			end)
		end)

		describe("bad_string_escape", function()
			it("reports an undefined escape in a double-quoted string", function()
				expect(gateCodes 'return "\\q"\n'):toEqual { "bad_string_escape" }
			end)

			it("reports an undefined escape in an interpolated string segment", function()
				expect(gateCodes "local a = 1\nreturn `pattern \\w {a}`\n"):toEqual { "bad_string_escape" }
			end)

			it("accepts every escape Luau actually defines", function()
				expect(gateCodes 'return "\\a\\b\\f\\n\\r\\t\\v\\z \\\\ \\" \\065 \\x41 \\u{1F600}"\n'):toEqual {}
			end)

			it("accepts an escaped backslash followed by a plain letter", function()
				expect(gateCodes 'return "\\\\q"\n'):toEqual {}
			end)

			it("accepts an undefined escape inside a long-bracket string, which is raw", function()
				expect(gateCodes "return [[\\q]]\n"):toEqual {}
			end)
		end)
	end)

	describe("upstream defects that keep two rules off", function()
		it("upstream still misreports an assignment-target base as unused", function()
			expect(defaultCodes(ASSIGNMENT_TARGET_BASE)):toEqual { "unused_variable" }
		end)

		it("upstream still misreports a nested assignment-target base as unused", function()
			expect(defaultCodes(NESTED_ASSIGNMENT_TARGET_BASE)):toEqual { "unused_variable" }
		end)

		it("upstream still misreports a compound-index-assigned local as unused", function()
			expect(defaultCodes(COMPOUND_INDEX_ASSIGNMENT)):toEqual { "unused_variable" }
		end)

		it("upstream still misreports forward-declared recursion", function()
			expect(defaultCodes(FORWARD_DECLARED_RECURSION)):toEqual {
				"global_function_in_scope",
				"unused_variable",
			}
		end)
	end)

	describe("the checked-in configuration", function()
		it("keeps the three contested rule decisions written down", function()
			local source = fs.readFileToString(CONFIG)
			expect(source):toContain "divide_by_zero"
			expect(source):toContain "global_function_in_scope = { off = true }"
			expect(source):toContain "unused_variable = { off = true }"
		end)

		it("loads every repository-owned rule, and each file exists", function()
			local source = fs.readFileToString(CONFIG)
			for _, owned in OWNED_RULES do
				expect(fs.exists(owned.file)):toBe(true)
				expect(source):toContain(owned.file)
			end
		end)

		it("names the global_table_usage exemption as a path that exists", function()
			expect(fs.exists(GLOBAL_TABLE_EXEMPT)):toBe(true)
			expect(fs.readFileToString(CONFIG)):toContain(GLOBAL_TABLE_EXEMPT)
		end)

		it("narrows divide_by_zero to a path that exists", function()
			expect(fs.exists(NAN_IDIOM_WITNESS)):toBe(true)
			expect(fs.readFileToString(CONFIG)):toContain(NAN_IDIOM_WITNESS)
		end)

		it("is clean over every gate lint root at HEAD", function()
			local argv = { "lute", "lint", "-c", CONFIG }
			for _, root in ROOTS do
				table.insert(argv, root)
			end
			local result = process.run(argv)
			if not result.ok then
				error(("lint policy is not clean:\n%s%s"):format(result.stdout, result.stderr), 0)
			end
			expect(result.ok):toBe(true)
		end)
	end)
end)

return nil
