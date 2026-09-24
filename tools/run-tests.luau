--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

local Manifest = require "../tests/manifest"
local Test = require "../tests/harness"
local Verify = require "../.lute/dependencies/verify/src/core"

type CaseResult = Test.CaseResult

local function parseArguments(): { filter: string?, jsonPath: string?, quiet: boolean }
	local options = { filter = nil :: string?, jsonPath = nil :: string?, quiet = false }

	local args = process.args
	local index = 2
	while index <= #args do
		local argument = args[index]
		if argument == "--filter" then
			index += 1
			options.filter = args[index]
		elseif argument == "--json" then
			index += 1
			options.jsonPath = args[index]
		elseif argument == "--quiet" then
			options.quiet = true
		else
			error(("run-tests: unrecognised argument %q"):format(tostring(argument)))
		end
		index += 1
	end
	return options
end

local function describeCase(result: CaseResult): string
	local source = result.source
	if source == nil then
		return result.id
	end
	return source .. " > " .. result.id
end

local function escapeJson(text: string): string
	local escaped = string.gsub(text, '[%c"\\]', function(character: string): string
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
		return string.format("\\u%04x", string.byte(character))
	end)
	return escaped
end

local function messageOf(result: CaseResult): string?
	if #result.failures > 0 then
		local pieces: { string } = {}
		for _, failure in result.failures do
			local prefix = if failure.phase == "case" then "" else failure.phase .. ": "
			table.insert(pieces, prefix .. failure.message)
		end
		return table.concat(pieces, "\n")
	end
	if #result.missingCapabilities > 0 then
		return "missing: " .. table.concat(result.missingCapabilities, ", ")
	end
	return nil
end

local function statusOf(result: CaseResult): "passed" | "failed" | "skipped"
	if result.status == "passed" then
		return "passed"
	elseif result.status == "skipped" then
		return "skipped"
	end
	return "failed"
end

local function toJson(results: { CaseResult }, files: number, failures: number, skipped: number): string
	local lines: { string } = {}
	table.insert(lines, "{")
	table.insert(lines, '  "schemaVersion": 1,')
	table.insert(lines, ('  "files": %d,'):format(files))
	table.insert(lines, ('  "cases": %d,'):format(#results))
	table.insert(lines, ('  "failed": %d,'):format(failures))
	table.insert(lines, ('  "skipped": %d,'):format(skipped))
	table.insert(lines, '  "results": [')
	for index, result in results do
		local suffix = if index == #results then "" else ","
		local text = messageOf(result)
		local message = if text ~= nil then '"' .. escapeJson(text) .. '"' else "null"
		table.insert(
			lines,
			('    { "case": "%s", "status": "%s", "durationMicros": %d, "message": %s }%s'):format(
				escapeJson(describeCase(result)),
				statusOf(result),
				result.durationMicros,
				message,
				suffix
			)
		)
	end
	table.insert(lines, "  ]")
	table.insert(lines, "}")
	return table.concat(lines, "\n") .. "\n"
end

local function main(): number
	local options = parseArguments()

	local specs = Test.sources(Manifest)
	if #specs == 0 then
		print "run-tests: the run manifest names no sources"
		return 1
	end

	local filter = options.filter
	local selection: Verify.Selection? = nil
	if filter ~= nil then
		local needle = filter :: string
		local matching: Verify.Selection = {
			predicate = function(subject: Verify.SelectionSubject): boolean
				local source = subject.source
				local haystack = if source ~= nil then source .. " > " .. subject.id else subject.id
				return string.find(haystack, needle, 1, true) ~= nil
			end,
		}
		selection = matching
	end

	local plan = Verify.planFromManifest(Manifest, { caseIdStyle = "bare" }) :: Verify.PlanDraft
	local execution = Verify.execute(plan, Test.host { selection = selection })

	for _, fact in execution.facts do
		if fact.severity ~= "failure" then
			print(("run-tests: %s (%s) %s"):format(fact.code, fact.subject, fact.detail))
		end
	end

	local report = execution.report
	local results = report.results
	local failures = report.failed + report.unsupported + report.timedOut + report.cancelled
	local skipped = report.skipped

	if not options.quiet then
		local lastSuite = ""
		for _, result in results do
			local pieces = table.clone(result.path)
			table.insert(pieces, 1, result.source or "<unknown source>")
			local suite = table.concat(pieces, " > ")
			if suite ~= lastSuite then
				lastSuite = suite
				print(suite)
			end
			local status = statusOf(result)
			if status == "passed" then
				print(("  ok    %s"):format(result.name))
			elseif status == "skipped" then
				print(("  skip  %s"):format(result.name))
			else
				print(("  FAIL  %s"):format(result.name))
				for line in string.gmatch(tostring(messageOf(result)), "[^\n]+") do
					print("        " .. line)
				end
			end
		end
	end

	if options.jsonPath ~= nil then
		local directory = string.match(options.jsonPath :: string, "^(.*)/[^/]+$")
		if directory ~= nil then
			process.run { "mkdir", "-p", directory }
		end
		fs.writeStringToFile(options.jsonPath, toJson(results, #specs, failures, skipped))
	end

	print(("\n%d files, %d cases, %d failed, %d skipped"):format(#specs, #results, failures, skipped))
	return if failures == 0 then 0 else 1
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
