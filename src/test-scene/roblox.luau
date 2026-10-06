--!strict

local Compose = require "../core"
local ComposeRoblox = require "../roblox"

export type Operation =
	"createNode"
	| "setProperty"
	| "setAttribute"
	| "clearProperty"
	| "insertChild"
	| "removeChild"
	| "destroyNode"
	| "setName"

export type LogEntry = {
	operation: Operation,
	node: Compose.Node,
	className: string,
	key: string?,
	value: unknown?,
	parent: Compose.Node?,
}

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<A... = ...unknown> = {
	Connect: (self: Signal<A...>, handler: (A...) -> ()) -> Connection,
	Fire: (self: Signal<A...>, A...) -> (),
	DisconnectAll: (self: Signal<A...>) -> (),
}

export type Method<A... = ...unknown, R... = ...unknown> = (A...) -> R...
export type Instance = {
	[string]: unknown,
	ClassName: string,
	Name: unknown,
	Parent: Instance?,
	Destroy: (Instance) -> (),
	Clone: (Instance) -> Instance?,
	AddTag: (Instance, string) -> (),
	RemoveTag: (Instance, string) -> (),
	HasTag: (Instance, string) -> boolean,
	GetTags: (Instance) -> { string },
	ClearAllChildren: (Instance) -> (),
	GetChildren: (Instance) -> { Instance },
	GetDescendants: (Instance) -> { Instance },
	FindFirstChild: (Instance, string, boolean?) -> Instance?,
	FindFirstChildOfClass: (Instance, string) -> Instance?,
	FindFirstChildWhichIsA: (Instance, string, boolean?) -> Instance?,
	FindFirstAncestor: (Instance, string) -> Instance?,
	FindFirstAncestorOfClass: (Instance, string) -> Instance?,
	FindFirstAncestorWhichIsA: (Instance, string) -> Instance?,
	GetFullName: (Instance) -> string,
	IsA: (Instance, string) -> boolean,
	IsDescendantOf: (Instance, Instance) -> boolean,
	IsAncestorOf: (Instance, Instance) -> boolean,
	SetAttribute: (Instance, string, unknown) -> (),
	GetAttribute: (Instance, string) -> unknown,
	GetAttributes: (Instance) -> { [string]: unknown },
	GetPropertyChangedSignal: (Instance, string) -> Signal<()>,
	GetAttributeChangedSignal: (Instance, string) -> Signal<()>,
	ResetPropertyToDefault: (Instance, string) -> (),
	Changed: Signal<string>,
	ChildAdded: Signal<Instance>,
	ChildRemoved: Signal<Instance>,
	DescendantAdded: Signal<Instance>,
	DescendantRemoving: Signal<Instance>,
	AncestryChanged: Signal<Instance, Instance?>,
	Destroying: Signal<()>,
	AttributeChanged: Signal<string>,
}
export type ClassSpec<P = { [string]: unknown }, M = { [string]: unknown }> = {
	super: string?,
	creatable: boolean?,
	properties: P?,
	events: { string }?,
	methods: M?,
}

export type DefineOptions = {
	replace: boolean?,
}

export type Environment = {
	root: Instance,
	heartbeat: Signal<number>,
	step: (seconds: number) -> (),
	now: () -> number,
	createInstance: (className: string, props: { [unknown]: unknown }?) -> Instance,
	defineClass: <P, M>(className: string, spec: ClassSpec<P, M>, options: DefineOptions?) -> (),
	newSignal: <A...>() -> Signal<A...>,
	fire: (object: Instance, event: string, ...unknown) -> (),
	poke: (object: Instance, key: string, value: unknown) -> (),
	childrenOf: (object: Instance) -> { Instance },
	parentOf: (object: Instance) -> Instance?,
	propertyOf: (object: Instance, key: string) -> unknown,
	attributeOf: (object: Instance, name: string) -> unknown,
	isAlive: (object: Instance) -> boolean,
	liveObjects: () -> number,
	liveConnections: () -> number,
}

export type Emulator = {
	engine: ComposeRoblox.Engine,
	adapter: Compose.Host,
	render: Compose.Renderer,
	environment: Environment,
	root: Instance,

	createInstance: (className: string, props: { [unknown]: unknown }?) -> Instance,

	log: () -> { LogEntry },
	clearLog: () -> (),

	failNext: (operation: Operation, times: number?) -> (),
	clearFailures: () -> (),
}

