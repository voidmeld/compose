--!strict

export type Summary = {
	samples: number,
	min: number,
	median: number,
	p95: number,
	p99: number,
	max: number,
	mean: number,
	deviation: number,
	total: number,
}

local function percentile(sorted: { number }, fraction: number): number
	local count = #sorted
	if count == 0 then
		return 0
	end
	local rank = math.ceil(fraction * count)
	return sorted[math.clamp(rank, 1, count)]
end

local function summarise(values: { number }): Summary
	local count = #values
	if count == 0 then
		return {
			samples = 0,
			min = 0,
			median = 0,
			p95 = 0,
			p99 = 0,
			max = 0,
			mean = 0,
			deviation = 0,
			total = 0,
		}
	end

	local sorted = table.clone(values)
	table.sort(sorted)

	local total = 0
	for _, value in sorted do
		total += value
	end
	local mean = total / count

	local variance = 0
	for _, value in sorted do
		local delta = value - mean
		variance += delta * delta
	end

	return {
		samples = count,
		min = sorted[1],
		median = percentile(sorted, 0.5),
		p95 = percentile(sorted, 0.95),
		p99 = percentile(sorted, 0.99),
		max = sorted[count],
		mean = mean,
		deviation = math.sqrt(variance / count),
		total = total,
	}
end

local function formatDuration(seconds: number): string
	if seconds >= 1 then
		return ("%.3f s"):format(seconds)
	elseif seconds >= 1e-3 then
		return ("%.3f ms"):format(seconds * 1e3)
	elseif seconds >= 1e-6 then
		return ("%.3f us"):format(seconds * 1e6)
	end
	return ("%.0f ns"):format(seconds * 1e9)
end

return {
	summarise = summarise,
	percentile = percentile,
	formatDuration = formatDuration,
}
