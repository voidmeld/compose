--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local FRAME = 1 / 60

local function step(world: Support.World, seconds: number)
	for _ = 1, math.round(seconds / FRAME) do
		world.host.step(FRAME)
	end
	world.settle()
end

describe("ramp", function()
	it("holds its initial value and reaches a target over the requested seconds", function()
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		local ramp = Compose.withOwner(owner, function()
			return world.runtime.ramp(1)
		end)
		expect(ramp.value:peek()):toBe(1)
		ramp.retarget(0, 0.5)
		world.settle()
		step(world, 0.25)
		expect(ramp.value:peek()):toBeCloseTo(0.5, 0.05)
		step(world, 0.3)
		expect(ramp.value:peek()):toBe(0)
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
	end)

	it("retargets from the current value with the new duration", function()
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		local ramp = Compose.withOwner(owner, function()
			return world.runtime.ramp(0)
		end)
		ramp.retarget(1, 1)
		step(world, 0.5)
		local midway = ramp.value:peek()
		expect(midway):toBeCloseTo(0.5, 0.05)
		ramp.retarget(0, 0.2)
		step(world, 0.1)
		expect(ramp.value:peek()):toBeCloseTo(midway / 2, 0.05)
		step(world, 0.2)
		expect(ramp.value:peek()):toBe(0)
		owner.dispose()
	end)

	it("jumps at once for a zero duration and ramps again afterwards", function()
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		local ramp = Compose.withOwner(owner, function()
			return world.runtime.ramp(0)
		end)
		ramp.retarget(1, 0)
		world.settle()
		expect(ramp.value:peek()):toBe(1)
		expect(world.host.counts().frameListeners):toBe(0)
		ramp.retarget(0, 0.4)
		step(world, 0.2)
		expect(ramp.value:peek()):toBeCloseTo(0.5, 0.05)
		owner.dispose()
	end)

	it("applies the easing to progress", function()
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		local ramp = Compose.withOwner(owner, function()
			return world.runtime.ramp(0, { ease = Compose.easing.inQuad })
		end)
		ramp.retarget(1, 1)
		step(world, 0.5)
		expect(ramp.value:peek()):toBeCloseTo(0.25, 0.05)
		owner.dispose()
	end)

	it("drives a bound property and releases its frame listener on dispose", function()
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		local ramp = Compose.withOwner(owner, function()
			return world.runtime.ramp(0)
		end)
		ramp.retarget(1, 1)
		world.settle()
		expect(world.host.counts().frameListeners):toBe(1)
		owner.dispose()
		expect(world.host.counts().frameListeners):toBe(0)
	end)

	it("refuses a non-finite duration and a missing owner", function()
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		local ramp = Compose.withOwner(owner, function()
			return world.runtime.ramp(0)
		end)
		for _, bad in { math.huge - math.huge, math.huge, ("1" :: unknown) :: number } do
			expect(function()
				ramp.retarget(1, bad)
			end):toThrow "ramp/invalid-seconds"
		end
		owner.dispose()
		expect(function()
			world.runtime.ramp(0)
		end):toThrow "owner/no-active-owner"
	end)
end)

return nil
