--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"
local describe, it, expect = Test.describe, Test.it, Test.expect

describe("runtime primitives", function()
	it("does not restart settled sampling for an equal restart key", function()
		local world = Support.world()
		local revision = Compose.cell(0)
		local value, owner = Support.owned(function()
			return world.runtime.settled {
				sample = function()
					return 1
				end,
				restart = function(use: Compose.Use)
					return math.floor(use(revision) / 2)
				end,
			}
		end)
		world.host.step(0)
		world.host.step(0)
		revision:set(1)
		expect(value:peek()):toBe(true)
		expect(world.host.counts().frameListeners):toBe(0)
		revision:set(2)
		expect(value:peek()):toBe(false)
		owner.dispose()
	end)
	it("uses ready time for optional settlement timeout", function()
		local world = Support.world()
		local ready, n = true, 0
		local result, owner = Support.owned(function()
			return world.runtime.settled {
				sample = function()
					n += 1
					return n
				end,
				ready = function()
					return ready
				end,
				timeout = 1,
			}
		end)
		world.host.step(0.5)
		ready = false
		world.host.step(10)
		ready = true
		world.host.step(0.5)
		expect(result:peek()):toBe(false)
		world.host.step(0.5)
		expect(result:peek()):toBe(true)
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
	end)

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

	it("settles only after equal ready samples and restarts without retaining idle frames", function()
		local world = Support.world()
		local restart = Compose.cell(0)
		local sample, ready = 0, false
		local value, owner = Support.owned(function()
			return world.runtime.settled {
				sample = function()
					return sample
				end,
				ready = function()
					return ready
				end,
				restart = restart,
				frames = 2,
			}
		end)
		world.host.step(1)
		expect(value:peek()):toBe(false)
		ready = true
		world.host.step(1)
		sample = 1
		world.host.step(1)
		expect(value:peek()):toBe(false)
		world.host.step(1)
		expect(value:peek()):toBe(true)
		expect(world.host.counts().frameListeners):toBe(0)
		restart:set(1)
		expect(value:peek()):toBe(false)
		expect(world.host.counts().frameListeners):toBe(1)
		owner.dispose()
		expect(world.host.counts().frameListeners):toBe(0)
	end)

	it("settles nil snapshots and custom equality and rejects invalid frame counts", function()
		local world = Support.world()
		Compose.withRootOwner(function()
			local value = world.runtime.settled {
				sample = function(): unknown
					return nil
				end,
			}
			local tables = world.runtime.settled {
				sample = function()
					return { x = 1 }
				end,
				equals = function(a: { x: number }, b: { x: number })
					return a.x == b.x
				end,
			}
			world.host.step(0)
			world.host.step(0)
			expect(value:peek()):toBe(true)
			expect(tables:peek()):toBe(true)
			expect(function()
				world.runtime.settled {
					sample = function()
						return 0
					end,
					frames = 0,
				}
			end):toThrow "positive integer"
		end)
	end)

end)

return nil
