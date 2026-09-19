--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Resource = { serial: number }

local function makePool(owner: Compose.Owner, maxRetained: number)
	local created = 0
	local destroyed: { [Resource]: number } = {}
	local pool = Compose.withOwner(owner, function()
		return Compose.createPool {
			create = function(): Resource
				created += 1
				return { serial = created }
			end,
			destroy = function(resource: Resource)
				destroyed[resource] = (destroyed[resource] or 0) + 1
			end,
			maxRetained = maxRetained,
		}
	end)
	return pool, function(): number
		return created
	end, destroyed
end

describe("pool identity contract", function()
	it("never hands the same resource to two holders at once", function()
		local owner = Compose.createOwner()
		local pool = makePool(owner, 4)

		local first = pool.acquire()
		local second = pool.acquire()
		local third = pool.acquire()
		expect(first.value ~= second.value):toBe(true)
		expect(first.value ~= third.value):toBe(true)
		expect(second.value ~= third.value):toBe(true)
		expect(pool.active()):toBe(3)

		local released = first.value
		first.release()
		local fourth = pool.acquire()
		expect(fourth.value):toBe(released)
		expect(fourth.value ~= second.value):toBe(true)
		expect(fourth.value ~= third.value):toBe(true)
		owner.dispose()
	end)

	it("reuses rather than reallocating across many cycles", function()
		local owner = Compose.createOwner()
		local pool, createdCount = makePool(owner, 1)

		local seen: { [Resource]: true } = {}
		for _ = 1, 50 do
			local lease = pool.acquire()
			seen[lease.value] = true
			lease.release()
		end

		expect(createdCount()):toBe(1)
		local distinct = 0
		for _ in seen do
			distinct += 1
		end
		expect(distinct):toBe(1)
		expect(pool.idle()):toBe(1)
		owner.dispose()
	end)

	it("destroys idle and leased resources exactly once on owner disposal", function()
		local owner = Compose.createOwner()
		local pool, createdCount, destroyed = makePool(owner, 4)

		local idleOne = pool.acquire()
		local idleTwo = pool.acquire()
		local held = pool.acquire()
		idleOne.release()
		idleTwo.release()
		expect(pool.idle()):toBe(2)
		expect(pool.active()):toBe(1)

		owner.dispose()

		expect(createdCount()):toBe(3)
		local total = 0
		for _, times in destroyed do
			expect(times):toBe(1)
			total += 1
		end
		expect(total):toBe(3)

		held.release()
		expect(destroyed[held.value]):toBe(1)
	end)

	it("bounds retention at maxRetained and reuses newest-idle first, by identity", function()
		local owner = Compose.createOwner()
		local pool, createdCount, destroyed = makePool(owner, 2)

		local a = pool.acquire()
		local b = pool.acquire()
		local c = pool.acquire()
		local valueA, valueB, valueC = a.value, b.value, c.value
		a.release()
		b.release()
		c.release()

		expect(pool.idle()):toBe(2)
		local destroyedTotal = 0
		for _ in destroyed do
			destroyedTotal += 1
		end
		expect(destroyedTotal):toBe(1)

		local next = pool.acquire()
		expect(next.value == valueA or next.value == valueB or next.value == valueC):toBe(true)
		expect(destroyed[next.value]):toBeNil()
		expect(createdCount()):toBe(3)
		owner.dispose()
	end)

	it("keeps a double release from freeing a slot twice", function()
		local owner = Compose.createOwner()
		local pool = makePool(owner, 2)

		local lease = pool.acquire()
		lease.release()
		lease.release()
		expect(pool.idle()):toBe(1)

		local first = pool.acquire()
		local second = pool.acquire()
		expect(first.value ~= second.value):toBe(true)
		owner.dispose()
	end)
end)

return nil
