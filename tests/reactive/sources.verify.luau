--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function domain()
	local reactor = Compose.reactor()
	local owner = Compose.createOwner(reactor)
	return reactor, owner
end

describe("Compose.sample", function()
	it("reads a cell without depending on it", function()
		local count = Compose.cell(3)
		expect(Compose.sample(count)):toBe(3)
	end)

	it("reads a body through a reader, rather than handing it nothing", function()
		local count = Compose.cell(3)
		local doubled = function(use: Compose.Use): number
			return use(count) * 2
		end
		expect(Compose.sample(doubled)):toBe(6)
		count:set(5)
		expect(Compose.sample(doubled)):toBe(10)
	end)

	it("reads a body that reads a formula at its current value", function()
		local count = Compose.cell(2)
		local squared = Compose.formula(function(use): number
			return use(count) ^ 2
		end)
		expect(Compose.sample(function(use: Compose.Use): number
			return use(squared)
		end)):toBe(4)
		count:set(3)
		expect(Compose.sample(function(use: Compose.Use): number
			return use(squared)
		end)):toBe(9)
	end)

	it("records no dependency for the body it samples", function()
		local reactor, owner = domain()
		local sampled = Compose.cell(0)
		local tracked = Compose.cell(0)
		local runs = 0
		owner.watch(function(use)
			use(tracked)
			Compose.sample(function(read: Compose.Use): number
				return read(sampled)
			end)
			runs += 1
		end)
		expect(runs):toBe(1)

		sampled:set(1)
		reactor:settle()
		expect(runs):toBe(1)

		tracked:set(1)
		reactor:settle()
		expect(runs):toBe(2)
		owner.dispose()
	end)

	it("refuses a value that is neither a node nor a body", function()
		local sample: any = Compose.sample
		expect(function()
			sample { width = 1 }
		end):toThrow "Compose.sample"
	end)

	it("names itself when a body reads something that is not a node", function()
		local ok, err = pcall(function()
			Compose.sample(function(use: Compose.Use): number
				return (use :: any)(function() end)
			end)
		end)
		expect(ok):toBe(false)
		local parsed = Compose.parseDiagnostic(tostring(err))
		expect(parsed ~= nil):toBe(true)
		expect((parsed :: Compose.Diagnostic).code):toBe "reactive/not-a-node"
		expect(string.find(tostring(err), "Compose.sample", 1, true) ~= nil):toBe(true)
	end)
end)

describe("use", function()
	it("refuses a body where a cell or formula was expected", function()
		local _reactor, owner = domain()
		local body = function(read: Compose.Use): number
			return read(Compose.cell(1))
		end
		local ok, err = pcall(function()
			owner.watch(function(use)
				local read: any = use
				read(body)
			end)
		end)
		expect(ok):toBe(false)
		local parsed = Compose.parseDiagnostic(tostring(err))
		expect(parsed ~= nil):toBe(true)
		local diagnostic = parsed :: Compose.Diagnostic
		expect(diagnostic.code):toBe "reactive/not-a-node"
		expect(string.find(diagnostic.summary, "use ", 1, true) == 1):toBe(true)
		expect(string.find(diagnostic.summary, "function", 1, true) ~= nil):toBe(true)
		expect(#diagnostic.fields.fix > 0):toBe(true)
		owner.dispose()
	end)

	it("refuses a plain table where a cell or formula was expected", function()
		local _reactor, owner = domain()
		expect(function()
			owner.watch(function(use)
				local read: any = use
				read { value = 1 }
			end)
		end):toThrow "cell or formula"
		owner.dispose()
	end)

	it("still reads a real node", function()
		local _reactor, owner = domain()
		local count = Compose.cell(7)
		local seen = 0
		owner.watch(function(use)
			seen = use(count)
		end)
		expect(seen):toBe(7)
		owner.dispose()
	end)
end)

return nil
