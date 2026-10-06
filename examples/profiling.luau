--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

local function run(): string
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors
	local cell = Compose.cell
	local formula = Compose.formula
	local profile = Compose.profile

	local elapsed = 0
	local function seconds(): number
		elapsed += 0.000005
		return elapsed
	end

	profile.start(seconds)

	local hitPoints = cell(1_000)
	profile.label(hitPoints, "unit.hitPoints")

	local maximum = cell(1_000)
	profile.label(maximum, "unit.maximumHitPoints")
	runtime:watch(function(use)
		use(maximum)
	end, "unit.maximumObserver")

	local fraction = formula(function(use)
		return use(hitPoints) / use(maximum)
	end)
	profile.label(fraction, "unit.healthFraction")

	local condition = formula(function(use)
		local value = use(fraction)
		if value > 0.6 then
			return "healthy"
		elseif value > 0.25 then
			return "hurt"
		end
		return "critical"
	end)
	profile.label(condition, "unit.condition")

	local dispose = runtime.mount(function()
		return Host.Frame {
			BarScale = fraction,
			ConditionText = condition,
		}
	end, test.root)

	for tick = 1, 200 do
		hitPoints:set(1_000 - tick * 4)
		runtime:settle()
	end

	local report = profile.stop()
	dispose()
	runtime:dispose()

	local byName: { [string]: Compose.ProfileNode } = {}
	for _, row in report.nodes do
		if row.label ~= nil then
			byName[row.label] = row
		end
	end

	local fractionRow = byName["unit.healthFraction"]
	local conditionRow = byName["unit.condition"]
	local observerRow = byName["unit.maximumObserver"]
	local published = conditionRow.recomputations - conditionRow.recomputationsSuppressed

	assert(fractionRow.recomputations == 201, "the fraction should recompute on every tick")
	assert(conditionRow.recomputations == 201, "the condition should be reached on every tick")
	assert(published == 3, "the condition should publish only when the word changes")
	assert(observerRow.runs == 1, "the named watch should run once when its source stays still")

	assert(not profile.active(), "the profiler is still running")
	assert(test.liveSubscriptions() == 0, "a subscription survived")

	return ("%s recomputed %dx, published %dx"):format(
		conditionRow.label :: string,
		conditionRow.recomputations,
		published
	)
end

return {
	name = "profiling",
	what = "finding the formula that recomputes constantly and publishes almost never",
	expected = "unit.condition recomputed 201x, published 3x",
	run = run,
}
