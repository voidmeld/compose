--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

local Consumer = require "../.lute/dependencies/verify/src/consumer"

local DEFAULT_ROOTS = { "tests", "verification" }

local function isSpecification(path: string): boolean
	return string.match(path, "%.verify%.luau$") ~= nil
end

local function main(): number
	local roots: { string } = {}
	for index = 2, #process.args do
		table.insert(roots, process.args[index])
	end
	if #roots == 0 then
		roots = DEFAULT_ROOTS
	end

	local findings: { string } = {}
	local scanned = 0

	local function scan(path: string)
		if not isSpecification(path) then
			return
		end
		scanned += 1
		for _, finding in Consumer.scan(fs.readFileToString(path), path) do
			table.insert(
				findings,
				("%s:%d %s %s; %s"):format(path, finding.offset, finding.code, finding.why, finding.fix)
			)
		end
	end

	local function walk(path: string)
		if fs.metadata(path).type == "file" then
			scan(path)
			return
		end
		local names: { string } = {}
		local kinds: { [string]: string } = {}
		for _, entry in fs.listDirectory(path) do
			table.insert(names, entry.name)
			kinds[entry.name] = entry.type
		end
		table.sort(names)
		for _, name in names do
			local child = path .. "/" .. name
			if kinds[name] == "dir" then
				walk(child)
			else
				scan(child)
			end
		end
	end

	for _, root in roots do
		if fs.exists(root) then
			walk(root)
		end
	end

	if #findings > 0 then
		print(("verify-check: %d finding(s)"):format(#findings))
		for _, finding in findings do
			print("  " .. finding)
		end
		return 1
	end
	print(("verify-check: clean (%d specification(s))"):format(scanned))
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
