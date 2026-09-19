--!strict

local Environment = require "../environment"

export type Scale = {
	name: string,
	size: number,
	[string]: any,
}

export type Context = {
	env: Environment.Environment,
	library: any,
	extras: { [string]: any },
	container: any,
}

export type Case = {
	build: (context: Context, scale: Scale) -> any,
	steady: (state: any, context: Context, tick: number) -> (),
	burst: (state: any, context: Context, round: number) -> (),
	teardown: (state: any, context: Context) -> (),
	snapshot: (state: any, context: Context) -> string,
	probe: ((state: any, context: Context) -> { [string]: number })?,
}

export type Scenario = {
	id: string,
	title: string,
	what: string,
	lane: string,
	steadyBudgetSeconds: number,
	frameBudgets: { { name: string, seconds: number } }?,
	scales: { Scale },
	steadyFrames: number,
	burstRounds: number,
	samples: number,
	warmup: number,
	cases: { [string]: Case },
	unsupported: { [string]: string }?,
}

return {}
