--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"
local describe, it, expect = Test.describe, Test.it, Test.expect

describe("runtime primitives", function()
	it("shares one property signal until the last holder releases it", function()
		local world = Support.world()
		local node = world.host.makeNode "Frame"
		world.host.poke(node, "AbsoluteSize", 10)
		local first, a = Support.owned(function()
			return world.runtime.observe(node, "AbsoluteSize")
		end)
		local second, b = Support.owned(function()
			return world.runtime.observe(node, "AbsoluteSize")
		end)
		expect(first):toBe(second)
		Compose.withOwner(a, function()
			for _ = 1, 98 do
				expect(world.runtime.observe(node, "AbsoluteSize")):toBe(first)
			end
		end)
		expect(world.host.liveSubscriptions()):toBe(1)
		expect(world.host.counts().frameListeners):toBe(0)
		world.host.poke(node, "AbsoluteSize", 20)
		expect(first:peek()):toBe(20)
		a.dispose()
		world.host.poke(node, "AbsoluteSize", nil)
		expect(second:peek()):toBe(nil)
		expect(world.host.liveSubscriptions()):toBe(1)
		b.dispose()
		expect(world.host.liveSubscriptions()):toBe(0)
		expect(world.host.isAlive(node)):toBe(true)
	end)

	it("unwinds observation and keeps different properties independent", function()
		local world = Support.world()
		local node = world.host.makeNode "Frame"
		expect(function()
			Compose.withRootOwner(function()
				world.runtime.observe(node, "Size")
				world.runtime.observe(node, "Position")
				expect(world.host.liveSubscriptions()):toBe(2)
				error "abort observation"
			end)
		end):toThrow "abort observation"
		expect(world.host.liveSubscriptions()):toBe(0)
	end)

end)

return nil
