--!strict

local Environment = require "../environment"
local Stats = require "../harness/stats"
local Platform = require "../harness/platform"

local function quoted(value: string): string
	return ('"%s"'):format((string.gsub(string.gsub(value, "\\", "\\\\"), '"', '\\"')))
end

local function numbers(values: { number }): string
	local parts = table.create(#values)
	for index, value in values do
		parts[index] = ("%.9g"):format(value)
	end
	return "[" .. table.concat(parts, ",") .. "]"
end

local function counters(record: Environment.Counters): string
	local keys: { string } = {}
	for key in (record :: any) :: { [string]: number } do
		table.insert(keys, key)
	end
	table.sort(keys)
	local parts: { string } = {}
	for _, key in keys do
		table.insert(parts, ("%s: %d"):format(quoted(key), ((record :: any) :: { [string]: number })[key]))
	end
	return "{ " .. table.concat(parts, ", ") .. " }"
end

local function write(destination: string, frameworks: { any }, results: { any })
	local lines: { string } = {}
	table.insert(lines, "{")
	table.insert(lines, '  "schemaVersion": 1,')
	table.insert(lines, '  "kind": "representative-scenarios",')

	local host = Platform.name()
	table.insert(lines, '  "environment": {')
	table.insert(lines, ('    "runtime": %s,'):format(quoted(host)))
	table.insert(
		lines,
		'    "host": "bench/environment: an emulated Roblox engine, identical for every implementation"'
	)
	table.insert(lines, "  },")

	table.insert(lines, '  "implementations": [')
	for index, framework in frameworks do
		table.insert(
			lines,
			('    { "name": %s, "version": %s, "what": %s }%s'):format(
				quoted(framework.name),
				quoted(framework.version),
				quoted(framework.what),
				if index == #frameworks then "" else ","
			)
		)
	end
	table.insert(lines, "  ],")

	table.insert(lines, '  "results": [')
	for index, entry in results do
		local scenario = entry.scenario
		table.insert(lines, "    {")
		table.insert(lines, ('      "scenario": %s,'):format(quoted(scenario.id)))
		table.insert(lines, ('      "title": %s,'):format(quoted(scenario.title)))
		table.insert(lines, ('      "lane": %s,'):format(quoted(scenario.lane)))
		table.insert(lines, ('      "what": %s,'):format(quoted(scenario.what)))
		table.insert(lines, ('      "steadyBudgetSeconds": %.9g,'):format(scenario.steadyBudgetSeconds))
		do
			local parts: { string } = {}
			local budgets: { { name: string, seconds: number } } = scenario.frameBudgets or {}
			for _, budget in budgets do
				table.insert(parts, ('{ "name": %s, "seconds": %.9g }'):format(quoted(budget.name), budget.seconds))
			end
			table.insert(lines, ('      "frameBudgets": [%s],'):format(table.concat(parts, ", ")))
		end
		table.insert(lines, ('      "scale": %s,'):format(quoted(entry.scale.name)))
		table.insert(lines, ('      "size": %d,'):format(entry.scale.size))
		table.insert(lines, ('      "steadyFrames": %d,'):format(scenario.steadyFrames))
		table.insert(lines, ('      "parity": %s,'):format(quoted(entry.parity)))
		table.insert(
			lines,
			('      "parityDetail": %s,'):format(
				if entry.parityDetail ~= nil then quoted(entry.parityDetail) else "null"
			)
		)
		table.insert(lines, '      "measurements": [')
		for position, measurement in entry.measurements do
			table.insert(lines, "        {")
			table.insert(lines, ('          "implementation": %s,'):format(quoted(measurement.framework)))
			table.insert(
				lines,
				('          "error": %s,'):format(
					if measurement.error ~= nil then quoted(measurement.error) else "null"
				)
			)
			table.insert(lines, ('          "coldSeconds": %s,'):format(numbers(measurement.samples.cold)))
			table.insert(lines, ('          "steadySeconds": %s,'):format(numbers(measurement.samples.steady)))
			table.insert(
				lines,
				('          "steadyChunkSeconds": %s,'):format(numbers(measurement.samples.steadyChunk))
			)
			table.insert(lines, ('          "burstSeconds": %s,'):format(numbers(measurement.samples.burst)))
			table.insert(lines, ('          "teardownSeconds": %s,'):format(numbers(measurement.samples.teardown)))
			table.insert(
				lines,
				('          "liveInstancesAfterBuild": %d,'):format(measurement.liveInstancesAfterBuild)
			)
			table.insert(lines, ('          "leakedInstances": %d,'):format(measurement.leakedInstances))
			table.insert(lines, ('          "leakedConnections": %d,'):format(measurement.leakedConnections))
			table.insert(lines, ('          "counters": %s,'):format(counters(measurement.counters)))
			table.insert(
				lines,
				('          "reactive": %s,'):format(
					if measurement.reactive ~= nil then counters(measurement.reactive) else "null"
				)
			)
			table.insert(
				lines,
				('          "probe": %s'):format(
					if measurement.probe ~= nil then counters(measurement.probe) else "null"
				)
			)
			table.insert(lines, ("        }%s"):format(if position == #entry.measurements then "" else ","))
		end
		table.insert(lines, "      ]")
		table.insert(lines, ("    }%s"):format(if index == #results then "" else ","))
	end
	table.insert(lines, "  ]")
	table.insert(lines, "}")

	Platform.writeFile(destination .. "/samples.json", table.concat(lines, "\n") .. "\n")
end

return {
	write = write,
	summarise = Stats.summarise,
}
