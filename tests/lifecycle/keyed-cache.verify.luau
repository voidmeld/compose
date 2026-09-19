--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function makeCache<K, T>(owner: Compose.Owner, maxRetained: number, build: (K) -> T)
	local destroyed: { T } = {}
	local cache = Compose.withOwner(owner, function()
		return Compose.createKeyedCache {
			build = build,
			destroy = function(value: T)
				table.insert(destroyed, value)
			end,
			maxRetained = maxRetained,
		}
	end)
	return cache, destroyed
end

describe("keyed cache", function()
	it("builds once per key and returns the cached value on a repeat get", function()
		local owner = Compose.createOwner()
		local builds = 0
		local cache = makeCache(owner, 4, function(key: string)
			builds += 1
			return { key = key, serial = builds }
		end)

		local first = cache.get "sword"
		local second = cache.get "sword"
		expect(first):toBe(second)
		expect(builds):toBe(1)
		expect(cache.size()):toBe(1)
		owner.dispose()
	end)

	it("evicts the least-recently-used entry once over the cap", function()
		local owner = Compose.createOwner()
		local cache, destroyed = makeCache(owner, 2, function(key: string)
			return { key = key }
		end)

		local sword = cache.get "sword"
		cache.get "shield"
		expect(cache.size()):toBe(2)
		cache.get "helmet"
		expect(cache.size()):toBe(2)
		expect(destroyed):toEqual { sword }
		expect(cache.peek "sword"):toBe(nil)
		expect(cache.peek "shield" ~= nil):toBe(true)
		expect(cache.peek "helmet" ~= nil):toBe(true)
		owner.dispose()
	end)

	it("a get() refreshes recency so a touched entry survives the next eviction", function()
		local owner = Compose.createOwner()
		local cache, destroyed = makeCache(owner, 2, function(key: string)
			return { key = key }
		end)

		local sword = cache.get "sword"
		local shield = cache.get "shield"
		cache.get "sword"
		cache.get "helmet"

		expect(destroyed):toEqual { shield }
		expect(cache.peek "sword"):toBe(sword)
		expect(cache.peek "shield"):toBe(nil)
		owner.dispose()
	end)

	it("keys() reports recency order, least-recently-used first", function()
		local owner = Compose.createOwner()
		local cache = makeCache(owner, 4, function(key: string)
			return { key = key }
		end)

		cache.get "a"
		cache.get "b"
		cache.get "c"
		cache.get "a"
		expect(cache.keys()):toEqual { "b", "c", "a" }
		owner.dispose()
	end)

	it("evict() destroys one entry and no-ops for a key that is not retained", function()
		local owner = Compose.createOwner()
		local cache, destroyed = makeCache(owner, 4, function(key: string)
			return { key = key }
		end)

		local sword = cache.get "sword"
		cache.evict "sword"
		expect(destroyed):toEqual { sword }
		expect(cache.size()):toBe(0)

		cache.evict "sword"
		expect(destroyed):toEqual { sword }
		owner.dispose()
	end)

	it("peek never builds and never affects recency", function()
		local owner = Compose.createOwner()
		local builds = 0
		local cache = makeCache(owner, 4, function(key: string)
			builds += 1
			return { key = key }
		end)

		expect(cache.peek "sword"):toBe(nil)
		expect(builds):toBe(0)
		owner.dispose()
	end)

	it("disposing the owner destroys every retained entry exactly once", function()
		local owner = Compose.createOwner()
		local cache, destroyed = makeCache(owner, 4, function(key: string)
			return { key = key }
		end)

		cache.get "sword"
		cache.get "shield"
		owner.dispose()
		expect(#destroyed):toBe(2)
		owner.dispose()
		expect(#destroyed):toBe(2)
	end)

	it("a get() after disposal raises rather than resurrecting an entry", function()
		local owner = Compose.createOwner()
		local cache = makeCache(owner, 4, function(key: string)
			return { key = key }
		end)
		owner.dispose()
		expect(function()
			cache.get "sword"
		end):toThrow "disposed"
	end)

	it("fires the touch hook on both a miss and a hit, without changing eviction", function()
		local owner = Compose.createOwner()
		local touches: { string } = {}
		local cache = Compose.withOwner(owner, function()
			return Compose.createKeyedCache {
				build = function(key: string)
					return { key = key }
				end,
				destroy = function() end,
				maxRetained = 4,
				touch = function(key: string)
					table.insert(touches, key)
				end,
			}
		end)

		cache.get "sword"
		cache.get "sword"
		expect(touches):toEqual { "sword", "sword" }
		owner.dispose()
	end)

	it("requires an explicit finite retention bound", function()
		local owner = Compose.createOwner()
		expect(function()
			Compose.withOwner(owner, function()
				Compose.createKeyedCache({
					build = function(key: string)
						return key
					end,
					destroy = function() end,
				} :: any)
			end)
		end):toThrow "retained-entry bound"
		owner.dispose()
	end)

	it("requires an active owner", function()
		expect(function()
			Compose.createKeyedCache {
				build = function(key: string)
					return key
				end,
				destroy = function() end,
				maxRetained = 4,
			}
		end):toThrow "createKeyedCache ran outside an owner"
	end)

	it("destroys overflow instead of retaining without bound when maxRetained is 0", function()
		local owner = Compose.createOwner()
		local cache, destroyed = makeCache(owner, 0, function(key: string)
			return { key = key }
		end)
		cache.get "sword"
		cache.get "shield"
		expect(#destroyed):toBe(1)
		expect(cache.size()):toBe(1)
		owner.dispose()
		expect(#destroyed):toBe(2)
	end)
end)

return nil
