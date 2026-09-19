--!strict

return table.freeze {
	schemaVersion = 1,
	dependencies = {
		table.freeze {
			name = "verify",
			repository = "https://github.com/voidmeld/verify.git",
			commit = "f0e3bda5dbaf1e7b831e451ea70710b4f3b6131f",
			tree = "0955116bb662048de92b3c2437c5e49e60345c37",
			rights = "MIT",
			surfaces = {
				{ root = "src", role = "verification" },
			},
		},
	},
}