local function create(environment: Environment, engine: ComposeRoblox.Engine): Emulator
	local failures: { [string]: number } = {}
	local log: { LogEntry } = {}

	local function classNameOf(node: Compose.Node): string
		return (node :: Instance).ClassName
	end

	local function checkFailure(operation: Operation)
		local remaining = failures[operation]
		if remaining == nil or remaining <= 0 then
			return
		end
		failures[operation] = remaining - 1
		error(("RobloxEmulator: injected failure in %s"):format(operation), 0)
	end

	local function record(
		operation: Operation,
		node: Compose.Node,
		key: string?,
		value: unknown?,
		parent: Compose.Node?
	)
		table.insert(log, {
			operation = operation,
			node = node,
			className = classNameOf(node),
			key = key,
			value = value,
			parent = parent,
		})
	end

	local adapter = ComposeRoblox.createHost(engine)
	local adapterRender = adapter.render
	local adapterNaming = adapter.naming

	local render: Compose.Renderer = {
		createNode = function(kind: string): Compose.Node
			checkFailure "createNode"
			local node = adapterRender.createNode(kind)
			record("createNode", node)
			return node
		end,
		setProperty = function(node: Compose.Node, key: string, value: unknown)
			checkFailure "setProperty"
			adapterRender.setProperty(node, key, value)
			record("setProperty", node, key, value)
		end,
		setAttribute = function(node: Compose.Node, name: string, value: unknown): (boolean, string?)
			local injected = failures.setAttribute
			if injected ~= nil and injected > 0 then
				failures.setAttribute = injected - 1
				return false, "RobloxEmulator: injected refusal in setAttribute"
			end
			local write = adapterRender.setAttribute
			if write == nil then
				return false, "RobloxEmulator: the adapter declares no attribute store"
			end
			local ok, reason = write(node, name, value)
			record("setAttribute", node, name, value)
			return ok, reason
		end,
		clearProperty = function(node: Compose.Node, key: string)
			checkFailure "clearProperty"
			adapterRender.clearProperty(node, key)
			record("clearProperty", node, key)
		end,
		insertChild = function(parent: Compose.Node, child: Compose.Node, position: number?)
			checkFailure "insertChild"
			adapterRender.insertChild(parent, child, position)
			record("insertChild", child, nil, position, parent)
		end,

		moveChild = nil,
		removeChild = function(parent: Compose.Node, child: Compose.Node)
			checkFailure "removeChild"
			adapterRender.removeChild(parent, child)
			record("removeChild", child, nil, nil, parent)
		end,
		destroyNode = function(node: Compose.Node)
			checkFailure "destroyNode"
			record("destroyNode", node)
			adapterRender.destroyNode(node)
		end,
	}

	local naming: Compose.Naming? = if adapterNaming == nil
		then nil
		else {
			setName = function(node: Compose.Node, label: string)
				local write = (adapterNaming :: Compose.Naming).setName
				checkFailure "setName"
				write(node, label)
				record("setName", node, "Name", label)
			end,
		}

	local host: Compose.Host = {
		name = adapter.name,
		render = render,
		events = adapter.events,
		observation = adapter.observation,
		frames = adapter.frames,
		naming = naming,
		describeNode = adapter.describeNode,
		typeNameOf = adapter.typeNameOf,
	}

	local function createInstance(className: string, props: { [unknown]: unknown }?): Instance
		local object = environment.createInstance(className)
		if props == nil then
			return object
		end
		local keys: { string } = {}
		for key in props do
			if type(key) == "string" and key ~= "Parent" then
				table.insert(keys, key)
			end
		end
		table.sort(keys)
		for _, key in keys do
			object[key] = props[key]
		end
		for _, child in ipairs(props :: { unknown }) do
			(child :: Instance).Parent = object
		end
		if props.Parent ~= nil then
			object.Parent = props.Parent :: Instance
		end
		return object
	end

	return {
		engine = engine,
		adapter = host,
		render = render,
		environment = environment,
		root = environment.root,

		createInstance = createInstance,

		log = function(): { LogEntry }
			return table.clone(log)
		end,
		clearLog = function()
			table.clear(log)
		end,

		failNext = function(operation: Operation, times: number?)
			failures[operation] = (failures[operation] or 0) + (if times ~= nil then times else 1)
		end,
		clearFailures = function()
			table.clear(failures)
		end,
	}
end

return {
	create = create,
}
