return {
	lute = {
		lint = {
			ignores = {
				"build/**",
				".lute/**",
			},
			globals = {},
			rulepaths = {
				"tools/lint-rules/global_table_usage.luau",
				"tools/lint-rules/type_check_inside_call.luau",
				"tools/lint-rules/bad_string_escape.luau",
			},
			ruleconfigs = {
				divide_by_zero = {
					ignores = {
						"tests/animation/timeline.verify.luau",
					},
				},
				global_function_in_scope = { off = true },
				unused_variable = { off = true },
				global_table_usage = {
					options = {
						allow = { "tests/tools/fixtures/global-table-allowed.luau" },
					},
				},
			},
		},
	},
}
