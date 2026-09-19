--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function domain()
	local reactor = Compose.reactor()
	local owner = Compose.createOwner(reactor)
	return reactor, owner
end

describe("diagnostics", function()
	it("reads a thrown diagnostic back into structured data", function()
		Compose.__resetForTests()
		local ok, err = pcall(function()
			Compose.watch(function() end)
		end)
		expect(ok):toBe(false)

		local parsed = Compose.parseDiagnostic(tostring(err))
		expect(parsed ~= nil):toBe(true)
		local diagnostic = parsed :: Compose.Diagnostic
		expect(diagnostic.code):toBe "owner/no-active-owner"
		expect(#diagnostic.summary > 0):toBe(true)
		expect(#diagnostic.fields.fix > 0):toBe(true)
		expect(#diagnostic.fields.contract > 0):toBe(true)
	end)

	it("parses through a script-and-line prefix", function()
		local raw = Compose.formatDiagnostic("props/not-a-table", "create expects a props table", {
			expected = "a table",
		})
		local parsed = Compose.parseDiagnostic(("some/file.luau:12: %s"):format(raw))
		expect((parsed :: Compose.Diagnostic).code):toBe "props/not-a-table"
		expect((parsed :: Compose.Diagnostic).fields.expected):toBe "a table"
	end)

	it("returns nil for anything that is not one", function()
		expect(Compose.parseDiagnostic "attempt to index nil with 'x'"):toBe(nil)
		expect(Compose.parseDiagnostic ""):toBe(nil)
	end)
end)

describe("cells", function()
	it("reads and writes", function()
		local count = Compose.cell(0)
		expect(count:peek()):toBe(0)
		count:set(7)
		expect(count:peek()):toBe(7)
	end)

	it("updates from the previous value", function()
		local count = Compose.cell(10)
		count:update(function(previous: number): number
			return previous * 3
		end)
		expect(count:peek()):toBe(30)
	end)

	it("does not run a thunk until the first read", function()
		local ran = 0
		local lazy = Compose.cell(function(): number
			ran += 1
			return 42
		end)
		expect(ran):toBe(0)
		expect(lazy:peek()):toBe(42)
		expect(ran):toBe(1)
		expect(lazy:peek()):toBe(42)
		expect(ran):toBe(1)
	end)

	it("runs a thunk on a first write, so update sees the real value", function()
		local ran = 0
		local lazy = Compose.cell(function(): number
			ran += 1
			return 10
		end)
		lazy:update(function(previous: number): number
			return previous + 5
		end)
		expect(ran):toBe(1)
		expect(lazy:peek()):toBe(15)
	end)

	it("suppresses a write that does not change the value", function()
		Compose.setWorkCounters(true)
		Compose.resetWorkCounters()
		local count = Compose.cell(1)
		count:set(2)
		count:set(2)
		count:set(1)
		expect(count:peek()):toBe(1)
		local counters = Compose.readWorkCounters()
		expect(counters.cellWrites):toBe(2)
		expect(counters.cellWritesSuppressed):toBe(1)
		Compose.setWorkCounters(false)
	end)

	it("honours a supplied comparison", function()
		local calls = 0
		local word = Compose.cell("cat", function(current: string, incoming: string): boolean
			calls += 1
			return #current == #incoming
		end)
		word:set "dog"
		expect(calls):toBe(1)
		expect(word:peek()):toBe "cat"
		word:set "horse"
		expect(word:peek()):toBe "horse"
	end)
end)

describe("formulas", function()
	it("derives, and caches until something moves", function()
		local runs = 0
		local price = Compose.cell(3)
		local quantity = Compose.cell(4)
		local total = Compose.formula(function(use)
			runs += 1
			return use(price) * use(quantity)
		end)

		expect(runs):toBe(0)
		expect(total:peek()):toBe(12)
		expect(total:peek()):toBe(12)
		expect(runs):toBe(1)

		quantity:set(5)
		expect(total:peek()):toBe(15)
		expect(runs):toBe(2)
	end)

	it("recomputes a diamond's tip once per change", function()
		local source = Compose.cell(1)
		local left = Compose.formula(function(use)
			return use(source) * 2
		end)
		local right = Compose.formula(function(use)
			return use(source) * 3
		end)
		local tipRuns = 0
		local tip = Compose.formula(function(use)
			tipRuns += 1
			return use(left) + use(right)
		end)

		expect(tip:peek()):toBe(5)
		expect(tipRuns):toBe(1)
		source:set(2)
		expect(tip:peek()):toBe(10)
		expect(tipRuns):toBe(2)
	end)

	it("stops a cascade when its own value is unchanged", function()
		local raw = Compose.cell(3)
		local clamped = Compose.formula(function(use)
			return math.min(use(raw), 5)
		end)
		local outerRuns = 0
		local doubled = Compose.formula(function(use)
			outerRuns += 1
			return use(clamped) * 2
		end)

		expect(doubled:peek()):toBe(6)
		expect(outerRuns):toBe(1)
		raw:set(9)
		expect(doubled:peek()):toBe(10)
		expect(outerRuns):toBe(2)

		raw:set(11)
		expect(doubled:peek()):toBe(10)
		expect(outerRuns):toBe(2)
		raw:set(12)
		expect(doubled:peek()):toBe(10)
		expect(outerRuns):toBe(2)
	end)

	it("settles a whole chain from one read at the end", function()
		local depth = 8
		local source = Compose.cell(1)
		local runs = table.create(depth, 0)
		local current: any = source
		for level = 1, depth do
			local previous = current
			local index = level
			current = Compose.formula(function(use)
				runs[index] += 1
				return use(previous) + 1
			end)
		end

		expect(current:peek()):toBe(1 + depth)
		for level = 1, depth do
			expect(runs[level]):toBe(1)
		end

		source:set(2)
		expect(current:peek()):toBe(2 + depth)
		for level = 1, depth do
			expect(runs[level]):toBe(2)
		end
	end)
end)

describe("watches", function()
	it("runs once immediately and again on change", function()
		local reactor, owner = domain()
		local count = Compose.cell(0)
		local seen: { number } = {}
		owner.watch(function(use)
			table.insert(seen, use(count))
		end)
		expect(seen):toEqual { 0 }

		count:set(1)
		reactor:settle()
		expect(seen):toEqual { 0, 1 }
		owner.dispose()
	end)

	it("stops permanently once its owner is disposed", function()
		local reactor, owner = domain()
		local count = Compose.cell(0)
		local runs = 0
		owner.watch(function(use)
			use(count)
			runs += 1
		end)
		expect(runs):toBe(1)

		owner.dispose()
		count:set(1)
		reactor:settle()
		expect(runs):toBe(1)
	end)

	it("refuses to run with no owner", function()
		expect(function()
			Compose.watch(function() end)
		end):toThrow "no owner"
	end)

	it("does not depend on a read taken with peek", function()
		local reactor, owner = domain()
		local tracked = Compose.cell(0)
		local loose = Compose.cell(0)
		local runs = 0
		owner.watch(function(use)
			use(tracked)
			loose:peek()
			runs += 1
		end)

		loose:set(1)
		reactor:settle()
		expect(runs):toBe(1)

		tracked:set(1)
		reactor:settle()
		expect(runs):toBe(2)
		owner.dispose()
	end)

	it("refuses a use() taken outside a reactive body", function()
		local count = Compose.cell(1)
		local escaped: Compose.Use
		local _reactor, owner = domain()
		owner.watch(function(use)
			escaped = use
			use(count)
		end)
		expect(function()
			escaped(count)
		end):toThrow "outside a reactive body"
		owner.dispose()
	end)
end)

describe("batching", function()
	it("runs a watch once for many writes", function()
		local reactor, owner = domain()
		local first = Compose.cell(0)
		local second = Compose.cell(0)
		local runs = 0
		owner.watch(function(use)
			use(first)
			use(second)
			runs += 1
		end)
		expect(runs):toBe(1)

		reactor:batch(function()
			first:set(1)
			second:set(2)
			expect(runs):toBe(1)
		end)
		expect(runs):toBe(2)
		owner.dispose()
	end)

	it("nests transparently", function()
		local reactor, owner = domain()
		local count = Compose.cell(0)
		local runs = 0
		owner.watch(function(use)
			use(count)
			runs += 1
		end)

		reactor:batch(function()
			count:set(1)
			reactor:batch(function()
				count:set(2)
			end)
			expect(runs):toBe(1)
		end)
		expect(runs):toBe(2)
		expect(count:peek()):toBe(2)
		owner.dispose()
	end)

	it("returns what its body returns", function()
		local reactor = Compose.reactor()
		expect(reactor:batch(function()
			return "result"
		end)):toBe "result"
	end)
end)

return nil
