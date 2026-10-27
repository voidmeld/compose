--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local function required<T>(value: T?): T
	assert(value ~= nil)
	return value
end

local describe, it, expect = Test.describe, Test.it, Test.expect

local function domain()
	local reactor = Compose.reactor.create()
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
		local diagnostic = required(parsed)
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
		expect((required(parsed)).code):toBe "props/not-a-table"
		expect((required(parsed)).fields.expected):toBe "a table"
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
		local makeNumber: (number | (() -> number), Compose.Equals<number>?) -> Compose.Value<number> = Compose.cell
		local lazy = makeNumber(function(): number
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
		local current: Compose.ReadOnlyValue<number> = source
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

describe("formulas with equals", function()
	it("cut off an equal result before any consumer is scheduled", function()
		local reactor, owner = domain()
		local source = Compose.cell(1)
		local parity = Compose.formula(function(use): number
			return use(source) % 2
		end, function(current: number, incoming: number): boolean
			return current == incoming
		end)
		local runs = 0
		for _ = 1, 50 do
			Compose.owner.watch(owner, function(use)
				use(parity)
				runs += 1
			end)
		end
		expect(runs):toBe(50)
		Compose.setWorkCounters(true)
		Compose.resetWorkCounters()
		source:set(3)
		Compose.reactor.settle(reactor)
		local counters = Compose.readWorkCounters()
		Compose.setWorkCounters(false)
		expect(runs):toBe(50)
		expect(counters.watchSchedules):toBe(0)

		source:set(4)
		Compose.reactor.settle(reactor)
		expect(runs):toBe(100)
		Compose.owner.dispose(owner)
	end)

	it("reads the new value through peek right after a write", function()
		local reactor, owner = domain()
		local source = Compose.cell(1)
		local doubled = Compose.formula(function(use): number
			return use(source) * 2
		end, function(current: number, incoming: number): boolean
			return current == incoming
		end)
		local outer = Compose.formula(function(use): number
			return use(doubled) + 1
		end)
		local seen: { number } = {}
		Compose.owner.watch(owner, function(use)
			table.insert(seen, use(outer))
		end)
		Compose.reactor.batch(reactor, function()
			source:set(5)
			expect(outer:peek()):toBe(11)
		end)
		Compose.reactor.settle(reactor)
		expect(seen):toEqual { 3, 11 }
		Compose.owner.dispose(owner)
	end)

	it("leaves an error to the consumer that reads it", function()
		local reactor, owner = domain()
		local source = Compose.cell(1)
		local checked = Compose.formula(function(use): number
			local value = use(source)
			assert(value > 0, "negative")
			return value
		end, function(current: number, incoming: number): boolean
			return current == incoming
		end)
		local failures = 0
		Compose.owner.watch(owner, function(use)
			local ok = pcall(use, checked)
			if not ok then
				failures += 1
			end
		end)
		expect(function()
			source:set(-1)
		end).never:toThrow()
		Compose.reactor.settle(reactor)
		expect(failures):toBe(1)
		Compose.owner.dispose(owner)
	end)
end)

describe("watches", function()
	it("runs once immediately and again on change", function()
		local reactor, owner = domain()
		local count = Compose.cell(0)
		local seen: { number } = {}
		Compose.owner.watch(owner, function(use)
			table.insert(seen, use(count))
		end)
		expect(seen):toEqual { 0 }

		count:set(1)
		Compose.reactor.settle(reactor)
		expect(seen):toEqual { 0, 1 }
		Compose.owner.dispose(owner)
	end)

	it("stops permanently once its owner is disposed", function()
		local reactor, owner = domain()
		local count = Compose.cell(0)
		local runs = 0
		Compose.owner.watch(owner, function(use)
			use(count)
			runs += 1
		end)
		expect(runs):toBe(1)

		Compose.owner.dispose(owner)
		count:set(1)
		Compose.reactor.settle(reactor)
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
		Compose.owner.watch(owner, function(use)
			use(tracked)
			loose:peek()
			runs += 1
		end)

		loose:set(1)
		Compose.reactor.settle(reactor)
		expect(runs):toBe(1)

		tracked:set(1)
		Compose.reactor.settle(reactor)
		expect(runs):toBe(2)
		Compose.owner.dispose(owner)
	end)

	it("refuses a use() taken outside a reactive body", function()
		local count = Compose.cell(1)
		local escaped: Compose.Use
		local _reactor, owner = domain()
		Compose.owner.watch(owner, function(use)
			escaped = use
			use(count)
		end)
		expect(function()
			escaped(count)
		end):toThrow "outside a reactive body"
		Compose.owner.dispose(owner)
	end)
end)

describe("batching", function()
	it("counts a write made after a watch registered inside the same batch as a change", function()
		local reactor, owner = domain()
		local source = Compose.cell "before"
		local seen: { string } = {}
		Compose.reactor.batch(reactor, function()
			local delivered = false
			Compose.owner.watch(owner, function(use)
				local current = use(source)
				if not delivered then
					delivered = true
					return
				end
				table.insert(seen, current)
			end)
			expect(seen):toEqual {}
			source:set "after"
			expect(seen):toEqual {}
		end)
		expect(seen):toEqual { "after" }
		Compose.owner.dispose(owner)
	end)

	it("runs a watch once for many writes", function()
		local reactor, owner = domain()
		local first = Compose.cell(0)
		local second = Compose.cell(0)
		local runs = 0
		Compose.owner.watch(owner, function(use)
			use(first)
			use(second)
			runs += 1
		end)
		expect(runs):toBe(1)

		Compose.reactor.batch(reactor, function()
			first:set(1)
			second:set(2)
			expect(runs):toBe(1)
		end)
		expect(runs):toBe(2)
		Compose.owner.dispose(owner)
	end)

	it("nests transparently", function()
		local reactor, owner = domain()
		local count = Compose.cell(0)
		local runs = 0
		Compose.owner.watch(owner, function(use)
			use(count)
			runs += 1
		end)

		Compose.reactor.batch(reactor, function()
			count:set(1)
			Compose.reactor.batch(reactor, function()
				count:set(2)
			end)
			expect(runs):toBe(1)
		end)
		expect(runs):toBe(2)
		expect(count:peek()):toBe(2)
		Compose.owner.dispose(owner)
	end)

	it("returns what its body returns", function()
		local reactor = Compose.reactor.create()
		expect(Compose.reactor.batch(reactor, function()
			return "result"
		end)):toBe "result"
	end)
end)

return nil
