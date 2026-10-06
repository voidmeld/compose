--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function driven(start: number, target: number, deltas: { number }): Compose.SpringState
	local state = Compose.createSpringState({ start }, 1)
	for _, delta in deltas do
		Compose.stepSpring(state, { target }, delta, 0.5, 1)
	end
	return state
end

describe("spring integrator", function()
	describe("createSpringState", function()
		it("starts at rest at the given position", function()
			local state = Compose.createSpringState({ 3, -2 }, 2)
			expect(state.position[1]):toBe(3)
			expect(state.position[2]):toBe(-2)
			expect(state.velocity[1]):toBe(0)
			expect(state.velocity[2]):toBe(0)
			expect(state.arity):toBe(2)
		end)

		it("copies the position rather than holding the caller's table", function()
			local origin = { 5 }
			local state = Compose.createSpringState(origin, 1)
			origin[1] = 99
			expect(state.position[1]):toBe(5)
		end)
	end)

	describe("springCoefficients", function()
		it("derives stiffness and drag from period and damping", function()
			local stiffness, drag = Compose.springCoefficients(2 * math.pi, 1)
			expect(stiffness):toBeCloseTo(1, 1e-9)
			expect(drag):toBeCloseTo(2, 1e-9)

			local _, halfDrag = Compose.springCoefficients(2 * math.pi, 0.5)
			expect(halfDrag):toBeCloseTo(1, 1e-9)
		end)

		it("makes a shorter period stiffer", function()
			local loose = Compose.springCoefficients(1, 1)
			local tight = Compose.springCoefficients(0.25, 1)
			expect(tight):toBeGreaterThan(loose)
		end)
	end)

	describe("stepSpring", function()
		it("produces the same curve at 30fps and at 240fps", function()
			local coarse = driven(0, 1, table.create(30, 1 / 30))
			local fine = driven(0, 1, table.create(240, 1 / 240))
			expect(coarse.position[1]):toBeCloseTo(fine.position[1], 1e-3)
			expect(coarse.velocity[1]):toBeCloseTo(fine.velocity[1], 1e-3)
		end)

		it("survives a hitch without diverging from the steady run", function()
			local steady = driven(0, 1, table.create(24, 1 / 120))
			local hitched = driven(0, 1, { 1 / 120, 1 / 120, 20 / 120, 2 / 120 })
			expect(hitched.position[1]):toBeCloseTo(steady.position[1], 1e-6)
		end)

		it("reports how much time it actually simulated", function()
			local state = Compose.createSpringState({ 0 }, 1)
			expect(Compose.stepSpring(state, { 1 }, 1 / 60, 0.5, 1)):toBeCloseTo(1 / 60, 1e-9)
		end)

		it("clamps a stalled delta instead of simulating the stall", function()
			local afterStall = Compose.createSpringState({ 0 }, 1)
			local simulated = Compose.stepSpring(afterStall, { 1 }, 10, 0.5, 1)
			expect(simulated):toBeLessThan(10)

			local afterLongerStall = Compose.createSpringState({ 0 }, 1)
			expect(Compose.stepSpring(afterLongerStall, { 1 }, 100, 0.5, 1)):toBe(simulated)
			expect(afterLongerStall.position[1]):toBe(afterStall.position[1])
		end)

		it("does nothing for a zero or negative delta", function()
			local state = Compose.createSpringState({ 0 }, 1)
			expect(Compose.stepSpring(state, { 1 }, 0, 0.5, 1)):toBe(0)
			expect(Compose.stepSpring(state, { 1 }, -1, 0.5, 1)):toBe(0)
			expect(state.position[1]):toBe(0)
			expect(state.velocity[1]):toBe(0)
		end)

		it("settles critically damped without overshooting", function()
			local state = Compose.createSpringState({ 0 }, 1)
			for _ = 1, 600 do
				Compose.stepSpring(state, { 1 }, 1 / 60, 0.3, 1)
				expect(state.position[1]):toBeLessThanOrEqual(1 + 1e-9)
			end
			expect(state.position[1]):toBeCloseTo(1, 1e-3)
		end)

		it("overshoots when underdamped, which is what bounce is", function()
			local state = Compose.createSpringState({ 0 }, 1)
			local peak = 0
			for _ = 1, 600 do
				Compose.stepSpring(state, { 1 }, 1 / 60, 0.3, 0.2)
				peak = math.max(peak, state.position[1])
			end
			expect(peak):toBeGreaterThan(1)
		end)

		it("advances every axis of a multi-dimensional state", function()
			local state = Compose.createSpringState({ 0, 10 }, 2)
			for _ = 1, 600 do
				Compose.stepSpring(state, { 1, -5 }, 1 / 60, 0.3, 1)
			end
			expect(state.position[1]):toBeCloseTo(1, 1e-3)
			expect(state.position[2]):toBeCloseTo(-5, 1e-3)
		end)
	end)

	describe("springAtRest", function()
		it("is false while the spring is still travelling", function()
			local state = Compose.createSpringState({ 0 }, 1)
			Compose.stepSpring(state, { 1 }, 1 / 60, 0.5, 1)
			expect(Compose.springAtRest(state, { 1 }, { 0 }, 0.001)):toBe(false)
		end)

		it("becomes true once the spring has settled", function()
			local state = Compose.createSpringState({ 0 }, 1)
			for _ = 1, 600 do
				Compose.stepSpring(state, { 1 }, 1 / 60, 0.3, 1)
			end
			expect(Compose.springAtRest(state, { 1 }, { 0 }, 0.001)):toBe(true)
		end)

		it("judges closeness relative to the distance this leg set out to travel", function()
			local state = Compose.createSpringState({ 999 }, 1)
			expect(Compose.springAtRest(state, { 1000 }, { 0 }, 0.01)):toBe(true)
			expect(Compose.springAtRest(state, { 1000 }, { 998 }, 0.01)):toBe(false)
		end)

		it("still settles a leg that had no distance to travel", function()
			local state = Compose.createSpringState({ 5 }, 1)
			expect(Compose.springAtRest(state, { 5 }, { 5 }, 0.001)):toBe(true)
		end)

		it("is not at rest while velocity remains, even at the target", function()
			local state = Compose.createSpringState({ 1 }, 1)
			state.velocity[1] = 50
			expect(Compose.springAtRest(state, { 1 }, { 0 }, 0.001)):toBe(false)
		end)
	end)
end)

return nil
