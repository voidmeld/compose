--!strict

return table.freeze {
	schemaVersion = 1,
	dependencies = {
		table.freeze {
			name = "verify",
			repository = "https://github.com/voidmeld/verify.git",
			commit = "823238830d32513704281049258c931ac169e29e",
			tree = "387788719d806f55b7f989ab688f1978ea5be9d6",
			rights = "MIT",
			surfaces = {
				{ root = "src", role = "verification" },
			},
		},
	},
}
