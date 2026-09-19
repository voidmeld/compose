--!strict

local ComposeCore = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local ComposeEngine = require "./compose-engine"
local Environment = require "../environment"

export type Loaded = {
	library: any,
	extras: { [string]: any },
}

export type Framework = {
	name: string,
	version: string,
	what: string,
	load: (environment: Environment.Environment) -> Loaded,
}

local FRAMEWORKS: { Framework } = {
	{
		name = "bare",
		version = "n/a",
		what = "no framework: plain imperative Luau against the same emulated engine",
		load = function(environment: Environment.Environment): Loaded
			return { library = environment.globals, extras = {} }
		end,
	},
	{
		name = "compose",
		version = "0.1.0-dev",
		what = "this repository, through its Roblox adapter",
		load = function(environment: Environment.Environment): Loaded
			ComposeCore.__resetForTests()
			ComposeRoblox.__resetForTests()
			local engine = ComposeEngine.engineFor(environment)
			local runtime = ComposeRoblox.createRuntime(engine)
			return {
				library = ComposeCore,
				extras = { runtime = runtime, create = runtime.create },
			}
		end,
	},
}

local function available(): { Framework }
	return FRAMEWORKS
end

return {
	available = available,
}
