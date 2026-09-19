--!strict

local fs = require "@std/fs"
local process = require "@lute/process"
local system = require "@lute/system"
local time = require "@lute/time"

local Environment = require "./environment"
local Frameworks = require "./harness/frameworks"
local Report = require "./harness/report"
local Stats = require "./harness/stats"
local Workloads = require "./workloads"

type Options = {
	filter: string?,
	only: { string }?,
	commit: boolean,
	verify: boolean,
	out: string?,
}

local function parse(): Options
	local options: Options = { filter = nil, only = nil, commit = false, verify = false, out = nil }
	local args = process.args
	local index = 2
	while index <= #args do
		local flag = args[index]
		if flag == "--filter" then
			index += 1
			options.filter = args[index]
		elseif flag == "--only" then
			index += 1
			local names: { string } = {}
			for name in string.gmatch(args[index], "[^,]+") do
				table.insert(names, name)
			end
			options.only = names
		elseif flag == "--commit" then
			options.commit = true
		elseif flag == "--out" then
			index += 1
			options.out = args[index]
		elseif flag == "--verify" then
			options.verify = true
		else
			error(("bench: unrecognised argument %q"):format(tostring(flag)))
		end
		index += 1
	end
	return options
end

local function gitCommit(): string
	local result = process.run { "git", "rev-parse", "HEAD" }
	if not result.ok then
		return "<not a git checkout>"
	end
	return (string.gsub(result.stdout, "%s+$", ""))
end

local function gitDirty(): boolean
	local result = process.run { "git", "status", "--porcelain" }
	return result.ok and (string.gsub(result.stdout, "%s+$", "")) ~= ""
end

local function rotated<T>(values: { T }, by: number): { T }
	local count = #values
	local out = table.create(count)
	for index = 1, count do
		out[index] = values[((index - 1 + by) % count) + 1]
	end
	return out
end

type Measurement = {
	framework: string,
	samples: { number },
	counters: Environment.Counters,
	leakedInstances: number,
	leakedConnections: number,
	diagnostics: number,
	firstDiagnostic: string?,
	error: string?,
}

type WorkloadResult = {
	id: string,
	title: string,
	what: string,
	parity: "matched" | "mismatched" | "single",
	parityDetail: string?,
	measurements: { Measurement },
	perUnit: { { count: number, name: string } }?,
	unsupported: { [string]: string }?,
}

local function parityRun(workload: Workloads.Workload, framework: Frameworks.Framework): (string?, string?)
	local environment = Environment.create()
	local ok, loaded = pcall(framework.load, environment)
	if not ok then
		return nil, ("could not load: %s"):format(tostring(loaded))
	end

	local case = workload.cases[framework.name]
	if case == nil then
		return nil, nil
	end

	local context: Workloads.Context = {
		env = environment,
		library = loaded.library,
		extras = loaded.extras,
		container = environment.container(),
	}

	local snapshot: string?
	local runOk, err: any = pcall(function()
		local state = case.prepare(context)
		for _ = 1, workload.iterations do
			case.run(state, context)
		end
		environment.drain()
		snapshot = case.snapshot(state, context)
		case.release(state, context)
		environment.drain()
	end)
	if not runOk then
		return nil, ("raised: %s"):format(tostring(err))
	end
	return snapshot, nil
end

local function measure(workload: Workloads.Workload, framework: Frameworks.Framework): Measurement
	local case = workload.cases[framework.name]
	local result: Measurement = {
		framework = framework.name,
		samples = {},
		counters = Environment.zeroCounters(),
		leakedInstances = 0,
		leakedConnections = 0,
		diagnostics = 0,
		firstDiagnostic = nil,
		error = nil,
	}
	if case == nil then
		local unsupported = workload.unsupported
		local reason = if unsupported ~= nil then unsupported[framework.name] else nil
		result.error = if reason ~= nil then reason else "no implementation and no recorded reason"
		return result
	end

	do
		local environment = Environment.create()
		local loaded = framework.load(environment)
		local context: Workloads.Context = {
			env = environment,
			library = loaded.library,
			extras = loaded.extras,
			container = environment.container(),
		}
		local baselineInstances = environment.liveInstances()
		local baselineConnections = environment.liveConnections()

		local state = case.prepare(context)
		environment.drain()
		environment.resetCounters()
		for _ = 1, workload.iterations do
			case.run(state, context)
		end
		environment.drain()
		result.counters = environment.counters()
		case.release(state, context)
		environment.drain()

		result.leakedInstances = environment.liveInstances() - baselineInstances
		result.leakedConnections = environment.liveConnections() - baselineConnections

		local emitted = environment.diagnostics()
		result.diagnostics = #emitted
		result.firstDiagnostic = emitted[1]
	end

	local total = workload.warmup + workload.samples
	for sample = 1, total do
		local environment = Environment.create()
		local loaded = framework.load(environment)
		local context: Workloads.Context = {
			env = environment,
			library = loaded.library,
			extras = loaded.extras,
			container = environment.container(),
		}
		local state = case.prepare(context)
		environment.drain()

		local started = time.now()
		for _ = 1, workload.iterations do
			case.run(state, context)
		end
		environment.drain()
		local elapsed = time.since(started) / workload.iterations

		case.release(state, context)
		environment.drain()

		if sample > workload.warmup then
			table.insert(result.samples, elapsed)
		end
	end

	return result
end

