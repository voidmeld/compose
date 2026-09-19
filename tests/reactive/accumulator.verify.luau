--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function domain()
	local reactor = Compose.reactor()
	local owner = Compose.createOwner(reactor)
	return reactor, owner
end

local function summing(owner: Compose.Owner, events: Compose.Cell<number>)
	local reduces = 0
	local total: Compose.Readable<number>
	Compose.withOwner(owner, function()
		total = Compose.accumulator {
			from = events,
			reduce = function(previous: number, event: number): number
				reduces += 1
				return previous + event
			end,
			initial = 0,
		}
	end)
	return total, function(): number
		return reduces
	end
end

describe("accumulators", function()
	it("refuses to run with no owner", function()
		expect(function()
			Compose.accumulator {
				from = Compose.cell(0),
				reduce = function(previous: number, _event: number): number
					return previous
				end,
				initial = 0,
			}
		end):toThrow "owner"
	end)

	it("refuses a source it cannot subscribe to", function()
		local _, owner = domain()
		expect(function()
			Compose.withOwner(owner, function()
				Compose.accumulator {
					from = { latest = 1 } :: any,
					reduce = function(previous: number, _event: number): number
						return previous
					end,
					initial = 0,
				}
			end)
		end):toThrow "cell or a formula"
		owner.dispose()
	end)

	it("refuses a reduce it cannot call", function()
		local _, owner = domain()
		expect(function()
			Compose.withOwner(owner, function()
				Compose.accumulator {
					from = Compose.cell(0),
					reduce = 5 :: any,
					initial = 0,
				}
			end)
		end):toThrow "reduce"
		owner.dispose()
	end)

	it("refuses an option it does not have", function()
		local _, owner = domain()
		expect(function()
			Compose.withOwner(owner, function()
				Compose.accumulator({
					from = Compose.cell(0),
					reduce = function(previous: number, _event: number): number
						return previous
					end,
					reducer = true,
				} :: any)
			end)
		end):toThrow "option"
		owner.dispose()
	end)

	it("is eager: the mount-time value of the source is the first event", function()
		local _, owner = domain()
		local events = Compose.cell(5)
		local total, reduces = summing(owner, events)
		expect(reduces()):toBe(1)
		expect(total:peek()):toBe(5)
		owner.dispose()
	end)

	it("reduces each change in write order, exactly once each", function()
		local _, owner = domain()
		local events = Compose.cell(0)
		local order: { number } = {}
		local log: Compose.Readable<{ number }>
		Compose.withOwner(owner, function()
			log = Compose.accumulator {
				from = events,
				reduce = function(previous: { number }, event: number): { number }
					table.insert(order, event)
					local merged = table.clone(previous)
					table.insert(merged, event)
					return merged
				end,
				initial = {},
			}
		end)

		events:set(1)
		events:set(2)
		events:set(3)
		expect(order):toEqual { 0, 1, 2, 3 }
		expect(log:peek()):toEqual { 0, 1, 2, 3 }
		owner.dispose()
	end)

	it("coalesces writes inside one batch, because a cell is a value, not a queue", function()
		local reactor, owner = domain()
		local events = Compose.cell(0)
		local total, reduces = summing(owner, events)
		expect(reduces()):toBe(1)

		reactor:batch(function()
			events:set(5)
			events:set(7)
			expect(reduces()):toBe(1)
		end)
		expect(reduces()):toBe(2)
		expect(total:peek()):toBe(7)
		owner.dispose()
	end)

	it("never re-triggers itself from its own write", function()
		local _, owner = domain()
		local events = Compose.cell(0)
		local _, reduces = summing(owner, events)
		events:set(1)
		events:set(2)
		expect(reduces()):toBe(3)
		owner.dispose()
	end)

	it("suppresses an equal reduction on output", function()
		local reactor, owner = domain()
		local events = Compose.cell(0)
		local clamped: Compose.Readable<number>
		Compose.withOwner(owner, function()
			clamped = Compose.accumulator {
				from = events,
				reduce = function(previous: number, event: number): number
					return math.max(previous, math.min(event, 5))
				end,
				initial = 0,
			}
		end)
		local downstream = 0
		owner.watch(function(use)
			use(clamped)
			downstream += 1
		end)
		expect(downstream):toBe(1)

		events:set(9)
		reactor:settle()
		expect(clamped:peek()):toBe(5)
		expect(downstream):toBe(2)

		events:set(11)
		reactor:settle()
		expect(clamped:peek()):toBe(5)
		expect(downstream):toBe(2)
		owner.dispose()
	end)

	it("honours a supplied comparison on its output", function()
		local reactor, owner = domain()
		local events = Compose.cell(1)
		local latest: Compose.Readable<{ value: number }>
		Compose.withOwner(owner, function()
			latest = Compose.accumulator {
				from = events,
				reduce = function(_previous: { value: number }, event: number): { value: number }
					return { value = event }
				end,
				initial = { value = 0 },
				equals = function(current: { value: number }, incoming: { value: number }): boolean
					return current.value == incoming.value
				end,
			}
		end)
		local downstream = 0
		owner.watch(function(use)
			use(latest)
			downstream += 1
		end)
		expect(downstream):toBe(1)

		events:set(1.0)
		events:set(2)
		reactor:settle()
		expect(downstream):toBe(2)
		owner.dispose()
	end)

	it("tracks a formula source", function()
		local _, owner = domain()
		local raw = Compose.cell(1)
		local doubled = Compose.formula(function(use)
			return use(raw) * 2
		end)
		local peak: Compose.Readable<number>
		Compose.withOwner(owner, function()
			peak = Compose.accumulator {
				from = doubled,
				reduce = function(previous: number, event: number): number
					return math.max(previous, event)
				end,
				initial = 0,
			}
		end)
		expect(peak:peek()):toBe(2)
		raw:set(5)
		expect(peak:peek()):toBe(10)
		raw:set(3)
		expect(peak:peek()):toBe(10)
		owner.dispose()
	end)

	it("stops permanently once its owner is disposed", function()
		local _, owner = domain()
		local events = Compose.cell(0)
		local total, reduces = summing(owner, events)
		events:set(4)
		expect(total:peek()):toBe(4)

		owner.dispose()
		events:set(10)
		expect(reduces()):toBe(2)
		expect(total:peek()):toBe(4)
	end)

	it("keeps its state intact when a reduce raises, and drops only that event", function()
		local _, owner = domain()
		local events = Compose.cell(1)
		local total: Compose.Readable<number>
		Compose.withOwner(owner, function()
			total = Compose.accumulator {
				from = events,
				reduce = function(previous: number, event: number): number
					if event < 0 then
						error("negative event", 0)
					end
					return previous + event
				end,
				initial = 0,
			}
		end)
		expect(total:peek()):toBe(1)

		expect(function()
			events:set(-1)
		end):toThrow "negative event"

		expect(total:peek()):toBe(1)

		events:set(3)
		expect(total:peek()):toBe(4)
		owner.dispose()
	end)

	it("reports a raising reduce to the owner's boundary instead of raising", function()
		local _, owner = domain()
		local failures: { string } = {}
		owner.guardWith {
			report = function(failure: unknown)
				table.insert(failures, tostring(failure))
			end,
		}
		local events = Compose.cell(1)
		local total: Compose.Readable<number>
		Compose.withOwner(owner, function()
			total = Compose.accumulator {
				from = events,
				reduce = function(previous: number, event: number): number
					if event < 0 then
						error("negative event", 0)
					end
					return previous + event
				end,
				initial = 0,
			}
		end)

		events:set(-1)
		expect(#failures):toBe(1)
		expect(total:peek()):toBe(1)
		events:set(3)
		expect(total:peek()):toBe(4)
		owner.dispose()
	end)

	it("unwinds a construction-time raise completely", function()
		local _, owner = domain()
		local events = Compose.cell(0)
		local reduces = 0
		expect(function()
			Compose.withOwner(owner, function()
				Compose.accumulator {
					from = events,
					reduce = function(_previous: number, _event: number): number
						reduces += 1
						error("refused at mount", 0)
					end,
					initial = 0,
				}
			end)
		end):toThrow "refused at mount"
		expect(reduces):toBe(1)

		events:set(9)
		expect(reduces):toBe(1)
		expect(owner.size()):toBe(0)
		owner.dispose()
	end)

	it("is readable by formulas and watches like any other source", function()
		local reactor, owner = domain()
		local events = Compose.cell(0)
		local total = summing(owner, events)
		local caption = Compose.formula(function(use)
			return ("total %d"):format(use(total))
		end)
		local seen: { string } = {}
		owner.watch(function(use)
			table.insert(seen, use(caption))
		end)

		events:set(2)
		events:set(3)
		reactor:settle()
		expect(seen):toEqual { "total 0", "total 2", "total 5" }
		owner.dispose()
	end)
end)

return nil
