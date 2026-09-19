--!strict

local fs = require "@std/fs"
local json = require "@std/json"
local process = require "@lute/process"

local Stats = require "./harness/stats"

type Measurement = {
	framework: string,
	seconds: { number },
	counters: { [string]: number },
	leakedInstances: number,
	leakedConnections: number,
	diagnostics: number?,
	firstDiagnostic: string?,
	medianSeconds: number,
	error: string?,
}

type WorkloadResult = {
	id: string,
	title: string,
	what: string,
	perUnit: { { count: number, name: string } }?,
	parity: string,
	parityDetail: string?,
	measurements: { Measurement },
}

type MemoryReading = {
	framework: string,
	liveKilobytes: number?,
	roundsSpreadKilobytes: number?,
	growthPerCycleKilobytes: number?,
	error: boolean?,
}

type Memory = {
	settleMethod: string,
	liveMethod: string,
	growthMethod: string,
	controlMethod: string,
	controlSlopeKilobytesPerCycle: number,
	leakThresholdKilobytesPerCycle: number,
	workloads: { { id: string, readings: { MemoryReading } } },
}

type Noise = {
	runs: number,
	pairs: number,
	medianSpread: number,
	p90Spread: number,
	threshold: number,
	perPair: { [string]: number },
}

type Samples = {
	schemaVersion: number,
	environment: {
		os: string,
		arch: string,
		cpu: string,
		threads: number,
		lute: string,
		composeCommit: string,
		workingTreeDirty: boolean,
		host: string,
	},
	frameworks: { { name: string, version: string, what: string } },
	workloads: { WorkloadResult },
}

local function optionalText(value: unknown): string?
	if type(value) == "string" then
		return value :: string
	end
	return nil
end

local function ratio(value: number, best: number): string
	if best <= 0 then
		return "-"
	end
	if value == best then
		return "**1.00x**"
	end
	return ("%.2fx"):format(value / best)
end

