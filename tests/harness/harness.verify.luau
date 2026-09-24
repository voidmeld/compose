--!strict

local Bdd = require "../../.lute/dependencies/verify/src/bdd"
local Test = require "../harness"
local Verify = require "../../.lute/dependencies/verify/src/core"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function witness(register: (bdd: Bdd.Bdd) -> ()): Verify.Report
	local ticks = 0
	local harness = Verify.createHarness {
		now = function(): number
			ticks += 1
			return ticks
		end,
	}
	register(Bdd.create(harness))
	return harness:run { executor = "witness", capabilities = {}, environment = {} }
end

describe("harness", function()
	describe("expect", function()
		it("compares by identity with toBe", function()
			local table1 = {}
			expect(table1):toBe(table1)
			expect(1):toBe(1)
			expect({}).never:toBe {}
		end)

		it("compares structurally with toEqual", function()
			local nested: { any } = { 1, 2, { a = 3 } }
			expect(nested):toEqual({ 1, 2, { a = 3 } } :: { any })
			expect({ 1, 2 }).never:toEqual { 1, 2, 3 }
			expect({ 1, 2, 3 }).never:toEqual { 1, 2 }
		end)

		it("reports the actual value in the failure message", function()
			local ok, err: any = pcall(function()
				expect({ 7 }):toEqual { 8 }
			end)
			expect(ok):toBe(false)
			expect(tostring(err)):toContain "to deeply equal"
			expect(tostring(err)):toContain "{ 7 }"
		end)

		it("catches throws and matches their message", function()
			expect(function()
				error "boom: bad key"
			end):toThrow "bad key"
			expect(function() end).never:toThrow()
		end)

		it("measures closeness and ordering", function()
			expect(0.1 + 0.2):toBeCloseTo(0.3, 1e-12)
			expect(3):toBeGreaterThan(2)
			expect(3):toBeLessThanOrEqual(3)
		end)

		it("inspects containers", function()
			expect({ "a", "b" }):toContain "b"
			expect({ "a", "b" }):toHaveLength(2)
			expect("compose"):toContain "pose"
		end)
	end)

	describe("hooks", function()
		local log: { string } = {}
		Test.beforeEach(function()
			table.insert(log, "before")
		end)
		Test.afterEach(function()
			table.insert(log, "after")
		end)

		it("runs beforeEach ahead of the body", function()
			expect(log[#log]):toBe "before"
		end)

		it("ran afterEach for the previous case", function()
			expect(log):toEqual { "before", "after", "before" }
		end)
	end)
end)

describe("verification lifecycle", function()
	it("stops setup at the first failed beforeEach, and still tears down", function()
		local log: { string } = {}
		local report = witness(function(bdd)
			bdd.describe("suite", function()
				bdd.beforeEach(function()
					error "setup exploded"
				end)
				bdd.beforeEach(function()
					table.insert(log, "second setup")
				end)
				bdd.afterEach(function()
					table.insert(log, "teardown")
				end)
				bdd.it("never runs its body", function()
					table.insert(log, "body")
				end)
			end)
		end)

		expect(report.failed):toBe(1)
		expect(report.results[1].failures[1].phase):toBe "setup"
		expect(report.results[1].failures[1].message):toContain "setup exploded"
		expect(log):toEqual { "teardown" }
	end)

	it("treats a runtime skip inside beforeEach as a skip, not a failure", function()
		local ran = false
		local report = witness(function(bdd)
			bdd.describe("suite", function()
				bdd.beforeEach(function()
					bdd.skip "prerequisite absent"
				end)
				bdd.it("is skipped before it starts", function()
					ran = true
				end)
			end)
		end)

		expect(report.skipped):toBe(1)
		expect(report.failed):toBe(0)
		expect(report.results[1].status):toBe "skipped"
		expect(report.results[1].skipReason):toBe "prerequisite absent"
		expect(ran):toBe(false)
	end)

	it("reports a raising cleanup as a cleanup failure of the case that owned it", function()
		local report = witness(function(bdd)
			bdd.describe("suite", function()
				bdd.it("passes, then fails to clean up", function(own)
					own(function()
						error "cleanup exploded"
					end)
				end)
			end)
		end)

		expect(report.failed):toBe(1)
		expect(report.results[1].failures[1].phase):toBe "cleanup"
		expect(report.results[1].failures[1].message):toContain "cleanup exploded"
	end)
end)

describe("matcher extension", function()
	it("accepts a toThrow needle on either plain or pattern semantics", function()
		local function raise()
			error "collection/no-frames"
		end

		expect(raise):toThrow "collection/no-frames"
		expect(raise):toThrow "collection/no%-frames"

		expect(function()
			expect(raise):toThrow "a needle that is in neither reading"
		end):toThrow "expected the thrown error to match"
	end)

	it("raises a failure message with no host position in front of it", function()
		local ok, thrown: any = pcall(function()
			expect(1):toBe(2)
		end)
		expect(ok):toBe(false)
		expect(string.sub(tostring(thrown), 1, 9)):toBe "expected "
	end)
end)

describe("source routing", function()
	it("routes each Verify suffix to exactly one host, and everything else to none", function()
		expect(Test.route "tests/reactive/sink.verify.luau"):toBe "neutral"
		expect(Test.route "tests/tools/bundle.lute.verify.luau"):toBe "lute"
		expect(Test.route "tests/tools/fixtures/global-table-allowed.luau"):toBeNil()
		expect(Test.route "tests/authoring/fixtures/set.json"):toBeNil()
	end)

	it("refuses an engine-only source it provably cannot run", function()
		expect(function()
			Test.route "tests/roblox/adapter.roblox.verify.luau"
		end):toThrow "is engine-only source"
	end)
end)

describe("run manifest", function()
	it("derives an entry's id, group and required capability from the source's own name", function()
		expect(Test.entryFor("tests", "tests/reactive/sink.verify.luau")):toEqual {
			id = "reactive/sink",
			source = "tests/reactive/sink.verify.luau",
			group = "reactive",
			tags = { "neutral" },
			requires = {},
		}
		expect(Test.entryFor("tests", "tests/tools/bundle.lute.verify.luau")):toEqual {
			id = "tools/bundle",
			source = "tests/tools/bundle.lute.verify.luau",
			group = "tools",
			tags = { "lute" },
			requires = { "lute" },
		}
	end)

	it("refuses to give a plain module a manifest entry", function()
		expect(function()
			Test.entryFor("tests", "tests/tools/fixtures/global-table-allowed.luau")
		end):toThrow "is not a verification source"
	end)

	it("reads a manifest in the order it is written, and holds it to Verify's schema", function()
		local manifest: Test.Manifest = {
			schemaVersion = 1,
			entries = {
				{ id = "second", source = "tests/b.verify.luau", group = "b" },
				{ id = "first", source = "tests/a.verify.luau", group = "a" },
			},
		}
		expect(Test.sources(manifest)):toEqual { "tests/b.verify.luau", "tests/a.verify.luau" }

		expect(function()
			Test.sources { schemaVersion = 2, entries = {} }
		end):toThrow "unsupported manifest schema major"

		expect(function()
			Test.sources {
				schemaVersion = 1,
				entries = {
					{ id = "one", source = "tests/a.verify.luau", group = "a" },
					{ id = "two", source = "tests/a.verify.luau", group = "a" },
				},
			}
		end):toThrow "duplicate manifest source"

		expect(function()
			Test.sources {
				schemaVersion = 1,
				entries = { { id = "engine", source = "tests/roblox/x.roblox.verify.luau", group = "roblox" } },
			}
		end):toThrow "is engine-only source"
	end)
end)

return nil
