--!strict

local Environment = require "../environment"

export type Context = {
	env: Environment.Environment,
	library: any,
	extras: { [string]: any },
	container: any,
}

export type Case = {
	prepare: (context: Context) -> any,
	run: (state: any, context: Context) -> (),
	snapshot: (state: any, context: Context) -> string,
	release: (state: any, context: Context) -> (),
}

export type Workload = {
	id: string,
	title: string,
	what: string,
	samples: number,
	iterations: number,
	warmup: number,
	cases: { [string]: Case },
	perUnit: { { count: number, name: string } }?,
	unsupported: { [string]: string }?,
}

return {}
