--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

local consumerRules = require "./lib/consumer-rules"
local readableRules = require "./lib/readable-rules"
local walk = require "./lib/walk"

type Confidence = "certain" | "likely"

type Finding = {
	code: string,
	confidence: Confidence,
	path: string,
	line: number,
	excerpt: string,
	why: string,
	fix: string,
	caveat: string?,
}

local READABLE = { ".luau", ".lua" }

local SKIP = {
	"/vendor/",
	"/packages/",
	"/serverpackages/",
	"/wally_packages/",
	"/.pesde/",
	"/.worktrees/",
	"/compose/src/",
	"/node_modules/",
	"/.git/",
	"/build/",
}

local function skipped(relative: string): boolean
	local normalized = string.lower(relative)
	for _, piece in SKIP do
		if string.find("/" .. normalized, piece, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local function below(root: string, path: string): string
	local prefix = (string.gsub(root, "/+$", "")) .. "/"
	if string.sub(path, 1, #prefix) == prefix then
		return string.sub(path, #prefix + 1)
	end
	return (string.gsub(path, "^%./", ""))
end

local function confidenceOf(rule: readableRules.Rule): Confidence
	return if rule.bodyNames then "likely" else "certain"
end

local function caveatOf(rule: readableRules.Rule): string?
	if not rule.bodyNames then
		return nil
	end
	return "a reactive body is legitimately called with the reader; this is a false positive if the "
		.. "name refers to a body rather than to a cell or formula"
end

type Options = { root: string, json: string?, code: string? }

local function parse(): Options
	local options: Options = { root = "", json = nil, code = nil }
	local args = process.args
	local index = 2
	while index <= #args do
		local argument = args[index]
		if argument == "--root" then
			index += 1
			options.root = args[index]
		elseif argument == "--json" then
			index += 1
			options.json = args[index]
		elseif argument == "--code" then
			index += 1
			options.code = args[index]
		else
			error(("compose-check: unrecognised argument %q"):format(tostring(argument)), 0)
		end
		index += 1
	end
	if options.root == "" then
		error("compose-check: --root is required", 0)
	end
	return options
end

local function excerptAt(contents: string, offset: number): string
	local line = string.match(string.sub(contents, offset, offset + 120), "^[^\n]*") :: string
	return (string.gsub(line, "%s+$", ""))
end

local function escape(text: string): string
	local out = string.gsub(text, "\\", "\\\\")
	out = string.gsub(out, '"', '\\"')
	out = string.gsub(out, "\n", "\\n")
	out = string.gsub(out, "\t", "\\t")
	return out
end

local function toJson(findings: { Finding }, scanned: number, root: string): string
	local lines: { string } = { "{" }
	table.insert(lines, '  "schemaVersion": 1,')
	table.insert(lines, ('  "root": "%s",'):format(escape(root)))
	table.insert(lines, ('  "filesScanned": %d,'):format(scanned))
	table.insert(lines, ('  "findingCount": %d,'):format(#findings))
	table.insert(lines, '  "findings": [')
	local entries: { string } = {}
	for _, finding in findings do
		local caveat = if finding.caveat == nil then "null" else ('"%s"'):format(escape(finding.caveat))
		table.insert(
			entries,
			('    {\n      "code": "%s",\n      "confidence": "%s",\n      "path": "%s",\n      "line": %d,\n'):format(
				finding.code,
				finding.confidence,
				escape(finding.path),
				finding.line
			)
				.. ('      "excerpt": "%s",\n      "why": "%s",\n      "fix": "%s",\n      "caveat": %s\n    }'):format(
					escape(finding.excerpt),
					escape(finding.why),
					escape(finding.fix),
					caveat
				)
		)
	end
	table.insert(lines, table.concat(entries, ",\n"))
	table.insert(lines, "  ]")
	table.insert(lines, "}")
	return table.concat(lines, "\n") .. "\n"
end

local function main(): number
	local options = parse()
	if not fs.exists(options.root) then
		print(("compose-check: no such directory: %s"):format(options.root))
		return 1
	end

	local findings: { Finding } = {}
	local scanned = 0

	for _, file in
		walk.filesSkipping(options.root, READABLE, function(relative: string, kind: string): boolean
			return skipped(relative .. if kind == "dir" then "/" else "")
		end)
	do
		local relative = below(options.root, file.path)
		scanned += 1
		local source = consumerRules.mask(file.contents)
		for _, rule in readableRules.rules do
			if options.code ~= nil and rule.code ~= options.code then
				continue
			end
			for _, occurrence in readableRules.occurrences(source, rule) do
				table.insert(findings, {
					code = rule.code,
					confidence = confidenceOf(rule),
					path = relative,
					line = walk.lineOf(file.contents, occurrence.offset),
					excerpt = excerptAt(file.contents, occurrence.offset),
					why = rule.why,
					fix = rule.fix,
					caveat = caveatOf(rule),
				})
			end
		end
		for _, finding in consumerRules.scan(file.contents, file.path) do
			if options.code ~= nil and finding.code ~= options.code then
				continue
			end
			table.insert(findings, {
				code = finding.code,
				confidence = finding.confidence,
				path = relative,
				line = walk.lineOf(file.contents, finding.offset),
				excerpt = excerptAt(file.contents, finding.offset),
				why = finding.why,
				fix = finding.fix,
				caveat = finding.caveat,
			})
		end
	end

	table.sort(findings, function(left: Finding, right: Finding): boolean
		if left.path ~= right.path then
			return left.path < right.path
		end
		if left.line ~= right.line then
			return left.line < right.line
		end
		return left.code < right.code
	end)

	if options.json ~= nil then
		fs.writeStringToFile(options.json, toJson(findings, scanned, options.root))
		print(("compose-check: wrote %s"):format(options.json))
	end

	if #findings == 0 then
		print(("compose-check: %d file(s) under %s, nothing found"):format(scanned, options.root))
		return 0
	end

	local certain = 0
	for _, finding in findings do
		if finding.confidence == "certain" then
			certain += 1
		end
	end

	print(
		("compose-check: %d finding(s) in %d file(s) -- %d certain, %d likely"):format(
			#findings,
			scanned,
			certain,
			#findings - certain
		)
	)
	print ""
	for _, finding in findings do
		print(("%s:%d  %s  [%s]"):format(finding.path, finding.line, finding.code, finding.confidence))
		print(("    %s"):format(finding.excerpt))
		print(("    why: %s"):format(finding.why))
		print(("    fix: %s"):format(finding.fix))
		if finding.caveat ~= nil then
			print(("    note: %s"):format(finding.caveat))
		end
		print ""
	end

	return if certain > 0 then 1 else 0
end

local ok, result: any = pcall(main)
if not ok then
	print(tostring(result))
	process.exit(1)
end
if result ~= 0 then
	process.exit(result)
end
