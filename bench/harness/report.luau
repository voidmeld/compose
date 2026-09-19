--!strict

local fs = require "@std/fs"

local Stats = require "./stats"

export type Environment = {
	os: string,
	arch: string,
	cpu: string,
	threads: number,
	lute: string,
	commit: string,
	dirty: boolean,
	host: string,
}

local function escape(text: string): string
	return (
		string.gsub(text, '[%c"\\]', function(character: string): string
			if character == '"' then
				return '\\"'
			elseif character == "\\" then
				return "\\\\"
			elseif character == "\n" then
				return "\\n"
			elseif character == "\r" then
				return "\\r"
			elseif character == "\t" then
				return "\\t"
			end
			return ("\\u%04x"):format(string.byte(character))
		end)
	)
end

local function quoted(text: string): string
	return '"' .. escape(text) .. '"'
end

local function numbers(values: { number }): string
	local parts = table.create(#values)
	for index, value in values do
		parts[index] = ("%.9g"):format(value)
	end
	return "[" .. table.concat(parts, ",") .. "]"
end

local function countersJson(counters: { [string]: number }): string
	local keys: { string } = {}
	for key in counters do
		table.insert(keys, key)
	end
	table.sort(keys)
	local parts: { string } = {}
	for _, key in keys do
		table.insert(parts, ("%s:%d"):format(quoted(key), counters[key]))
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

local function write(destination: string, environment: Environment, frameworks: { any }, results: { any })
	local lines: { string } = {}
	table.insert(lines, "{")
	table.insert(lines, '  "schemaVersion": 1,')
	table.insert(lines, '  "environment": {')
	table.insert(lines, ('    "os": %s,'):format(quoted(environment.os)))
	table.insert(lines, ('    "arch": %s,'):format(quoted(environment.arch)))
	table.insert(lines, ('    "cpu": %s,'):format(quoted(environment.cpu)))
	table.insert(lines, ('    "threads": %d,'):format(environment.threads))
	table.insert(lines, ('    "lute": %s,'):format(quoted(environment.lute)))
	table.insert(lines, ('    "composeCommit": %s,'):format(quoted(environment.commit)))
	table.insert(lines, ('    "workingTreeDirty": %s,'):format(tostring(environment.dirty)))
	table.insert(lines, ('    "host": %s'):format(quoted(environment.host)))
	table.insert(lines, "  },")

	table.insert(lines, '  "frameworks": [')
	for index, framework in frameworks do
		local suffix = if index == #frameworks then "" else ","
		table.insert(
			lines,
			('    { "name": %s, "version": %s, "what": %s }%s'):format(
				quoted(framework.name),
				quoted(framework.version),
				quoted(framework.what),
				suffix
			)
		)
	end
	table.insert(lines, "  ],")

	table.insert(lines, '  "workloads": [')
	for workloadIndex, result in results do
		table.insert(lines, "    {")
		table.insert(lines, ('      "id": %s,'):format(quoted(result.id)))
		table.insert(lines, ('      "title": %s,'):format(quoted(result.title)))
		table.insert(lines, ('      "what": %s,'):format(quoted(result.what)))
		local perUnit = result.perUnit
		if perUnit ~= nil and #perUnit > 0 then
			local pieces: { string } = {}
			for _, unit in perUnit do
				table.insert(pieces, ('{ "count": %d, "name": %s }'):format(unit.count, quoted(unit.name)))
			end
			table.insert(lines, ('      "perUnit": [%s],'):format(table.concat(pieces, ", ")))
		end
		table.insert(lines, ('      "parity": %s,'):format(quoted(result.parity)))
		table.insert(
			lines,
			('      "parityDetail": %s,'):format(
				if result.parityDetail ~= nil then quoted(result.parityDetail) else "null"
			)
		)
		table.insert(lines, '      "measurements": [')
		for index, measurement in result.measurements do
			local suffix = if index == #result.measurements then "" else ","
			local summary = Stats.summarise(measurement.samples)

			local fields: { string } = {
				("%s: %s"):format(quoted "framework", quoted(measurement.framework)),
				("%s: %s"):format(quoted "seconds", numbers(measurement.samples)),
				("%s: %s"):format(quoted "counters", countersJson(measurement.counters)),
				("%s: %d"):format(quoted "leakedInstances", measurement.leakedInstances),
				("%s: %d"):format(quoted "leakedConnections", measurement.leakedConnections),
				("%s: %d"):format(quoted "diagnostics", measurement.diagnostics or 0),
				("%s: %s"):format(
					quoted "firstDiagnostic",
					if measurement.firstDiagnostic ~= nil then quoted(measurement.firstDiagnostic) else "null"
				),
				("%s: %s"):format(quoted "medianSeconds", ("%.9g"):format(summary.median)),
				("%s: %s"):format(
					quoted "error",
					if measurement.error ~= nil then quoted(measurement.error) else "null"
				),
			}
			table.insert(lines, ("        { %s }%s"):format(table.concat(fields, ", "), suffix))
		end
		table.insert(lines, "      ]")
		table.insert(lines, if workloadIndex == #results then "    }" else "    },")
	end
	table.insert(lines, "  ]")
	table.insert(lines, "}")

	fs.writeStringToFile(destination .. "/samples.json", table.concat(lines, "\n") .. "\n")
end

return {
	write = write,
}
