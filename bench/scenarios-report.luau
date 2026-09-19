--!strict

local Stats = require "./harness/stats"
local fs = require "@std/fs"
local json = require "@std/json"
local process = require "@lute/process"

local FRAME_60 = 1 / 60
local FRAME_120 = 1 / 120

local function optionalText(value: unknown): string?
	if type(value) == "string" then
		return value :: string
	end
	return nil
end

local function percentOfFrame(seconds: number, frame: number): string
	return ("%.2f%%"):format(seconds / frame * 100)
end

local function main(): number
	local from = "bench/results/scenarios"
	local index = 2
	while index <= #process.args do
		if process.args[index] == "--from" then
			index += 1
			from = process.args[index]
		end
		index += 1
	end

	local path = from .. "/samples.json"
	if not fs.exists(path) then
		print(("scenarios-report: no samples at %s"):format(path))
		return 1
	end
	local samples = json.deserialize(fs.readFileToString(path)) :: any

	local out: { string } = {}
	local function line(text: string?)
		table.insert(out, if text ~= nil then text else "")
	end

	line "# Representative scenario results"
	line()
	line "**Generated from [`samples.json`](samples.json). Do not edit.**"
	line("Regenerate with `lute run bench/scenarios-report.luau --from " .. from .. "`.")
	line()
	line "Read [`../../../docs/scenarios.md`](../../../docs/scenarios.md) before drawing a conclusion from"
	line "any number here, in particular the note on what the steady column is and is not."
	line()

	line "## What is measured"
	line()
	line "| Entry | Version | What it is |"
	line "| --- | --- | --- |"
	for _, entry in samples.implementations do
		line(("| %s | %s | %s |"):format(entry.name, entry.version, entry.what))
	end
	line()
	line(("Host: %s. Runtime: %s."):format(samples.environment.host, samples.environment.runtime))
	line()
	line "**`frame`** is the mean of one steady frame, timed as a block and divided, because the"
	line "clock quantises to a microsecond and a five-microsecond frame timed individually is a"
	line "five-bucket histogram. **`p99`** and **`max`** come from the per-frame samples, which"
	line "carry the tail a budget is actually missed by. Both are in `samples.json`."
	line()

	local seen: { [string]: boolean } = {}
	for _, result in samples.results do
		if seen[result.scenario] then
			continue
		end
		seen[result.scenario] = true

		line(("## %s"):format(result.title))
		line()
		line(("`%s`: %s"):format(result.scenario, result.what))
		line()
		line(
			("Lane: **%s**. Pre-registered steady budget at the large scale: **%s**."):format(
				result.lane,
				Stats.formatDuration(result.steadyBudgetSeconds)
			)
		)
		line()
		line "| Scale | Size | Entry | Cold | Frame | p99 | Max | Burst p50 | Teardown | Live | Leaked |"
		line "| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"

		for _, entry in samples.results do
			if entry.scenario ~= result.scenario then
				continue
			end
			if entry.parity ~= "matched" then
				line(
					("| %s | %d | — | — | — | — | — | — | — | — | **parity: %s** |"):format(
						entry.scale,
						entry.size,
						tostring(entry.parityDetail)
					)
				)
				continue
			end
			for _, measurement in entry.measurements do
				local failure = optionalText(measurement.error)
				if failure ~= nil then
					line(
						("| %s | %d | %s | — | — | — | — | — | — | — | %s |"):format(
							entry.scale,
							entry.size,
							measurement.implementation,
							failure
						)
					)
					continue
				end
				local cold = Stats.summarise(measurement.coldSeconds)
				local chunk = Stats.summarise(measurement.steadyChunkSeconds)
				local steady = Stats.summarise(measurement.steadySeconds)
				local burst = Stats.summarise(measurement.burstSeconds)
				local teardown = Stats.summarise(measurement.teardownSeconds)
				local leaked = measurement.leakedInstances + measurement.leakedConnections
				line(
					("| %s | %d | %s | %s | %s | %s | %s | %s | %s | %d | %s |"):format(
						entry.scale,
						entry.size,
						measurement.implementation,
						Stats.formatDuration(cold.median),
						Stats.formatDuration(chunk.median),
						Stats.formatDuration(steady.p99),
						Stats.formatDuration(steady.max),
						Stats.formatDuration(burst.median),
						Stats.formatDuration(teardown.median),
						measurement.liveInstancesAfterBuild,
						if leaked == 0 then "none" else ("**%d**"):format(leaked)
					)
				)
			end
		end
		line()

		local budgets: { { name: string, seconds: number } } = result.frameBudgets or {}
		if #budgets == 0 then
			budgets = { { name = "16.67 ms", seconds = FRAME_60 }, { name = "8.33 ms", seconds = FRAME_120 } }
		end
		local header = { "| Scale | Entry | Frame vs budget" }
		local rule = { "| --- | --- | ---:" }
		for _, budget in budgets do
			table.insert(header, (" | Frame vs %s | p99 vs %s"):format(budget.name, budget.name))
			table.insert(rule, " | ---: | ---:")
		end
		line(table.concat(header, "") .. " |")
		line(table.concat(rule, "") .. " |")
		for _, entry in samples.results do
			if entry.scenario ~= result.scenario or entry.parity ~= "matched" then
				continue
			end
			for _, measurement in entry.measurements do
				if optionalText(measurement.error) ~= nil then
					continue
				end
				local chunk = Stats.summarise(measurement.steadyChunkSeconds)
				local steady = Stats.summarise(measurement.steadySeconds)
				local share = chunk.median / result.steadyBudgetSeconds
				local cells = {
					("| %s | %s | %s"):format(
						entry.scale,
						measurement.implementation,
						("%.0f%%%s"):format(share * 100, if share > 1 then " **over**" else "")
					),
				}
				for _, budget in budgets do
					table.insert(
						cells,
						(" | %s | %s"):format(
							percentOfFrame(chunk.median, budget.seconds),
							percentOfFrame(steady.p99, budget.seconds)
						)
					)
				end
				line(table.concat(cells, "") .. " |")
			end
		end
		line()

		line "| Scale | Entry | Instances created | destroyed | Property writes | Connections | Cell writes | Watch runs |"
		line "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |"
		for _, entry in samples.results do
			if entry.scenario ~= result.scenario or entry.parity ~= "matched" then
				continue
			end
			for _, measurement in entry.measurements do
				if optionalText(measurement.error) ~= nil then
					continue
				end
				local counters = measurement.counters

				local reactive = if type(measurement.reactive) == "table" then measurement.reactive else nil
				line(
					("| %s | %s | %d | %d | %d | %d | %s | %s |"):format(
						entry.scale,
						measurement.implementation,
						counters.instancesCreated or 0,
						counters.instancesDestroyed or 0,
						counters.propertyWrites or 0,
						counters.connectionsMade or 0,
						if reactive ~= nil then tostring(reactive.cellWrites or 0) else "—",
						if reactive ~= nil then tostring(reactive.watchRuns or 0) else "—"
					)
				)
			end
		end
		line()
	end

	fs.writeStringToFile(from .. "/report.md", table.concat(out, "\n") .. "\n")
	print(("scenarios-report: wrote %s/report.md"):format(from))
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
