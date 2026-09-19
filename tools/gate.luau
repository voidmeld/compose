--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

type Step = {
	name: string,
	why: string,
	command: { string },
	targets: { string },
	slow: boolean,
}

local SOURCE_TREES = {
	"dependencies.lock.luau",
	"src",
	"authoring",
	"tests",
	"tools",
	"bench",
	"examples",
	"verification",
}

local ANALYZE = {
	"luau-lsp",
	"analyze",
	"--platform=standard",
	"--base-luaurc=.luaurc",
	"--ignore=**/.lute/**",
	"--ignore=**/build/**",
}

local STEPS: { Step } = {
	{
		name = "dependencies",
		why = "every studio-owned dependency resolves at its exact committed identity outside this repository",
		command = { "lute", "run", "tools/sync-dependencies.luau" },
		targets = { "dependencies.lock.luau" },
		slow = false,
	},
	{
		name = "format",
		why = "source is formatted exactly as stylua.toml specifies",
		command = { "stylua", "--check" },
		targets = SOURCE_TREES,
		slow = false,
	},

	{
		name = "comments",
		why = "source contains only permitted tool directives, never explanatory comments",
		command = { "lute", "run", "tools/check-code-comments.luau" },
		targets = SOURCE_TREES,
		slow = false,
	},
	{
		name = "lint",
		why = "no lint findings under the policy in lint.config.luau",
		command = { "lute", "lint", "-c", "lint.config.luau" },
		targets = SOURCE_TREES,
		slow = false,
	},
	{
		name = "types:core",
		why = "compose-core, the test host, and the Roblox adapter type-check strictly on their own",
		command = ANALYZE,
		targets = { "src" },
		slow = false,
	},
	{
		name = "types:support",
		why = "the authoring package, tests, tools, benchmarks, and examples type-check strictly",
		command = ANALYZE,
		targets = { "authoring", "tests", "tools", "bench", "examples" },
		slow = false,
	},
	{
		name = "test-manifest",
		why = "the committed run manifest is the corpus on disk, so what runs is a reviewed artefact",

		command = { "lute", "run", "tools/check-test-manifest.luau" },
		targets = { "tests/manifest.luau" },
		slow = false,
	},
	{
		name = "tests",
		why = "unit, property, lifecycle failure-injection, and adapter contract tests pass",
		command = { "lute", "run", "tools/run-tests.luau", "--json", "bench/results/last-test-run.json" },
		targets = { "tests" },
		slow = false,
	},
	{
		name = "verify-check",
		why = "every specification satisfies Verify's consumer-semantic rules, and a portable one is portable",
		command = { "lute", "run", "tools/verify-check.luau" },
		targets = { "tests" },
		slow = false,
	},
	{
		name = "roblox-only",
		why = "Roblox-only source parses and is formatted, which is all the gate can check off-platform",
		command = { "lute", "run", "tools/check-roblox-only.luau" },
		targets = { "verification" },
		slow = false,
	},
	{
		name = "boundary",
		why = "src/core names nothing Roblox-specific and takes no ambient clock",
		command = { "lute", "run", "tools/check-boundary.luau" },
		targets = { "src/core" },
		slow = false,
	},
	{
		name = "provenance",
		why = "no foreign source tree, no dependency descriptor, and the licence inventory is complete",
		command = { "lute", "run", "tools/check-provenance.luau" },
		targets = { "src" },
		slow = false,
	},
	{
		name = "leakage",
		why = "no material from the originating private repository is present",
		command = { "lute", "run", "tools/check-leakage.luau" },
		targets = { "tools" },
		slow = false,
	},

	{
		name = "public-surface",
		why = "the documented public API and the exported public API are the same set",
		command = { "lute", "run", "tools/check-public-surface.luau" },
		targets = { "tools" },
		slow = false,
	},
	{
		name = "production-surface",
		why = "no Verify framework, specification or test-harness source reaches a built production artefact",
		command = { "lute", "run", "tools/check-production-surface.luau" },
		targets = { "default.project.json" },
		slow = false,
	},
	{
		name = "clean-clone",
		why = "a fresh clone of HEAD builds and tests with no working-tree state",
		command = { "lute", "run", "tools/check-clean-clone.luau" },
		targets = { "tools" },
		slow = true,
	},
}

local function parse(): { fast: boolean, list: boolean }
	local options = { fast = false, list = false }
	for index = 2, #process.args do
		local argument = process.args[index]
		if argument == "--fast" then
			options.fast = true
		elseif argument == "--list" then
			options.list = true
		else
			error(("gate: unrecognised argument %q"):format(tostring(argument)))
		end
	end
	return options
end

local function argvFor(step: Step): { string }
	local argv = table.clone(step.command)
	if step.command[1] == "lute" and step.command[2] == "run" then
		return argv
	end
	for _, target in step.targets do
		table.insert(argv, target)
	end
	return argv
end

local function main(): number
	local options = parse()

	if options.list then
		for _, step in STEPS do
			print(("%-16s %s%s"):format(step.name, step.why, if step.slow then "  [slow]" else ""))
		end
		return 0
	end

	for _, step in STEPS do
		for _, target in step.targets do
			if not fs.exists(target) then
				print(("gate: %s requires missing target %s"):format(step.name, target))
				return 1
			end
		end
	end

	if not options.fast then
		local status = process.run { "git", "status", "--porcelain" }
		if not status.ok or string.match(status.stdout, "%S") ~= nil then
			print "gate: full candidate requires a clean committed HEAD; use focused checks while editing, then commit locally before the full gate and push"
			return 1
		end
	end

	local failed: { string } = {}
	local skipped: { string } = {}

	for _, step in STEPS do
		local argv = argvFor(step)
		if step.slow and options.fast then
			table.insert(skipped, step.name)
			print(("--- %-16s skipped (--fast)"):format(step.name))
			continue
		end

		print(("--- %s"):format(step.name))
		local result = process.run(argv, { stdio = "inherit" })
		if not result.ok then
			table.insert(failed, step.name)
			print(("--- %-16s FAILED (exit %d): %s"):format(step.name, result.exitcode, step.why))
		else
			print(("--- %-16s ok"):format(step.name))
		end
	end

	print ""
	if #skipped > 0 then
		print(("gate: skipped %d slow step(s): %s"):format(#skipped, table.concat(skipped, ", ")))
	end
	if #failed > 0 then
		print(("gate: FAILED (%d of %d steps): %s"):format(#failed, #STEPS, table.concat(failed, ", ")))
		return 1
	end
	local ran = #STEPS - #skipped
	if #skipped > 0 then
		print(("gate: %d step(s) passed; this is not a candidate gate"):format(ran))
		return 0
	end
	print(("gate: PASSED (%d steps)"):format(ran))
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
