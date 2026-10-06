--!strict

local Compose = require "../../src/core"
local TestScene = require "../../src/test-scene"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("one host driving several runtimes", function()
	it("gives each runtime its own listener on the one clock, in the order they took it", function()
		Compose.__resetForTests()
		local host = TestScene.create()
		local first = Compose.createRuntime(host.adapter)
		local second = Compose.createRuntime(host.adapter)

		local order: { string } = {}
		local firstTarget = Compose.cell(0)
		local secondTarget = Compose.cell(0)
		local watcher = Compose.createOwner(first.reactor)
		local later = Compose.createOwner(second.reactor)
		local firstSpring = Compose.withOwner(watcher, function()
			return first.spring(function(use)
				return use(firstTarget)
			end, { period = 0.1 })
		end)
		local secondSpring = Compose.withOwner(later, function()
			return second.spring(function(use)
				return use(secondTarget)
			end, { period = 0.1 })
		end)

		watcher.watch(function(use)
			use(firstSpring)
			table.insert(order, "first")
		end)
		later.watch(function(use)
			use(secondSpring)
			table.insert(order, "second")
		end)
		table.clear(order)

		firstTarget:set(10)
		secondTarget:set(10)
		first:settle()
		second:settle()
		table.clear(order)
		expect(host.counts().frameListeners):toBe(2)

		host.step(1 / 60)
		first:settle()
		second:settle()

		expect(order):toEqual { "first", "second" }
		expect(firstSpring:peek()).never:toBe(0)
		expect(secondSpring:peek()).never:toBe(0)

		watcher.dispose()
		expect(host.counts().frameListeners):toBe(1)
		later.dispose()
		expect(host.counts().frameListeners):toBe(0)
		first:dispose()
		second:dispose()
	end)
end)

return nil
