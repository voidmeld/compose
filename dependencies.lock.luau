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
			commit = "c3b4706b9d98b1e4287019e79554f42d22bc7d55",
			tree = "b116afd83b09c859211ee2e938e052372857f15a",
			rights = "MIT",
			surfaces = {
				{ root = "src", role = "verification" },
			},
		},
	},
}
