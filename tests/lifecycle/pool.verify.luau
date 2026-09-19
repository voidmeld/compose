--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("resource pool", function()
	it("reuses reset resources and releases everything exactly once", function()
		local owner = Compose.createOwner()
		local created = 0
		local reset = 0
		local destroyed = 0
		local pool = Compose.withOwner(owner, function()
			return Compose.createPool {
				create = function()
					created += 1
					return { id = created }
				end,
				reset = function()
					reset += 1
				end,
				destroy = function()
					destroyed += 1
				end,
				maxRetained = 1,
			}
		end)
		local first = pool.acquire()
		first.release()
		first.release()
		local second = pool.acquire()
		expect(second.value.id):toBe(1)
		expect(created):toBe(1)
		expect(reset):toBe(1)
		owner.dispose()
		expect(destroyed):toBe(1)
		second.release()
		expect(destroyed):toBe(1)
	end)

	it("destroys overflow instead of retaining without bound", function()
		local owner = Compose.createOwner()
		local destroyed = 0
		local pool = Compose.withOwner(owner, function()
			return Compose.createPool {
				create = function()
					return {}
				end,
				destroy = function()
					destroyed += 1
				end,
				maxRetained = 0,
			}
		end)
		pool.acquire().release()
		expect(destroyed):toBe(1)
		owner.dispose()
		expect(destroyed):toBe(1)
	end)

	it("destroys a resource whose reset fails instead of poisoning the pool", function()
		local owner = Compose.createOwner()
		local destroyed = 0
		local pool = Compose.withOwner(owner, function()
			return Compose.createPool {
				create = function()
					return {}
				end,
				reset = function()
					error "cannot reset"
				end,
				destroy = function()
					destroyed += 1
				end,
				maxRetained = 1,
			}
		end)
		local lease = pool.acquire()
		expect(lease.release):toThrow "cannot reset"
		expect(destroyed):toBe(1)
		expect(pool.idle()):toBe(0)
		expect(pool.active()):toBe(0)
		owner.dispose()
		expect(destroyed):toBe(1)
	end)

	it("requires an explicit finite retention bound", function()
		local owner = Compose.createOwner()
		expect(function()
			Compose.withOwner(owner, function()
				Compose.createPool({
					create = function()
						return {}
					end,
					destroy = function() end,
				} :: any)
			end)
		end):toThrow "retained-memory bound"
		owner.dispose()
	end)
end)

return nil
