--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

local DEPENDENCY_CACHE = ".lute/dependencies/verify"
local DIRECTORY = ".lute/tmp/compose-gate"

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

local TYPED_TREES = {
	"dependencies.lock.luau",
	"lint.config.luau",
	"src",
	"authoring",
	"tests",
	"tools",
	"bench",
	"examples",
}

local USAGE =
	"usage: lute run tools/gate.luau [--native] [--only producer]... [--tier name]... [--case id]... [--file spec]... [--name text] [--rerun] [--explain id] [--list]"
local native = false
local flags: { string } = {}
for position = 2, #process.args do
	if process.args[position] == "--native" then
		native = true
	else
		table.insert(flags, process.args[position])
	end
end

for _, tree in { SOURCE_TREES, TYPED_TREES } do
	for _, target in tree do
		if not fs.exists(target) then
			print(("gate: requires missing target %s"):format(target))
			process.exit(1)
		end
	end
end

local complete = #flags == 0
if complete then
	local status = process.run { "git", "status", "--porcelain" }
	if not status.ok or string.match(status.stdout, "%S") ~= nil then
		print "gate: full candidate requires a clean committed HEAD; use focused checks while editing, then commit locally before the full gate and push"
		process.exit(1)
	end
end
if not fs.exists(DEPENDENCY_CACHE) and not process.run({ "lute", "run", "tools/sync-dependencies.luau" }).ok then
	print "gate: the dependency cache could not be created; run lute run tools/sync-dependencies.luau"
	process.exit(1)
end

local Gate = require "../.lute/dependencies/verify/src/gate"
local Lute = require "../.lute/dependencies/verify/src/lute"
local Manifest = require "../tests/manifest"

local specs = table.clone(Manifest)
assert(#specs > 0, "the test manifest names no specification")

local function check(id: string, why: string, argv: { string }, targets: { string }?, tier: string?): Gate.ProducerDraft
	local full = table.clone(argv)
	if targets ~= nil then
		table.move(targets, 1, #targets, #full + 1, full)
	end
	return { id = id, kind = "command", argv = full, why = why, tier = tier or "fast" }
end

local function script(id: string, why: string, path: string, ...: string): Gate.ProducerDraft
	return check(id, why, { "lute", "run", path, ... })
end

local ANALYZE = { "luau-lsp", "analyze", "--platform=standard", "--base-luaurc=.luaurc" }
local SOLVER_V2 = table.clone(ANALYZE)
table.insert(SOLVER_V2, 3, "--flag:LuauSolverV2=true")
for _, argv in { ANALYZE, SOLVER_V2 } do
	table.insert(argv, "--ignore=**/.lute/**")
	table.insert(argv, "--ignore=**/build/**")
end

local draft: Gate.Draft = {
	id = "compose-gate",
	producers = {
		script(
			"dependencies",
			"every pinned dependency resolves at its exact committed identity outside this repository",
			"tools/sync-dependencies.luau"
		),
		check("format", "source is formatted exactly as stylua.toml specifies", { "stylua", "--check" }, SOURCE_TREES),
		script("type-policy", "strict maintained Luau has no explicit any", "tools/check-no-any.luau"),
		script(
			"comments",
			"source contains only permitted tool directives, never explanatory comments",
			"tools/check-code-comments.luau"
		),
		check(
			"lint",
			"no lint findings under the policy in lint.config.luau",
			{ "lute", "lint", "-c", "lint.config.luau" },
			SOURCE_TREES
		),
		check(
			"types",
			"every portable package, test, tool, benchmark, example, and configuration type-checks strictly under the old type solver",
			ANALYZE,
			TYPED_TREES
		),
		check(
			"types-solver-v2",
			"the same trees type-check strictly under the new type solver, including the tests/types contracts",
			SOLVER_V2,
			TYPED_TREES
		),
		script(
			"test-manifest",
			"the committed run manifest is the corpus on disk, so what runs is a reviewed artefact",
			"tools/check-test-manifest.luau"
		),
		{
			id = "tests",
			kind = "tests",
			worker = "tests/worker.luau",
			locators = specs,
			tier = "fast",
			why = "unit, property, lifecycle failure-injection, adapter contract and example tests pass",
			deadlineSeconds = 1800,
		},
		script(
			"benchmark-parity",
			"every benchmark workload and scenario builds the same observable tree in every framework",
			"bench/run.luau",
			"--verify",
			"--suite",
			"all"
		),
		check(
			"verify-check",
			"every specification satisfies the Verify consumer rules, and a portable one is portable",
			{
				"lute",
				"run",
				".lute/dependencies/verify/tools/verify-check.luau",
				"--ruleset",
				"roblox",
				"tests",
				"verification",
			}
		),
		script(
			"roblox-only",
			"native verification type-checks under both solvers with the pinned Roblox declarations",
			"tools/check-roblox-only.luau"
		),
		script(
			"boundary",
			"src/core names nothing Roblox-specific and takes no ambient clock",
			"tools/check-boundary.luau"
		),
		script(
			"provenance",
			"no foreign source tree, no dependency descriptor, and the licence inventory is complete",
			"tools/check-provenance.luau"
		),
		script(
			"leakage",
			"checks that no content from a consumer repository leaked into this repository",
			"tools/check-leakage.luau"
		),
		script(
			"public-surface",
			"the documented public API and the exported public API are the same set",
			"tools/check-public-surface.luau"
		),
		script(
			"production-surface",
			"no Verify framework, specification or test-harness source reaches a built production artefact",
			"tools/check-production-surface.luau"
		),
		{
			id = "roblox-engine",
			kind = "native",
			argv = {
				"lute",
				"run",
				".lute/dependencies/verify/tools/run.luau",
				"--entry",
				"verification/roblox/entry.luau",
				"--host",
				"studio",
				"--deadline",
				"300",
			},
			requires = { "native-studio" },
			tier = "native",
			why = "the engine checks run in a launched Studio and report through the standard report",
		},
		{
			id = "clean-clone",
			kind = "command",
			argv = { "lute", "run", "tools/check-clean-clone.luau" },
			why = "a fresh clone of HEAD builds and tests with no working-tree state",
			tier = "slow",
			deadlineSeconds = 1800,
		},
	},
	policy = {
		commandDeadlineSeconds = 900,
		deadlineSeconds = 3600,
		deferrals = if native
			then nil
			else { ["roblox-engine"] = "the portable gate does not run Studio; use --native" },
	},
}

local exitCode = Lute.gate.cli(draft, flags, {
	usage = USAGE,
	options = { directory = DIRECTORY, capabilities = if native then { "native-studio" } else {} },
})
if exitCode ~= 0 then
	process.exit(exitCode)
end
