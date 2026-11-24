--!strict

local fs = require "@std/fs"
local Rules = require "./lib/ownership-rules"

export type Finding = Rules.Finding
export type Naming = Rules.Naming
export type Options = Rules.Options
export type Exemption = { path: string, reason: string, rule: string?, snippet: string? }
export type Config = {
	roots: { string },
	options: Options,
	include: ((path: string) -> boolean)?,
	exemptions: { Exemption }?,
	minimumReasonLength: number?,
	baseline: { [string]: { [string]: number } }?,
}
export type Result = { findings: { Finding }, notes: { string } }

local function evaluate(files: { [string]: string }, config: Config): Result
	if config.include ~= nil then
		local selected: { [string]: string } = {}
		for path, source in files do
			if config.include(path) then
				selected[path] = source
			end
		end
		files = selected
	end
	local findings: { Finding } = {}
	local notes: { string } = {}
	local used: { [number]: boolean } = {}
	local function configuration(path: string, message: string)
		table.insert(findings, { path = path, line = 1, rule = "configuration", message = message, snippet = "" })
	end
	local exemptions = config.exemptions or {}
	for _, entry in exemptions do
		local reason = string.gsub(entry.reason, "%s", "")
		if #reason < (config.minimumReasonLength or 1) or files[entry.path] == nil then
			configuration(entry.path, "an exemption needs a reason and a selected source file")
		end
	end
	local counts: { [string]: { [string]: number } } = {}
	for path, source in files do
		for _, finding in Rules.scan(path, source, config.options) do
			local exempt = false
			for index, entry in exemptions do
				if
					entry.path == path
					and (entry.rule == nil or entry.rule == finding.rule)
					and (entry.snippet == nil or entry.snippet == finding.snippet)
				then
					exempt = true
					used[index] = true
				end
			end
			if exempt then
				continue
			end
			local bucket = counts[path] or {}
			counts[path] = bucket
			bucket[finding.rule] = (bucket[finding.rule] or 0) + 1
			local baseline = if config.baseline ~= nil then config.baseline[path] else nil
			if bucket[finding.rule] > (if baseline ~= nil then baseline[finding.rule] or 0 else 0) then
				table.insert(findings, finding)
			end
		end
	end
	for index, entry in exemptions do
		if not used[index] then
			table.insert(
				notes,
				"unused exemption: " .. entry.path .. (if entry.rule ~= nil then " [" .. entry.rule .. "]" else "")
			)
		end
	end
	for _, row in config.options.counts or {} do
		if files[row.path] == nil then
			configuration(row.path, "missing required source file")
		end
	end
	local baselines: { [string]: { [string]: number } } = config.baseline or {}
	for path, baseline in baselines do
		for rule, allowed in baseline do
			local bucket = counts[path]
			local found = if bucket ~= nil then bucket[rule] or 0 else 0
			if found < allowed then
				table.insert(notes, ("%s [%s]: lower baseline from %d to %d"):format(path, rule, allowed, found))
			end
		end
	end
	table.sort(findings, function(left: Finding, right: Finding): boolean
		if left.path ~= right.path then
			return left.path < right.path
		elseif left.line ~= right.line then
			return left.line < right.line
		elseif left.rule ~= right.rule then
			return left.rule < right.rule
		end
		return left.message < right.message
	end)
	table.sort(notes)
	return { findings = findings, notes = notes }
end

local function check(config: Config): Result
	local files: { [string]: string } = {}
	local seen: { [string]: boolean } = {}
	local function walk(path: string)
		if seen[path] then
			return
		end
		seen[path] = true
		local metadata = fs.metadata(path)
		if metadata.type == "dir" then
			for _, child in fs.listDirectory(path) do
				walk(path .. "/" .. child.name)
			end
		elseif
			metadata.type == "file"
			and string.match(path, "%.lua[u]?$") ~= nil
			and (config.include == nil or config.include(path))
		then
			files[path] = fs.readFileToString(path)
		end
	end
	for _, root in config.roots do
		local path = string.gsub(root, "^%./", "")
		walk((string.gsub(path, "/+$", "")))
	end
	return evaluate(files, config)
end

return { check = check, evaluate = evaluate, scan = Rules.scan }
