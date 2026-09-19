--!strict

export type Counters = {
	instancesCreated: number,
	instancesDestroyed: number,
	propertyWrites: number,
	propertyReads: number,
	parentChanges: number,
	connectionsMade: number,
	connectionsBroken: number,
	eventsFired: number,
	tasksDeferred: number,
}

export type Environment = {
	globals: { [string]: any },
	container: () -> any,
	step: (delta: number) -> (),
	drain: () -> (),
	counters: () -> Counters,
	resetCounters: () -> (),
	liveInstances: () -> number,
	liveConnections: () -> number,
	snapshot: (object: any, keys: { string }?, sortBy: string?) -> string,
	fire: (object: any, event: string, ...any) -> (),
	diagnostics: () -> { string },
	get: (object: any, key: string) -> any,
	children: (object: any) -> { any },
}

local function zeroCounters(): Counters
	return {
		instancesCreated = 0,
		instancesDestroyed = 0,
		propertyWrites = 0,
		propertyReads = 0,
		parentChanges = 0,
		connectionsMade = 0,
		connectionsBroken = 0,
		eventsFired = 0,
		tasksDeferred = 0,
	}
end

local CLASS_PROPERTIES: { [string]: { [string]: any } } = {
	Folder = { Name = "Folder" },
	Frame = {
		Name = "Frame",
		Visible = true,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		ZIndex = 1,
		Active = false,
		ClipsDescendants = false,
	},
	TextLabel = {
		Name = "TextLabel",
		Text = "",
		Visible = true,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		ZIndex = 1,
		TextTransparency = 0,
		RichText = false,
	},
	TextButton = {
		Name = "TextButton",
		Text = "",
		Visible = true,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		ZIndex = 1,
		AutoButtonColor = true,
	},
	ImageLabel = {
		Name = "ImageLabel",
		Image = "",
		Visible = true,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		ZIndex = 1,
	},
	ScreenGui = { Name = "ScreenGui", Enabled = true, ResetOnSpawn = true, DisplayOrder = 0 },
	BillboardGui = {
		Name = "BillboardGui",
		Enabled = true,
		AlwaysOnTop = false,
		LightInfluence = 0,
		MaxDistance = math.huge,
		ResetOnSpawn = true,
	},
	UIListLayout = { Name = "UIListLayout", Padding = 0 },
	Part = { Name = "Part", Transparency = 0, Anchored = false, CanCollide = true, Position = 0 },
	MeshPart = { Name = "MeshPart", Transparency = 0, Anchored = false, CanCollide = true, Position = 0 },
	Attachment = { Name = "Attachment", Visible = false, Position = 0 },
	Highlight = { Name = "Highlight", Enabled = true, FillTransparency = 0, OutlineTransparency = 0 },
	ParticleEmitter = { Name = "ParticleEmitter", Enabled = false, Rate = 0, Lifetime = 1 },
	Model = { Name = "Model", Transparency = 0 },
	Configuration = { Name = "Configuration" },
}

local CLASS_EVENTS: { [string]: { string } } = {
	Folder = { "ChildAdded", "ChildRemoved" },
	Frame = { "InputBegan", "InputEnded", "MouseEnter", "MouseLeave", "ChildAdded", "ChildRemoved" },
	TextLabel = { "InputBegan", "ChildAdded", "ChildRemoved" },
	TextButton = { "Activated", "MouseButton1Click", "InputBegan", "ChildAdded", "ChildRemoved" },
	ImageLabel = { "InputBegan", "ChildAdded", "ChildRemoved" },
	ScreenGui = { "ChildAdded", "ChildRemoved" },
	BillboardGui = { "ChildAdded", "ChildRemoved" },
	UIListLayout = {},
	Part = { "Touched", "TouchEnded", "ChildAdded", "ChildRemoved" },
	MeshPart = { "Touched", "TouchEnded", "ChildAdded", "ChildRemoved" },
	Attachment = { "ChildAdded", "ChildRemoved" },
	Highlight = { "ChildAdded", "ChildRemoved" },
	ParticleEmitter = { "ChildAdded", "ChildRemoved" },
	Model = { "ChildAdded", "ChildRemoved" },
	Configuration = { "ChildAdded", "ChildRemoved" },
}

