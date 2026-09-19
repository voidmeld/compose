--!strict

local fs = require "@std/fs"
local json = require "@std/json"
local process = require "@lute/process"

local Stats = require "../bench/harness/stats"

local THRESHOLD = 1.5

local FLOOR_SECONDS = 5e-6

type Measurement = { framework: string, medianSeconds: number }
type Workload = { id: string, measurements: { Measurement } }
type Samples = { workloads: { Workload } }

local function medians(path: string): { [string]: number }
	local decoded = json.deserialize(fs.readFileToString(path)) :: Samples
	local out: { [string]: number } = {}
	for _, workload in decoded.workloads do
		for _, measurement in workload.measurements do
			if measurement.framework == "compose" then
				out[workload.id] = measurement.medianSeconds
			end
		end
	end
	return out
end

local function main(): number
	local baselinePath = process.args[2]
	local currentPath = process.args[3]
	if baselinePath == nil or currentPath == nil or #process.args ~= 3 then
		print "check-benchmark-regressions: usage: lute run tools/check-benchmark-regressions.luau BASELINE.json CURRENT.json"
		return 1
	end
	if not fs.exists(baselinePath) or not fs.exists(currentPath) then
		print "check-benchmark-regressions: both explicit sample files must exist; run the selected benchmarks first"
		return 1
	end
	local baseline = medians(baselinePath)
	local current = medians(currentPath)
	if next(baseline) == nil or next(current) == nil then
		print "check-benchmark-regressions: both samples must contain Compose measurements"
		return 1
	end

	local ids: { string } = {}
	for id in baseline do
		table.insert(ids, id)
	end
	table.sort(ids)

	local regressions: { string } = {}
	local compared = 0
	local ignored = 0

	print ""
	for _, id in ids do
		local was = baseline[id]
		local now = current[id]
		if now == nil then
			table.insert(regressions, ("%s: no longer measured"):format(id))
			continue
		end
		if was < FLOOR_SECONDS then
			ignored += 1
			print(("  %-20s %-12s (too small to compare)"):format(id, Stats.formatDuration(now)))
			continue
		end

		compared += 1
		local factor = now / was
		local verdict = if factor > THRESHOLD then "REGRESSED" elseif factor < 0.8 then "faster" else "ok"
		print(
			("  %-20s %-12s was %-12s %.2fx  %s"):format(
				id,
				Stats.formatDuration(now),
				Stats.formatDuration(was),
				factor,
				verdict
			)
		)
		if factor > THRESHOLD then
			table.insert(
				regressions,
				("%s: %s, was %s (%.2fx, threshold %.2fx)"):format(
					id,
					Stats.formatDuration(now),
					Stats.formatDuration(was),
					factor,
					THRESHOLD
				)
			)
		end
	end

	print ""
	if #regressions > 0 then
		print(("check-benchmark-regressions: %d regression(s)"):format(#regressions))
		for _, regression in regressions do
			print("  " .. regression)
		end
		return 1
	end

	print(
		("check-benchmark-regressions: ok (%d compared at %.2fx, %d too small to compare)"):format(
			compared,
			THRESHOLD,
			ignored
		)
	)
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
