--!strict

local fs = require "@std/fs"
local json = require "@std/json"
local process = require "@lute/process"

type Measurement = { framework: string, medianSeconds: number, error: unknown }

local function failure(value: unknown): string?
	if type(value) == "string" then
		return value
	end
	return nil
end
type Workload = { id: string, measurements: { Measurement } }
type Samples = { workloads: { Workload } }

type Pair = { key: string, spread: number, low: number, high: number }

local function percentile(sorted: { number }, fraction: number): number
	if #sorted == 0 then
		return 0
	end
	local rank = math.ceil(fraction * #sorted)
	return sorted[math.clamp(rank, 1, #sorted)]
end

local function main(): number
	local directories: { string } = {}
	local out = "bench/results/committed"
	local index = 2
	while index <= #process.args do
		local argument = process.args[index]
		if argument == "--out" then
			index += 1
			out = process.args[index]
		else
			table.insert(directories, argument)
		end
		index += 1
	end

	if #directories < 2 then
		print "measure-noise: needs at least two run directories to compare"
		return 1
	end

	local medians: { [string]: { number } } = {}
	local order: { string } = {}
	for _, directory in directories do
		local path = directory .. "/samples.json"
		if not fs.exists(path) then
			print(("measure-noise: no samples at %s"):format(path))
			return 1
		end
		local samples = json.deserialize(fs.readFileToString(path)) :: Samples
		for _, workload in samples.workloads do
			for _, measurement in workload.measurements do
				if failure(measurement.error) ~= nil or measurement.medianSeconds <= 0 then
					continue
				end
				local key = workload.id .. " / " .. measurement.framework
				if medians[key] == nil then
					medians[key] = {}
					table.insert(order, key)
				end
				table.insert(medians[key], measurement.medianSeconds)
			end
		end
	end

	local pairs_: { Pair } = {}
	local spreads: { number } = {}
	for _, key in order do
		local values = medians[key]
		if #values ~= #directories then
			continue
		end
		local low, high = math.huge, 0
		for _, value in values do
			low = math.min(low, value)
			high = math.max(high, value)
		end
		local spread = (high - low) / low
		table.insert(pairs_, { key = key, spread = spread, low = low, high = high })
		table.insert(spreads, spread)
	end

	table.sort(spreads)
	table.sort(pairs_, function(left: Pair, right: Pair): boolean
		return left.spread > right.spread
	end)

	local threshold = percentile(spreads, 0.90)
	print(("measure-noise: %d workload/framework pairs across %d runs"):format(#pairs_, #directories))
	print(("  median spread   %6.1f%%"):format(percentile(spreads, 0.50) * 100))
	print(("  p75             %6.1f%%"):format(percentile(spreads, 0.75) * 100))
	print(("  p90             %6.1f%%  <- threshold"):format(threshold * 100))
	print(("  p95             %6.1f%%"):format(percentile(spreads, 0.95) * 100))
	print(("  worst           %6.1f%%  (%s)"):format(spreads[#spreads] * 100, pairs_[1].key))
	print "  noisiest pairs:"
	for position = 1, math.min(8, #pairs_) do
		local pair = pairs_[position]
		print(("    %-34s %6.1f%%"):format(pair.key, pair.spread * 100))
	end

	local lines: { string } = {}
	table.insert(lines, "{")
	table.insert(lines, ('  "runs": %d,'):format(#directories))
	table.insert(lines, ('  "pairs": %d,'):format(#pairs_))
	table.insert(
		lines,
		'  "method": "relative spread (max-min)/min of the median of each workload/framework pair, across independent runs of the identical suite on one machine",'
	)
	table.insert(lines, ('  "medianSpread": %.6f,'):format(percentile(spreads, 0.50)))
	table.insert(lines, ('  "p75Spread": %.6f,'):format(percentile(spreads, 0.75)))
	table.insert(lines, ('  "p90Spread": %.6f,'):format(threshold))
	table.insert(lines, ('  "p95Spread": %.6f,'):format(percentile(spreads, 0.95)))
	table.insert(lines, ('  "worstSpread": %.6f,'):format(spreads[#spreads]))
	table.insert(
		lines,
		'  "thresholdRule": "a ratio between two medians counts as material only above 1 + p90Spread; at or below it, re-running alone produces differences that large",'
	)
	table.insert(lines, ('  "threshold": %.6f,'):format(1 + threshold))
	table.insert(
		lines,
		'  "perPairNote": "spread of each pair on its own. A comparison between two pairs is material only above the larger of the global threshold and what either of them moves by itself -- one noisy measurement is enough to explain a difference, however quiet the other is.",'
	)
	table.insert(lines, '  "perPair": {')
	local ordered: { Pair } = table.clone(pairs_)
	table.sort(ordered, function(left: Pair, right: Pair): boolean
		return left.key < right.key
	end)
	for position, pair in ordered do
		table.insert(lines, ('    "%s": %.6f%s'):format(pair.key, pair.spread, if position < #ordered then "," else ""))
	end
	table.insert(lines, "  }")
	table.insert(lines, "}")
	fs.writeStringToFile(out .. "/noise.json", table.concat(lines, "\n") .. "\n")
	print(("measure-noise: wrote %s/noise.json"):format(out))
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