local function main(): number
	local from = "bench/results/committed"
	local args = process.args
	local index = 2
	while index <= #args do
		if args[index] == "--from" then
			index += 1
			from = args[index]
		else
			error(("report: unrecognised argument %q"):format(tostring(args[index])))
		end
		index += 1
	end

	local path = from .. "/samples.json"
	if not fs.exists(path) then
		print(("report: no samples at %s. Run `lute run bench/run.luau --commit` first."):format(path))
		return 1
	end

	local samples = json.deserialize(fs.readFileToString(path)) :: Samples
	local out: { string } = {}

	local function line(text: string?)
		table.insert(out, if text ~= nil then text else "")
	end

	line "# Benchmark results"
	line()
	line "**Generated from [`samples.json`](samples.json). Do not edit.**"
	line("Regenerate with `lute run bench/report.luau --from " .. from .. "`.")
	line()
	line "Read [`../../../docs/benchmarks.md`](../../../docs/benchmarks.md) before drawing conclusions from any"
	line "number here. In particular: every measurement is of *framework runtime cost against an emulated"
	line "host*. It is not engine cost, and a framework that wins here can still lose on a real engine if it"
	line "writes more properties or creates more Instances -- which is why the work counters are reported"
	line "next to the times."
	line()

	line "## Environment"
	line()
	line "| | |"
	line "| --- | --- |"
	line(("| OS | %s / %s |"):format(samples.environment.os, samples.environment.arch))
	line(("| CPU | %s (%d threads) |"):format(samples.environment.cpu, samples.environment.threads))
	line(("| Runtime | lute %s |"):format(samples.environment.lute))
	line(("| Measured source commit | `%s` |"):format(samples.environment.composeCommit))
	line(("| Working tree | %s |"):format(if samples.environment.workingTreeDirty then "**dirty**" else "clean"))
	line(("| Host | %s |"):format(samples.environment.host))
	line()

	line "## What is measured"
	line()
	line "| Entry | Version | What it is |"
	line "| --- | --- | --- |"
	for _, framework in samples.frameworks do
		line(("| %s | %s | %s |"):format(framework.name, framework.version, framework.what))
	end
	line()

	local noisePath = from .. "/noise.json"
	local noise: Noise? = if fs.exists(noisePath)
		then json.deserialize(fs.readFileToString(noisePath)) :: Noise
		else nil

	if noise ~= nil then
		local threshold = noise.threshold
		type Comparison = { workload: string, mine: number, theirs: number, ratio: number }
		local against: { [string]: { wins: { Comparison }, losses: { Comparison } } } = {}
		local opponents: { string } = {}

		for _, workload in samples.workloads do
			local found: number? = nil
			for _, measurement in workload.measurements do
				if measurement.framework == "compose" and optionalText(measurement.error) == nil then
					found = measurement.medianSeconds
				end
			end
			if found == nil or found <= 0 then
				continue
			end
			local mine: number = found
			for _, measurement in workload.measurements do
				local name = measurement.framework
				if name == "compose" or optionalText(measurement.error) ~= nil or measurement.medianSeconds <= 0 then
					continue
				end
				if against[name] == nil then
					against[name] = { wins = {}, losses = {} }
					table.insert(opponents, name)
				end
				local theirs = measurement.medianSeconds
				local faster = mine < theirs
				local comparison: Comparison = {
					workload = workload.id,
					mine = mine,
					theirs = theirs,
					ratio = if faster then theirs / mine else mine / theirs,
				}
				if faster then
					table.insert(against[name].wins, comparison)
				else
					table.insert(against[name].losses, comparison)
				end
			end
		end
		table.sort(opponents)

		local function lineFor(workload: string, opponent: string): number
			local mineSpread = noise.perPair[workload .. " / compose"] or 0
			local theirSpread = noise.perPair[workload .. " / " .. opponent] or 0
			return math.max(threshold, 1 + mineSpread, 1 + theirSpread)
		end

		local function isMaterial(comparison: Comparison, opponent: string): boolean
			return comparison.ratio > lineFor(comparison.workload, opponent)
		end

		local function material(list: { Comparison }, opponent: string): number
			local count = 0
			for _, comparison in list do
				if isMaterial(comparison, opponent) then
					count += 1
				end
			end
			return count
		end

		line "## What the abstraction costs"
		line()
		line "`bare` is not a competitor. It is the same observable work written as plain imperative"
		line "Luau against the same emulated host, with no ownership, no unwind, no reactivity and no"
		line "diagnostics. Every workload below is Compose against that floor, and the ratio is the"
		line "price of what the floor does not provide -- not a contest anybody is trying to win."
		line()
		line "Two questions, kept apart."
		line()
		line "A **strict** result is simply which median is lower, by any margin. A **material** result"
		line(
			("is one where the ratio exceeds **%.3fx**, or the amount either of the two measurements"):format(threshold)
		)
		line "moves on its own between runs, whichever is largest. That number is not chosen: it is the 90th"
		line "percentile of how far a median moves when this identical suite is re-run on this machine"
		line(("with nothing changed, %d workload/framework pairs across %d runs, in"):format(noise.pairs, noise.runs))
		line "[`noise.json`](noise.json). Half the pairs move by"
		line(
			("%.1f%% on their own. Below the threshold a comparison is reported as a tie, whichever"):format(
				noise.medianSpread * 100
			)
		)
		line "way it points, because re-running alone produces differences that large."
		line()
		line "| Against | Strictly faster | Strictly slower | Materially faster | Materially slower | Ties |"
		line "| --- | ---: | ---: | ---: | ---: | ---: |"
		for _, name in opponents do
			local record = against[name]
			local materialWins = material(record.wins, name)
			local materialLosses = material(record.losses, name)
			local total = #record.wins + #record.losses
			line(
				("| %s | %d | %d | %d | %d | %d |"):format(
					name,
					#record.wins,
					#record.losses,
					materialWins,
					materialLosses,
					total - materialWins - materialLosses
				)
			)
		end
		line()

		for _, name in opponents do
			local record = against[name]
			local losses: { Comparison } = {}
			for _, comparison in record.losses do
				if isMaterial(comparison, name) then
					table.insert(losses, comparison)
				end
			end
			if #losses == 0 then
				continue
			end
			table.sort(losses, function(left: Comparison, right: Comparison): boolean
				return left.ratio > right.ratio
			end)
			if name == "bare" then
				line "### What Compose costs over no framework at all"
				line()
				line "Not losses. Every row is the price of an ownership scope, an unwind that runs, a"
				line "reactive graph and a diagnostic, against code that provides none of them and could"
				line "not be maintained at the size of a real project."
				line()
				line "Read the absolute times, not the ratios. The largest ratios in this table sit on"
				line "the smallest absolute numbers, because that is where a fixed per-operation cost"
				line "shows up undiluted by the host work around it."
			else
				line(("### Where Compose materially loses to %s"):format(name))
			end
			line()
			line("| Workload | Compose | " .. name .. " | Ratio | Line it had to clear |")
			line "| --- | ---: | ---: | ---: | ---: |"
			for _, comparison in losses do
				line(
					("| `%s` | %s | %s | **%.2fx** | %.2fx |"):format(
						comparison.workload,
						Stats.formatDuration(comparison.mine),
						Stats.formatDuration(comparison.theirs),
						comparison.ratio,
						lineFor(comparison.workload, name)
					)
				)
			end
			line()
		end
	end

	line "## Results"
	line()

	for _, workload in samples.workloads do
		line(("### %s"):format(workload.title))
		line()
		line(("`%s`: %s"):format(workload.id, workload.what))
		line()

		local detail = optionalText(workload.parityDetail)
		if workload.parity == "mismatched" then
			line(("> **Parity failed, so no timings were recorded.** %s"):format(detail or "reason not recorded"))
			line()
			continue
		end
		if workload.parity == "single" then
			line(("> Only one framework implements this workload. %s"):format(detail or ""))
			line()
		end

		local best = math.huge
		for _, measurement in workload.measurements do
			if optionalText(measurement.error) == nil and measurement.medianSeconds > 0 then
				best = math.min(best, measurement.medianSeconds)
			end
		end

		local perUnit = workload.perUnit
		if perUnit ~= nil and #perUnit > 0 then
			local composeMedian: number? = nil
			for _, measurement in workload.measurements do
				if measurement.framework == "compose" and optionalText(measurement.error) == nil then
					composeMedian = measurement.medianSeconds
				end
			end
			line "**One run is a batch, not one operation.** The medians below cover the whole run."
			line()
			for _, unit in perUnit do
				local suffix = ""
				if composeMedian ~= nil and unit.name == "simulated frame" then
					local each = (composeMedian :: number) / unit.count
					suffix = (", Compose %s, %.2f%% of a 16.67 ms frame, %.2f%% of 8.33 ms"):format(
						Stats.formatDuration(each),
						each / 0.01667 * 100,
						each / 0.00833 * 100
					)
				elseif composeMedian ~= nil then
					suffix = (", Compose %s"):format(Stats.formatDuration((composeMedian :: number) / unit.count))
				end
				line(("- divide by **%d** for one %s%s"):format(unit.count, unit.name, suffix))
			end
			line()
		end

		line "| Framework | Median | p95 | Max | Relative | Instances | Property writes | Leaked |"
		line "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"
		for _, measurement in workload.measurements do
			local failure = optionalText(measurement.error)
			if failure ~= nil then
				line(("| %s | — | — | — | — | — | — | %s |"):format(measurement.framework, failure))
				continue
			end
			local summary = Stats.summarise(measurement.seconds)
			local leaked = measurement.leakedInstances + measurement.leakedConnections
			line(
				("| %s | %s | %s | %s | %s | %d | %d | %s |"):format(
					measurement.framework,
					Stats.formatDuration(summary.median),
					Stats.formatDuration(summary.p95),
					Stats.formatDuration(summary.max),
					ratio(summary.median, best),
					measurement.counters.instancesCreated or 0,
					measurement.counters.propertyWrites or 0,
					if leaked == 0 then "none" else ("**%d**"):format(leaked)
				)
			)
		end
		line()
		local first = workload.measurements[1]
		if first ~= nil then
			local summary = Stats.summarise(first.seconds)
			line(
				("<sub>%d samples per framework. Deviation on %s: %s.</sub>"):format(
					summary.samples,
					first.framework,
					Stats.formatDuration(summary.deviation)
				)
			)
			line()
		end
	end

	local memoryPath = from .. "/memory.json"
	if fs.exists(memoryPath) then
		local memory = json.deserialize(fs.readFileToString(memoryPath)) :: Memory
		line "## Memory"
		line()
		line "Measured under **lune**, not the runtime everything above runs on: lute exposes no"
		line "`collectgarbage`, so it cannot report a heap. Regenerate with `lune run bench/memory.luau --commit`."
		line()
		line(("- **Settling.** %s"):format(memory.settleMethod))
		line(("- **Live.** %s"):format(memory.liveMethod))
		line(("- **Growth.** %s"):format(memory.growthMethod))
		line(
			("- **Control.** %s Measured at **%+.2f KB/cycle**, so a reading counts as a leak only above **%.0f KB/cycle**."):format(
				memory.controlMethod,
				memory.controlSlopeKilobytesPerCycle,
				memory.leakThresholdKilobytesPerCycle
			)
		)
		line()
		for _, workload in memory.workloads do
			line(("### %s: memory"):format(workload.id))
			line()
			line "| Framework | Live | Round spread | Growth per cycle |"
			line "| --- | ---: | ---: | ---: |"
			for _, reading in workload.readings do
				if reading.error then
					line(("| %s | — | — | not implemented |"):format(reading.framework))
					continue
				end
				local growth = reading.growthPerCycleKilobytes or 0
				line(
					("| %s | %.0f KB | ±%.0f KB | %+.2f KB%s |"):format(
						reading.framework,
						reading.liveKilobytes or 0,
						reading.roundsSpreadKilobytes or 0,
						growth,
						if growth > memory.leakThresholdKilobytesPerCycle then " **leak**" else ""
					)
				)
			end
			line()
		end
	end

	fs.writeStringToFile(from .. "/report.md", table.concat(out, "\n") .. "\n")
	print(("report: wrote %s/report.md from %d workload(s)"):format(from, #samples.workloads))
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
