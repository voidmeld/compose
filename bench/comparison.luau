--!strict

local Benchmark = require "../.lute/dependencies/verify/src/benchmark"

local function summarize(runs: { Benchmark.Stored }): Benchmark.Stored
	assert(#runs == 3, "paired comparison requires three complete runs per revision")
	local spread = Benchmark.spread(runs)
	assert(#spread.incomplete == 0, "paired comparison has missing measurements")
	local environments: { [string]: string } = {}
	for _, measurement in runs[1].measurements do
		environments[measurement.name] = measurement.environment
	end
	local measurements: { Benchmark.StoredMeasurement } = {}
	for _, noise in spread.noise do
		if not noise.name:match "/counts$" then
			table.insert(measurements, {
				name = noise.name,
				unit = noise.unit,
				environment = environments[noise.name],
				samples = noise.values,
			})
		end
	end
	assert(#measurements > 0, "paired comparison has no timed measurements")
	return { schemaVersion = 1, name = runs[1].name, measurements = measurements }
end

return { summarize = summarize }
