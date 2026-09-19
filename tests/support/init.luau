--!strict
local Compose = require "../src/core"
local TestHost = require "../src/test-host"

export type World = {
	host: TestHost.TestHost,
	runtime: Compose.Runtime,
	create: (kind: string) -> Compose.Constructor,
	root: Compose.Node,
	settle: () -> (),
	batch: <T...>(body: () -> T...) -> T...,
	pending: () -> number,
}

local function world(options: TestHost.Options?): World
	Compose.__resetForTests()
	local host = TestHost.create(options)
	local runtime = Compose.createRuntime(host.host)
	return {
		host = host,
		runtime = runtime,
		create = runtime.create,
		root = host.root,
		settle = function()
			runtime:settle()
		end,
		batch = function<T...>(body: () -> T...): T...
			return runtime:batch(body)
		end,
		pending = function(): number
			return runtime:pending()
		end,
	}
end

local function owned<T>(body: () -> T): (T, Compose.Owner)
	local owner = Compose.createOwner()
	local result = Compose.withOwner(owner, body)
	return result, owner
end

return {
	world = world,
	owned = owned,
}
