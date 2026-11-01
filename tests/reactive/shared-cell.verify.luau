--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function domain()
	local reactor = Compose.reactor.create()
	local owner = Compose.createOwner(reactor)
	return reactor, owner
end

describe("shared cells", function()
	it("reads, writes, and updates exactly as a cell does", function()
		local presses = Compose.sharedCell(0)
		expect(presses:peek()):toBe(0)
		presses:set(7)
		expect(presses:peek()):toBe(7)
		presses:update(function(previous: number): number
			return previous * 3
		end)
		expect(presses:peek()):toBe(21)
	end)

	it("needs no owner, which is the point", function()
		expect(Compose.currentOwner()):toBe(nil)
		local anchor = Compose.sharedCell "north"
		anchor:set "south"
		expect(anchor:peek()):toBe "south"
	end)

	it("is registered as a readable like a cell", function()
		expect(Compose.isValue(Compose.sharedCell(0))):toBe(true)
	end)

	it("uses the explicit lazy constructor for shared deferred state", function()
		local ran = 0
		local lazy = Compose.lazyCell(function(): number
			ran += 1
			return 42
		end)
		expect(ran):toBe(0)
		expect(lazy:peek()):toBe(42)
		expect(ran):toBe(1)
		expect(lazy:peek()):toBe(42)
		expect(ran):toBe(1)
	end)

	it("suppresses equal writes with the same counters a cell bumps", function()
		Compose.setWorkCounters(true)
		Compose.resetWorkCounters()
		local count = Compose.sharedCell(1)
		count:set(2)
		count:set(2)
		count:set(1)
		local counters = Compose.readWorkCounters()
		expect(counters.cellWrites):toBe(2)
		expect(counters.cellWritesSuppressed):toBe(1)
		Compose.setWorkCounters(false)
	end)

	it("honours a supplied comparison", function()
		local word = Compose.sharedCell("cat", function(current: string, incoming: string): boolean
			return #current == #incoming
		end)
		word:set "dog"
		expect(word:peek()):toBe "cat"
		word:set "horse"
		expect(word:peek()):toBe "horse"
	end)

	it("takes the single-subscriber fast path: one watch, one write, one immediate run", function()
		local reactor, owner = domain()
		local value = Compose.sharedCell(0)
		local seen: { number } = {}
		Compose.owner.watch(owner, function(use)
			table.insert(seen, use(value))
		end)
		expect(seen):toEqual { 0 }

		value:set(1)
		expect(seen):toEqual { 0, 1 }
		Compose.reactor.settle(reactor)
		expect(seen):toEqual { 0, 1 }
		Compose.owner.dispose(owner)
	end)

	it("drives a formula exactly as a cell does", function()
		local level = Compose.sharedCell(100)
		local runs = 0
		local percent = Compose.formula(function(use)
			runs += 1
			return use(level) / 100
		end)
		expect(percent:peek()):toBe(1)
		level:set(50)
		expect(percent:peek()):toBe(0.5)
		level:set(50)
		expect(percent:peek()):toBe(0.5)
		expect(runs):toBe(2)
	end)

	it("outlives any owner that read it, because disposal is not expected", function()
		local reactor, owner = domain()
		local value = Compose.sharedCell(0)
		local firstRuns = 0
		Compose.owner.watch(owner, function(use)
			use(value)
			firstRuns += 1
		end)
		Compose.owner.dispose(owner)

		value:set(1)
		expect(firstRuns):toBe(1)
		expect(value:peek()):toBe(1)

		local _, second = domain()
		local seen: { number } = {}
		Compose.owner.watch(second, function(use)
			table.insert(seen, use(value))
		end)
		value:set(2)
		expect(seen):toEqual { 1, 2 }
		Compose.owner.dispose(second)
		Compose.reactor.settle(reactor)
	end)
end)

return nil
