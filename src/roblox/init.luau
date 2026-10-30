--!strict

local Codecs = require "@self/codecs"
local Compose = require "./core"
local Engine = require "@self/engine"
local HostImpl = require "@self/host"
local RobloxTypes = require "@self/types"

export type Engine = Engine.Engine
export type Signal<A... = ...unknown> = Engine.Signal<A...>
export type Connection = Engine.Connection
export type Viewport = RobloxTypes.Viewport
export type ViewportOptions = RobloxTypes.ViewportOptions
export type PreferredInputClass = RobloxTypes.PreferredInputClass
export type PreferredInputSpec = RobloxTypes.PreferredInputSpec

local sharedHost: Compose.Host? = nil

local function createHost(engine: Engine.Engine?): Compose.Host
	if engine ~= nil then
		local host = HostImpl.createHost(engine)
		Codecs.register(engine)
		return host
	end

	local existing = sharedHost
	if existing ~= nil then
		return existing
	end
	local ambient = Engine.ambient()
	local host = HostImpl.createHost(ambient)
	Codecs.register(ambient)
	sharedHost = host
	return host
end

local function createRuntime(engine: Engine.Engine?): Compose.Runtime
	return Compose.createRuntime(createHost(engine))
end

local function designEnvironment(options: {
	values: typeof(Engine.designEnvironment(HostImpl.readMember).values),
	service: (string) -> unknown,
}?): typeof(Engine.designEnvironment(HostImpl.readMember))
	if options then
		return {
			values = options.values,
			service = options.service,
			descendants = Engine.descendants,
			invoke = function(object: unknown, method: string, ...: unknown): ...unknown
				return Engine.invoke(HostImpl.readMember, object, method, ...)
			end,
		}
	end
	return Engine.designEnvironment(HostImpl.readMember)
end

local function animatableTypes(engine: Engine.Engine?): { string }
	local resolved = if engine ~= nil then engine else Engine.ambient()
	local names = Codecs.register(resolved)
	table.sort(names)
	return names
end

local cleanupModule = require "@self/cleanup"

local viewportModule = require "@self/viewport"

local inputModule = require "@self/input"

local function cleanup(value: unknown): Compose.Dispose
	return cleanupModule.cleanup(value)
end

local function createCleanup(typeName: ((value: unknown) -> string)?): (value: unknown) -> Compose.Dispose
	return cleanupModule.createCleanup(typeName)
end

local function createViewport(
	camera: { ViewportSize: Engine.Vector2 },
	engine: Engine.Engine?,
	options: RobloxTypes.ViewportOptions?
): (Compose.ReadOnlyValue<RobloxTypes.Viewport>, Compose.ReadOnlyValue<boolean>)
	return viewportModule.createViewport(camera, engine, options)
end

local function usableViewportSize(size: Engine.Vector2?, minimum: number?): boolean
	return viewportModule.usableViewportSize(size, minimum)
end

local function preferredInput(
	inputService: { PreferredInput: unknown }?,
	engine: Engine.Engine?
): Compose.Value<RobloxTypes.PreferredInputClass>
	return inputModule.preferredInput(inputService, engine)
end

local function preferredInputSpec(value: unknown): RobloxTypes.PreferredInputSpec
	return inputModule.preferredInputSpec(value)
end

local function __resetForTests()
	sharedHost = nil
end

return {
	createHost = createHost,
	createRuntime = createRuntime,
	designEnvironment = designEnvironment,
	animatableTypes = animatableTypes,
	cleanup = cleanup,
	createCleanup = createCleanup,
	createViewport = createViewport,
	usableViewportSize = usableViewportSize,
	preferredInput = preferredInput,
	preferredInputSpec = preferredInputSpec,
	__resetForTests = __resetForTests,
}
