--!strict

local Environment = require "../cost-model"
local Compose = require "../../src/core"

export type OrderedCollectionLayout = Compose.OrderedCollectionLayout
export type OrderedCollectionViewport = Compose.OrderedCollectionViewport
export type Placement = Compose.Placement
export type Use = Compose.Use
export type Props = Compose.Props
export type Cell<T> = Compose.Value<T>
export type Readable<T> = Compose.ReadOnlyValue<T>

export type Scale = {
	name: string,
	size: number,
	[string]: number,
}

export type Extras = { runtime: Compose.Runtime? }

export type Context<L = unknown, E = Extras> = {
	env: Environment.Environment,
	library: L,
	extras: E,
	container: Environment.Instance,
	observe: ((string) -> ())?,
}

export type ComposeContext = Context<typeof(Compose), { runtime: Compose.Runtime }>
export type PlainContext = Context<Environment.Globals, {}>

export type State = {
	steady: (number) -> (),
	burst: (number) -> (),
	teardown: () -> (),
	snapshot: () -> string,
	probe: () -> { [string]: number },
}

type ErasedContext = Context<unknown, Extras>

export type Case<S = State, C = ErasedContext> = {
	build: (context: C, scale: Scale) -> S,
	steady: (state: S, context: C, tick: number) -> (),
	burst: (state: S, context: C, round: number) -> (),
	teardown: (state: S, context: C) -> (),
	snapshot: (state: S, context: C) -> string,
	probe: ((state: S, context: C) -> { [string]: number })?,
}

export type RunContext<S, C> = C & { scale: Scale, step: (number) -> () }

export type Scenario = {
	id: string,
	title: string,
	what: string,
	lane: string,
	steadyBudgetSeconds: number,
	scales: { Scale },
	steadyFrames: number,
	burstRounds: number,
	warmup: number,
	cases: { [string]: Case },
	unsupported: { [string]: string }?,
}

local function resultOf<R, A...>(_build: (A...) -> R): R
	error "benchmark state type query"
end

local function pack<S, C>(case: Case<S, C>, convert: (Context, Scale, (number) -> ()) -> C): Case
	local probe: ((State, Context) -> { [string]: number })? = nil
	if case.probe ~= nil then
		probe = function(state: State, _context: Context): { [string]: number }
			return state.probe()
		end
	end
	return {
		build = function(context: Context, scale: Scale): State
			local typed: C
			local state: S
			typed = convert(context, scale, function(tick: number)
				case.steady(state, typed, tick)
			end)
			state = case.build(typed, scale)
			return {
				steady = function(tick: number)
					case.steady(state, typed, tick)
				end,
				burst = function(round: number)
					case.burst(state, typed, round)
				end,
				teardown = function()
					case.teardown(state, typed)
				end,
				snapshot = function(): string
					return case.snapshot(state, typed)
				end,
				probe = function(): { [string]: number }
					local read = case.probe
					return if read then read(state, typed) else {}
				end,
			}
		end,
		steady = function(state: State, _context: Context, tick: number)
			state.steady(tick)
		end,
		burst = function(state: State, _context: Context, round: number)
			state.burst(round)
		end,
		teardown = function(state: State, _context: Context)
			state.teardown()
		end,
		snapshot = function(state: State, _context: Context): string
			return state.snapshot()
		end,
		probe = probe,
	}
end

local function compose<S>(case: Case<S, ComposeContext>): Case
	return pack(case, function(context: Context, _scale: Scale, _step: (number) -> ()): ComposeContext
		return {
			env = context.env,
			library = Compose,
			extras = { runtime = assert(context.extras.runtime) },
			container = context.container,
		}
	end)
end

local function plain<S>(case: Case<S, PlainContext>): Case
	return pack(case, function(context: Context, _scale: Scale, _step: (number) -> ()): PlainContext
		return {
			env = context.env,
			library = context.env.globals,
			extras = {},
			container = context.container,
		}
	end)
end

local function composeRun<S>(case: Case<S, RunContext<S, ComposeContext>>): Case
	return pack(case, function(context: Context, scale: Scale, step: (number) -> ()): RunContext<S, ComposeContext>
		return {
			env = context.env,
			library = Compose,
			extras = { runtime = assert(context.extras.runtime) },
			container = context.container,
			scale = scale,
			step = step,
		}
	end)
end
local function plainRun<S>(case: Case<S, RunContext<S, PlainContext>>): Case
	return pack(case, function(context: Context, scale: Scale, step: (number) -> ()): RunContext<S, PlainContext>
		return {
			env = context.env,
			library = context.env.globals,
			extras = {},
			container = context.container,
			scale = scale,
			step = step,
		}
	end)
end
return { compose = compose, plain = plain, composeRun = composeRun, plainRun = plainRun, resultOf = resultOf }
