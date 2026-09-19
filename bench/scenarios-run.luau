--!strict

local Environment = require "./environment"
local Frameworks = require "./harness/frameworks"
local Platform = require "./harness/platform"
local Report = require "./scenarios/report"
local Battle = require "./battle"
local Scenarios = require "./scenarios"
local Stats = require "./harness/stats"
local Types = require "./scenarios/types"
local process = require "@lute/process"
local time = require "@lute/time"

type Options = {
	filter: string?,
	scale: string?,
	only: { string }?,
	commit: boolean,
	verify: boolean,
	out: string?,
	suite: string,
}

local function parse(): Options
	local options: Options =
		{ filter = nil, scale = nil, only = nil, commit = false, verify = false, out = nil, suite = "screens" }
	local args = process.args
	local index = 2
	while index <= #args do
		local flag = args[index]
		if flag == "--filter" then
			index += 1
			options.filter = args[index]
		elseif flag == "--scale" then
			index += 1
			options.scale = args[index]
		elseif flag == "--only" then
			index += 1
			local names: { string } = {}
			for name in string.gmatch(args[index], "[^,]+") do
				table.insert(names, name)
			end
			options.only = names
		elseif flag == "--out" then
			index += 1
			options.out = args[index]
		elseif flag == "--suite" then
			index += 1
			options.suite = args[index]
			if options.suite ~= "screens" and options.suite ~= "battle" and options.suite ~= "all" then
				error(("scenarios: unknown suite %q (screens, battle, all)"):format(options.suite))
			end
		elseif flag == "--commit" then
			options.commit = true
		elseif flag == "--verify" then
			options.verify = true
		else
			error(("scenarios: unrecognised argument %q"):format(tostring(flag)))
		end
		index += 1
	end
	return options
end

export type PhaseSamples = {
	cold: { number },
	steady: { number },
	steadyChunk: { number },
	burst: { number },
	teardown: { number },
}

export type Measurement = {
	framework: string,
	scale: string,
	size: number,
	samples: PhaseSamples,
	counters: Environment.Counters,
	liveInstancesAfterBuild: number,
	leakedInstances: number,
	leakedConnections: number,
	reactive: any,
	probe: { [string]: number }?,
	error: string?,
}

local function emptySamples(): PhaseSamples
	return { cold = {}, steady = {}, steadyChunk = {}, burst = {}, teardown = {} }
end

local function makeContext(framework: Frameworks.Framework): (Environment.Environment, Types.Context)
	local environment = Environment.create()
	local loaded = framework.load(environment)
	return environment,
		{
			env = environment,
			library = loaded.library,
			extras = loaded.extras,
			container = environment.container(),
		}
end

local function attach(context: Types.Context, scale: Types.Scale, case: Types.Case)
	local mutable = context :: any
	mutable.scale = scale
	mutable.case = case
end

local function parityRun(
	scenario: Types.Scenario,
	framework: Frameworks.Framework,
	scale: Types.Scale
): (string?, string?)
	local case = scenario.cases[framework.name]
	if case == nil then
		return nil, "no implementation"
	end
	local environment, context = makeContext(framework)
	attach(context, scale, case)
	local ok, result: any = pcall(function()
		local state = case.build(context, scale)

		for tick = 1, 12 do
			case.steady(state, context, tick)
		end

		case.burst(state, context, 1)
		case.steady(state, context, 13)
		case.burst(state, context, 2)
		for tick = 14, 20 do
			case.steady(state, context, tick)
		end
		environment.drain()
		local snapshot = case.snapshot(state, context)
		case.teardown(state, context)
		environment.drain()
		return snapshot
	end)
	if not ok then
		return nil, ("raised: %s"):format(tostring(result))
	end
	return result :: string, nil
end

