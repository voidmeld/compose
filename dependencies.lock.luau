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
			commit = "5d2b41e3d00f0e84bd20bc7910f239e54aec8337",
			tree = "f8cdace0801028125a21c455568629484bb6951b",
			rights = "MIT",
			surfaces = {
				{ root = "src", role = "verification" },
			},
		},
	},
}
