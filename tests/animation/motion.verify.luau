--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local FRAME = 1 / 60

local function stepFor(world: Support.World, seconds: number)
	local remaining = seconds
	while remaining > 1e-9 do
		local delta = math.min(FRAME, remaining)
		remaining -= delta
		world.host.step(delta)
	end
end

describe("easing", function()
	it("pins both ends of every curve", function()
		local curves = (Compose.easing :: any) :: { [string]: (number) -> number }
		for name, curve in curves do
			if math.abs(curve(0)) > 1e-9 then
				error(("curve %s starts at %s, not 0"):format(name, tostring(curve(0))))
			end
			if math.abs(curve(1) - 1) > 1e-9 then
				error(("curve %s ends at %s, not 1"):format(name, tostring(curve(1))))
			end
		end
	end)

	it("derives inOut from in, so the midpoint is exactly half", function()
		expect(Compose.easing.inOutQuad(0.5)):toBeCloseTo(0.5, 1e-9)
		expect(Compose.easing.inOutCubic(0.5)):toBeCloseTo(0.5, 1e-9)
	end)

	it("moves monotonically for the standard curves", function()
		for _, name in { "linear", "inQuad", "outQuad", "inOutQuad", "inSine", "outExpo" } do
			local curve = (Compose.easing :: { [string]: (number) -> number })[name]
			local previous = -math.huge
			for step = 0, 20 do
				local value = curve(step / 20)
				if value < previous - 1e-9 then
					error("curve " .. name .. " went backwards")
				end
				previous = value
			end
		end
	end)
end)

describe("spring integrator", function()
	Test.beforeEach(function()
		Compose.__resetForTests()
	end)

	it("converges on its target", function()
		local state = Compose.createSpringState({ 0 }, 1)
		for _ = 1, 600 do
			Compose.stepSpring(state, { 10 }, FRAME, 0.5, 1)
		end
		expect(state.position[1]):toBeCloseTo(10, 1e-3)
	end)

	it("produces the same curve at any frame rate", function()
		local coarse = Compose.createSpringState({ 0 }, 1)
		local fine = Compose.createSpringState({ 0 }, 1)
		for _ = 1, 30 do
			Compose.stepSpring(coarse, { 1 }, 1 / 30, 0.5, 0.6)
		end
		for _ = 1, 240 do
			Compose.stepSpring(fine, { 1 }, 1 / 240, 0.5, 0.6)
		end
		expect(coarse.position[1]):toBeCloseTo(fine.position[1], 1e-3)
	end)

	it("overshoots when underdamped and does not when critically damped", function()
		local bouncy = Compose.createSpringState({ 0 }, 1)
		local firm = Compose.createSpringState({ 0 }, 1)
		local bouncyPeak, firmPeak = 0, 0
		for _ = 1, 120 do
			Compose.stepSpring(bouncy, { 1 }, FRAME, 0.3, 0.3)
			Compose.stepSpring(firm, { 1 }, FRAME, 0.3, 1)
			bouncyPeak = math.max(bouncyPeak, bouncy.position[1])
			firmPeak = math.max(firmPeak, firm.position[1])
		end
		expect(bouncyPeak):toBeGreaterThan(1)
		expect(firmPeak):toBeLessThanOrEqual(1.0001)
	end)

	it("clamps a huge delta instead of simulating it", function()
		local state = Compose.createSpringState({ 0 }, 1)
		local simulated = Compose.stepSpring(state, { 1 }, 30, 0.5, 1)
		expect(simulated):toBeLessThanOrEqual(0.25)
	end)
end)

