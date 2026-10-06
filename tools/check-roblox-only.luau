--!strict

local fs = require "@std/fs"
local process = require "@lute/process"
local lock = require "../dependencies.lock"

local CACHE = ".lute/roblox-types/" .. lock.robloxTypes.sha256 .. ".d.luau"

local function checked(arguments: { string }): boolean
	local result = process.run(arguments, { stdio = "inherit" })
	return result.ok
end

local function main(): number
	fs.createDirectory(".lute/roblox-types", { makeParents = true })
	if not fs.exists(CACHE) then
		if
			not checked {
				"curl",
				"--fail",
				"--silent",
				"--show-error",
				"--location",
				lock.robloxTypes.url,
				"--output",
				CACHE,
			}
		then
			return 1
		end
	end
	local digest = process.run { "shasum", "-a", "256", CACHE }
	if not digest.ok or string.match(digest.stdout, "^(%x+)") ~= lock.robloxTypes.sha256 then
		print "check-roblox-only: downloaded Roblox declarations failed the pinned digest"
		return 1
	end
	local arguments = {
		"luau-lsp",
		"analyze",
		"--platform=roblox",
		"--definitions=" .. CACHE,
		"--base-luaurc=.luaurc",
		"--ignore=**/.lute/**",
		"verification",
	}
	if not checked(arguments) then
		return 1
	end
	table.insert(arguments, 3, "--flag:LuauSolverV2=true")
	if not checked(arguments) then
		return 1
	end
	print "check-roblox-only: native verification type-checks under both solvers; engine checks have not run"
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
