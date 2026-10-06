--!strict

local Environment = require "./cost-model"
local Frameworks = require "./harness/frameworks"
local Types = require "./scenarios/types"
local Workloads = require "./workloads"

local function firstDifference(expected: string, actual: string): string
	local expectedLines: { string } = {}
	local actualLines: { string } = {}
	for line in string.gmatch(expected, "[^\n]*") do
		table.insert(expectedLines, line)
	end
	for line in string.gmatch(actual, "[^\n]*") do
		table.insert(actualLines, line)
	end
	for index = 1, math.max(#expectedLines, #actualLines) do
		if expectedLines[index] ~= actualLines[index] then
			return ("line %d: expected %s, produced %s"):format(
				index,
				tostring(expectedLines[index]),
				tostring(actualLines[index])
			)
		end
	end
	return "trees differ in length"
end

local function mismatch(order: { Frameworks.Framework }, snapshots: { [string]: string }): string?
	local reference: string? = nil
	local referenceName = ""
	for _, framework in order do
		local snapshot = snapshots[framework.name]
		if snapshot == nil then
			continue
		end
		if reference == nil then
			reference = snapshot
			referenceName = framework.name
		elseif snapshot ~= reference then
			return ("%s differs from %s (%s)"):format(
				framework.name,
				referenceName,
				firstDifference(reference, snapshot)
			)
		end
	end
	return nil
end

local function workloadSnapshot(workload: Workloads.Workload, framework: Frameworks.Framework): (string?, string?)
	local environment = Environment.create()
	local loaded, result: unknown = pcall(framework.load, environment)
	if not loaded then
		return nil, ("could not load: %s"):format(tostring(result))
	end
	local case = workload.cases[framework.name]
	local context: Workloads.Context = {
		env = environment,
		library = (result :: Frameworks.Loaded).library,
		extras = (result :: Frameworks.Loaded).extras,
		container = environment.container(),
	}
	local snapshot: string? = nil
	local ran, err: unknown = pcall(function()
		local state = case.prepare(context)
		for _ = 1, workload.iterations do
			case.run(state, context)
		end
		environment.drain()
		snapshot = case.snapshot(state, context)
		case.release(state, context)
		environment.drain()
	end)
	if not ran then
		return nil, ("raised: %s"):format(tostring(err))
	end
	return snapshot, nil
end

local function workload(subject: Workloads.Workload, order: { Frameworks.Framework }): string?
	local snapshots: { [string]: string } = {}
	local problems: { string } = {}
	for _, framework in order do
		if subject.cases[framework.name] == nil then
			local unsupported = subject.unsupported
			if unsupported == nil or unsupported[framework.name] == nil then
				table.insert(
					problems,
					("%s has neither an implementation nor a recorded reason for not having one"):format(framework.name)
				)
			end
			continue
		end
		local snapshot, err = workloadSnapshot(subject, framework)
		if err ~= nil then
			table.insert(problems, ("%s %s"):format(framework.name, err))
		elseif snapshot ~= nil then
			snapshots[framework.name] = snapshot
		end
	end
	if #problems > 0 then
		return table.concat(problems, "; ")
	end
	return mismatch(order, snapshots)
end

local function scenarioSnapshot(
	scenario: Types.Scenario,
	framework: Frameworks.Framework,
	scale: Types.Scale
): (string?, string?)
	local case = scenario.cases[framework.name]
	local environment = Environment.create()
	local loaded = framework.load(environment)
	local context = {
		env = environment,
		library = loaded.library,
		extras = loaded.extras,
		container = environment.container(),
		scale = scale,
		case = case,
	} :: Types.Context
	local ok, result: unknown = pcall(function()
		local state = case.build(context, scale)
		for tick = 1, 12 do
			case.steady(state, context, tick)
		end
		case.burst(state, context, 1)
		case.steady(state, context, 13)
		case.burst(state, context, 2)
		for tick = 14, 20 do
			case.steady(state, context, tick)
		end
		environment.drain()
		local snapshot = case.snapshot(state, context)
		case.teardown(state, context)
		environment.drain()
		return snapshot
	end)
	if not ok then
		return nil, ("raised: %s"):format(tostring(result))
	end
	return result :: string, nil
end

local function scenario(subject: Types.Scenario, scale: Types.Scale, order: { Frameworks.Framework }): string?
	local snapshots: { [string]: string } = {}
	local problems: { string } = {}
	for _, framework in order do
		if subject.cases[framework.name] == nil then
			continue
		end
		local snapshot, err = scenarioSnapshot(subject, framework, scale)
		if err ~= nil then
			table.insert(problems, ("%s %s"):format(framework.name, err))
		elseif snapshot ~= nil then
			snapshots[framework.name] = snapshot
		end
	end
	if #problems > 0 then
		return table.concat(problems, "; ")
	end
	return mismatch(order, snapshots)
end

return {
	workload = workload,
	scenario = scenario,
}
