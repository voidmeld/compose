--!strict

local fs = require "@std/fs"
local process = require "@std/process"
local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Lute = require "../.lute/dependencies/verify/src/lute"

local USAGE = "usage: lute run bench/publish.luau HISTORY_DIRECTORY COMMIT DATE STORED.json..."
local CHART_POINTS = 30
local CHARTED_UNIT = "microseconds"

type Row = { name: string, unit: string, median: number, p95: number }
type Entry = { commit: string, date: string, rows: { Row } }

local function sorted(samples: { number }): { number }
	local copy = table.clone(samples)
	table.sort(copy)
	return copy
end

local function quantile(samples: { number }, fraction: number): number
	local ordered = sorted(samples)
	if #ordered == 0 then
		return 0
	end
	local position = math.clamp(math.ceil(fraction * #ordered), 1, #ordered)
	return ordered[position]
end

local function rowsOf(paths: { string }): { Row }
	local byName: { [string]: Row } = {}
	local names: { string } = {}
	for _, path in paths do
		local stored = Benchmark.decode(Lute.parse(fs.readFileToString(path)))
		for _, measurement in stored.measurements do
			local samples: { number } = measurement.samples
			local existing = byName[measurement.name]
			if existing == nil and #samples > 0 then
				table.insert(names, measurement.name)
				byName[measurement.name] = {
					name = measurement.name,
					unit = measurement.unit,
					median = quantile(samples, 0.5),
					p95 = quantile(samples, 0.95),
				}
			end
		end
	end
	table.sort(names)
	local rows: { Row } = {}
	for _, name in names do
		table.insert(rows, byName[name])
	end
	return rows
end

local function readEntry(path: string): Entry?
	local ok, stored = pcall(function(): Benchmark.Stored
		return Benchmark.decode(Lute.parse(fs.readFileToString(path)))
	end)
	if not ok then
		return nil
	end
	local date, commit = string.match(stored.name, "^(%S+) (%S+)$")
	if date == nil or commit == nil then
		return nil
	end
	local rows: { Row } = {}
	for _, measurement in stored.measurements do
		local samples = measurement.samples
		if #samples == 2 then
			table.insert(
				rows,
				{ name = measurement.name, unit = measurement.unit, median = samples[1], p95 = samples[2] }
			)
		end
	end
	return { commit = commit, date = date, rows = rows }
end

local function encodeEntry(entry: Entry): string
	local measurements: { Benchmark.StoredMeasurement } = {}
	for _, row in entry.rows do
		table.insert(
			measurements,
			{ name = row.name, unit = row.unit, environment = "median-p95", samples = { row.median, row.p95 } }
		)
	end
	local stored: Benchmark.Stored = {
		schemaVersion = 1,
		name = `{entry.date} {entry.commit}`,
		measurements = measurements,
	}
	return Lute.encode(stored) .. "\n"
end

local function history(directory: string): { Entry }
	local entries: { Entry } = {}
	if fs.exists(directory) then
		for _, item in fs.listDirectory(directory) do
			if string.sub(item.name, -5) == ".json" then
				local entry = readEntry(`{directory}/{item.name}`)
				if entry then
					table.insert(entries, entry)
				end
			end
		end
	end
	table.sort(entries, function(left: Entry, right: Entry): boolean
		if left.date ~= right.date then
			return left.date < right.date
		end
		return left.commit < right.commit
	end)
	return entries
end

local function format(value: number, unit: string): string
	if unit == CHARTED_UNIT then
		return if value >= 1000 then ("%.2f ms"):format(value / 1000) else ("%.1f µs"):format(value)
	end
	return ("%g %s"):format(value, unit)
end

local function change(current: number, previous: number?): string
	if previous == nil or previous == 0 then
		return "—"
	end
	return ("%+.1f%%"):format((current / previous - 1) * 100)
end

local function render(entries: { Entry }): string
	local latest = entries[#entries]
	local previous = entries[#entries - 1]
	local before: { [string]: number } = {}
	if previous then
		for _, row in previous.rows do
			before[row.name] = row.median
		end
	end
	local lines = {
		"# Compose performance",
		"",
		`Latest: \`{latest.commit}\` on {latest.date}, measured on the CI Ubuntu runner by the paired performance shards.`,
		"Each value is the median of the candidate arm's samples; p95 is shown beside it. Change compares the previous main commit.",
		"",
		"| Benchmark | Median | p95 | Change |",
		"| --- | --- | --- | --- |",
	}
	for _, row in latest.rows do
		table.insert(
			lines,
			`| {row.name} | {format(row.median, row.unit)} | {format(row.p95, row.unit)} | {change(
				row.median,
				before[row.name]
			)} |`
		)
	end
	local start = math.max(1, #entries - CHART_POINTS + 1)
	local window = table.move(entries, start, #entries, 1, {})
	if #window >= 2 then
		table.insert(lines, "")
		table.insert(lines, `## Trends over the last {#window} main commits`)
		local charted: { string } = {}
		for _, row in latest.rows do
			if row.unit == CHARTED_UNIT and string.find(row.name, "/compose", 1, true) then
				table.insert(charted, row.name)
			end
		end
		for _, name in charted do
			local values: { string } = {}
			for _, entry in window do
				local found = "0"
				for _, row in entry.rows do
					if row.name == name then
						found = ("%.1f"):format(row.median)
					end
				end
				table.insert(values, found)
			end
			table.insert(lines, "")
			table.insert(lines, "```mermaid")
			table.insert(lines, "xychart-beta")
			table.insert(lines, `    title "{name} (median µs)"`)
			table.insert(lines, `    x-axis 1 --> {#window}`)
			table.insert(lines, `    line [{table.concat(values, ", ")}]`)
			table.insert(lines, "```")
		end
	end
	table.insert(lines, "")
	return table.concat(lines, "\n")
end

local directory = process.args[2]
local commit = process.args[3]
local date = process.args[4]
if directory == nil or commit == nil or date == nil or process.args[5] == nil then
	print(USAGE)
	process.exit(2)
end
local paths = table.move(process.args, 5, #process.args, 1, {})
local results = `{directory}/results`
fs.createDirectory(results, { makeParents = true })
local entry: Entry = { commit = commit, date = date, rows = rowsOf(paths) }
fs.writeStringToFile(`{results}/{date}-{string.sub(commit, 1, 12)}.json`, encodeEntry(entry))
local entries = history(results)
fs.writeStringToFile(`{directory}/README.md`, render(entries))
print(`publish: {#entry.rows} benchmarks for {commit}`)
