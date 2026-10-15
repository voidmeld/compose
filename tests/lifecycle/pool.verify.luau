--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("resource pool", function()
	it("drains pools and keyed caches after every destroy callback fails", function()
		for _, kind in { "pool", "keyed-cache" } do
			local owner = Compose.createOwner()
			local destroyed = 0
			local function destroy(_value: unknown): ()
				destroyed += 1
				error "destroy refused"
			end
			local empty = Compose.withOwner(owner, function()
				if kind == "pool" then
					local pool = Compose.createPool {
						create = function()
							return {}
						end,
						destroy = destroy,
						maxRetained = 2,
					}
					pool.acquire().release()
					pool.acquire()
					pool.acquire()
					return function()
						return pool.idle() + pool.active()
					end
				end
				local cache = Compose.createKeyedCache {
					build = function(key: number)
						return key
					end,
					destroy = destroy,
					maxRetained = 2,
				}
				cache.get(1)
				cache.get(2)
				return cache.size
			end)
			expect(owner.dispose):toThrow("2 " .. kind .. " resource destroy failures")
			expect(destroyed):toBe(2)
			expect(empty()):toBe(0)
			owner.dispose()
			expect(destroyed):toBe(2)
		end
	end)

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
				Compose.createPool(({
					create = function()
						return {}
					end,
					destroy = function() end,
				} :: unknown) :: Compose.PoolOptions<{}>)
			end)
		end):toThrow "retained-memory bound"
		owner.dispose()
	end)
end)

return nil
