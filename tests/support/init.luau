--!strict
local Compose = require "../src/core"
local RobloxEmulator = require "../src/test-scene/roblox"
local TestScene = require "../src/test-scene"
local VerifyRoblox = require "../.lute/dependencies/verify/src/roblox"
local Records = require "../tools/lib/records"
local ReactiveNodes = require "../src/core/reactive/node"
local Dynamic = require "../src/core/dynamic"

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

local function node(value: unknown): Compose.Node
	assert(type(value) == "table" or type(value) == "userdata")
	return value
end

local function instance(value: unknown): RobloxEmulator.Instance
	return VerifyRoblox.assertInstance(value)
end

local function weakValues<K, V>(values: { [K]: V })
	setmetatable(values, { __mode = "v" })
end

local function record(value: unknown): { [unknown]: unknown }
	local fields = Records.read(ReactiveNodes.asNode(value) or value)
	assert(fields ~= nil)
	return fields
end

local function fieldCount(value: { [unknown]: unknown }): number
	local count = 0
	for _ in value do
		count += 1
	end
	return count
end

local function required<T>(value: T?): T
	assert(value ~= nil)
	return value
end

local function invokeMethod(object: unknown, name: string, ...: unknown): ...unknown
	return Dynamic.invoke(Dynamic.read(object, name), object, ...)
end

local function orderedStatus(): Compose.Value<Compose.OrderedCollectionStatus>
	return Compose.cell<<Compose.OrderedCollectionStatus>> {
		mode = "all",
		direction = "vertical",
		total = 0,
		retained = 0,
		first = 0,
		last = 0,
		firstRow = 0,
		lastRow = 0,
		rowCount = 0,
		extent = 0,
		following = false,
		measured = 0,
	}
end

local function spatialStatus(): Compose.Value<Compose.SpatialCollectionStatus>
	return Compose.cell<<Compose.SpatialCollectionStatus>> {
		total = 0,
		retained = 0,
		queried = 0,
		pending = 0,
		perTier = {},
		cells = 0,
	}
end

return {
	read = Dynamic.read,
	invoke = Dynamic.invoke,
	invokeMethod = invokeMethod,
	datatypes = VerifyRoblox.datatypes,
	required = required,
	weakValues = weakValues,
	record = record,
	fieldCount = fieldCount,
	node = node,
	instance = instance,
	emulator = emulator,
	world = world,
	owned = owned,
	orderedStatus = orderedStatus,
	spatialStatus = spatialStatus,
}