describe("runtime.spring", function()
	it("moves towards the target and settles exactly on it", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local dispose, node = world.runtime.mount(function()
			local smooth = world.runtime.spring(function(use)
				return use(target)
			end, { period = 0.2, damping = 1 })
			return world.create "Frame" {
				Position = function(use)
					return use(smooth)
				end,
			}
		end, world.root)

		expect(world.host.propertyOf(node, "Position")):toBe(0)
		target:set(100)
		world.settle()

		stepFor(world, 0.05)
		local partway = world.host.propertyOf(node, "Position") :: number
		expect(partway):toBeGreaterThan(0)
		expect(partway):toBeLessThan(100)

		stepFor(world, 2)
		expect(world.host.propertyOf(node, "Position")):toBe(100)
		dispose()
	end)

	it("stops consuming frames once it settles", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local dispose = world.runtime.mount(function()
			local smooth = world.runtime.spring(function(use)
				return use(target)
			end, { period = 0.1 })
			return world.create "Frame" {
				Position = function(use)
					return use(smooth)
				end,
			}
		end, world.root)

		expect(world.host.counts().frameListeners):toBe(0)

		target:set(50)
		world.settle()
		expect(world.host.counts().frameListeners):toBe(1)

		stepFor(world, 2)
		expect(world.host.counts().frameListeners):toBe(0)

		world.host.resetCounts()
		stepFor(world, 1)
		expect(world.host.counts().setProperty):toBe(0)
		dispose()
	end)

	it("carries its velocity through an interruption", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local reading: () -> number
		local dispose = world.runtime.mount(function()
			local smooth = world.runtime.spring(function(use)
				return use(target)
			end, { period = 0.4, damping = 0.4 })
			reading = function(): number
				return smooth:peek()
			end
			return world.create "Frame" {
				Position = function(use)
					return use(smooth)
				end,
			}
		end, world.root)

		target:set(100)
		world.settle()
		stepFor(world, 0.15)
		local movingFast = reading()

		target:set(0)
		world.settle()
		stepFor(world, 0.15)
		expect(reading()):toBeLessThan(movingFast)

		stepFor(world, 4)
		expect(reading()):toBeCloseTo(0, 1e-6)
		dispose()
	end)

	it("stops completely when its owner is disposed", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local dispose = world.runtime.mount(function()
			local smooth = world.runtime.spring(function(use)
				return use(target)
			end, { period = 0.5 })
			return world.create "Frame" {
				Position = function(use)
					return use(smooth)
				end,
			}
		end, world.root)

		target:set(100)
		world.settle()
		dispose()

		world.host.resetCounts()
		stepFor(world, 1)
		expect(world.host.counts().setProperty):toBe(0)
		expect(world.host.counts().frameListeners):toBe(0)
	end)
end)

describe("reduced motion", function()
	it("arrives at once while the policy says so, and animates again when it changes back", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local reduced = Compose.cell(true)
		local dispose, node = world.runtime.mount(function()
			local smooth = world.runtime.spring(function(use)
				return use(target)
			end, { period = 0.2, damping = 1, reducedMotion = reduced })
			return world.create "Frame" {
				Position = function(use)
					return use(smooth)
				end,
			}
		end, world.root)

		target:set(100)
		world.settle()
		expect(world.host.propertyOf(node, "Position")):toBe(100)
		expect(world.host.counts().frameListeners):toBe(0)

		reduced:set(false)
		target:set(200)
		world.settle()
		stepFor(world, 0.05)
		local partway = world.host.propertyOf(node, "Position") :: number
		expect(partway):toBeGreaterThan(100)
		expect(partway):toBeLessThan(200)

		stepFor(world, 2)
		expect(world.host.propertyOf(node, "Position")):toBe(200)
		dispose()
	end)

	it("lands a spring that was already in flight when the policy turned on", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local reduced = Compose.cell(false)
		local dispose, node = world.runtime.mount(function()
			local smooth = world.runtime.spring(function(use)
				return use(target)
			end, { period = 0.2, damping = 1, reducedMotion = reduced })
			return world.create "Frame" {
				Position = function(use)
					return use(smooth)
				end,
			}
		end, world.root)

		target:set(100)
		world.settle()
		stepFor(world, 0.05)
		expect(world.host.propertyOf(node, "Position")):toBeLessThan(100)

		reduced:set(true)
		world.settle()
		expect(world.host.propertyOf(node, "Position")):toBe(100)
		expect(world.host.counts().frameListeners):toBe(0)
		dispose()
	end)

	it("takes the policy from a tween as well", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local dispose, node = world.runtime.mount(function()
			local eased = world.runtime.tween(function(use)
				return use(target)
			end, {
				seconds = 0.5,
				reducedMotion = function()
					return true
				end,
			})
			return world.create "Frame" {
				Position = function(use)
					return use(eased)
				end,
			}
		end, world.root)

		target:set(50)
		world.settle()
		expect(world.host.propertyOf(node, "Position")):toBe(50)
		dispose()
	end)

	it("refuses a policy it cannot read", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				local smooth = world.runtime.spring(function()
					return 0
				end, { reducedMotion = true :: any })
				return world.create "Frame" {
					Position = function(use)
						return use(smooth)
					end,
				}
			end, world.root)
		end):toThrow "animation/bad%-reduced%-motion"
	end)
