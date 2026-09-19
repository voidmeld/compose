--!strict

local Dispositions = require "../../tools/dispositions"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function finding(code: string, path: string, line: number, excerpt: string): Dispositions.Finding
	return {
		code = code,
		confidence = "likely",
		path = path,
		line = line,
		excerpt = excerpt,
		why = "why",
		fix = "fix",
		caveat = nil,
	}
end

local function disposition(code: string, consumerId: string, bodyName: string): Dispositions.Disposition
	return {
		code = code,
		consumerId = consumerId,
		reactiveBodyName = bodyName,
		reason = "the name refers to a reactive body",
	}
end

describe("dispositions.bodyNameOf", function()
	it("names the call the finding points at", function()
		expect(Dispositions.bodyNameOf(finding("CMP011", "a.luau", 4, "option(reader)"))):toBe "option"
	end)

	it("names a method call the finding points at", function()
		expect(Dispositions.bodyNameOf(finding("CMP029", "a.luau", 4, ":peek()"))):toBe "peek"
	end)

	it("names a call written with a leading dot", function()
		expect(Dispositions.bodyNameOf(finding("CMP011", "a.luau", 4, ".getOpen(reader)"))):toBe "getOpen"
	end)

	it("is empty when the excerpt names no call", function()
		expect(Dispositions.bodyNameOf(finding("CMP011", "a.luau", 4, "local x = 1"))):toBe ""
	end)
end)

describe("dispositions.keyOf", function()
	it("ignores the line, so moving a finding keeps its disposition", function()
		local before = finding("CMP011", "a.luau", 4, "option(reader)")
		local after = finding("CMP011", "a.luau", 900, "option(reader)")
		expect(Dispositions.keyOf(before)):toBe(Dispositions.keyOf(after))
	end)

	it("separates two findings of the same code in different consumers", function()
		local left = finding("CMP011", "a.luau", 4, "option(reader)")
		local right = finding("CMP011", "b.luau", 4, "option(reader)")
		expect(Dispositions.keyOf(left) ~= Dispositions.keyOf(right)):toBe(true)
	end)

	it("separates two bodies of the same code in one consumer", function()
		local left = finding("CMP011", "a.luau", 4, "option(reader)")
		local right = finding("CMP011", "a.luau", 8, "entryHeight(reader)")
		expect(Dispositions.keyOf(left) ~= Dispositions.keyOf(right)):toBe(true)
	end)
end)

describe("dispositions.apply", function()
	it("clears a finding its disposition names", function()
		local remaining, stale = Dispositions.apply(
			{ finding("CMP011", "a.luau", 4, "option(reader)") },
			{ disposition("CMP011", "a.luau", "option") }
		)
		expect(#remaining):toBe(0)
		expect(#stale):toBe(0)
	end)

	it("clears a finding that moved to another line", function()
		local remaining = Dispositions.apply(
			{ finding("CMP011", "a.luau", 512, "option(reader)") },
			{ disposition("CMP011", "a.luau", "option") }
		)
		expect(#remaining):toBe(0)
	end)

	it("spends one entry per finding", function()
		local remaining, stale = Dispositions.apply({
			finding("CMP011", "a.luau", 4, "option(reader)"),
			finding("CMP011", "a.luau", 9, "option(reader)"),
		}, { disposition("CMP011", "a.luau", "option") })
		expect(#remaining):toBe(1)
		expect(#stale):toBe(0)
	end)

	it("reports an entry nothing matched as stale", function()
		local remaining, stale = Dispositions.apply({}, { disposition("CMP011", "a.luau", "option") })
		expect(#remaining):toBe(0)
		expect(#stale):toBe(1)
		expect(stale[1].reactiveBodyName):toBe "option"
	end)

	it("keeps a finding whose code was dispositioned elsewhere", function()
		local remaining = Dispositions.apply(
			{ finding("CMP011", "b.luau", 4, "option(reader)") },
			{ disposition("CMP011", "a.luau", "option") }
		)
		expect(#remaining):toBe(1)
	end)

	it("refuses an entry that is not a complete disposition", function()
		expect(function()
			Dispositions.apply({}, { { code = "CMP011" } :: any })
		end):toThrow "complete disposition"
	end)
end)

describe("dispositions.findings", function()
	it("reads a compose-check report", function()
		local read = Dispositions.findings {
			schemaVersion = 1,
			findings = { finding("CMP011", "a.luau", 4, "option(reader)") },
		}
		expect(#read):toBe(1)
		expect(read[1].code):toBe "CMP011"
	end)

	it("refuses a report of another schema", function()
		expect(function()
			Dispositions.findings { schemaVersion = 2, findings = {} }
		end):toThrow "malformed"
	end)

	it("refuses a finding without the fields the key needs", function()
		expect(function()
			Dispositions.findings { schemaVersion = 1, findings = { { code = "CMP011" } } }
		end):toThrow "malformed"
	end)
end)

return nil
