--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect, afterEach = Test.describe, Test.it, Test.expect, Test.afterEach

describe("setYieldChecking", function()
	afterEach(function()
		Compose.setYieldChecking(false)
	end)

	it("reports a lazy cell initialiser that yields as an error, not a suspension", function()
		Compose.setYieldChecking(true)
		local lazy = Compose.cell(function(): number
			coroutine.yield()
			return 1
		end)
		expect(function()
			lazy:peek()
		end):toThrow "yielded"
	end)

	it("reports an update function that yields", function()
		Compose.setYieldChecking(true)
		local count = Compose.cell(1)
		expect(function()
			count:update(function(value: number): number
				coroutine.yield()
				return value
			end)
		end):toThrow "yielded"
		expect(count:peek()):toBe(1)
	end)

	it("reports a supplied comparison that yields", function()
		Compose.setYieldChecking(true)
		local word = Compose.cell("cat", function(): boolean
			coroutine.yield()
			return false
		end)
		expect(function()
			word:set "dog"
		end):toThrow "yielded"
	end)

	it("reports a formula body that yields", function()
		Compose.setYieldChecking(true)
		local f = Compose.formula(function(): number
			coroutine.yield()
			return 1
		end)
		expect(function()
			f:peek()
		end):toThrow "yielded"
	end)

	it("reports a watch body that yields, from the first run and from a queued run", function()
		Compose.setYieldChecking(true)
		local owner = Compose.createOwner()
		local source = Compose.cell(0)
		expect(function()
			Compose.withOwner(owner, function()
				Compose.watch(function(use)
					use(source)
					coroutine.yield()
				end)
			end)
		end):toThrow "yielded"

		local runs = 0
		Compose.withOwner(owner, function()
			Compose.watch(function(use)
				use(source)
				runs += 1
				if runs > 1 then
					coroutine.yield()
				end
			end)
		end)
		expect(function()
			source:set(1)
		end):toThrow "yielded"
		owner.dispose()
	end)

	it("names the remedy: work that waits belongs in an async resource", function()
		Compose.setYieldChecking(true)
		local lazy = Compose.cell(function(): number
			coroutine.yield()
			return 1
		end)
		local ok, err = pcall(function()
			lazy:peek()
		end)
		expect(ok):toBe(false)
		expect(tostring(err)):toContain "async resource"
	end)

	it("leaves the graph healthy after reporting a yield", function()
		Compose.setYieldChecking(true)
		local count = Compose.cell(2)
		pcall(function()
			count:update(function(value: number): number
				coroutine.yield()
				return value
			end)
		end)

		local doubled = Compose.formula(function(use)
			return use(count) * 2
		end)
		expect(doubled:peek()):toBe(4)
		count:set(5)
		expect(doubled:peek()):toBe(10)
	end)

	it("runs a guarded function on a fresh coroutine while on, and on the caller's while off", function()
		local seen: { thread } = {}
		local function record(value: number): number
			table.insert(seen, coroutine.running())
			return value * 10
		end

		Compose.setYieldChecking(false)
		local count = Compose.cell(1)
		count:update(record)
		Compose.setYieldChecking(true)
		count:update(record)
		count:update(record)
		Compose.setYieldChecking(false)
		count:update(record)

		expect(#seen):toBe(4)
		expect(count:peek()):toBe(10000)
		expect(seen[1]):toBe(coroutine.running())
		expect(seen[4]):toBe(coroutine.running())
		expect(seen[2] ~= coroutine.running()):toBe(true)
		expect(seen[3] ~= coroutine.running()):toBe(true)
		expect(seen[2] ~= seen[3]):toBe(true)
	end)

	it("propagates an ordinary error from a checked function with its message intact", function()
		Compose.setYieldChecking(true)
		local count = Compose.cell(1)
		expect(function()
			count:update(function(): number
				error "deliberate failure inside the body"
			end)
		end):toThrow "deliberate failure inside the body"
	end)
end)

return nil
