--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("selector", function()
	it("keeps unobserved formulas lazy and cuts off equal results through diamonds", function()
		Compose.withRootOwner(function(owner)
			local source = Compose.cell(1)
			local derivations, runs = 0, 0
			local parity = Compose.formula(function(use)
				derivations += 1
				return use(source) % 2
			end)
			local left = Compose.formula(function(use)
				return use(parity) + 10
			end)
			local right = Compose.formula(function(use)
				return use(parity) + 20
			end)
			source:set(3)
			expect(derivations):toBe(0)
			Compose.owner.watch(owner, function(use)
				expect(use(right) - use(left)):toBe(10)
				runs += 1
			end)
			source:set(5)
			expect(derivations):toBe(2)
			expect(runs):toBe(1)
			source:set(6)
			expect(derivations):toBe(3)
			expect(runs):toBe(2)
		end)
	end)

	it("notifies only the old and new keys among 500 projections", function()
		Compose.withRootOwner(function(owner)
			local selected = Compose.cell(1)
			local select = Compose.selector(selected)
			local runs = 0
			for key = 1, 500 do
				local active = select(key)
				expect(select(key)):toBe(active)
				Compose.owner.watch(owner, function(use)
					expect(use(active)):toBe(selected:peek() == key)
					runs += 1
				end)
			end
			expect(runs):toBe(500)
			for key = 2, 401 do
				selected:set(key)
			end
			expect(runs):toBe(1300)
			selected:set(401)
			expect(runs):toBe(1300)
		end)
	end)

	it("keeps direct reads and diamonds coherent across batches and formula sources", function()
		Compose.withRootOwner(function(owner)
			local source = Compose.cell(1)
			local derived = Compose.formula(function(use)
				return use(source) * 2
			end)
			local select = Compose.selector(derived)
			local first, second = select(2), select(4)
			local combined = Compose.formula(function(use)
				return `{use(first)}:{use(second)}:{use(derived)}`
			end)
			local seen: { string } = {}
			Compose.owner.watch(owner, function(use)
				local direct = use(source)
				table.insert(seen, `{direct}:{use(combined)}`)
			end)
			Compose.reactor.batch(assert(owner.reactor), function()
				source:set(2)
				expect(first:peek()):toBe(false)
				expect(second:peek()):toBe(true)
				source:set(3)
				expect(#seen):toBe(1)
			end)
			expect(seen):toEqual { "1:true:false:2", "3:false:false:6" }
			source:set(2)
			expect(seen[3]):toBe "2:false:true:4"
		end)
	end)

	it("supports nil, false, and identity keys with no subscribers", function()
		Compose.withRootOwner(function()
			local source = Compose.cell(nil)
			local select = Compose.selector(source)
			expect(select(nil):peek()):toBe(true)
			local flag = Compose.cell(false)
			local flags = Compose.selector(flag)
			expect(flags(false):peek()):toBe(true)
			flag:set(true)
			expect(flags(false):peek()):toBe(false)
			expect(flags(true):peek()):toBe(true)
			local a, b = {}, {}
			local object = Compose.cell(a)
			local objects = Compose.selector(object)
			object:set(b)
			expect(objects(a):peek()):toBe(false)
			expect(objects(b):peek()):toBe(true)
		end)
	end)

	it("routes nil transitions and chained selectors before readers run", function()
		Compose.withRootOwner(function(owner)
			local initial: number? = nil
			local source: Compose.Value<number?> = Compose.cell(initial)
			local select = Compose.selector(source)
			local absent = select(nil)
			local present = Compose.selector(absent)(false)
			local runs = 0
			expect(Compose.isValue(absent)):toBe(true)
			Compose.owner.watch(owner, function(use)
				local value = use(source)
				expect(use(absent)):toBe(value == nil)
				expect(use(present)):toBe(value ~= nil)
				runs += 1
			end)
			source:set(1)
			source:set(2)
			source:set(nil)
			expect(runs):toBe(4)
		end)
	end)

	it("unwinds owned selectors and rejects reads after disposal", function()
		local reactor = Compose.reactor.create()
		local owner = Compose.createOwner(reactor)
		local source = Compose.cell(1)
		local select = Compose.withOwner(owner, function()
			return Compose.selector(source)
		end)
		local active = select(1)
		Compose.owner.dispose(owner)
		Compose.owner.dispose(owner)
		source:set(2)
		expect(function()
			active:peek()
		end):toThrow "reactive/disposed-selector"
		expect(function()
			select(2)
		end):toThrow "reactive/disposed-selector"
		expect(function()
			Compose.selector(source)
		end):toThrow "selector/no-active-owner"
	end)

	it("uses key identity and settles independent reactors despite a failing reader", function()
		local first = Compose.reactor.create()
		local second = Compose.reactor.create()
		local model = Compose.createOwner(first)
		local view = Compose.createOwner(second)
		local equality = {
			__eq = function(): boolean
				return true
			end,
		}
		local a, b = setmetatable({}, equality), setmetatable({}, equality)
		local source = Compose.cell(a, function(): boolean
			return false
		end)
		local select = Compose.withOwner(model, function()
			return Compose.selector(source)
		end)
		local active = select(a)
		expect(select(b):peek()):toBe(false)
		local calls = 0
		Compose.owner.watch(model, function(use)
			assert(use(active), "reader failed")
		end)
		Compose.owner.watch(view, function(use)
			use(active)
			calls += 1
		end)
		expect(function()
			source:set(b)
		end):toThrow "reader failed"
		expect(calls):toBe(2)
		expect(select(b):peek()):toBe(true)
		Compose.owner.dispose(view)
		Compose.owner.dispose(model)
	end)

	it("recovers subscriptions after a formula source raises", function()
		Compose.withRootOwner(function(owner)
			local source = Compose.cell(1)
			local derived = Compose.formula(function(use)
				local value = use(source)
				assert(value ~= 2, "source failed")
				return value
			end)
			local select = Compose.selector(derived)
			local active = select(1)
			local seen: { boolean } = {}
			Compose.owner.watch(owner, function(use)
				table.insert(seen, use(active))
			end)
			expect(function()
				source:set(2)
			end):toThrow "source failed"
			source:set(3)
			expect(seen):toEqual { true, false }
		end)
	end)

	it("releases a failed construction while preserving its borrowed source", function()
		Compose.withRootOwner(function(owner)
			local source = Compose.cell(1)
			local runs = 0
			local derived = Compose.formula(function(use): number
				runs += 1
				local incoming = use(source)
				assert(incoming ~= 1, "initial source failed")
				return incoming
			end)
			local resources = Compose.owner.size(owner)
			expect(function()
				Compose.selector(derived)
			end):toThrow "initial source failed"
			expect(Compose.owner.size(owner)):toBe(resources)
			source:set(2)
			expect(runs):toBe(1)
			expect(derived:peek()):toBe(2)
		end)
	end)
end)

return nil
