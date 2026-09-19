--!strict

local parser = require "@lute/syntax/parser"
local process = require "@lute/process"

local walk = require "./lib/walk"

local ROOTS = { "verification" }

local function main(): number
	local problems: { string } = {}
	local checked = 0

	for _, root in ROOTS do
		for _, file in walk.files(root, { ".luau" }) do
			checked += 1
			local ok, err: any = pcall(parser.parse, file.contents)
			if not ok then
				table.insert(problems, ("%s: does not parse: %s"):format(file.path, tostring(err)))
			end
		end
	end

	if checked == 0 then
		print "check-roblox-only: nothing to check"
		return 0
	end

	if #problems > 0 then
		print(("check-roblox-only: %d problem(s)"):format(#problems))
		for _, problem in problems do
			print("  " .. problem)
		end
		return 1
	end

	print(("check-roblox-only: ok (%d file(s) parse; types are checked in Studio, not here)"):format(checked))
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
