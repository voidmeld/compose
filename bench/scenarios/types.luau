--!strict

local Environment = require "../cost-model"
local Compose = require "../../src/core"

export type OrderedCollectionLayout = Compose.OrderedCollectionLayout
export type Placement = Compose.Placement
export type Use = Compose.Use
export type Props = Compose.Props
export type Cell<T> = Compose.Cell<T>
export type Readable<T> = Compose.Readable<T>

export type Scale = {
	name: string,
	size: number,
	[string]: number,
}

export type Context<L = unknown, E = unknown> = {
	env: Environment.Environment,
	library: L,
	extras: E,
	container: Environment.Instance,
}

export type ComposeContext = Context<typeof(Compose), { runtime: Compose.Runtime }>
export type BareContext = Context<Environment.Globals, {}>

export type Case<S = unknown, C = unknown> = {
	build: (context: C, scale: Scale) -> S,
	steady: (state: S, context: C, tick: number) -> (),
	burst: (state: S, context: C, round: number) -> (),
	teardown: (state: S, context: C) -> (),
	snapshot: (state: S, context: C) -> string,
	probe: ((state: S, context: C) -> { [string]: number })?,
}

export type RunContext<S, C> = C & { scale: Scale, case: Case<S, C> }

export type Scenario = {
	id: string,
	title: string,
	what: string,
	lane: string,
	steadyBudgetSeconds: number,
	scales: { Scale },
	steadyFrames: number,
	burstRounds: number,
	samples: number,
	warmup: number,
	cases: { [string]: Case<unknown, Context> },
	unsupported: { [string]: string }?,
}

return {}
