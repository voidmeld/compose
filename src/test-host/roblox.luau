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
	node: any,
	className: string,
	key: string?,
	value: unknown?,
	parent: any?,
}

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, handler: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
}

export type ClassSpec = {

	super: string?,

	creatable: boolean?,
	properties: { [string]: any }?,
	events: { string }?,
	methods: { [string]: (self: any, ...any) -> ...any }?,
}

export type Emulator = {
	engine: ComposeRoblox.Engine,
	host: Compose.Host,
	render: Compose.Renderer,
	root: any,

	createInstance: (className: string, props: { [any]: any }?) -> any,
	defineClass: (className: string, spec: ClassSpec) -> (),
	newSignal: () -> Signal,

	step: (delta: number) -> (),
	now: () -> number,

	childrenOf: (object: any) -> { any },
	parentOf: (object: any) -> any,
	propertyOf: (object: any, key: string) -> any,
	attributeOf: (object: any, name: string) -> any,
	isAlive: (object: any) -> boolean,
	liveObjects: () -> number,
	liveConnections: () -> number,
	serialize: (object: any) -> string,

	log: () -> { LogEntry },
	clearLog: () -> (),

	poke: (object: any, key: string, value: any) -> (),
	fire: (object: any, event: string, ...any) -> (),

	failNext: (operation: Operation, times: number?) -> (),
	clearFailures: () -> (),
}

type Handler = (...any) -> ()

type Class = {
	creatable: boolean,
	super: string?,
	properties: { [string]: any },
	events: { [string]: true },
	methods: { [string]: any },
}

local ATTRIBUTE_TYPES: { [string]: true } = {
	string = true,
	number = true,
	boolean = true,
	["nil"] = true,
}

local BUILTIN_CLASSES: { { name: string, spec: ClassSpec } } = {
	{ name = "Instance", spec = { creatable = false, properties = { Name = "Instance" } } },
	{ name = "Folder", spec = { super = "Instance", properties = { Name = "Folder" } } },
	{ name = "Model", spec = { super = "Instance", properties = { Name = "Model" } } },
	{ name = "Configuration", spec = { super = "Instance", properties = { Name = "Configuration" } } },
	{
		name = "BasePart",
		spec = {
			super = "Instance",
			creatable = false,
			properties = { Name = "BasePart", Transparency = 0, Anchored = false, CanCollide = true },
			events = { "Touched", "TouchEnded" },
		},
	},
	{ name = "Part", spec = { super = "BasePart", properties = { Name = "Part" } } },
	{ name = "MeshPart", spec = { super = "BasePart", properties = { Name = "MeshPart" } } },
	{
		name = "GuiObject",
		spec = {
			super = "Instance",
			creatable = false,
			properties = {
				Name = "GuiObject",
				Visible = true,
				BackgroundTransparency = 0,
				LayoutOrder = 0,
				ZIndex = 1,
			},
			events = { "InputBegan", "InputEnded", "MouseEnter", "MouseLeave" },
		},
	},
	{ name = "Frame", spec = { super = "GuiObject", properties = { Name = "Frame" } } },
	{ name = "TextLabel", spec = { super = "GuiObject", properties = { Name = "TextLabel", Text = "" } } },
	{
		name = "TextButton",
		spec = {
			super = "GuiObject",
			properties = { Name = "TextButton", Text = "" },
			events = { "Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up" },
		},
	},
	{ name = "ImageLabel", spec = { super = "GuiObject", properties = { Name = "ImageLabel", Image = "" } } },
	{
		name = "ImageButton",
		spec = {
			super = "GuiObject",
			properties = { Name = "ImageButton", Image = "" },
			events = { "Activated", "MouseButton1Click" },
		},
	},
	{ name = "ScreenGui", spec = { super = "Instance", properties = { Name = "ScreenGui", Enabled = true } } },
	{
		name = "Humanoid",
		spec = { super = "Instance", properties = { Name = "Humanoid", Health = 100, MaxHealth = 100 } },
	},
	{ name = "Animation", spec = { super = "Instance", properties = { Name = "Animation", AnimationId = "" } } },
}

