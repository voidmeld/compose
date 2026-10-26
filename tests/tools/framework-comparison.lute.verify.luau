--!strict

local Test = require "../harness"
local Benchmark = require "../../.lute/dependencies/verify/src/benchmark"
local Verify = require "../../.lute/dependencies/verify/src/core"
local Frameworks = require "../../bench/harness/frameworks"
local Report = require "../../bench/comparison/report"
local Workloads = require "../../bench/workloads"
local WorkloadTypes = require "../../bench/workloads/types"
local Environment = require "../../bench/cost-model"
local Lock = require "../../dependencies.lock"

local function framework(name: string): Frameworks.Framework
	return {
		name = name,
		version = "fixture",
		what = "report fixture",
		workCounters = false,
		load = function(): Frameworks.Loaded
			return { library = nil, extras = {} }
		end,
	}
end

local function subject(): Workloads.Workload
	local case: Workloads.Case = {
		prepare = function(): WorkloadTypes.State
			return {
				run = function() end,
				snapshot = function(): string
					return ""
				end,
				release = function() end,
			}
		end,
		run = function() end,
		snapshot = function(): string
			return ""
		end,
		release = function() end,
	}
	return {
		id = "fixture",
		title = "fixture",
		what = "report fixture",
		samples = 2,
		iterations = 10,
		warmup = 0,
		cases = { compose = case, other = case },
		unsupported = { absent = "No primitive | no substitute" },
	}
end

local function stored(): Benchmark.Stored
	local measurements: { Benchmark.StoredMeasurement } = {}
	for _, metric in
		{
			{ name = "compose", unit = "microseconds", value = 10 },
			{ name = "other", unit = "microseconds", value = 20 },
			{ name = "compose/memory/mounted", unit = "KiB", value = 100 },
			{ name = "other/memory/mounted", unit = "KiB", value = 50 },
			{ name = "compose/memory/teardown", unit = "KiB", value = 0 },
			{ name = "other/memory/teardown", unit = "KiB", value = 1 },
			{ name = "compose/work/writes", unit = "count", value = 30 },
			{ name = "other/work/writes", unit = "count", value = 40 },
			{ name = "compose/work/created", unit = "count", value = 0 },
			{ name = "other/work/created", unit = "count", value = 2 },
			{ name = "compose/work/connections", unit = "count", value = 0 },
			{ name = "other/work/connections", unit = "count", value = 3 },
			{ name = "compose/work/deferred", unit = "count", value = 0 },
			{ name = "other/work/deferred", unit = "count", value = 4 },
		}
	do
		table.insert(measurements, {
			name = "fixture/" .. metric.name,
			unit = metric.unit,
			environment = "fixture",
			samples = { metric.value, metric.value },
		})
	end
	return { schemaVersion = 1, name = "fixture", measurements = measurements }
end

Test.it("comparison summary reports medians, Compose ratios, and explicit unsupported reasons", function()
	local markdown, complete = Report.markdown(
		stored(),
		{ subject() },
		{ framework "compose", framework "other", framework "absent" }
	)
	Test.expect(complete):toBe(true)
	Test.expect(markdown):toContain "| other | 20.000 | 2.00x | 50.000 | 0.50x | 1.000 | 40 | 2 | 3 | 4 |"
	Test.expect(markdown):toContain "unsupported: No primitive \\| no substitute"
	Test.expect(Report.median { 4, 1, 3, 2 }):toBe(2.5)
end)

Test.it("comparison summary rejects missing supported measurements and handles zero heap baselines", function()
	local run = stored()
	table.remove(run.measurements)
	local markdown, complete = Report.markdown(run, { subject() }, { framework "compose", framework "other" })
	Test.expect(complete):toBe(false)
	Test.expect(markdown):toContain "missing evidence"
	local zero = stored()
	zero.measurements[3].samples = { 0, 0 }
	local rendered, hasEvidence = Report.markdown(zero, { subject() }, { framework "compose", framework "other" })
	Test.expect(hasEvidence):toBe(true)
	Test.expect(rendered):toContain "n/a (zero baseline)"
end)

