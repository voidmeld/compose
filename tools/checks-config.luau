--!strict

local process = require "@std/process"
local Policy = require "./checks-policy"
local Repository = require "../.lute/dependencies/verify/src/checks/repository"
local Clone = require "../.lute/dependencies/verify/src/checks/clean-clone"
local Comments = require "../.lute/dependencies/verify/src/checks/comments"
local Manifest = require "../.lute/dependencies/verify/src/checks/manifest"
local Provenance = require "../.lute/dependencies/verify/src/checks/provenance"
local Surface = require "../.lute/dependencies/verify/src/checks/surface"

local config: {
	boundary: Repository.Boundary,
	leakage: Repository.Scan,
	provenance: Provenance.Config,
	comments: Comments.Config,
	manifest: Manifest.Config,
	publicSurface: Surface.Config,
	cleanClone: Clone.Config,
	noAny: Repository.Selection,
	specStyle: Repository.Selection,
} =
	{
		boundary = { root = "src/core", allowMissing = true, rules = Policy.boundary },
		leakage = {
			suffixes = { ".luau", ".lua", ".md", ".json", ".toml", ".txt", ".yml", ".yaml" },
			exclude = { [Policy.selfPath] = true, LICENSE = true },
			rules = Policy.leakage,
			allowedLiterals = {},
		},
		provenance = {
			forbiddenPaths = {
				"vendor",
				"third_party",
				"third-party",
				"node_modules",
				"Packages",
				"DevPackages",
				"bench/frameworks",
			},
			license = "LICENSE",
			licensePrefix = "MIT License\n",
			licenseFragments = {
				"Copyright (c) 2026 voidmeld",
				"Permission is hereby granted, free of charge, to any person obtaining a copy",
			},
			lock = "dependencies.lock.luau",
			dependencyCommand = { "lute", "run", "tools/sync-dependencies.luau", "--check" },
			root = ".",
			skip = { ".git/", "build/", "bench/results/", ".lute/" },
			suffixes = { ".luau", ".lua", ".md", ".toml", ".json", ".yml", ".yaml", ".sh", ".py" },
			descriptors = {
				"manifest.json",
				"package.json",
				"package-lock.json",
				"wally.toml",
				"wally.lock",
				"rotriever.toml",
			},
			noticeNames = { "LICENSE", "LICENCE", "LICENSE.md", "LICENCE.md", "COPYING", "NOTICE", "NOTICE.md" },
			expectedNotices = { LICENSE = "Compose's MIT license grant" },
			scriptExceptions = {},
			forbiddenSuffixes = { ".py" },
			justifiedSuffixes = { ".sh" },
		},
		comments = {
			roots = { "authoring", "bench", "examples", "src", "tests", "tools", "verification" },
			files = { "dependencies.lock.luau", "lint.config.luau" },
			configFiles = { ".styluaignore", "rokit.toml", "stylua.toml" },
			allowed = { "^%-%-![A-Za-z]+", "^%-%-# selene" },
			lineDirectives = true,
		},
		manifest = { path = "tests/manifest.luau", rules = { { root = "tests", pattern = "%.verify%.luau$" } } },
		publicSurface = {
			docs = "docs/api.md",
			undocumented = {
				["Compose.__resetForTests"] = "test seam, named with a reserved prefix",
				["ComposeRoblox.__resetForTests"] = "test seam, named with a reserved prefix",
			},
			packages = {
				{
					prefix = "Compose",
					entry = "src/core/init.luau",
					load = function(): unknown
						return require "../src/core"
					end,
				},
				{
					prefix = "TestScene",
					entry = "src/test-scene/init.luau",
					load = function(): unknown
						return require "../src/test-scene"
					end,
				},
				{
					prefix = "ComposeRoblox",
					entry = "src/roblox/init.luau",
					load = function(): unknown
						return require "../src/roblox"
					end,
				},
				{
					prefix = "Design",
					entry = "src/design/init.luau",
					load = function(): unknown
						return require "../src/design"
					end,
				},
				{
					prefix = "DesignEditor",
					entry = "src/design-editor/init.luau",
					load = function(): unknown
						return require "../src/design-editor"
					end,
				},
				{
					prefix = "RobloxEmulator",
					entry = "src/test-scene/roblox.luau",
					load = function(): unknown
						return require "../src/test-scene/roblox"
					end,
				},
				{
					prefix = "Author",
					entry = "authoring/init.luau",
					load = function(): unknown
						return require "../authoring"
					end,
				},
			},
		},
		cleanClone = {
			prefix = "compose-clean-clone",
			command = { "lute", "run", "tools/gate.luau", "--tier", "fast" },
			env = { COMPOSE_DEPENDENCY_SOURCE_ROOT = tostring(process.cwd()) .. "/.lute/dependencies" },
			requiredPaths = { ".lute/dependencies" },
		},
		noAny = { untracked = true },
		specStyle = {
			untracked = true,
			exclude = { ["tests/tools/framework-comparison.lute.verify.luau"] = true },
		},
	}

return config
