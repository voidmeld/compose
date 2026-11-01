--!strict

return table.freeze {
	schemaVersion = 1,
	robloxTypes = table.freeze {
		url = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau",
		sha256 = "2857efa8245485f8c25c19c018ee1ef9b46afab4efd2ea70fc3257cd3faf7080",
	},
	dependencies = {
		table.freeze {
			name = "verify",
			version = "unreleased",
			repository = "https://github.com/voidmeld/verify.git",
			commit = "da25e2668aafbc3828aa5a3853f7f0c376bae6de",
			tree = "7eee4e18576cca860e9ab3f8b84becd7f69f2a26",
			rights = "MIT",
			surfaces = {
				{ root = "src", role = "verification" },
			},
		},
	},
}
