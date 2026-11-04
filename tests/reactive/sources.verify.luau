--!strict

local Compose = require "../../src/core"
local Support = require "../support"
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

describe("Compose.sample", function()
	it("reads a body through a reader, rather than handing it nothing", function()
		local count = Compose.cell(2)
		local squared = Compose.formula(function(use): number
			return use(count) ^ 2
		end)
		expect(Compose.sample(count)):toBe(2)
		local doubled = function(use: Compose.Use): number
			return use(count) * 2
		end
		local sampleSquared = function(use: Compose.Use): number
			return use(squared)
		end
		expect(Compose.sample(doubled)):toBe(4)
		expect(Compose.sample(sampleSquared)):toBe(4)
		count:set(3)
		expect(Compose.sample(doubled)):toBe(6)
		expect(Compose.sample(sampleSquared)):toBe(9)
		squared:dispose()
	end)

	it("records no dependency for the body it samples", function()
		local reactor, owner = domain()
		local sampled = Compose.cell(0)
		local tracked = Compose.cell(0)
		local runs = 0
		Compose.owner.watch(owner, function(use)
			use(tracked)
			Compose.sample(function(read: Compose.Use): number
				return read(sampled)
			end)
			runs += 1
		end)
		expect(runs):toBe(1)

		sampled:set(1)
		Compose.reactor.settle(reactor)
		expect(runs):toBe(1)

		tracked:set(1)
		Compose.reactor.settle(reactor)
		expect(runs):toBe(2)
		Compose.owner.dispose(owner)
	end)

	it("refuses a value that is neither a node nor a body", function()
		local sample = Compose.sample
		expect(function()
			Support.invoke(sample, { width = 1 })
		end):toThrow "Compose.sample"
	end)

	it("names itself when a body reads something that is not a node", function()
		local ok, err = pcall(function()
			Compose.sample(function(use: Compose.Use): number
				Support.invoke(use, function() end)
				return 0
			end)
		end)
		expect(ok):toBe(false)
		local parsed = Compose.parseDiagnostic(tostring(err))
		expect(parsed ~= nil):toBe(true)
		expect((required(parsed)).code):toBe "reactive/not-a-node"
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
			Compose.owner.watch(owner, function(use)
				local read = use
				Support.invoke(read, body)
			end)
		end)
		expect(ok):toBe(false)
		local parsed = Compose.parseDiagnostic(tostring(err))
		expect(parsed ~= nil):toBe(true)
		local diagnostic = required(parsed)
		expect(diagnostic.code):toBe "reactive/not-a-node"
		expect(string.find(diagnostic.summary, "use ", 1, true) == 1):toBe(true)
		expect(string.find(diagnostic.summary, "function", 1, true) ~= nil):toBe(true)
		expect(#diagnostic.fields.fix > 0):toBe(true)
		Compose.owner.dispose(owner)
	end)

	it("refuses a plain table where a cell or formula was expected", function()
		local _reactor, owner = domain()
		expect(function()
			Compose.owner.watch(owner, function(use)
				local read = use
				Support.invoke(read, { value = 1 })
			end)
		end):toThrow "cell or formula"
		Compose.owner.dispose(owner)
	end)
end)

return nil