end)

describe("runtime.tween", function()
	it("follows its curve and lands exactly on the target", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local dispose, node = world.runtime.mount(function()
			local eased = world.runtime.tween(function(use)
				return use(target)
			end, { seconds = 1, ease = Compose.easing.linear })
			return world.create "Frame" {
				Value = function(use)
					return use(eased)
				end,
			}
		end, world.root)

		target:set(100)
		world.settle()

		stepFor(world, 0.5)
		expect(world.host.propertyOf(node, "Value") :: number):toBeCloseTo(50, 2)

		stepFor(world, 0.6)
		expect(world.host.propertyOf(node, "Value")):toBe(100)
		expect(world.host.counts().frameListeners):toBe(0)
		dispose()
	end)

	it("restarts its curve from where it is when retargeted", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local dispose, node = world.runtime.mount(function()
			local eased = world.runtime.tween(function(use)
				return use(target)
			end, { seconds = 1 })
			return world.create "Frame" {
				Value = function(use)
					return use(eased)
				end,
			}
		end, world.root)

		target:set(100)
		world.settle()
		stepFor(world, 0.5)
		local midway = world.host.propertyOf(node, "Value") :: number

		target:set(200)
		world.settle()
		stepFor(world, 1 / 60)
		expect(world.host.propertyOf(node, "Value") :: number):toBeGreaterThanOrEqual(midway)
		expect(world.host.propertyOf(node, "Value") :: number):toBeLessThan(midway + 10)

		stepFor(world, 1.1)
		expect(world.host.propertyOf(node, "Value")):toBe(200)
		dispose()
	end)

	it("keeps a fixed duration across every retarget", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local dispose, node = world.runtime.mount(function()
			local eased = world.runtime.tween(function(use)
				return use(target)
			end, { seconds = 1, ease = Compose.easing.linear })
			return world.create "Frame" {
				Value = function(use)
					return use(eased)
				end,
			}
		end, world.root)

		target:set(100)
		world.settle()
		stepFor(world, 0.5)

		target:set(200)
		world.settle()
		stepFor(world, 1 - FRAME)
		expect(world.host.propertyOf(node, "Value") :: number):toBeLessThan(200)
		expect(world.host.counts().frameListeners):toBe(1)
		stepFor(world, 2 * FRAME)
		expect(world.host.propertyOf(node, "Value")):toBe(200)
		expect(world.host.counts().frameListeners):toBe(0)
		dispose()
	end)

	it("samples a readable duration at each retarget and settles on that schedule", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local duration = Compose.cell(1)
		local dispose, node = world.runtime.mount(function()
			local eased = world.runtime.tween(function(use)
				return use(target)
			end, { seconds = duration, ease = Compose.easing.linear })
			return world.create "Frame" {
				Value = function(use)
					return use(eased)
				end,
			}
		end, world.root)

		target:set(100)
		world.settle()
		stepFor(world, 0.5)
		local midway = world.host.propertyOf(node, "Value") :: number
		expect(midway):toBeCloseTo(50, 2)

		duration:set(0.25)
		target:set(200)
		world.settle()

		stepFor(world, FRAME)
		local resumed = world.host.propertyOf(node, "Value") :: number
		expect(resumed):toBeGreaterThanOrEqual(midway)
		expect(resumed):toBeLessThan(midway + 15)

		stepFor(world, 0.25)
		expect(world.host.propertyOf(node, "Value")):toBe(200)
		expect(world.host.counts().frameListeners):toBe(0)
		dispose()
	end)

	it("computes a body duration fresh for every leg", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local eased: Compose.Readable<number>
		local dispose, node = world.runtime.mount(function()
			eased = world.runtime.tween(function(use)
				return use(target)
			end, {
				seconds = function()
					return math.abs(target:peek() - eased:peek()) / 400
				end,
				ease = Compose.easing.linear,
			})
			return world.create "Frame" {
				Value = function(use)
					return use(eased)
				end,
			}
		end, world.root)

		target:set(100)
		world.settle()
		stepFor(world, 0.25 - FRAME)
		expect(world.host.propertyOf(node, "Value") :: number):toBeLessThan(100)
		stepFor(world, 2 * FRAME)
		expect(world.host.propertyOf(node, "Value")):toBe(100)

		target:set(300)
		world.settle()
		stepFor(world, 0.25)
		expect(world.host.propertyOf(node, "Value") :: number):toBeCloseTo(200, 4)
		stepFor(world, 0.3)
		expect(world.host.propertyOf(node, "Value")):toBe(300)
		expect(world.host.counts().frameListeners):toBe(0)
		dispose()
	end)

	it("does not depend on its duration readable", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local duration = Compose.cell(1)
		local dispose, node = world.runtime.mount(function()
			local eased = world.runtime.tween(function(use)
				return use(target)
			end, { seconds = duration, ease = Compose.easing.linear })
			return world.create "Frame" {
				Value = function(use)
					return use(eased)
				end,
			}
		end, world.root)

		duration:set(0.5)
		world.settle()
		expect(world.host.counts().frameListeners):toBe(0)

		duration:set(1)
		target:set(100)
		world.settle()
		stepFor(world, 0.5)
		duration:set(0.05)
		world.settle()
		stepFor(world, 0.25)
		local threeQuarters = world.host.propertyOf(node, "Value") :: number
		expect(threeQuarters):toBeCloseTo(75, 2)
		stepFor(world, 0.3)
		expect(world.host.propertyOf(node, "Value")):toBe(100)
		dispose()
	end)

	it("refuses a duration that is neither seconds nor readable", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				local eased = world.runtime.tween(function()
					return 0
				end, { seconds = "fast" :: any })
				return world.create "Frame" {
					Value = function(use)
						return use(eased)
					end,
				}
			end, world.root)
		end):toThrow "animation/bad%-duration"
	end)

	it("refuses a readable duration that produces a non-positive length", function()
		local world = Support.world()
		local target = Compose.cell(0)
		local duration = Compose.cell(0)
		local dispose = world.runtime.mount(function()
			local eased = world.runtime.tween(function(use)
				return use(target)
			end, { seconds = duration })
			return world.create "Frame" {
				Value = function(use)
					return use(eased)
				end,
			}
		end, world.root)

		expect(function()
			target:set(100)
			world.settle()
		end):toThrow "animation/bad%-duration"
		dispose()
	end)
end)

describe("codecs", function()
	Test.beforeEach(function()
		Compose.__resetForTests()
	end)

	it("registers number out of the box and nothing else", function()
		expect(Compose.registeredCodecs()):toContain "number"
	end)

	it("animates a registered multi-component type", function()
		local world = Support.world()
		Compose.registerCodec("vector", {
			arity = 2,
			encode = function(value: any, out: { number })
				out[1], out[2] = value.x, value.y
			end,
			decode = function(components: { number }): any
				return setmetatable({ x = components[1], y = components[2] }, { __type = "vector" })
			end,
		})

		local state = Compose.createSpringState({ 0, 0 }, 2)
		for _ = 1, 400 do
			Compose.stepSpring(state, { 3, 4 }, FRAME, 0.3, 1)
		end
		expect(state.position[1]):toBeCloseTo(3, 1e-3)
		expect(state.position[2]):toBeCloseTo(4, 1e-3)
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("refuses to animate a type with no codec", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				local moved = world.runtime.spring(function()
					return "not animatable"
				end)
				return world.create "Frame" {
					Value = function(use)
						return use(moved)
					end,
				}
			end, world.root)
		end):toThrow "animation/no-codec"
	end)
end)

return nil
