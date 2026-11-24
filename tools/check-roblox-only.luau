--!strict

local fs = require "@std/fs"
local process = require "@lute/process"
local RobloxTypes = require "./roblox-types"

local CACHE = ".lute/roblox-types/" .. RobloxTypes.sha256 .. ".d.luau"
local SOURCEMAP = ".lute/studio-sourcemap.json"

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
				RobloxTypes.url,
				"--output",
				CACHE,
			}
		then
			return 1
		end
	end
	local digest = process.run { "sha256sum", CACHE }
	if not digest.ok or string.match(digest.stdout, "^(%x+)") ~= RobloxTypes.sha256 then
		print "check-roblox-only: downloaded Roblox declarations failed the pinned digest"
		return 1
	end
	local arguments = {
		"luau-lsp",
		"analyze",
		"--flag:LuauSolverV2=true",
		"--platform=roblox",
		"--definitions=" .. CACHE,
		"--ignore=**/.lute/**",
		"verification",
	}
	if
		not checked { "rojo", "sourcemap", "studio/design/plugin.project.json", "--absolute", "--output", SOURCEMAP }
	then
		return 1
	end
	local plugin = {
		"luau-lsp",
		"analyze",
		"--flag:LuauSolverV2=true",
		"--platform=roblox",
		"--definitions=" .. CACHE,
		"--sourcemap=" .. SOURCEMAP,
		"studio",
	}
	for _, command in { arguments, plugin } do
		if not checked(command) then
			return 1
		end
	end
	print "check-roblox-only: native verification and the Studio plugin type-check with Solver V2; engine checks have not run"
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
