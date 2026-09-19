--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

local Consumer = require "../.lute/dependencies/verify/src/consumer"
local walk = require "./lib/walk"

local OUT = "build/production"
local PROJECT = "default.project.json"

local EXCLUDED_ROOTS = { ".lute", "vendor", "tests", "bench", "verification", "examples" }

type Artefact = {
	name: string,
	paths: { string },
}

local function resolve(moduleId: string): string
	for _, candidate in { moduleId .. ".luau", moduleId .. "/init.luau" } do
		if fs.exists(candidate) then
			return candidate
		end
	end

	return moduleId
end

local function bundledPaths(text: string): { string }
	local paths: { string } = {}
	local seen: { [string]: boolean } = {}
	for moduleId in string.gmatch(text, '__compose_modules%["([^"]+)"%]') do
		if not seen[moduleId] then
			seen[moduleId] = true
			table.insert(paths, resolve(moduleId))
		end
	end
	table.sort(paths)
	return paths
end

local function projectPaths(): { string }
	local text = fs.readFileToString(PROJECT)
	local paths: { string } = {}
	for mounted in string.gmatch(text, '"%$path"%s*:%s*"([^"]+)"') do
		if not fs.exists(mounted) then
			table.insert(paths, mounted)
		elseif fs.metadata(mounted).type == "file" then
			table.insert(paths, mounted)
		else
			walk.paths(mounted, { ".luau" }, paths)
		end
	end
	table.sort(paths)
	return paths
end

local function build(argv: { string }, out: string): string?
	local result = process.run(argv)
	if not result.ok or not fs.exists(out) then
		print(("check-production-surface: building %s failed\n%s%s"):format(out, result.stdout, result.stderr))
		return nil
	end
	return fs.readFileToString(out)
end

local function main(): number
	process.run { "mkdir", "-p", OUT }

	if not fs.exists ".lute/dependencies/verify/src" or not fs.exists "tests/harness" then
		print "check-production-surface: the verification surface is missing, so its exclusion proves nothing"
		return 1
	end

	local core = build({
		"lute",
		"run",
		"tools/bundle.luau",
		"--entry",
		"src/core",
		"--name",
		"Compose",
		"--out",
		OUT .. "/compose-core.luau",
	}, OUT .. "/compose-core.luau")
	local both = build({
		"lute",
		"run",
		"tools/bundle.luau",
		"--entry",
		"src/core",
		"--entry",
		"src/roblox",
		"--name",
		"Compose",
		"--out",
		OUT .. "/compose.luau",
	}, OUT .. "/compose.luau")
	local plugin = build({
		"lute",
		"run",
		"tools/make-verification-plugin.luau",
		"--out",
		OUT .. "/ComposeVerify.rbxmx",
	}, OUT .. "/ComposeVerify.rbxmx")
	if core == nil or both == nil or plugin == nil then
		return 1
	end

	local artefacts: { Artefact } = {
		{ name = PROJECT, paths = projectPaths() },
		{ name = "bundle(src/core)", paths = bundledPaths(core) },
		{ name = "bundle(src/core + src/roblox)", paths = bundledPaths(both) },
		{ name = "plugin bundle", paths = bundledPaths(plugin) },
	}

	local findings: { string } = {}
	local inspected = 0

	for _, artefact in artefacts do
		if #artefact.paths == 0 then
			table.insert(findings, ("%s: nothing was read back out of it, so it proves nothing"):format(artefact.name))
			continue
		end
		inspected += #artefact.paths
		for _, finding in Consumer.scanProductionPaths(artefact.paths) do
			table.insert(
				findings,
				("%s: %s %s; %s"):format(artefact.name, finding.code, finding.why, finding.fix)
					.. ("\n      %s"):format(finding.path)
			)
		end
		for _, path in artefact.paths do
			for _, root in EXCLUDED_ROOTS do
				if string.sub(path, 1, #root + 1) == root .. "/" then
					table.insert(
						findings,
						("%s: mounts %s, and a production artefact contains nothing under %s/"):format(
							artefact.name,
							path,
							root
						)
					)
				end
			end
		end
	end

	if #findings > 0 then
		print(("check-production-surface: %d finding(s)"):format(#findings))
		for _, finding in findings do
			print("  " .. finding)
		end
		return 1
	end

	print(
		("check-production-surface: %d artefact(s), %d source(s), no Verify framework, specification or test surface"):format(
			#artefacts,
			inspected
		)
	)
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
