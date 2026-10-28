--!strict

local ComposeCore = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local ComposeEngine = require "./compose-engine"
local Environment = require "../cost-model"

type Extras = { runtime: ComposeCore.Runtime? }

export type Loaded<L = unknown, E = Extras> = {
	library: L,
	extras: E,
}

export type Framework = {
	name: string,
	version: string,
	what: string,
	workCounters: boolean,
	load: (environment: Environment.Environment) -> Loaded,
}

export type Opened = {
	environment: Environment.Environment,
	loaded: Loaded,
}

local function plainLoad(environment: Environment.Environment): Loaded
	return { library = environment.globals, extras = {} }
end

local FRAMEWORKS: { Framework } = {
	{
		name = "plain",
		version = "n/a",
		what = "no framework: plain imperative Luau against the same cost-model environment",
		workCounters = false,
		load = plainLoad,
	},
	{
		name = "compose",
		version = "0.1.0-dev",
		what = "this repository, through its Roblox adapter",
		workCounters = true,
		load = function(environment: Environment.Environment): Loaded
			ComposeCore.__resetForTests()
			ComposeRoblox.__resetForTests()
			local engine = ComposeEngine.engineFor(environment)
			local runtime = ComposeRoblox.createRuntime(engine)
			return {
				library = ComposeCore,
				extras = { runtime = runtime },
			}
		end,
	},
}

local function open(framework: Framework): Opened
	local environment = Environment.create()
	return { environment = environment, loaded = framework.load(environment) }
end

local function available(): { Framework }
	return FRAMEWORKS
end

return {
	available = available,
	open = open,
}
