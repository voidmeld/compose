--!strict

local system = require "@lute/system"
local Compose = require "../src/core"

local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Lute = require "../.lute/dependencies/verify/src/lute"
local measureRetained = require "./retained"
local Environment = require "./cost-model"
local Entities = require "./entities"
local Frameworks = require "./harness/frameworks"
local Parity = require "./parity"
local Scenarios = require "./scenarios"
local Types = require "./scenarios/types"
local Workloads = require "./workloads"
local Projections = require "./workloads/projections"
local WorkloadTypes = require "./workloads/types"

export type Suite = "workloads" | "screens" | "entities" | "all"

export type Entry = {
	id: string,
	parity: () -> string?,
	collection: Benchmark.Collection,
	memory: (number?) -> Lute.MemoryResult,
}

export type Filter = {
	suite: Suite,
	filter: string?,
	scale: string?,
	paired: boolean?,
	comparison: boolean?,
}

local pairedRun = false

type Counters = Environment.Counters
type ScenarioState = Types.State?

type Sample<S = ScenarioState> = {
	environment: Environment.Environment,
	context: Types.Context,
	state: S,
	baselineInstances: number,
	baselineConnections: number,
	liveAfterBuild: number,
}

local MICROSECONDS = 1e6
local LARGE = "large"

local clock = os.clock

local function composeFramework(): Frameworks.Framework
	for _, framework in Frameworks.available() do
		if framework.name == "compose" then
			return framework
		end
	end
	error "the Compose benchmark adapter is missing"
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

local function yardstick(paired: boolean?): Benchmark.Yardstick
	return {
		run = function()
			local total = 0
			for index = 1, 20000 do
				total += index % 7
			end
		end,
		samples = 32,
		iterations = 64,
		warmup = 16,
		maxSpread = 4,
		maxDrift = if paired then 1 else 0.25,
		driftBase = "mean",
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

local function environmentCounts(counters: Environment.Counters): { [string]: number }
	return {
		instancesCreated = counters.instancesCreated,
		instancesDestroyed = counters.instancesDestroyed,
		propertyWrites = counters.propertyWrites,
		propertyReads = counters.propertyReads,
		parentChanges = counters.parentChanges,
		connectionsMade = counters.connectionsMade,
		connectionsBroken = counters.connectionsBroken,
		eventsFired = counters.eventsFired,
		tasksDeferred = counters.tasksDeferred,
	}
end

local function reactiveCounts(counters: Compose.WorkCounters): { [string]: number }
	return {
		cellWrites = counters.cellWrites,
		cellWritesSuppressed = counters.cellWritesSuppressed,
		notifications = counters.notifications,
		formulaRecomputations = counters.formulaRecomputations,
		formulaRecomputationsSuppressed = counters.formulaRecomputationsSuppressed,
		watchRuns = counters.watchRuns,
		watchSchedules = counters.watchSchedules,
		watchSchedulesCoalesced = counters.watchSchedulesCoalesced,
		drains = counters.drains,
		continuationPasses = counters.continuationPasses,
	}
end

local function recordEnvironment(
	sampler: Benchmark.Sampler,
	sample: {
		environment: Environment.Environment,
		baselineInstances: number,
		baselineConnections: number,
	},
	counters: Counters
)
	for name, value in environmentCounts(counters) do
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
	local samples: { [unknown]: Sample<WorkloadTypes.State> } = {}
	setmetatable(samples, { __mode = "kv" })
	return {
		name = ("%s/%s"):format(workload.id, framework.name),
		unit = "microseconds",
		clock = clock,
		warmup = workload.warmup,
		warmupScope = "sample",
		samples = workload.samples,
		percentiles = { 75, 90 },
		environment = { observed = observed },
		beforeSample = function(): Sample<WorkloadTypes.State>
			local environment, context = makeContext(framework)
			local baselineInstances = environment.liveInstances()
			local baselineConnections = environment.liveConnections()
			local sample: Sample<WorkloadTypes.State> = {
				environment = environment,
				context = context,
				state = case.prepare(context),
				baselineInstances = baselineInstances,
				baselineConnections = baselineConnections,
				liveAfterBuild = 0,
			}
			environment.drain()
			environment.resetCounters()
			samples[sample] = sample
			return sample
		end,
		workload = function(state: unknown)
			local sample = samples[state]
			for _ = 1, workload.iterations do
				case.run(sample.state, sample.context)
			end
		end,
		finalize = function(state: unknown)
			samples[state].environment.drain()
		end,
		afterSample = function(state: unknown, sampler: Benchmark.Sampler)
			local sample = samples[state]
			local counters = sample.environment.counters()
			case.release(sample.state, sample.context)
			sample.environment.drain()
			recordEnvironment(sampler, sample, counters)
		end,
	}
end

local function workloadEntry(
	workload: Workloads.Workload,
	position: number,
	observed: string,
	comparison: boolean?
): Entry
	local order = rotated(Frameworks.available(comparison), position - 1)
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
		collection = { name = workload.id, yardstick = yardstick(pairedRun), benchmarks = members, clock = clock },
		memory = function(plantedBytes: number?): Lute.MemoryResult
			local framework = composeFramework()
			local case = assert(workload.cases.compose)
			return measureRetained({
				setup = function()
					local environment, context = makeContext(framework)
					local state = case.prepare(context)
					environment.drain()
					return { environment = environment, context = context, state = state }
				end,
				run = function(sample)
					for _ = 1, workload.iterations do
						case.run(sample.state, sample.context)
					end
					sample.environment.drain()
				end,
				teardown = function(sample)
					case.release(sample.state, sample.context)
					sample.environment.drain()
				end,
				warmup = workload.warmup,
				iterations = 1,
			}, plantedBytes)
		end,
	}
