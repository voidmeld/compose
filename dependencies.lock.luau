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
			commit = "4d6fe22a7b5261c4925889b3449fcf9e60d36f28",
			tree = "ee0a7007acbf7b4942eb785d3a2d703946848674",
			rights = "MIT",
			surfaces = {
				{ root = "src", role = "verification" },
			},
		},
	},
}
