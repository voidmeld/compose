--!strict

local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Comparison = require "../bench/comparison"
local Test = require "./harness"

local function run(duration: number): Benchmark.Stored
	return {
		schemaVersion = 1,
		name = "revision",
		measurements = {
			{ name = "scene/compose/cold", unit = "microseconds", environment = "same-runner", samples = { duration } },
			{
				name = "scene/compose/counts",
				unit = "microseconds",
				environment = "same-runner",
				samples = { duration * 20 },
			},
		},
	}
end

local function compare(values: { number }): number
	local candidate: { Benchmark.Stored } = {}
	for _, value in values do
		table.insert(candidate, run(value))
	end
	return Benchmark.compare(
		Comparison.summarize { run(100), run(100), run(100) },
		Comparison.summarize(candidate),
		{ rule = { ratio = 1.5, floor = 5 }, minimumSamples = 3 }
	).failed
end

Test.describe("paired benchmark comparison", function()
	Test.it("retains a repeatable regression while rejecting a single noisy process", function()
		Test.expect(compare { 100, 1000, 100 }):toBe(0)
		Test.expect(compare { 200, 100, 200 }):toBe(1)
		Test.expect(compare { 200, 200, 200 }):toBe(1)
	end)
	Test.it("does not compare the diagnostic counters pass as a timing sample", function()
		local summary = Comparison.summarize { run(100), run(100), run(100) }
		Test.expect(#summary.measurements):toBe(1)
		Test.expect(summary.measurements[1].name):toBe "scene/compose/cold"
	end)
	Test.it("refuses incomplete evidence rather than shrinking coverage", function()
		local incomplete = run(100)
		table.remove(incomplete.measurements, 1)
		Test.expect(function()
			Comparison.summarize { run(100), incomplete, run(100) }
		end):toThrow "missing measurements"
		Test.expect(function()
			Comparison.summarize { run(100), run(100) }
		end):toThrow "three complete runs"
	end)
end)

return nil
