--!strict

export type Example = {
	name: string,
	what: string,
	expected: string,
	run: () -> string,
}

local all: { Example } = {
	require "@self/profiling",
	require "@self/lifetime",
	require "@self/accumulator",
	require "@self/arena",
	require "@self/collections",
	require "@self/composition-primitives",
	require "@self/mount-target",
	require "@self/attributes",
	require "@self/root-scope",
	require "@self/roblox-emulator",
}

return {
	all = all,
}
