--!strict

return table.freeze {
	schemaVersion = 1,
	dependencies = {
		table.freeze {
			name = "verify",
			repository = "https://github.com/voidmeld/verify.git",
			commit = "71c61ad7378388e3f388dc694b69592467b29784",
			tree = "346ce71ae2e857cb53395849f982454ac5d103b7",
			rights = "MIT",
			surfaces = {
				{ root = "src", role = "verification" },
			},
		},
	},
}
