--!strict

local Compose = require "../../src/core"
local TestScene = require "../../src/test-scene"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("one host driving several runtimes", function()
	it("defers compaction until the outer frame completes after a nested frame removes a listener", function(own)
		local host = TestScene.create()
		local runtime = Compose.createRuntime(host.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local seen = 0
		local timeline = Compose.withOwner(owner, function()
			runtime.scheduler().after(0, function()
				host.step(0.01)
			end)
			runtime.scheduler().after(0, function()
				seen += 1
			end)
			return runtime.timeline { duration = 1 }
		end)
		own(function()
			Compose.owner.dispose(owner)
			runtime:dispose()
		end)
		expect(function()
			host.step(0.01)
		end).never:toThrow()
		expect(seen):toBe(1)
		expect(timeline.elapsed:peek()):toBe(0.02)
		expect(host.counts().frameListeners):toBe(1)
		Compose.owner.dispose(owner)
		expect(host.counts().frameListeners):toBe(0)
	end)

	it("continues frame work after a callback failure and releases the shared subscription", function()
		local host = TestScene.create()
		local runtime = Compose.createRuntime(host.adapter)
		local owner = Compose.createOwner(runtime.reactor)
		local timeline = Compose.withOwner(owner, function()
			runtime.scheduler().after(0, function()
				error "frame callback failed"
			end)
			return runtime.timeline { duration = 1 }
		end)
		expect(function()
			host.step(0.5)
		end):toThrow "frame callback failed"
		expect(timeline.elapsed:peek()):toBe(0.5)
		host.step(0.5)
		expect(timeline.completed:peek()):toBe(true)
		expect(host.counts().frameListeners):toBe(0)
		Compose.owner.dispose(owner)
		runtime:dispose()
	end)

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

		Compose.owner.watch(watcher, function(use)
			use(firstSpring)
			table.insert(order, "first")
		end)
		Compose.owner.watch(later, function(use)
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

		Compose.owner.dispose(watcher)
		expect(host.counts().frameListeners):toBe(1)
		Compose.owner.dispose(later)
		expect(host.counts().frameListeners):toBe(0)
		first:dispose()
		second:dispose()
	end)
end)

return nil
