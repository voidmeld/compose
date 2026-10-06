--!strict
local Compose = require "../src/core"
local RobloxEmulator = require "../src/test-scene/roblox"
local TestScene = require "../src/test-scene"
local VerifyRoblox = require "../.lute/dependencies/verify/src/roblox"

export type World = {
	host: TestScene.TestScene,
	runtime: Compose.Runtime,
	create: (kind: string) -> Compose.Constructor,
	root: Compose.Node,
	settle: () -> (),
	batch: <T...>(body: () -> T...) -> T...,
	pending: () -> number,
}

local function world(options: TestScene.Options?): World
	Compose.__resetForTests()
	local host = TestScene.create(options)
	local runtime = Compose.createRuntime(host.adapter)
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

local function emulator(options: VerifyRoblox.EnvironmentOptions?): RobloxEmulator.Emulator
	local environment = VerifyRoblox.testEnvironment(options)
	return RobloxEmulator.create(environment, VerifyRoblox.environmentEngine(environment))
end

return {
	emulator = emulator,
	world = world,
	owned = owned,
}