end

type WorkCounters = typeof(Compose)

local function scenarioMember(
	scenario: Types.Scenario,
	scale: Types.Scale,
	framework: Frameworks.Framework,
	observed: string
): Benchmark.Spec
	local case = scenario.cases[framework.name]
	local samples: { [unknown]: Sample } = {}
	setmetatable(samples, { __mode = "kv" })
	local label = ("%s.%s/%s"):format(scenario.id, scale.name, framework.name)
	local steadyBudget: Benchmark.Budget? = if scale.name == LARGE
		then { p50 = scenario.steadyBudgetSeconds * scenario.steadyFrames * MICROSECONDS }
		else nil

	local phases: { Benchmark.Phase } = {
		{
			name = "cold",
			run = function(state: unknown)
				local sample = samples[state]
				sample.state = case.build(sample.context, scale)
				sample.environment.drain()
				sample.liveAfterBuild = sample.environment.liveInstances()
			end,
		},
		{
			name = "steady",
			run = function(state: unknown, sampler: Benchmark.Sampler)
				local sample = samples[state]
				local createFrames: (number, number?) -> { number } = table.create
				local frames: { number } = createFrames(scenario.steadyFrames)
				for tick = 1, scenario.steadyFrames do
					local at = clock()
					case.steady(assert(sample.state), sample.context, tick)
					frames[tick] = (clock() - at) * MICROSECONDS
				end
				sampler.series("frame", frames)
			end,
			budget = steadyBudget,
		},
		{
			name = "burst",
			run = function(state: unknown, sampler: Benchmark.Sampler)
				local sample = samples[state]
				local createRounds: (number, number?) -> { number } = table.create
				local rounds: { number } = createRounds(scenario.burstRounds)
				for round = 1, scenario.burstRounds do
					local at = clock()
					case.burst(assert(sample.state), sample.context, round)
					rounds[round] = (clock() - at) * MICROSECONDS
				end
				sampler.series("round", rounds)
			end,
		},
		{
			name = "settle",
			run = function(state: unknown)
				samples[state].environment.drain()
			end,
		},
		{
			name = "teardown",
			run = function(state: unknown)
				local sample = samples[state]
				case.teardown(assert(sample.state), sample.context)
			end,
		},
	}

	return {
		name = label,
		unit = "microseconds",
		clock = clock,
		warmup = scenario.warmup,
		warmupScope = "sample",
		samples = 31,
		percentiles = { 75, 90 },
		tags = { scenario.lane },
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
			samples[sample] = sample
			return sample
		end,
		phases = phases,
		afterSample = function(state: unknown, sampler: Benchmark.Sampler)
			local sample = samples[state]
			sample.environment.drain()
			recordEnvironment(sampler, sample, sample.environment.counters())
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
	local samples: { [unknown]: Sample } = {}
	setmetatable(samples, { __mode = "kv" })
	local function reactive(_sample: Sample): WorkCounters?
		if framework.workCounters then
			return Compose
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
			samples[sample] = sample
			return sample
		end,
		workload = function(state: unknown, sampler: Benchmark.Sampler)
			local sample = samples[state]
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
			local sample = samples[state]
			recordEnvironment(sampler, sample, sample.environment.counters())
			local counters = reactive(sample)
			if counters ~= nil then
				for name, value in reactiveCounts(counters.readWorkCounters()) do
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
		local samples: { [unknown]: Sample } = {}
		setmetatable(samples, { __mode = "kv" })
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
		collection = { name = id, yardstick = yardstick(pairedRun), benchmarks = members, clock = clock },
		memory = function(plantedBytes: number?): Lute.MemoryResult
			local framework = composeFramework()
			local case = assert(scenario.cases.compose)
			return measureRetained({
				setup = function(): { environment: Environment.Environment, context: Types.Context, state: Types.State }
					local environment, context = makeContext(framework)
					local state = case.build(context, scale)
					environment.drain()
					return { environment = environment, context = context, state = state }
				end,
				run = function(
					sample: { environment: Environment.Environment, context: Types.Context, state: Types.State }
				)
					for tick = 1, scenario.steadyFrames do
						case.steady(sample.state, sample.context, tick)
					end
					for round = 1, scenario.burstRounds do
						case.burst(sample.state, sample.context, round)
					end
					sample.environment.drain()
				end,
				teardown = function(sample: {
					environment: Environment.Environment,
					context: Types.Context,
					state: Types.State,
				})
					case.teardown(sample.state, sample.context)
					sample.environment.drain()
				end,
				iterations = 1,
			}, plantedBytes)
		end,
	}
end

local function selected(id: string, filter: string?): boolean
	return filter == nil or string.find(id, filter, 1, true) ~= nil
end

local function prime(collection: Benchmark.Collection)
	for _, member in collection.benchmarks do
		local once = table.clone(member)
		once.warmup = 0
		once.samples = 1
		once.baseline = nil
		once.yardstick = nil
		local result = Benchmark.run(once)
		assert(result.failure == nil, result.failure)
	end
end

local function entries(settings: Filter): { Entry }
	pairedRun = settings.paired == true
	local observed = identity()
	local found: { Entry } = {}
	if settings.suite == "workloads" or settings.suite == "all" then
		local position = 0
		local workloads = table.clone(Workloads.all)
		if not settings.comparison then
			for _, workload in Projections do
				table.insert(workloads, workload)
			end
		end
		for _, workload in workloads do
			if selected(workload.id, settings.filter) then
				position += 1
				table.insert(found, workloadEntry(workload, position, observed, settings.comparison))
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
	prime = prime,
}