type Handler = (...any) -> ()

local function create(): Environment
	local counters = zeroCounters()
	local liveInstanceCount = 0
	local liveConnectionCount = 0
	type Deferred = { fn: Handler, arguments: { n: number, [number]: any } }
	type Delayed = { at: number, fn: Handler, arguments: { n: number, [number]: any } }
	local deferred: { Deferred } = {}
	local delayed: { Delayed } = {}
	local clock = 0
	local clockReads = 0

	local function makeSignal(): any
		local handlers: { Handler } = {}
		local connections: { any } = {}
		local signal: any = { __datatype = "RBXScriptSignal" }

		local function release(connection: any)
			if not connection.Connected then
				return
			end
			connection.Connected = false
			counters.connectionsBroken += 1
			liveConnectionCount -= 1
			for index, candidate in handlers do
				if candidate == connection.__handler then
					table.remove(handlers, index)
					break
				end
			end
			for index, candidate in connections do
				if candidate == connection then
					table.remove(connections, index)
					break
				end
			end
		end

		function signal:Connect(handler: Handler): any
			table.insert(handlers, handler)
			counters.connectionsMade += 1
			liveConnectionCount += 1
			local connection: any = { Connected = true, __handler = handler, __datatype = "RBXScriptConnection" }
			function connection:Disconnect()
				release(connection)
			end
			connection.disconnect = connection.Disconnect
			table.insert(connections, connection)
			return connection
		end

		signal.Once = signal.Connect

		function signal:__fire(...: any)
			counters.eventsFired += 1
			for _, handler in table.clone(handlers) do
				handler(...)
			end
		end

		function signal:__sever()
			for _, connection in table.clone(connections) do
				release(connection)
			end
		end

		return signal
	end

	local states = (setmetatable({}, { __mode = "k" }) :: any) :: { [any]: any }
	local instanceIndex: (object: any, key: string) -> any
	local instanceNewIndex: (object: any, key: string, value: any) -> ()

	local function stateOf(object: any): any
		return states[object]
	end

	local function newInstance(className: string): any
		local defaults = CLASS_PROPERTIES[className]
		if defaults == nil then
			error(("Unable to create an Instance of type %q"):format(className), 0)
		end
		counters.instancesCreated += 1
		liveInstanceCount += 1

		local events: { [string]: any } = {}
		for _, event in CLASS_EVENTS[className] do
			events[event] = makeSignal()
		end

		events.Destroying = makeSignal()

		local object: any = newproxy(true)
		states[object] = {
			className = className,
			properties = table.clone(defaults),
			children = {} :: { any },
			parent = nil :: any,
			events = events,
			changed = {} :: { [string]: any },
			attributes = {} :: { [string]: any },
			tags = {} :: { [string]: true },
			destroyed = false,
		}

		local meta: any = getmetatable(object)
		meta.__index = instanceIndex
		meta.__newindex = instanceNewIndex
		meta.__tostring = function(self: any): string
			return states[self].properties.Name
		end
		return object
	end

	local function detach(object: any)
		local state = stateOf(object)
		local parent = state.parent
		if parent == nil then
			return
		end
		local siblings = stateOf(parent).children
		for index, candidate in siblings do
			if candidate == object then
				table.remove(siblings, index)
				break
			end
		end
		state.parent = nil
	end

	local destroyInstance: (object: any) -> ()
	function destroyInstance(object: any)
		local state = stateOf(object)
		if state.destroyed then
			return
		end
		state.destroyed = true
		counters.instancesDestroyed += 1
		liveInstanceCount -= 1

		local destroying = state.events.Destroying
		if destroying ~= nil then
			destroying:__fire(object)
		end
		detach(object)
		for _, child in table.clone(state.children) do
			destroyInstance(child)
		end
		state.children = {}
		for _, signal in state.events do
			signal:__sever()
		end
		for _, signal in state.changed do
			signal:__sever()
		end
	end

	function instanceIndex(object: any, key: string): any
		local state = stateOf(object)
		if key == "ClassName" then
			return state.className
		elseif key == "Parent" then
			return state.parent
		elseif key == "Destroy" then
			return destroyInstance
		elseif key == "Clone" then
			return function(self: any): any
				local copy = newInstance(stateOf(self).className)
				for property, value in stateOf(self).properties do
					stateOf(copy).properties[property] = value
				end
				return copy
			end
		elseif key == "GetChildren" then
			return function(self: any): { any }
				return table.clone(stateOf(self).children)
			end
		elseif key == "GetDescendants" then
			return function(self: any): { any }
				local found: { any } = {}
				local function walk(current: any)
					for _, child in stateOf(current).children do
						table.insert(found, child)
						walk(child)
					end
				end
				walk(self)
				return found
			end
		elseif key == "FindFirstChild" then
			return function(self: any, name: string): any?
				for _, child in stateOf(self).children do
					if stateOf(child).properties.Name == name then
						return child
					end
				end
				return nil
			end
		elseif key == "GetFullName" then
			return function(self: any): string
				local parts: { string } = {}
				local current: any = self
				while current ~= nil do
					table.insert(parts, 1, tostring(stateOf(current).properties.Name))
					current = stateOf(current).parent
				end
				return table.concat(parts, ".")
			end
		elseif key == "GetTags" then
			return function(self: any): { string }
				local tags: { string } = {}
				for tag in stateOf(self).tags do
					table.insert(tags, tag)
				end
				table.sort(tags)
				return tags
			end
		elseif key == "AddTag" then
			return function(self: any, tag: string)
				stateOf(self).tags[tag] = true
			end
		elseif key == "RemoveTag" then
			return function(self: any, tag: string)
				stateOf(self).tags[tag] = nil
			end
		elseif key == "HasTag" then
			return function(self: any, tag: string): boolean
				return stateOf(self).tags[tag] == true
			end
		elseif key == "ClearAllChildren" then
			return function(self: any)
				for _, child in table.clone(stateOf(self).children) do
					destroyInstance(child)
				end
			end
		elseif key == "IsA" then
			return function(self: any, className: string): boolean
				return stateOf(self).className == className
			end
		elseif key == "GetPropertyChangedSignal" then
			return function(self: any, property: string): any
				local own = stateOf(self)
				local existing = own.changed[property]
				if existing == nil then
					existing = makeSignal()
					own.changed[property] = existing
				end
				return existing
			end
		elseif key == "GetAttribute" then
			return function(self: any, name: string): any
				return stateOf(self).attributes[name]
			end
		elseif key == "SetAttribute" then
			return function(self: any, name: string, value: any)
				stateOf(self).attributes[name] = value
			end
		end
		local event = state.events[key]
		if event ~= nil then
			return event
		end
		counters.propertyReads += 1
		return state.properties[key]
	end

	function instanceNewIndex(object: any, key: string, value: any)
		local state = stateOf(object)

		if key == "Parent" then
			if state.destroyed then
				if value == nil then
					return
				end
				error("The Parent property of a destroyed Instance is locked", 0)
			end
			counters.parentChanges += 1
			detach(object)
			state.parent = value
			if value ~= nil then
				table.insert(stateOf(value).children, object)
			end
			return
		end
		if state.events[key] ~= nil then
			error(("%s.%s is an event and cannot be assigned"):format(state.className, key), 0)
		end
		if state.destroyed then
			counters.propertyWrites += 1
			state.properties[key] = value
			return
		end
		counters.propertyWrites += 1
		local previous = state.properties[key]
		state.properties[key] = value
		if previous ~= value then
			local signal = state.changed[key]
			if signal ~= nil then
				signal:__fire()
			end
		end
	end

	local function tagged(name: string, fields: { [string]: any }, operators: { [string]: any }?): any
		fields.__datatype = name

		local meta: any = {
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
		}
		if operators ~= nil then
			for key, value in operators do
				meta[key] = value
			end
		end
		return setmetatable(fields, meta)
	end

	local Vector2: any = {}
	local Vector3: any = {}
	local UDim: any = {}
	local UDim2: any = {}

	local function scale2(value: any, factor: number): any
		return Vector2.new(value.X * factor, value.Y * factor)
	end
	function Vector2.new(x: number?, y: number?): any
		local vx, vy = x or 0, y or 0
		return tagged("Vector2", { X = vx, Y = vy, Magnitude = math.sqrt(vx * vx + vy * vy) }, {
			__add = function(a: any, b: any): any
				return Vector2.new(a.X + b.X, a.Y + b.Y)
			end,
			__sub = function(a: any, b: any): any
				return Vector2.new(a.X - b.X, a.Y - b.Y)
			end,
			__mul = function(a: any, b: any): any
				if type(b) == "number" then
					return scale2(a, b)
				end
				if type(a) == "number" then
					return scale2(b, a)
				end
				return Vector2.new(a.X * b.X, a.Y * b.Y)
			end,
			__div = function(a: any, b: any): any
				if type(b) == "number" then
					return scale2(a, 1 / b)
				end
				return Vector2.new(a.X / b.X, a.Y / b.Y)
			end,
			__unm = function(a: any): any
				return Vector2.new(-a.X, -a.Y)
			end,
		})
	end
	Vector2.zero = Vector2.new(0, 0)
	Vector2.one = Vector2.new(1, 1)
	Vector2.xAxis = Vector2.new(1, 0)
	Vector2.yAxis = Vector2.new(0, 1)

	local function scale3(value: any, factor: number): any
		return Vector3.new(value.X * factor, value.Y * factor, value.Z * factor)
	end
	function Vector3.new(x: number?, y: number?, z: number?): any
		local vx, vy, vz = x or 0, y or 0, z or 0
		return tagged("Vector3", {
			X = vx,
			Y = vy,
			Z = vz,
			Magnitude = math.sqrt(vx * vx + vy * vy + vz * vz),
		}, {
			__add = function(a: any, b: any): any
				return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
			end,
			__sub = function(a: any, b: any): any
				return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
			end,
			__mul = function(a: any, b: any): any
				if type(b) == "number" then
					return scale3(a, b)
				end
				if type(a) == "number" then
					return scale3(b, a)
				end
				return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
			end,
			__div = function(a: any, b: any): any
				if type(b) == "number" then
					return scale3(a, 1 / b)
				end
				return Vector3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
			end,
			__unm = function(a: any): any
				return Vector3.new(-a.X, -a.Y, -a.Z)
			end,
		})
	end
	Vector3.zero = Vector3.new(0, 0, 0)
	Vector3.one = Vector3.new(1, 1, 1)
	Vector3.xAxis = Vector3.new(1, 0, 0)
	Vector3.yAxis = Vector3.new(0, 1, 0)
	Vector3.zAxis = Vector3.new(0, 0, 1)

	local NumberRange: any = {}
	function NumberRange.new(minimum: number, maximum: number?): any
		return tagged("NumberRange", { Min = minimum, Max = if maximum ~= nil then maximum else minimum })
	end

	local NumberSequenceKeypoint: any = {}
	function NumberSequenceKeypoint.new(time: number, value: number, envelope: number?): any
		return tagged("NumberSequenceKeypoint", { Time = time, Value = value, Envelope = envelope or 0 })
	end

	local NumberSequence: any = {}
	function NumberSequence.new(first: any, second: any?): any
		local keypoints
		if type(first) == "table" and (first :: any).Time == nil then
			keypoints = first
		elseif second ~= nil then
			keypoints = {
				NumberSequenceKeypoint.new(0, first :: any),
				NumberSequenceKeypoint.new(1, second :: any),
			}
		else
			keypoints = { NumberSequenceKeypoint.new(0, first :: any), NumberSequenceKeypoint.new(1, first :: any) }
		end
		return tagged("NumberSequence", { Keypoints = keypoints })
	end

	local ColorSequenceKeypoint: any = {}
	function ColorSequenceKeypoint.new(time: number, value: any): any
		return tagged("ColorSequenceKeypoint", { Time = time, Value = value })
	end

	local ColorSequence: any = {}
	function ColorSequence.new(first: any, second: any?): any
		local keypoints
		if type(first) == "table" and (first :: any).Time ~= nil then
			keypoints = { first }
		elseif type(first) == "table" and (first :: any).R == nil then
			keypoints = first
		else
			local last = if second ~= nil then second else first
			keypoints = { ColorSequenceKeypoint.new(0, first), ColorSequenceKeypoint.new(1, last) }
		end
		return tagged("ColorSequence", { Keypoints = keypoints })
	end

	local Rect: any = {}
	function Rect.new(minX: any, minY: any?, maxX: number?, maxY: number?): any
		if type(minX) == "table" then
			return tagged("Rect", { Min = minX, Max = minY })
		end
		return tagged("Rect", {
			Min = Vector2.new(minX :: number, minY :: number),
			Max = Vector2.new(maxX, maxY),
		})
	end

	local Ray: any = {}
	function Ray.new(origin: any, direction: any): any
		return tagged("Ray", { Origin = origin, Direction = direction })
	end

	local PhysicalProperties: any = {}
	function PhysicalProperties.new(
		density: number,
		friction: number?,
		elasticity: number?,
		frictionWeight: number?,
		elasticityWeight: number?
	): any
		return tagged("PhysicalProperties", {
			Density = density,
			Friction = friction or 0,
			Elasticity = elasticity or 0,
			FrictionWeight = frictionWeight or 1,
			ElasticityWeight = elasticityWeight or 1,
		})
	end

	local Region3: any = {}
	function Region3.new(minimum: any, maximum: any): any
		return tagged("Region3", { CFrame = nil, Size = nil, Min = minimum, Max = maximum })
	end

	local Region3int16: any = {}
	function Region3int16.new(minimum: any, maximum: any): any
		return tagged("Region3int16", { Min = minimum, Max = maximum })
	end

	local Vector2int16: any = {}
	function Vector2int16.new(x: number?, y: number?): any
		return tagged("Vector2int16", { X = math.floor(x or 0), Y = math.floor(y or 0) })
	end

	local Vector3int16: any = {}
	function Vector3int16.new(x: number?, y: number?, z: number?): any
		return tagged("Vector3int16", { X = math.floor(x or 0), Y = math.floor(y or 0), Z = math.floor(z or 0) })
	end

	local DateTime: any = {}
	function DateTime.fromUnixTimestampMillis(millis: number): any
		return tagged("DateTime", { UnixTimestampMillis = millis })
	end
	function DateTime.fromUnixTimestamp(seconds: number): any
		return DateTime.fromUnixTimestampMillis(seconds * 1000)
	end

	local Color3: any = {}
	function Color3.new(r: number?, g: number?, b: number?): any
		return tagged("Color3", { R = r or 0, G = g or 0, B = b or 0 })
	end
	function Color3.fromRGB(r: number?, g: number?, b: number?): any
		return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
	end
	function Color3.fromHSV(h: number, s: number, v: number): any
		local c = v * s
		local x = c * (1 - math.abs((h * 6) % 2 - 1))
		local m = v - c
		return Color3.new(c + m, x + m, m)
	end

	function UDim.new(scale: number?, offset: number?): any
		return tagged("UDim", { Scale = scale or 0, Offset = offset or 0 }, {
			__add = function(a: any, b: any): any
				return UDim.new(a.Scale + b.Scale, a.Offset + b.Offset)
			end,
			__sub = function(a: any, b: any): any
				return UDim.new(a.Scale - b.Scale, a.Offset - b.Offset)
			end,
			__unm = function(a: any): any
				return UDim.new(-a.Scale, -a.Offset)
			end,
		})
	end

	function UDim2.new(xs: number?, xo: number?, ys: number?, yo: number?): any
		return tagged("UDim2", { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }, {
			__add = function(a: any, b: any): any
				return UDim2.new(
					a.X.Scale + b.X.Scale,
					a.X.Offset + b.X.Offset,
					a.Y.Scale + b.Y.Scale,
					a.Y.Offset + b.Y.Offset
				)
			end,
			__sub = function(a: any, b: any): any
				return UDim2.new(
					a.X.Scale - b.X.Scale,
					a.X.Offset - b.X.Offset,
					a.Y.Scale - b.Y.Scale,
					a.Y.Offset - b.Y.Offset
				)
			end,
			__unm = function(a: any): any
				return UDim2.new(-a.X.Scale, -a.X.Offset, -a.Y.Scale, -a.Y.Offset)
			end,
		})
	end
	function UDim2.fromScale(x: number?, y: number?): any
		return UDim2.new(x, 0, y, 0)
	end
	function UDim2.fromOffset(x: number?, y: number?): any
		return UDim2.new(0, x, 0, y)
	end

	local CFrame: any = {}
	function CFrame.new(x: any, y: number?, z: number?): any
		local position = if type(x) == "table" then x else Vector3.new(x :: number, y, z)
		return tagged("CFrame", {
			Position = position,
			p = position,
			X = position.X,
			Y = position.Y,
			Z = position.Z,
			Rotation = { 1, 0, 0, 0, 1, 0, 0, 0, 1 },
			GetComponents = function(self: any): ...number
				return self.Position.X, self.Position.Y, self.Position.Z, table.unpack(self.Rotation, 1, 9)
			end,
		}, {
			__mul = function(a: any, b: any): any
				if typeof(b) == "table" and rawget(b, "__datatype") == "Vector3" then
					return Vector3.new(a.Position.X + b.X, a.Position.Y + b.Y, a.Position.Z + b.Z)
				end
				return CFrame.new(a.Position + b.Position)
			end,
		})
	end
	CFrame.identity = CFrame.new(0, 0, 0)

	local enumItems: { [string]: any } = {}
	local function enumFor(enumName: string): any
		local existing = enumItems[enumName]
		if existing ~= nil then
			return existing
		end
		local items: { [string]: any } = {}
		local enum: any = setmetatable({}, {
			__index = function(_: any, itemName: string): any
				local item = items[itemName]
				if item == nil then
					item = tagged("EnumItem", { Name = itemName, EnumType = enumName, Value = 0 })
					items[itemName] = item
				end
				return item
			end,
			__tostring = function(): string
				return "Enum." .. enumName
			end,
		})
		enumItems[enumName] = enum
		return enum
	end

	local Enum = setmetatable({}, {
		__index = function(_: any, enumName: string): any
			return enumFor(enumName)
		end,
		__tostring = function(): string
			return "Enums"
		end,
	})

	local function typeName(value: any): string
		local kind = typeof(value)
		if kind == "userdata" then
			if states[value] ~= nil then
				return "Instance"
			end
			return "userdata"
		end
		if kind ~= "table" then
			return kind
		end
		local datatype = rawget(value :: any, "__datatype")
		if datatype ~= nil then
			return datatype :: string
		end
		return "table"
	end

	local heartbeat = makeSignal()
	local renderStepped = makeSignal()
	local runService: any = {
		Heartbeat = heartbeat,
		RenderStepped = renderStepped,
		PostSimulation = heartbeat,
		IsClient = function(): boolean
			return true
		end,
		IsServer = function(): boolean
			return false
		end,
		IsRunning = function(): boolean
			return true
		end,
		IsStudio = function(): boolean
			return false
		end,
	}

	local renderBindings: { { id: string, priority: number, fn: Handler } } = {}
	function runService.BindToRenderStep(_self: any, id: string, priority: number, fn: Handler)
		table.insert(renderBindings, { id = id, priority = priority, fn = fn })
		table.sort(renderBindings, function(left, right)
			if left.priority ~= right.priority then
				return left.priority < right.priority
			end
			return left.id < right.id
		end)
	end
	function runService.UnbindFromRenderStep(_self: any, id: string)
		for index, binding in renderBindings do
			if binding.id == id then
				table.remove(renderBindings, index)
				return
			end
		end
	end

	local guidCounter = 0
	local httpService: any = {
		GenerateGUID = function(_self: any, wrapped: boolean?): string
			guidCounter += 1
			local guid = ("%08x-0000-4000-8000-%012x"):format(guidCounter, guidCounter)
			return if wrapped == false then guid else "{" .. guid .. "}"
		end,
		JSONEncode = function(_self: any, value: any): string
			return tostring(value)
		end,
		JSONDecode = function(_self: any, _text: string): any
			return {}
		end,
	}

	local collectionService: any = {
		AddTag = function(_self: any, instance: any, tag: string)
			stateOf(instance).tags[tag] = true
		end,
		RemoveTag = function(_self: any, instance: any, tag: string)
			stateOf(instance).tags[tag] = nil
		end,
		HasTag = function(_self: any, instance: any, tag: string): boolean
			return stateOf(instance).tags[tag] == true
		end,
		GetTags = function(_self: any, instance: any): { string }
			local tags: { string } = {}
			for tag in stateOf(instance).tags do
				table.insert(tags, tag)
			end
			table.sort(tags)
			return tags
		end,
		GetTagged = function(_self: any, _tag: string): { any }
			return {}
		end,
	}

	local guiService: any = {
		TopbarInset = nil,
		GetGuiInset = function(): (any, any)
			return Vector2.new(0, 36), Vector2.new(0, 0)
		end,
		GetPropertyChangedSignal = function(_self: any, _property: string): any
			return {
				Connect = function(): any
					return { Disconnect = function() end, Connected = true }
				end,
			}
		end,
	}

	local services: { [string]: any } = {
		RunService = runService,
		HttpService = httpService,
		CollectionService = collectionService,
		GuiService = guiService,
	}
	local dataModel: any = {
		GetService = function(_self: any, name: string): any
			local existing = services[name]
			if existing == nil then
				existing = newInstance "Folder"
				services[name] = existing
			end
			return existing
		end,
	}
	setmetatable(dataModel, {
		__index = function(_: any, key: string): any
			return services[key]
		end,
	})

	local task = {
		defer = function(fn: any, ...: any)
			counters.tasksDeferred += 1
			table.insert(deferred, { fn = fn, arguments = table.pack(...) })
		end,
		delay = function(seconds: number, fn: any, ...: any)
			counters.tasksDeferred += 1
			table.insert(delayed, { at = clock + seconds, fn = fn, arguments = table.pack(...) })
		end,
		spawn = function(fn: any, ...: any)
			if type(fn) == "thread" then
				coroutine.resume(fn, ...)
			else
				fn(...)
			end
		end,
		cancel = function(_thread: thread) end,
		wait = function(_seconds: number?): number
			return 0
		end,
		synchronize = function() end,
		desynchronize = function() end,
	}

	local function drain()
		local passes = 0
		while #deferred > 0 do
			passes += 1
			if passes > 10000 then
				error("benchmark environment: deferred work did not settle", 0)
			end
			local batch = deferred
			deferred = {}
			for _, entry in batch do
				entry.fn(table.unpack(entry.arguments, 1, entry.arguments.n))
			end
		end
	end

	local function step(delta: number)
		clock += delta
		local due: { Delayed } = {}
		local remaining: { Delayed } = {}
		for _, entry in delayed do
			if entry.at <= clock then
				table.insert(due, entry)
			else
				table.insert(remaining, entry)
			end
		end
		delayed = remaining
		table.sort(due, function(left, right)
			return left.at < right.at
		end)
		for _, entry in due do
			entry.fn(table.unpack(entry.arguments, 1, entry.arguments.n))
		end

		for _, binding in table.clone(renderBindings) do
			binding.fn(delta)
		end
		renderStepped:__fire(delta)
		heartbeat:__fire(delta)
		drain()
	end

	local diagnostics: { string } = {}
	local function record(...: any)
		local parts: { string } = {}
		for index = 1, select("#", ...) do
			table.insert(parts, tostring((select(index, ...))))
		end
		table.insert(diagnostics, table.concat(parts, "\t"))
	end

	local globals: { [string]: any } = {
		assert = assert,
		bit32 = bit32,
		buffer = buffer,
		coroutine = coroutine,
		error = error,
		getmetatable = getmetatable,
		ipairs = ipairs,
		math = math,
		newproxy = newproxy,
		next = next,
		pairs = pairs,
		pcall = pcall,
		print = record,
		warn = record,
		rawequal = rawequal,
		rawget = rawget,
		rawlen = rawlen,
		rawset = rawset,
		select = select,
		setmetatable = setmetatable,
		string = string,
		table = table,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack,
		utf8 = utf8,
		vector = vector,
		xpcall = xpcall,
		_G = {},

		os = {
			clock = function(): number
				clockReads += 1
				return clock + clockReads * 1e-9
			end,
			time = function(): number
				return math.floor(clock)
			end,
			date = os.date,
		},
		debug = {
			info = debug.info,
			traceback = debug.traceback,
			profilebegin = function(_label: string) end,
			profileend = function() end,
			setmemorycategory = function(_label: string) end,
			resetmemorycategory = function() end,
			getmemorycategory = function(): string
				return "emulated"
			end,
		},

		game = dataModel,
		workspace = dataModel:GetService "Workspace",
		Instance = {
			new = function(className: string, parent: any?): any
				local object = newInstance(className)
				if parent ~= nil then
					object.Parent = parent
				end
				return object
			end,
		},
		typeof = typeName,
		task = task,
		Vector2 = Vector2,
		Vector3 = Vector3,
		Color3 = Color3,
		UDim = UDim,
		UDim2 = UDim2,
		CFrame = CFrame,
		NumberRange = NumberRange,
		NumberSequence = NumberSequence,
		NumberSequenceKeypoint = NumberSequenceKeypoint,
		ColorSequence = ColorSequence,
		ColorSequenceKeypoint = ColorSequenceKeypoint,
		Rect = Rect,
		Ray = Ray,
		Region3 = Region3,
		Region3int16 = Region3int16,
		Vector2int16 = Vector2int16,
		Vector3int16 = Vector3int16,
		PhysicalProperties = PhysicalProperties,
		DateTime = DateTime,
		Enum = Enum,
	}

	local renderValue: (value: any, depth: number) -> string
	function renderValue(value: any, depth: number): string
		if type(value) == "string" then
			return ("%q"):format(value)
		end
		if type(value) ~= "table" or depth > 3 then
			return tostring(value)
		end
		local datatype = rawget(value, "__datatype")
		if datatype == nil then
			return tostring(value)
		end
		local fields: { string } = {}
		for key in value do
			if key ~= "__datatype" then
				table.insert(fields, key)
			end
		end
		table.sort(fields)
		local parts: { string } = {}
		for _, key in fields do
			local field = value[key]
			if type(field) ~= "function" then
				table.insert(parts, ("%s=%s"):format(key, renderValue(field, depth + 1)))
			end
		end
		return ("%s(%s)"):format(datatype, table.concat(parts, ","))
	end

	local function snapshot(object: any, keys: { string }?, sortBy: string?): string
		local wanted: { string }
		if keys ~= nil then
			wanted = table.clone(keys)
			table.sort(wanted)
		else
			wanted = {}
		end

		local lines: { string } = {}
		local function walk(current: any, depth: number)
			local state = stateOf(current)
			local rendered: { string } = {}
			for _, key in wanted do
				local value = state.properties[key]
				if value ~= nil then
					table.insert(rendered, ("%s=%s"):format(key, renderValue(value, 0)))
				end
			end
			table.insert(
				lines,
				("%s%s{%s}"):format(string.rep(" ", depth), state.className, table.concat(rendered, ","))
			)
			local children = state.children
			if sortBy ~= nil then
				children = table.clone(children)
				table.sort(children, function(left: any, right: any): boolean
					local leftKey = states[left].properties[sortBy]
					local rightKey = states[right].properties[sortBy]
					if leftKey == rightKey then
						return tostring(states[left].properties.Name) < tostring(states[right].properties.Name)
					end
					return (leftKey or 0) < (rightKey or 0)
				end)
			end
			for _, child in children do
				walk(child, depth + 1)
			end
		end
		walk(object, 0)
		return table.concat(lines, "\n")
	end

	return {
		globals = globals,
		container = function(): any
			return newInstance "Folder"
		end,
		step = step,
		drain = drain,
		counters = function(): Counters
			return table.clone(counters)
		end,
		resetCounters = function()
			counters = zeroCounters()
		end,
		liveInstances = function(): number
			return liveInstanceCount
		end,
		liveConnections = function(): number
			return liveConnectionCount
		end,
		snapshot = snapshot,
		diagnostics = function(): { string }
			return table.clone(diagnostics)
		end,
		fire = function(object: any, event: string, ...: any)
			local signal = stateOf(object).events[event]
			if signal == nil then
				error(("%s has no event %q"):format(stateOf(object).className, event), 0)
			end
			signal:__fire(...)
		end,
		get = function(object: any, key: string): any
			return stateOf(object).properties[key]
		end,
		children = function(object: any): { any }
			return table.clone(stateOf(object).children)
		end,
	}
end

return {
	create = create,
	zeroCounters = zeroCounters,
}
