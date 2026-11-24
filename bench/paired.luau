--!strict

local Benchmark = require "@verify/src/benchmark"
local Verify = require "@verify/src/core"

local function budget(total: number, round: number): number
	assert(total >= 1 and total % 1 == 0)
	assert(round >= 1 and round <= 6 and round % 1 == 0)
	if total == 1 then
		return 1
	end
	assert(total >= 3)
	local position = (round - 1) % 3 + 1
	return math.floor(total / 3) + (if position <= total % 3 then 1 else 0)
end

local function collection(original: Benchmark.Collection, round: number): Benchmark.Collection
	local result = table.clone(original)
	local members: { Benchmark.Spec } = {}
	for _, member in original.benchmarks do
		local copy = table.clone(member)
		copy.samples = budget(member.samples, round)
		table.insert(members, copy)
	end
	local yardstick = table.clone(original.yardstick)
	yardstick.samples = budget(yardstick.samples, round)
	local warmup = yardstick.warmup or 0
	yardstick.warmup = if warmup == 0 then 0 else budget(warmup, round)
	result.benchmarks = members
	result.yardstick = yardstick
	return result
end

local function selected(stored: Benchmark.Stored): Benchmark.Stored
	local run = Benchmark.decode(stored)
	local measurements: { Benchmark.StoredMeasurement } = {}
	for _, measurement in run.measurements do
		if not measurement.name:match "/counts$" then
			table.insert(measurements, measurement)
		end
	end
	assert(#measurements > 0, "paired measurements are missing")
	return { schemaVersion = 1, name = run.name, measurements = measurements }
end

local function pool(runs: { Benchmark.Stored }, reference: Benchmark.Stored): Benchmark.Stored
	local measurements: { Benchmark.StoredMeasurement } = {}
	local expected: { [string]: Benchmark.StoredMeasurement } = {}
	for _, measurement in reference.measurements do
		local copy = table.clone(measurement)
		copy.samples = {}
		expected[copy.name] = copy
		table.insert(measurements, copy)
	end
	for _, run in runs do
		assert(#run.measurements == #measurements, "paired measurement coverage changed")
		for _, measurement in run.measurements do
			local target = assert(expected[measurement.name], "unexpected paired measurement")
			assert(target.unit == measurement.unit, "paired measurement unit changed")
			assert(target.environment == measurement.environment, "paired measurement environment changed")
			for _, sample in measurement.samples do
				table.insert(target.samples, sample)
			end
		end
	end
	return { schemaVersion = 1, name = "pooled", measurements = measurements }
end

local function compare(base: { Benchmark.Stored }, candidate: { Benchmark.Stored })
	assert((#base == 3 or #base == 6) and #candidate == #base, "paired comparison needs three or six complete rounds")
	local left: { Benchmark.Stored } = {}
	local right: { Benchmark.Stored } = {}
	for round = 1, #base do
		table.insert(left, selected(base[round]))
		table.insert(right, selected(candidate[round]))
	end
	local reference = left[1]
	local first = pool(left, reference)
	local second = pool(right, reference)
	local overrides: { [string]: Benchmark.CompareRule } = {}
	local endpoints: { [string]: number } = {}
	local memories = 0
	for _, measurement in reference.measurements do
		if measurement.name:find("/memory/", 1, true) then
			local scene, endpoint = measurement.name:match "^(.*)/memory/(%a+)$"
			assert(scene ~= nil and (endpoint == "mounted" or endpoint == "teardown"), "unknown memory endpoint")
			endpoints[scene] = (endpoints[scene] or 0) + (if endpoint == "mounted" then 1 else 2)
			overrides[measurement.name] = { ratio = 1.05, floor = 64 }
			memories += 1
		end
	end
	for _, count in endpoints do
		assert(count == 3, "mounted or teardown memory evidence is missing")
	end
	assert(memories > 0 and memories < #reference.measurements, "paired timing or memory evidence is missing")
	local options: Benchmark.CompareOptions = { rule = { ratio = 1.5, floor = 5 }, rules = overrides }
	local pooled = Benchmark.compare(first, second, options)
	local rounds: { Verify.Report } = {}
	local persistent: { [string]: boolean } = {}
	for _, result in pooled.results do
		persistent[result.name] = result.status == "failed"
	end
	for round = 1, #base do
		local report = Benchmark.compare(left[round], right[round], options)
		table.insert(rounds, report)
		for _, result in report.results do
			if result.status ~= "failed" then
				persistent[result.name] = false
			end
		end
	end
	local regressed: { string } = {}
	for _, measurement in reference.measurements do
		if persistent[measurement.name] then
			table.insert(regressed, measurement.name)
		end
	end
	return { regressed = regressed, pooled = pooled, rounds = rounds }
end

return { budget = budget, collection = collection, compare = compare }
