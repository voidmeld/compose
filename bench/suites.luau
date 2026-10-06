--!strict

local system = require "@lute/system"
local time = require "@lute/time"

local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Environment = require "./cost-model"
local Entities = require "./entities"
local Frameworks = require "./harness/frameworks"
local Parity = require "./parity"
local Scenarios = require "./scenarios"
local Types = require "./scenarios/types"
local Workloads = require "./workloads"

export type Suite = "workloads" | "screens" | "entities" | "all"

export type Entry = {
	id: string,
	parity: () -> string?,
	collection: Benchmark.Collection,
}

export type Filter = {
	suite: Suite,
	filter: string?,
	scale: string?,
}

type Counters = { [string]: number }

type Sample = {
	environment: Environment.Environment,
	context: Types.Context,
	state: unknown,
	baselineInstances: number,
	baselineConnections: number,
	liveAfterBuild: number,
}

local MICROSECONDS = 1e6
local LARGE = "large"

local origin = time.now()

local function clock(): number
	return time.since(origin)
end

local function identity(): string
	local cpus = system.cpus()
	return ("%s-%s-%s-%dthreads"):format(
		system.os,
		system.arch,
		if #cpus > 0 then cpus[1].model else "unknown",
		system.threadCount()
	)
end

local function yardstick(): Benchmark.Yardstick
	return {
		run = function()
			local total = 0
			for index = 1, 20000 do
				total += index % 7
			end
		end,
		samples = 5,
		maxSpread = 4,
		maxDrift = 4,
	}
end

local function rotated<T>(values: { T }, by: number): { T }
	local count = #values
	local out = table.create(count)
	for index = 1, count do
		out[index] = values[((index - 1 + by) % count) + 1]
	end
	return out
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