local function measure(scenario: Types.Scenario, framework: Frameworks.Framework, scale: Types.Scale): Measurement
	local case = scenario.cases[framework.name]
	local result: Measurement = {
		framework = framework.name,
		scale = scale.name,
		size = scale.size,
		samples = emptySamples(),
		counters = Environment.zeroCounters(),
		liveInstancesAfterBuild = 0,
		leakedInstances = 0,
		leakedConnections = 0,
		reactive = nil,
		error = nil,
	}
	if case == nil then
		local unsupported = scenario.unsupported
		result.error = if unsupported ~= nil and unsupported[framework.name] ~= nil
			then unsupported[framework.name]
			else "no implementation"
		return result
	end

	do
		local environment, context = makeContext(framework)
		attach(context, scale, case)
		local baselineInstances = environment.liveInstances()
		local baselineConnections = environment.liveConnections()
		local reactive = if type(context.library) == "table" and context.library.setWorkCounters ~= nil
			then context.library
			else nil
		if reactive ~= nil then
			reactive.setWorkCounters(true)
			reactive.resetWorkCounters()
		end
		local ok, err: any = pcall(function()
			local state = case.build(context, scale)
			result.liveInstancesAfterBuild = environment.liveInstances()
			for tick = 1, scenario.steadyFrames do
				case.steady(state, context, tick)
			end
			for round = 1, scenario.burstRounds do
				case.burst(state, context, round)
			end
			environment.drain()
			if case.probe ~= nil then
				result.probe = case.probe(state, context)
			end
			case.teardown(state, context)
			environment.drain()
		end)
		local reactiveCounters: any = nil
		if reactive ~= nil then
			reactiveCounters = reactive.readWorkCounters()
			reactive.setWorkCounters(false)
		end
		result.reactive = reactiveCounters
		if not ok then
			result.error = tostring(err)
			return result
		end
		result.counters = environment.counters()
		result.leakedInstances = environment.liveInstances() - baselineInstances
		result.leakedConnections = environment.liveConnections() - baselineConnections
	end

	for sample = 1, scenario.warmup + scenario.samples do
		local environment, context = makeContext(framework)
		attach(context, scale, case)
		local measured = sample > scenario.warmup

		local started = time.now()
		local state = case.build(context, scale)
		environment.drain()
		local cold = time.since(started)

		local steady = table.create(scenario.steadyFrames)
		local blockStarted = time.now()
		for tick = 1, scenario.steadyFrames do
			local at = time.now()
			case.steady(state, context, tick)
			steady[tick] = time.since(at)
		end
		local perFrame = time.since(blockStarted) / scenario.steadyFrames

		local burst = table.create(scenario.burstRounds)
		for round = 1, scenario.burstRounds do
			local at = time.now()
			case.burst(state, context, round)
			burst[round] = time.since(at)
		end
		environment.drain()

		local at = time.now()
		case.teardown(state, context)
		local teardown = time.since(at)
		environment.drain()

		if measured then
			table.insert(result.samples.cold, cold)
			for _, value in steady do
				table.insert(result.samples.steady, value)
			end
			table.insert(result.samples.steadyChunk, perFrame)
			for _, value in burst do
				table.insert(result.samples.burst, value)
			end
			table.insert(result.samples.teardown, teardown)
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
				if name == framework.name then
					table.insert(frameworks, framework)
					break
				end
			end
		end
	end

	local pool: { Types.Scenario } = {}
	if options.suite == "screens" or options.suite == "all" then
		for _, scenario in Scenarios.all do
			table.insert(pool, scenario)
		end
	end
	if options.suite == "battle" or options.suite == "all" then
		for _, scenario in Battle.all do
			table.insert(pool, scenario)
		end
	end

	local selected: { Types.Scenario } = {}
	for _, scenario in pool do
		if options.filter == nil or string.find(scenario.id, options.filter, 1, true) ~= nil then
			table.insert(selected, scenario)
		end
	end

	print(("scenarios: %d scenario(s) x %d implementation(s)"):format(#selected, #frameworks))
	for _, framework in frameworks do
		print(("  %-10s %-12s %s"):format(framework.name, framework.version, framework.what))
	end

	local results: {
		{
			scenario: Types.Scenario,
			scale: Types.Scale,
			measurements: { Measurement },
			parity: string,
			parityDetail: string?,
		}
	} =
		{}
	local parityFailures = 0
	local rotation = 0

	for _, scenario in selected do
		print(("--- %s"):format(scenario.id))
		for _, scale in scenario.scales do
			if options.scale ~= nil and scale.name ~= options.scale then
				continue
			end

			local ordered: { Frameworks.Framework } = {}
			rotation += 1
			for offset = 0, #frameworks - 1 do
				table.insert(ordered, frameworks[((rotation + offset - 1) % #frameworks) + 1])
			end

			local snapshots: { [string]: string } = {}
			local problems: { string } = {}
			for _, framework in ordered do
				local snapshot, err = parityRun(scenario, framework, scale)
				if err ~= nil then
					if scenario.cases[framework.name] ~= nil then
						table.insert(problems, ("%s %s"):format(framework.name, err))
					end
				else
					snapshots[framework.name] = snapshot :: string
				end
			end

			local parity = "matched"
			local parityDetail: string? = nil
			local reference: string? = nil
			local referenceName = ""
			local mismatched: { string } = {}
			for _, framework in ordered do
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
			if #problems > 0 then
				parity = "mismatched"
				parityDetail = table.concat(problems, "; ")
			elseif #mismatched > 0 then
				parity = "mismatched"
				parityDetail = ("%s differ from %s"):format(table.concat(mismatched, ", "), referenceName)
			end

			local measurements: { Measurement } = {}
			if parity == "mismatched" then
				parityFailures += 1
				print(("    %-8s PARITY FAILED: %s"):format(scale.name, tostring(parityDetail)))
			elseif options.verify then
				print(("    %-8s parity ok (timing skipped)"):format(scale.name))
			else
				for _, framework in ordered do
					table.insert(measurements, measure(scenario, framework, scale))
				end
				table.sort(measurements, function(left: Measurement, right: Measurement): boolean
					return left.framework < right.framework
				end)
				for _, entry in measurements do
					if entry.error ~= nil then
						print(("    %-8s %-10s unsupported: %s"):format(scale.name, entry.framework, entry.error))
						continue
					end
					local steady = Stats.summarise(entry.samples.steady)
					local chunk = Stats.summarise(entry.samples.steadyChunk)
					local cold = Stats.summarise(entry.samples.cold)
					print(
						("    %-8s %-10s cold %-9s frame %-9s p99 %-9s max %-9s live %d"):format(
							scale.name,
							entry.framework,
							Stats.formatDuration(cold.median),
							Stats.formatDuration(chunk.median),
							Stats.formatDuration(steady.p99),
							Stats.formatDuration(steady.max),
							entry.liveInstancesAfterBuild
						)
					)
				end
			end

			table.insert(results, {
				scenario = scenario,
				scale = scale,
				measurements = measurements,
				parity = parity,
				parityDetail = parityDetail,
			})
		end
	end

	if options.verify then
		if parityFailures > 0 then
			print(("scenarios: %d parity failure(s)"):format(parityFailures))
			return 1
		end
		print "scenarios: parity ok"
		return 0
	end

	local family = if options.suite == "battle" then "battle" else "scenarios"
	local destination = options.out
		or (if options.commit then ("bench/results/%s"):format(family) else ("bench/results/%s-scratch"):format(family))
	if not Platform.isFile(destination .. "/.keep") then
		process.run { "mkdir", "-p", destination }
	end
	Report.write(destination, frameworks, results)
	print(("scenarios: wrote raw samples to %s/"):format(destination))
	if parityFailures > 0 then
		print(("scenarios: %d scale(s) failed parity and reported no timings"):format(parityFailures))
		return 1
	end
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