local function createEmulator(): Emulator
	local classes: { [string]: Class } = {}
	local live: { [any]: true } = {}
	local liveCount = 0
	local connectionCount = 0
	local log: { LogEntry } = {}
	local failures: { [string]: number } = {}

	local function makeSignal(): any
		local handlers: { Handler } = {}
		local signal: any = {}

		function signal:Connect(handler: Handler): any
			table.insert(handlers, handler)
			connectionCount += 1
			local connection: any = { Connected = true }
			function connection:Disconnect()
				if not connection.Connected then
					return
				end
				connection.Connected = false
				connectionCount -= 1
				for index, candidate in handlers do
					if candidate == handler then
						table.remove(handlers, index)
						break
					end
				end
			end
			return connection
		end

		function signal:Fire(...: any)
			for _, handler in table.clone(handlers) do
				handler(...)
			end
		end

		return signal
	end

	local function defineClass(className: string, spec: ClassSpec)
		if type(className) ~= "string" or className == "" then
			error("RobloxEmulator.defineClass: a class name must be a non-empty string", 0)
		end

		local properties: { [string]: any } = {}
		local events: { [string]: true } = {}
		local methods: { [string]: any } = {}

		local superName = spec.super
		if superName ~= nil then
			local parent = classes[superName]
			if parent == nil then
				error(
					("RobloxEmulator.defineClass: %s inherits from %s, which is not defined yet"):format(
						className,
						superName
					),
					0
				)
			end
			properties = table.clone(parent.properties)
			events = table.clone(parent.events)
			methods = table.clone(parent.methods)
		end

		if spec.properties ~= nil then
			for key, value in spec.properties do
				properties[key] = value
			end
		end
		if spec.events ~= nil then
			for _, event in spec.events do
				events[event] = true
			end
		end
		if spec.methods ~= nil then
			for name, implementation in spec.methods do
				methods[name] = implementation
			end
		end
		properties.Name = if spec.properties ~= nil and spec.properties.Name ~= nil
			then spec.properties.Name
			else className

		classes[className] = {
			creatable = spec.creatable ~= false,
			super = superName,
			properties = properties,
			events = events,
			methods = methods,
		}
	end

	for _, entry in BUILTIN_CLASSES do
		defineClass(entry.name, entry.spec)
	end

	local instanceMetatable: any

	local function stateOf(object: any): any
		return rawget(object, "__state")
	end

	local function classNameOf(object: any): string
		local state = stateOf(object)
		return if state ~= nil then state.className else "<not an emulated Instance>"
	end

	local function construct(className: string): any
		local class = classes[className]
		if class == nil then
			error(("RobloxEmulator: Unable to create an Instance of type %q"):format(tostring(className)), 0)
		end

		local state = {
			className = className,
			class = class,
			properties = table.clone(class.properties),
			children = {} :: { any },
			parent = nil :: any,
			attributes = {} :: { [string]: any },
			events = {} :: { [string]: any },
			changed = {} :: { [string]: any },
			attributeChanged = {} :: { [string]: any },
			destroyed = false,
		}

		local object: any = setmetatable({}, instanceMetatable)
		rawset(object, "__state", state)
		live[object] = true
		liveCount += 1
		return object
	end

	local function newInstance(className: string): any
		local class = classes[className]
		if class == nil or not class.creatable then
			error(("RobloxEmulator: Unable to create an Instance of type %q"):format(tostring(className)), 0)
		end
		return construct(className)
	end

	local function eventOf(state: any, key: string): any?
		local existing = state.events[key]
		if existing ~= nil then
			return existing
		end
		if not state.class.events[key] then
			return nil
		end
		local created = makeSignal()
		state.events[key] = created
		return created
	end

	local function detach(object: any)
		local state = stateOf(object)
		local parent = state.parent
		if parent == nil then
			return
		end
		local parentState = stateOf(parent)
		for index, candidate in parentState.children do
			if candidate == object then
				table.remove(parentState.children, index)
				break
			end
		end
		state.parent = nil
		local removed = parentState.events.ChildRemoved
		if removed ~= nil then
			removed:Fire(object)
		end
	end

	local destroyInstance: (object: any) -> ()
	function destroyInstance(object: any)
		local state = stateOf(object)
		if state.destroyed then
			return
		end
		state.destroyed = true
		local destroying = state.events.Destroying
		if destroying ~= nil then
			destroying:Fire()
		end
		detach(object)
		for _, child in table.clone(state.children) do
			destroyInstance(child)
		end
		state.children = {}
		if live[object] then
			live[object] = nil
			liveCount -= 1
		end
	end

	local function fireChanged(state: any, key: string)
		local signal = state.changed[key]
		if signal ~= nil then
			signal:Fire()
		end
	end

	local BUILTIN: { [string]: any }
	BUILTIN = {
		Destroy = destroyInstance,

		GetChildren = function(self: any): { any }
			return table.clone(stateOf(self).children)
		end,

		GetDescendants = function(self: any): { any }
			local found: { any } = {}
			local function walk(current: any)
				for _, child in stateOf(current).children do
					table.insert(found, child)
					walk(child)
				end
			end
			walk(self)
			return found
		end,

		FindFirstChild = function(self: any, name: string, recursive: boolean?): any?
			for _, child in stateOf(self).children do
				if stateOf(child).properties.Name == name then
					return child
				end
			end
			if recursive ~= true then
				return nil
			end
			for _, child in stateOf(self).children do
				local found = BUILTIN.FindFirstChild(child, name, true)
				if found ~= nil then
					return found
				end
			end
			return nil
		end,

		FindFirstChildOfClass = function(self: any, className: string): any?
			for _, child in stateOf(self).children do
				if stateOf(child).className == className then
					return child
				end
			end
			return nil
		end,

		IsA = function(self: any, className: string): boolean
			local current: string? = stateOf(self).className
			while current ~= nil do
				if current == className then
					return true
				end
				local class = classes[current]
				current = if class ~= nil then class.super else nil
			end
			return false
		end,

		IsDescendantOf = function(self: any, ancestor: any): boolean
			local current = stateOf(self).parent
			while current ~= nil do
				if current == ancestor then
					return true
				end
				current = stateOf(current).parent
			end
			return false
		end,

		IsAncestorOf = function(self: any, descendant: any): boolean
			return BUILTIN.IsDescendantOf(descendant, self)
		end,

		SetAttribute = function(self: any, name: string, value: any)
			if type(name) ~= "string" or name == "" then
				error("RobloxEmulator: Attribute name must be a non-empty string", 0)
			end
			if not ATTRIBUTE_TYPES[typeof(value)] then
				error(("RobloxEmulator: Attribute %q cannot hold a value of type %s"):format(name, typeof(value)), 0)
			end
			local state = stateOf(self)
			local previous = state.attributes[name]
			state.attributes[name] = value
			if previous ~= value then
				local signal = state.attributeChanged[name]
				if signal ~= nil then
					signal:Fire()
				end
			end
		end,

		GetAttribute = function(self: any, name: string): any
			return stateOf(self).attributes[name]
		end,

		GetAttributes = function(self: any): { [string]: any }
			return table.clone(stateOf(self).attributes)
		end,

		GetAttributeChangedSignal = function(self: any, name: string): any
			local state = stateOf(self)
			local existing = state.attributeChanged[name]
			if existing == nil then
				existing = makeSignal()
				state.attributeChanged[name] = existing
			end
			return existing
		end,

		GetPropertyChangedSignal = function(self: any, property: string): any
			local state = stateOf(self)
			local existing = state.changed[property]
			if existing == nil then
				existing = makeSignal()
				state.changed[property] = existing
			end
			return existing
		end,
	}

	local BUILTIN_EVENTS: { [string]: true } = {
		ChildAdded = true,
		ChildRemoved = true,
		Destroying = true,
	}

	instanceMetatable = {
		__index = function(object: any, key: string): any
			local state = stateOf(object)
			if key == "ClassName" then
				return state.className
			elseif key == "Parent" then
				return state.parent
			end

			local builtin = BUILTIN[key]
			if builtin ~= nil then
				return builtin
			end

			local method = state.class.methods[key]
			if method ~= nil then
				return method
			end

			if BUILTIN_EVENTS[key] then
				local existing = state.events[key]
				if existing == nil then
					existing = makeSignal()
					state.events[key] = existing
				end
				return existing
			end

			local event = eventOf(state, key)
			if event ~= nil then
				return event
			end
			return state.properties[key]
		end,

		__newindex = function(object: any, key: string, value: any)
			local state = stateOf(object)
			if state.destroyed then
				error("RobloxEmulator: cannot write to a destroyed Instance", 0)
			end
			if key == "Parent" then
				detach(object)
				state.parent = value
				if value ~= nil then
					local parentState = stateOf(value)
					if parentState == nil then
						error("RobloxEmulator: Parent must be an emulated Instance or nil", 0)
					end
					table.insert(parentState.children, object)
					local added = parentState.events.ChildAdded
					if added ~= nil then
						added:Fire(object)
					end
				end
				return
			end
			if state.class.events[key] or BUILTIN_EVENTS[key] then
				error(("RobloxEmulator: %s.%s is an event and cannot be assigned"):format(state.className, key), 0)
			end
			local previous = state.properties[key]
			state.properties[key] = value
			if previous ~= value then
				fireChanged(state, key)
			end
		end,

		__tostring = function(object: any): string
			return stateOf(object).properties.Name
		end,
	}

	local function datatype(name: string, fields: { [string]: any }): any
		fields.__datatype = name
		return setmetatable(fields, {
			__index = fields,
			__eq = function(left: any, right: any): boolean
				for key, value in left do
					if key ~= "__datatype" and right[key] ~= value then
						return false
					end
				end
				return true
			end,
			__tostring = function(): string
				return name
			end,
		})
	end

	local function Vector2(x: number, y: number): any
		return datatype("Vector2", { X = x, Y = y })
	end
	local function Vector3(x: number, y: number, z: number): any
		return datatype("Vector3", { X = x, Y = y, Z = z })
	end
	local function Color3(r: number, g: number, b: number): any
		return datatype("Color3", { R = r, G = g, B = b })
	end
	local function UDim(scale: number, offset: number): any
		return datatype("UDim", { Scale = scale, Offset = offset })
	end
	local function UDim2(xs: number, xo: number, ys: number, yo: number): any
		return datatype("UDim2", { X = UDim(xs, xo), Y = UDim(ys, yo) })
	end
	local function CFrame(position: any, rotation: { number }): any
		return datatype("CFrame", { Position = position, Rotation = table.clone(rotation) })
	end

	local function typeName(value: any): string
		local kind = typeof(value)
		if kind ~= "table" then
			return kind
		end
		local tagged = rawget(value, "__datatype")
		if tagged ~= nil then
			return tagged :: string
		end
		if rawget(value, "__state") ~= nil then
			return "Instance"
		end
		return "table"
	end

	local heartbeat = makeSignal()
	local clock = 0

	local engine: ComposeRoblox.Engine = {
		new = newInstance,
		heartbeat = heartbeat,
		clock = function(): number
			return clock
		end,
		typeName = typeName,
		destroy = destroyInstance,
		propertyChanged = function(object: any, property: string): any
			return object:GetPropertyChangedSignal(property)
		end,
		datatypes = {
			Vector2 = Vector2,
			Vector3 = Vector3,
			Color3 = Color3,
			UDim = UDim,
			UDim2 = UDim2,
			CFrame = CFrame,
		},
		readCFrame = function(value: any): (number, number, number, { number })
			return value.Position.X, value.Position.Y, value.Position.Z, table.clone(value.Rotation)
		end,
	}

	defineClass("AnimationTrack", {
		super = "Instance",

		creatable = false,
		properties = {
			Name = "AnimationTrack",
			IsPlaying = false,
			Looped = false,
			Priority = "Action",
			Speed = 1,
			TimePosition = 0,
			Length = 0,
		},
		events = { "Stopped", "Ended" },
		methods = {
			Play = function(self: any, _fadeTime: number?, _weight: number?, speed: number?)
				self.IsPlaying = true
				if speed ~= nil then
					self.Speed = speed
				end
			end,
			Stop = function(self: any, _fadeTime: number?)
				if not self.IsPlaying then
					return
				end
				self.IsPlaying = false
				local stopped = stateOf(self).events.Stopped
				if stopped ~= nil then
					stopped:Fire()
				end
			end,
			AdjustSpeed = function(self: any, speed: number)
				self.Speed = speed
			end,
		},
	})

	defineClass("Animator", {
		super = "Instance",
		properties = { Name = "Animator" },
		methods = {
			LoadAnimation = function(_self: any, animation: any): any
				local track = construct "AnimationTrack"
				track.Animation = animation
				return track
			end,
		},
	})

	local function checkFailure(operation: Operation)
		local remaining = failures[operation]
		if remaining == nil or remaining <= 0 then
			return
		end
		failures[operation] = remaining - 1
		error(("RobloxEmulator: injected failure in %s"):format(operation), 0)
	end

	local function record(operation: Operation, node: any, key: string?, value: unknown?, parent: any?)
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

	local function serialize(object: any): string
		local lines: { string } = {}
		local function walk(current: any, depth: number)
			local state = stateOf(current)
			local keys: { string } = {}
			for key in state.properties do
				table.insert(keys, key)
			end
			table.sort(keys)
			local rendered: { string } = {}
			for _, key in keys do
				local value = state.properties[key]
				local shown = if type(value) == "string" then ("%q"):format(value) else tostring(value)
				table.insert(rendered, ("%s=%s"):format(key, shown))
			end
			table.insert(
				lines,
				("%s%s { %s }"):format(string.rep("  ", depth), state.className, table.concat(rendered, ", "))
			)
			for _, child in state.children do
				walk(child, depth + 1)
			end
		end
		walk(object, 0)
		return table.concat(lines, "\n")
	end

	local function createInstance(className: string, props: { [any]: any }?): any
		local object = newInstance(className)
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

		for _, child in ipairs(props) do
			child.Parent = object
		end

		local parent = props.Parent
		if parent ~= nil then
			object.Parent = parent
		end
		return object
	end

	local root = newInstance "Folder"
	root.Name = "Root"

	return {
		engine = engine,
		host = host,
		render = render,
		root = root,

		createInstance = createInstance,
		defineClass = defineClass,
		newSignal = function(): Signal
			return makeSignal() :: Signal
		end,

		step = function(delta: number)
			clock += delta
			heartbeat:Fire(delta)
		end,
		now = function(): number
			return clock
		end,

		childrenOf = function(object: any): { any }
			return table.clone(stateOf(object).children)
		end,
		parentOf = function(object: any): any
			return stateOf(object).parent
		end,
		propertyOf = function(object: any, key: string): any
			return stateOf(object).properties[key]
		end,
		attributeOf = function(object: any, name: string): any
			return stateOf(object).attributes[name]
		end,
		isAlive = function(object: any): boolean
			return live[object] == true
		end,
		liveObjects = function(): number
			return liveCount
		end,
		liveConnections = function(): number
			return connectionCount
		end,
		serialize = serialize,

		log = function(): { LogEntry }
			return table.clone(log)
		end,
		clearLog = function()
			table.clear(log)
		end,

		poke = function(object: any, key: string, value: any)
			local state = stateOf(object)
			local previous = state.properties[key]
			state.properties[key] = value
			if previous ~= value then
				fireChanged(state, key)
			end
		end,
		fire = function(object: any, event: string, ...: any)
			local state = stateOf(object)
			local signal = if BUILTIN_EVENTS[event] then object[event] else eventOf(state, event)
			if signal == nil then
				error(("RobloxEmulator: %s has no event %q"):format(state.className, event), 0)
			end
			signal:Fire(...)
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
	create = createEmulator,
}
