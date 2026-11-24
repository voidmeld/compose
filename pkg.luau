--!strict

return {
	package = {
		name = "voidmeld/compose",
		version = "0.1.1",
		files = {
			"src/**",
			"authoring/**",
			"docs/**",
			"/.agents/skills/compose/**",
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
				rev = "2e8cedeb260dd61d29b6f4be51a5fc250254e80b",
			},
		},
	},
}
