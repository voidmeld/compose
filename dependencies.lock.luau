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
			commit = "e1ebf16de976a796836182dea294403922b2f5ec",
			tree = "f99c1c1df577816b4dbbb8bafc645630a94d21ad",
			rights = "MIT",
			surfaces = {
				{ root = "src", role = "verification" },
			},
		},
	},
}
