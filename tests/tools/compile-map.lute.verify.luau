--!strict

local Test = require "../harness"
local CompileMap = require "../../tools/lib/compile-map"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function compile(source: string): CompileMap.Result
	return CompileMap.compile(source, "Compose")
end

describe("compile-map", function()
	it("rewrites a single-source property body into Compose.map", function()
		local result = compile [[
local Compose = require(script.Compose)
local index = Compose.cell(1)
local props = {
	LayoutOrder = function(use: Compose.Use): number
		return use(index) * 2
	end,
}
]]
		expect(result.rewritten):toBe(1)
		expect(
			string.find(
				result.source,
				"LayoutOrder = Compose.map(index, function(__value) return __value * 2 end),",
				1,
				true
			) ~= nil
		):toBe(true)
	end)

	it("leaves a body alone when the source local is reassigned", function()
		local source = [[
local Compose = require(script.Compose)
local index = Compose.cell(1)
local bind = function(use) return use(index) end
index = Compose.cell(2)
]]
		local result = compile(source)
		expect(result.rewritten):toBe(0)
		expect(result.source):toBe(source)
	end)

	it("leaves a body alone when use is read twice, passed on, or reads a field", function()
		local source = [[
local Compose = require(script.Compose)
local a, b = Compose.cell(1), Compose.cell(2)
local state = { value = Compose.cell(3) }
local twice = function(use) return use(a) + use(b) end
local passed = function(use) return helper(use) end
local field = function(use) return use(state.value) end
local statements = function(use) local x = use(a) return x end
]]
		local result = compile(source)
		expect(result.rewritten):toBe(0)
		expect(result.source):toBe(source)
	end)

	it("leaves named function declarations alone", function()
		local source = [[
local Compose = require(script.Compose)
local palette = Compose.cell("red")
local function outfit(use)
	return use(palette)
end
function shared(use)
	return use(palette)
end
]]
		local result = compile(source)
		expect(result.rewritten):toBe(0)
		expect(result.source):toBe(source)
	end)

	it("needs the Compose binding in the file", function()
		local source = [[
local index = 1
local bind = function(use) return use(index) end
]]
		expect(compile(source).rewritten):toBe(0)
	end)

	it("rewrites an outer body and keeps a nested function verbatim", function()
		local result = compile [[
local Compose = require(script.Compose)
local rows = Compose.cell({})
local outer = function(use) return #use(rows) + (function(other) return other(rows) end)(nil) end
]]
		expect(result.rewritten):toBe(1)
		expect(
			string.find(
				result.source,
				"Compose.map(rows, function(__value) return #__value + (function(other) return other(rows) end)(nil) end)",
				1,
				true
			) ~= nil
		):toBe(true)
		local single = compile [[
local Compose = require(script.Compose)
local count = Compose.cell(1)
local first = function(use) return use(count) end
local second = function(use) return tostring(use(count)) end
]]
		expect(single.rewritten):toBe(2)
		expect(
			string.find(single.source, "Compose.map(count, function(__value) return tostring(__value) end)", 1, true)
				~= nil
		):toBe(true)
	end)
end)

return nil