local function recordEnvironment(sampler: Benchmark.Sampler, sample: Sample, counters: Counters)
	for name, value in counters do
		sampler.series("counter." .. name, { value })
	end
	sampler.series("leakedInstances", { sample.environment.liveInstances() - sample.baselineInstances })
	sampler.series("leakedConnections", { sample.environment.liveConnections() - sample.baselineConnections })
	sampler.series("diagnostics", { #sample.environment.diagnostics() })
end

local function workloadMember(
	workload: Workloads.Workload,
	framework: Frameworks.Framework,
	observed: string
): Benchmark.Spec
	local case = workload.cases[framework.name]
	return {
		name = ("%s/%s"):format(workload.id, framework.name),
		unit = "microseconds",
		clock = clock,
		warmup = workload.warmup,
		warmupScope = "sample",
		samples = workload.samples,
		percentiles = { 75, 90 },
		environment = { observed = observed },
		beforeSample = function(): Sample
			local environment, context = makeContext(framework)
			local sample: Sample = {
				environment = environment,
				context = context,
				state = nil,
				baselineInstances = environment.liveInstances(),
				baselineConnections = environment.liveConnections(),
				liveAfterBuild = 0,
			}
			sample.state = case.prepare(context)
			environment.drain()
			environment.resetCounters()
			return sample
		end,
		workload = function(state: unknown)
			local sample = state :: Sample
			for _ = 1, workload.iterations do
				case.run(sample.state, sample.context)
			end
		end,
		finalize = function(state: unknown)
			(state :: Sample).environment.drain()
		end,
		afterSample = function(state: unknown, sampler: Benchmark.Sampler)
			local sample = state :: Sample
			local counters = (sample.environment.counters() :: unknown) :: Counters
			case.release(sample.state, sample.context)
			sample.environment.drain()
			recordEnvironment(sampler, sample, counters)
		end,
	}
end

local function workloadEntry(workload: Workloads.Workload, position: number, observed: string): Entry
	local order = rotated(Frameworks.available(), position - 1)
	local members: { Benchmark.Spec } = {}
	for _, framework in order do
		if workload.cases[framework.name] ~= nil then
			table.insert(members, workloadMember(workload, framework, observed))
		end
	end
	return {
		id = workload.id,
		parity = function(): string?
			return Parity.workload(workload, order)
		end,
		collection = { name = workload.id, yardstick = yardstick(), benchmarks = members, clock = clock },
	}
end

local function attach(context: Types.Context, scale: Types.Scale, case: Types.Case<unknown, Types.Context>)
	local mutable = (context :: unknown) :: Types.RunContext<unknown, Types.Context>
	mutable.scale = scale
	mutable.case = case
end

type WorkCounters = {
	setWorkCounters: (enabled: boolean) -> (),
	resetWorkCounters: () -> (),
	readWorkCounters: () -> Counters,
}

local function scenarioMember(
	scenario: Types.Scenario,
	scale: Types.Scale,
	framework: Frameworks.Framework,
	observed: string
): Benchmark.Spec
	local case = scenario.cases[framework.name]
	local label = ("%s.%s/%s"):format(scenario.id, scale.name, framework.name)
	local steadyBudget: Benchmark.Budget? = if scale.name == LARGE
		then { p50 = scenario.steadyBudgetSeconds * scenario.steadyFrames * MICROSECONDS }
		else nil

	local phases: { Benchmark.Phase } = {
		{
			name = "cold",
			run = function(state: unknown)
				local sample = state :: Sample
				sample.state = case.build(sample.context, scale)
				sample.environment.drain()
				sample.liveAfterBuild = sample.environment.liveInstances()
			end,
		},
		{
			name = "steady",
			run = function(state: unknown, sampler: Benchmark.Sampler)
				local sample = state :: Sample
				local frames = table.create(scenario.steadyFrames) :: { number }
				for tick = 1, scenario.steadyFrames do
					local at = clock()
					case.steady(sample.state, sample.context, tick)
					frames[tick] = (clock() - at) * MICROSECONDS
				end
				sampler.series("frame", frames)
			end,
			budget = steadyBudget,
		},
		{
			name = "burst",
			run = function(state: unknown, sampler: Benchmark.Sampler)
				local sample = state :: Sample
				local rounds = table.create(scenario.burstRounds) :: { number }
				for round = 1, scenario.burstRounds do
					local at = clock()
					case.burst(sample.state, sample.context, round)
					rounds[round] = (clock() - at) * MICROSECONDS
				end
				sampler.series("round", rounds)
			end,
		},
		{
			name = "settle",
			run = function(state: unknown)
				(state :: Sample).environment.drain()
			end,
		},
		{
			name = "teardown",
			run = function(state: unknown)
				local sample = state :: Sample
				case.teardown(sample.state, sample.context)
			end,
		},
	}

	return {
		name = label,
		unit = "microseconds",
		clock = clock,
		warmup = scenario.warmup,
		warmupScope = "sample",
		samples = scenario.samples,
		percentiles = { 75, 90 },
		tags = { scenario.lane },
		environment = { observed = observed },
		beforeSample = function(): Sample
			local environment, context = makeContext(framework)
			attach(context, scale, case)
			return {
				environment = environment,
				context = context,
				state = nil,
				baselineInstances = environment.liveInstances(),
				baselineConnections = environment.liveConnections(),
				liveAfterBuild = 0,
			}
		end,
		phases = phases,
		afterSample = function(state: unknown, sampler: Benchmark.Sampler)
			local sample = state :: Sample
			sample.environment.drain()
			recordEnvironment(sampler, sample, (sample.environment.counters() :: unknown) :: Counters)
			sampler.series("liveInstancesAfterBuild", { sample.liveAfterBuild })
		end,
	}
end

local function countsMember(
	scenario: Types.Scenario,
	scale: Types.Scale,
	framework: Frameworks.Framework,
	observed: string
): Benchmark.Spec
	local case = scenario.cases[framework.name]
	local function reactive(sample: Sample): WorkCounters?
		local library = sample.context.library
		if framework.workCounters and type(library) == "table" then
			return (library :: unknown) :: WorkCounters
		end
		return nil
	end
	return {
		name = ("%s.%s/%s/counts"):format(scenario.id, scale.name, framework.name),
		unit = "microseconds",
		clock = clock,
		warmup = 0,
		samples = 1,
		environment = { observed = observed },
		beforeSample = function(): Sample
			local environment, context = makeContext(framework)
			attach(context, scale, case)
			local sample: Sample = {
				environment = environment,
				context = context,
				state = nil,
				baselineInstances = environment.liveInstances(),
				baselineConnections = environment.liveConnections(),
				liveAfterBuild = 0,
			}
			local counters = reactive(sample)
			if counters ~= nil then
				counters.setWorkCounters(true)
				counters.resetWorkCounters()
			end
			return sample
		end,
		workload = function(state: unknown, sampler: Benchmark.Sampler)
			local sample = state :: Sample
			local built = case.build(sample.context, scale)
			for tick = 1, scenario.steadyFrames do
				case.steady(built, sample.context, tick)
			end
			for round = 1, scenario.burstRounds do
				case.burst(built, sample.context, round)
			end
			sample.environment.drain()
			if case.probe ~= nil then
				for name, value in case.probe(built, sample.context) do
					sampler.series("probe." .. name, { value })
				end
			end
			case.teardown(built, sample.context)
			sample.environment.drain()
		end,
		afterSample = function(state: unknown, sampler: Benchmark.Sampler)
			local sample = state :: Sample
			recordEnvironment(sampler, sample, (sample.environment.counters() :: unknown) :: Counters)
			local counters = reactive(sample)
			if counters ~= nil then
				for name, value in counters.readWorkCounters() do
					sampler.series("reactive." .. name, { value })
				end
				counters.setWorkCounters(false)
			end
		end,
	}
end

local function scenarioEntry(scenario: Types.Scenario, scale: Types.Scale, position: number, observed: string): Entry
	local order = rotated(Frameworks.available(), position - 1)
	local members: { Benchmark.Spec } = {}
	for _, framework in order do
		local case = scenario.cases[framework.name]
		if case == nil then
			continue
		end
		if framework.workCounters or case.probe ~= nil then
			table.insert(members, countsMember(scenario, scale, framework, observed))
		end
		table.insert(members, scenarioMember(scenario, scale, framework, observed))
	end
	local id = ("%s.%s"):format(scenario.id, scale.name)
	return {
		id = id,
		parity = function(): string?
			return Parity.scenario(scenario, scale, order)
		end,
		collection = { name = id, yardstick = yardstick(), benchmarks = members, clock = clock },
	}
end

local function selected(id: string, filter: string?): boolean
	return filter == nil or string.find(id, filter, 1, true) ~= nil
end

local function entries(settings: Filter): { Entry }
	local observed = identity()
	local found: { Entry } = {}
	if settings.suite == "workloads" or settings.suite == "all" then
		local position = 0
		for _, workload in Workloads.all do
			if selected(workload.id, settings.filter) then
				position += 1
				table.insert(found, workloadEntry(workload, position, observed))
			end
		end
	end
	local pools: { { Types.Scenario } } = {}
	if settings.suite == "screens" or settings.suite == "all" then
		table.insert(pools, Scenarios.all)
	end
	if settings.suite == "entities" or settings.suite == "all" then
		table.insert(pools, Entities.all)
	end
	local position = 0
	for _, pool in pools do
		for _, scenario in pool do
			if not selected(scenario.id, settings.filter) then
				continue
			end
			for _, scale in scenario.scales do
				if settings.scale == nil or scale.name == settings.scale then
					position += 1
					table.insert(found, scenarioEntry(scenario, scale, position, observed))
				end
			end
		end
	end
	return found
end

return {
	entries = entries,
	identity = identity,
}
