--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("isReadable", function()
	it("is true for a cell and for a formula", function()
		expect(Compose.isReadable(Compose.cell(1))):toBe(true)
		expect(Compose.isReadable(Compose.formula(function()
			return 1
		end))):toBe(true)
	end)

	it("is false for everything that merely looks reactive", function()
		expect(Compose.isReadable(nil)):toBe(false)
		expect(Compose.isReadable(5)):toBe(false)
		expect(Compose.isReadable "text"):toBe(false)
		expect(Compose.isReadable {}):toBe(false)
		expect(Compose.isReadable(function()
			return 1
		end)):toBe(false)
		expect(Compose.isReadable {
			peek = function()
				return 1
			end,
			set = function() end,
		}):toBe(false)
	end)
end)

describe("currentOwner", function()
	it("is nil outside any mount or withOwner", function()
		expect(Compose.currentOwner()):toBeNil()
	end)

	it("is the active owner inside withOwner, and pops afterwards", function()
		local owner = Compose.createOwner()
		local observed = Compose.withOwner(owner, function()
			return Compose.currentOwner()
		end)
		expect(observed):toBe(owner)
		expect(Compose.currentOwner()):toBeNil()
		owner.dispose()
	end)

	it("pops even when the body raises", function()
		local owner = Compose.createOwner()
		pcall(function()
			Compose.withOwner(owner, function()
				error "body failed"
			end)
		end)
		expect(Compose.currentOwner()):toBeNil()
		owner.dispose()
	end)

	it("nests: the innermost owner wins and the outer one is restored", function()
		local outer = Compose.createOwner()
		local inner = Compose.createOwner()
		Compose.withOwner(outer, function()
			expect(Compose.currentOwner()):toBe(outer)
			Compose.withOwner(inner, function()
				expect(Compose.currentOwner()):toBe(inner)
			end)
			expect(Compose.currentOwner()):toBe(outer)
		end)
		inner.dispose()
		outer.dispose()
	end)
end)

return nil
