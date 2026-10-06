--!strict

local Environment = require "../cost-model"
local Core = require "../../src/core"

export type Context<L = unknown, E = unknown> = {
	env: Environment.Environment,
	library: L,
	extras: E,
	container: Environment.Instance,
}

export type ComposeContext = Context<typeof(Core), { runtime: Core.Runtime }>
export type BareContext = Context<Environment.Globals, {}>

export type Case<S = unknown, C = unknown> = {
	prepare: (context: C) -> S,
	run: (state: S, context: C) -> (),
	snapshot: (state: S, context: C) -> string,
	release: (state: S, context: C) -> (),
}

export type Workload = {
	id: string,
	title: string,
	what: string,
	samples: number,
	iterations: number,
	warmup: number,
	cases: { [string]: Case },
	unsupported: { [string]: string }?,
}

return {}