Test.it("normal benchmark entries keep only the required bare and Compose lanes", function()
	local names: { string } = {}
	for _, candidate in Frameworks.available() do
		table.insert(names, candidate.name)
	end
	Test.expect(table.concat(names, ",")):toBe "bare,compose"
end)

Test.it("optional comparison lanes classify every runtime workload and pin benchmark-only sources", function()
	local names: { [string]: string } = {
		roact = "roact",
		seam = "seam",
		signals = "signals",
		["react-reflex"] = "reflex",
		["fusion-charm"] = "charm",
		["react-upstream"] = "react-upstream",
	}
	local seen: { [string]: boolean } = {}
	for _, candidate in Frameworks.available(true) do
		local dependencyName = names[candidate.name]
		if not dependencyName then
			continue
		end
		seen[candidate.name] = true
		local found = false
		for _, dependency in Lock.dependencies do
			if dependency.name == dependencyName then
				found = true
				Test.expect(#dependency.commit):toBe(40)
				Test.expect(#dependency.tree):toBe(40)
				Test.expect(dependency.rights):toBe "MIT"
				for _, surface in dependency.surfaces do
					Test.expect(surface.role):toBe "benchmark"
				end
			end
		end
		Test.expect(found):toBe(true)
		Test.expect(#Workloads.all):toBe(24)
		for _, workload in Workloads.all do
			local implemented = workload.cases[candidate.name] ~= nil
			local reasons: { [string]: string } = workload.unsupported or {}
			local reason = reasons[candidate.name]
			Test.expect(implemented ~= (reason ~= nil)):toBe(true)
			if reason then
				Test.expect(#reason > 20):toBe(true)
			end
		end
	end
	for name in names do
		Test.expect(seen[name]):toBe(true)
	end
end)

Test.it("comparison host models native vector defaults and ancestry", function()
	local environment = Environment.create()
	local container = environment.container()
	local parent = environment.globals.Instance.new "Frame"
	local part = environment.globals.Instance.new "Part"
	Test.expect(environment.globals.typeof(part.Position)):toBe "Vector3"
	parent.Parent = container
	part.Parent = parent
	Test.expect(part:IsDescendantOf(environment.globals.game)):toBe(true)
	local changes = 0
	local connection = environment.signal(part, "AncestryChanged"):Connect(function()
		changes += 1
	end)
	part.Parent = parent
	Test.expect(changes):toBe(0)
	part.Parent = container
	Test.expect(changes):toBe(1)
	part.Parent = nil
	Test.expect(part:IsDescendantOf(environment.globals.game)):toBe(false)
	connection:Disconnect()
	parent:Destroy()
	part:Destroy()
	container:Destroy()
	Test.expect(environment.liveConnections()):toBe(0)
	Test.expect(environment.liveInstances()):toBe(1)
end)

Test.it("calibration rejection keeps raw measurements but cannot supply comparison values", function()
	local harness = Verify.createHarness { now = os.clock }
	local function measure(context: Verify.Context, name: string)
		context:measure("fixture", name, {
			samples = { 1, 2 },
			unit = "microseconds",
			context = { environment = "fixture", signal = name, timing = "observed" },
		}, { unit = "microseconds", minimumSamples = 2, measureOnly = true })
	end
	harness:case("accepted", function(context)
		measure(context, "accepted")
	end)
	harness:case("rejected", function(context)
		measure(context, "rejected")
		context:unsupported "CPU reference drift"
	end)
	local report = harness:run { executor = "fixture" }
	Test.expect(report.unsupported):toBe(1)
	Test.expect(#Benchmark.storeReport("raw", report).measurements):toBe(2)
	local accepted = Report.store("qualified", report)
	Test.expect(#accepted.measurements):toBe(1)
	Test.expect(accepted.measurements[1].name):toBe "accepted"
end)

return nil
