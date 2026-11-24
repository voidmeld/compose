--!strict

return {
	package = {
		name = "voidmeld/compose",
		version = "0.1.0",
		files = {
			"src/**",
			"authoring/**",
			"docs/**",
			"/default.project.json",
			"/README.md",
			"/CHANGELOG.md",
			"/LICENSE",
			"!**/*.verify.luau",
		},
		metadata = {
			description = "A reactive UI and scene library for Roblox, written in strict Luau.",
			license = "MIT",
			repository = "https://github.com/voidmeld/compose",
			exports = {
				Compose = "src/core",
				ComposeRoblox = "src/roblox",
				TestScene = "src/test-scene",
				RobloxEmulator = "src/test-scene/roblox.luau",
				Design = "src/design",
				DesignEditor = "src/design-editor",
				Author = "authoring",
			},
		},
		dependencies = {},
		dev_dependencies = {
			verify = {
				sourceKind = "github",
				source = "https://github.com/voidmeld/verify",
				rev = "35c5590efa9fdb9fc12319a7bc9455a81c2d1970",
			},
		},
	},
}
