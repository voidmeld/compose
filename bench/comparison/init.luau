--!strict

local Roact = require "@self/roact"
local Seam = require "@self/seam"
local Signals = require "@self/signals"
local ReactReflex = require "@self/react-reflex"
local FusionCharm = require "@self/fusion-charm"
local ReactUpstream = require "@self/react-upstream"

local Blend = require "@self/blend"
local Fusion = require "@self/fusion"
local React = require "@self/react"
local Vide = require "@self/vide"
local Workloads = require "@self/workloads"
local Lock = require "@self/../../dependencies.lock"

local function version(name: string): string
	for _, dependency in Lock.dependencies do
		if dependency.name == name then
			return assert(dependency.version)
		end
	end
	error("benchmark dependency is not locked: " .. name, 0)
end

return {
	{
		name = "fusion",
		version = version "fusion",
		what = "Fusion scoped values and Instances",
		workCounters = false,
		load = Workloads.include("fusion", function(environment)
			return Fusion.create(environment)
		end),
	},
	{
		name = "vide",
		version = version "vide",
		what = "Vide sources, values and scoped cleanup",
		workCounters = false,
		load = Workloads.include("vide", Vide.create),
	},
	{
		name = "react",
		version = version "react",
		what = "React bindings and ReactRoblox legacy roots",
		workCounters = false,
		load = Workloads.include("react", function(environment)
			return React.create(environment)
		end),
	},
	{
		name = "blend",
		version = version "blend",
		what = "Blend states, observables and computed pairs",
		workCounters = false,
		load = Workloads.include("blend", Blend.create),
	},
	{
		name = "roact",
		version = version "roact",
		what = "roact public APIs",
		workCounters = false,
		load = Workloads.include("roact", Roact.create, Roact.unsupported),
	},
	{
		name = "seam",
		version = version "seam",
		what = "seam public APIs",
		workCounters = false,
		load = Workloads.include("seam", Seam.create, Seam.unsupported),
	},
	{
		name = "signals",
		version = version "signals",
		what = "signals public APIs",
		workCounters = false,
		load = Workloads.include("signals", Signals.create, Signals.unsupported),
	},
	{
		name = "react-reflex",
		version = version "reflex",
		what = "react-reflex public APIs",
		workCounters = false,
		load = Workloads.include("react-reflex", ReactReflex.create),
	},
	{
		name = "fusion-charm",
		version = version "charm",
		what = "fusion-charm public APIs",
		workCounters = false,
		load = Workloads.include("fusion-charm", FusionCharm.create),
	},
	{
		name = "react-upstream",
		version = version "react-upstream",
		what = "react-upstream public APIs",
		workCounters = false,
		load = Workloads.include("react-upstream", ReactUpstream.create),
	},
}