local function main(): number
	local options = parse()

	local frameworks: { Frameworks.Framework } = {}
	for _, framework in Frameworks.available() do
		if options.only == nil then
			table.insert(frameworks, framework)
		else
			for _, name in options.only do
				if framework.name == name then
					table.insert(frameworks, framework)
					break
				end
			end
		end
	end

	if #frameworks == 0 then
		print "bench: nothing to measure -- --only selected no entry that exists."
		return 1
	end

	local selected: { Workloads.Workload } = {}
	for _, workload in Workloads.all do
		if options.filter == nil or string.find(workload.id, options.filter, 1, true) ~= nil then
			table.insert(selected, workload)
		end
	end
	if #selected == 0 then
		print(("bench: no workload matches %q"):format(tostring(options.filter)))
		return 1
	end

	print(("bench: %d workload(s) x %d framework(s)"):format(#selected, #frameworks))
	for _, framework in frameworks do
		print(("  %-10s %-12s %s"):format(framework.name, framework.version, framework.what))
	end
	print ""

	local results: { WorkloadResult } = {}
	local parityFailures = 0

	for workloadIndex, workload in selected do
		local order = rotated(frameworks, workloadIndex - 1)
		print(("--- %s"):format(workload.id))

		local snapshots: { [string]: string } = {}
		local problems: { string } = {}
		local participants = 0
		for _, framework in order do
			if workload.cases[framework.name] == nil then
				local unsupported = workload.unsupported
				if unsupported == nil or unsupported[framework.name] == nil then
					table.insert(
						problems,
						("%s has neither an implementation nor a recorded reason for not having one"):format(
							framework.name
						)
					)
				end
				continue
			end
			participants += 1
			local snapshot, err = parityRun(workload, framework)
			if err ~= nil then
				table.insert(problems, ("%s %s"):format(framework.name, err))
			elseif snapshot ~= nil then
				snapshots[framework.name] = snapshot
			end
		end

		local reference: string? = nil
		local referenceName = ""
		local mismatched: { string } = {}
		for _, framework in order do
			local snapshot = snapshots[framework.name]
			if snapshot == nil then
				continue
			end
			if reference == nil then
				reference = snapshot
				referenceName = framework.name
			elseif snapshot ~= reference then
				table.insert(mismatched, framework.name)
			end
		end

		local parity: "matched" | "mismatched" | "single" = "matched"
		local parityDetail: string? = nil
		if #problems > 0 then
			parity = "mismatched"
			parityDetail = table.concat(problems, "; ")
		elseif #mismatched > 0 then
			parity = "mismatched"
			local first = snapshots[mismatched[1]] :: string
			local expected = reference :: string
			local difference = "trees differ in length"
			local expectedLines: { string } = {}
			local actualLines: { string } = {}
			for line in string.gmatch(expected, "[^\n]*") do
				table.insert(expectedLines, line)
			end
			for line in string.gmatch(first, "[^\n]*") do
				table.insert(actualLines, line)
			end
			for index = 1, math.max(#expectedLines, #actualLines) do
				if expectedLines[index] ~= actualLines[index] then
					difference = ("line %d: %s expected %s, %s produced %s"):format(
						index,
						referenceName,
						tostring(expectedLines[index]),
						mismatched[1],
						tostring(actualLines[index])
					)
					break
				end
			end
			parityDetail = ("%s differ from %s (%s)"):format(table.concat(mismatched, ", "), referenceName, difference)
		elseif participants <= 1 then
			parity = "single"
			parityDetail = "only one framework implements this workload, so there is nothing to compare against"
		end

		local measurements: { Measurement } = {}
		if parity == "mismatched" then
			parityFailures += 1
			print(("    PARITY FAILED: %s"):format(tostring(parityDetail)))
			print "    no timings reported for this workload"
		elseif options.verify then
			print "    parity ok (timing skipped)"
		else
			for _, framework in order do
				local measurement = measure(workload, framework)
				table.insert(measurements, measurement)
				if measurement.error ~= nil then
					print(("    %-10s unsupported: %s"):format(framework.name, measurement.error))
				else
					local summary = Stats.summarise(measurement.samples)
					print(
						("    %-10s median %-12s p95 %-12s instances %-6d writes %-6d"):format(
							framework.name,
							Stats.formatDuration(summary.median),
							Stats.formatDuration(summary.p95),
							measurement.counters.instancesCreated,
							measurement.counters.propertyWrites
						)
					)
				end
			end
		end

		table.sort(measurements, function(left, right)
			return left.framework < right.framework
		end)

		table.insert(results, {
			id = workload.id,
			title = workload.title,
			what = workload.what,
			parity = parity,
			parityDetail = parityDetail,
			measurements = measurements,
			perUnit = workload.perUnit,
			unsupported = workload.unsupported,
		})
	end

	local environment = {
		os = system.os,
		arch = system.arch,
		cpu = if #system.cpus() > 0 then system.cpus()[1].model else "unknown",
		threads = system.threadCount(),
		lute = "1.0.1-nightly.20260823",
		commit = gitCommit(),
		dirty = gitDirty(),
		host = "bench/environment: an emulated Roblox engine, identical for every framework",
	}

	local destination = options.out or (if options.commit then "bench/results/committed" else "bench/results/scratch")
	if not fs.exists(destination) then
		process.run { "mkdir", "-p", destination }
	end

	Report.write(destination, environment, frameworks, results)
	print ""
	print(("bench: wrote raw samples and report to %s/"):format(destination))
	if parityFailures > 0 then
		print(("bench: %d workload(s) failed the parity gate and reported no timings"):format(parityFailures))
		return 1
	end
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
