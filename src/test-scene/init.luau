--!strict

local Compose = require "./core"

type Node = Compose.Node

export type Operation =
	"createNode"
	| "setProperty"
	| "setAttribute"
	| "clearProperty"
	| "insertChild"
	| "moveChild"
	| "removeChild"
	| "destroyNode"
	| "connectEvent"
	| "setName"

export type Counts = {
	createNode: number,
	setProperty: number,
	setAttribute: number,
	setName: number,
	clearProperty: number,
	insertChild: number,
	moveChild: number,
	removeChild: number,
	destroyNode: number,
	connectEvent: number,
	disconnectEvent: number,
	dispatchEvent: number,
	observeProperty: number,
	frameListeners: number,
}

export type TestScene = {
	adapter: Compose.Host,
	root: Node,

	makeNode: (kind: string) -> Node,
	kindOf: (node: Node) -> string?,
	propertyOf: (node: Node, key: string) -> unknown,
	attributeOf: (node: Node, name: string) -> unknown,
	nameOf: (node: Node) -> string?,
	childrenOf: (node: Node) -> { Node },
	parentOf: (node: Node) -> Node?,
	isAlive: (node: Node) -> boolean,
	handlerCount: (node: Node, event: string) -> number,

	declareEvent: (kind: string, event: string) -> (),
	dispatch: (node: Node, event: string, ...any) -> (),
	poke: (node: Node, key: string, value: unknown) -> (),

	step: (delta: number) -> (),
	now: () -> number,

	failNext: (operation: Operation, times: number?) -> (),
	clearFailures: () -> (),

	counts: () -> Counts,
	resetCounts: () -> (),
	liveNodes: () -> number,
	liveSubscriptions: () -> number,
	leaked: () -> { string },
	serialize: (node: Node) -> string,
}

type Handler = (...any) -> ()

type Record = {
	kind: string,
	sequence: number,
	name: string?,
	properties: { [string]: unknown },
	attributes: { [string]: unknown },
	children: { Node },
	parent: Node?,
	handlers: { [string]: { Handler } },
	observers: { [string]: { () -> () } },
}

local ATTRIBUTE_TYPES: { [string]: true } = {
	string = true,
	number = true,
	boolean = true,
	["nil"] = true,
}

local function zeroCounts(): Counts
	return {
		createNode = 0,
		setProperty = 0,
		setAttribute = 0,
		setName = 0,
		clearProperty = 0,
		insertChild = 0,
		moveChild = 0,
		removeChild = 0,
		destroyNode = 0,
		connectEvent = 0,
		disconnectEvent = 0,
		dispatchEvent = 0,
		observeProperty = 0,
		frameListeners = 0,
	}
end

export type Options = {
	ordersChildren: boolean?,
	namesNodes: boolean?,
}

local function create(options: Options?): TestScene
	local records: { [Node]: Record } = {}
	local sequence = 0
	local counts = zeroCounts()
	local failures: { [string]: number } = {}
	local clock = 0
	local frameListeners: { (number) -> () } = {}

	local function recordOf(node: Node, operation: string): Record
		local record = records[node]
		if record == nil then
			error(
				("TestScene.%s: node is not alive (either never created here, or already destroyed)"):format(operation),
				0
			)
		end
		return record
	end

	local function checkFailure(operation: Operation)
		local remaining = failures[operation]
		if remaining == nil or remaining <= 0 then
			return
		end
		failures[operation] = remaining - 1
		error(("TestScene: injected failure in %s"):format(operation), 0)
	end

	local function newNode(kind: string): Node
		sequence += 1
		local node = table.freeze {}
		records[node] = {
			kind = kind,
			sequence = sequence,
			name = nil,
			properties = {},
			attributes = {},
			children = {},
			parent = nil,
			handlers = {},
			observers = {},
		}
		return node :: Node
	end

	local function indexOfChild(record: Record, child: Node): number?
		for index, candidate in record.children do
			if candidate == child then
				return index
			end
		end
		return nil
	end

	local function detach(record: Record, child: Node)
		local at = indexOfChild(record, child)
		if at ~= nil then
			table.remove(record.children, at)
		end
	end

	local eventKinds: { [string]: true } = {}

	local function createNode(kind: string): Node
		checkFailure "createNode"
		counts.createNode += 1
		return newNode(kind)
	end

	local function setName(node: Node, label: string)
		checkFailure "setName"
		counts.setName += 1
		local record = records[node]
		if record ~= nil then
			record.name = label
		end
	end

	local function notifyObservers(record: Record, key: string)
		local listeners = record.observers[key]
		if listeners == nil then
			return
		end
		for _, listener in table.clone(listeners) do
			listener()
		end
	end

	local function setProperty(node: Node, key: string, value: unknown)
		checkFailure "setProperty"
		counts.setProperty += 1
		local record = recordOf(node, "setProperty")
		record.properties[key] = value
		notifyObservers(record, key)
	end

	local function setAttribute(node: Node, name: string, value: unknown): (boolean, string?)
		counts.setAttribute += 1
		local injected = failures.setAttribute
		if injected ~= nil and injected > 0 then
			failures.setAttribute = injected - 1
			return false, "TestScene: injected refusal in setAttribute"
		end
		local kind = type(value)
		if not ATTRIBUTE_TYPES[kind] then
			return false, ("TestScene: attributes hold string, number, boolean or nil, not %s"):format(kind)
		end
		recordOf(node, "setAttribute").attributes[name] = value
		return true, nil
	end

	local function clearProperty(node: Node, key: string)
		checkFailure "clearProperty"
		counts.clearProperty += 1
		local record = recordOf(node, "clearProperty")
		record.properties[key] = nil
		notifyObservers(record, key)
	end

	local function insertChild(parent: Node, child: Node, position: number?)
		checkFailure "insertChild"
		counts.insertChild += 1
		local parentRecord = recordOf(parent, "insertChild")
		local childRecord = recordOf(child, "insertChild")

		local previousParent = childRecord.parent
		if previousParent ~= nil then
			detach(recordOf(previousParent, "insertChild"), child)
		end

		local at = if position ~= nil then position else #parentRecord.children + 1
		at = math.clamp(at, 1, #parentRecord.children + 1)
		table.insert(parentRecord.children, at, child)
		childRecord.parent = parent
	end

	local function moveChild(parent: Node, child: Node, position: number)
		checkFailure "moveChild"
		counts.moveChild += 1
		local parentRecord = recordOf(parent, "moveChild")
		local at = indexOfChild(parentRecord, child)
		if at == nil then
			error("TestScene.moveChild: the node is not a child of that parent", 0)
		end
		table.remove(parentRecord.children, at)
		local target = math.clamp(position, 1, #parentRecord.children + 1)
		table.insert(parentRecord.children, target, child)
	end

	local function removeChild(parent: Node, child: Node)
		checkFailure "removeChild"
		counts.removeChild += 1
		local parentRecord = records[parent]
		local childRecord = records[child]
		if parentRecord == nil or childRecord == nil then
			return
		end
		detach(parentRecord, child)
		childRecord.parent = nil
	end

	local destroyNode: (node: Node) -> ()
	function destroyNode(node: Node)
		checkFailure "destroyNode"
		local record = records[node]
		if record == nil then
			return
		end
		counts.destroyNode += 1

		local parent = record.parent
		if parent ~= nil and records[parent] ~= nil then
			detach(records[parent], node)
		end

		for _, child in table.clone(record.children) do
			destroyNode(child)
		end

		records[node] = nil
	end

	local function connectEvent(node: Node, event: string, handler: Handler): () -> ()
		checkFailure "connectEvent"
		counts.connectEvent += 1
		local record = recordOf(node, "connectEvent")
		local bucket = record.handlers[event]
		if bucket == nil then
			bucket = {}
			record.handlers[event] = bucket
		end
		table.insert(bucket, handler)

		local disconnected = false
		return function()
			if disconnected then
				return
			end
			disconnected = true
			counts.disconnectEvent += 1
			local current = record.handlers[event]
			if current == nil then
				return
			end
			for index, candidate in current do
				if candidate == handler then
					table.remove(current, index)
					break
				end
			end
		end
	end

	local function classifyKey(node: Node, key: string): Compose.KeyKind
		local record = records[node]
		if record ~= nil and eventKinds[record.kind .. "." .. key] then
			return "event"
		end
		return "property"
	end

	local function readProperty(node: Node, key: string): unknown
		return recordOf(node, "readProperty").properties[key]
	end

	local function observeProperty(node: Node, key: string, listener: () -> ()): () -> ()
		counts.observeProperty += 1
		local record = recordOf(node, "observeProperty")
		local bucket = record.observers[key]
		if bucket == nil then
			bucket = {}
			record.observers[key] = bucket
		end
		table.insert(bucket, listener)

		local disconnected = false
		return function()
			if disconnected then
				return
			end
			disconnected = true
			local current = record.observers[key]
			if current == nil then
				return
			end
			for index, candidate in current do
				if candidate == listener then
					table.remove(current, index)
					break
				end
			end
		end
	end

	local function onFrame(listener: (number) -> ()): () -> ()
		counts.frameListeners += 1
		table.insert(frameListeners, listener)
		local removed = false
		return function()
			if removed then
				return
			end
			removed = true
			counts.frameListeners -= 1
			for index, candidate in frameListeners do
				if candidate == listener then
					table.remove(frameListeners, index)
					break
				end
			end
		end
	end

	local function describeNode(node: Node): string
		local record = records[node]
		if record == nil then
			return "<destroyed node>"
		end
		return ("%s#%d"):format(record.kind, record.sequence)
	end

	local host: Compose.Host = {
		name = "test",
		render = {
			createNode = createNode,
			setProperty = setProperty,
			setAttribute = setAttribute,
			clearProperty = clearProperty,
			insertChild = insertChild,
			moveChild = if options ~= nil and options.ordersChildren == false then nil else moveChild,
			removeChild = removeChild,
			destroyNode = destroyNode,
		},
		events = {
			connectEvent = connectEvent,
			classifyKey = classifyKey,
		},
		observation = {
			readProperty = readProperty,
			observeProperty = observeProperty,
		},
		naming = if options ~= nil and options.namesNodes == false then nil else { setName = setName },
		frames = {
			onFrame = onFrame,
			now = function(): number
				return clock
			end,
		},
		describeNode = describeNode,
	}

	local root = newNode "Root"

	local function serialize(node: Node): string
		local lines: { string } = {}
		local function walk(current: Node, depth: number)
			local record = records[current]
			local indent = string.rep("  ", depth)
			if record == nil then
				table.insert(lines, indent .. "<destroyed>")
				return
			end
			local keys: { string } = {}
			for key in record.properties do
				table.insert(keys, key)
			end
			table.sort(keys)
			local rendered: { string } = {}
			for _, key in keys do
				local value = record.properties[key]
				local shown = if type(value) == "string" then ("%q"):format(value) else tostring(value)
				table.insert(rendered, ("%s=%s"):format(key, shown))
			end
			local events: { string } = {}
			for event, handlers in record.handlers do
				if #handlers > 0 then
					table.insert(events, ("%s x%d"):format(event, #handlers))
				end
			end
			table.sort(events)
			local suffix = ""
			if #rendered > 0 then
				suffix ..= " { " .. table.concat(rendered, ", ") .. " }"
			end
			if #events > 0 then
				suffix ..= " on[" .. table.concat(events, ", ") .. "]"
			end
			table.insert(lines, ("%s%s%s"):format(indent, record.kind, suffix))
			for _, child in record.children do
				walk(child, depth + 1)
			end
		end
		walk(node, 0)
		return table.concat(lines, "\n")
	end

	local function leaked(): { string }
		local live: { Record } = {}
		for _, record in records do
			table.insert(live, record)
		end
		table.sort(live, function(left: Record, right: Record): boolean
			return left.sequence < right.sequence
		end)
		local described: { string } = {}
		for _, record in live do
			table.insert(described, ("%s#%d"):format(record.kind, record.sequence))
		end
		return described
	end

	local function liveNodes(): number
		local total = 0
		for _ in records do
			total += 1
		end
		return total
	end

	local function liveSubscriptions(): number
		local total = 0
		for _, record in records do
			for _, handlers in record.handlers do
				total += #handlers
			end
			for _, observers in record.observers do
				total += #observers
			end
		end
		return total
	end

	return {
		adapter = host,
		root = root,

		makeNode = newNode,
		kindOf = function(node: Node): string?
			local record = records[node]
			return if record ~= nil then record.kind else nil
		end,
		nameOf = function(node: Node): string?
			local record = records[node]
			return if record ~= nil then record.name else nil
		end,
		propertyOf = function(node: Node, key: string): unknown
			return recordOf(node, "propertyOf").properties[key]
		end,
		attributeOf = function(node: Node, name: string): unknown
			return recordOf(node, "attributeOf").attributes[name]
		end,
		childrenOf = function(node: Node): { Node }
			return table.clone(recordOf(node, "childrenOf").children)
		end,
		parentOf = function(node: Node): Node?
			return recordOf(node, "parentOf").parent
		end,
		isAlive = function(node: Node): boolean
			return records[node] ~= nil
		end,
		handlerCount = function(node: Node, event: string): number
			local handlers = recordOf(node, "handlerCount").handlers[event]
			return if handlers ~= nil then #handlers else 0
		end,

		declareEvent = function(kind: string, event: string)
			eventKinds[kind .. "." .. event] = true
		end,
		dispatch = function(node: Node, event: string, ...: any)
			counts.dispatchEvent += 1
			local handlers = recordOf(node, "dispatch").handlers[event]
			if handlers == nil then
				return
			end
			for _, handler in table.clone(handlers) do
				handler(...)
			end
		end,
		poke = function(node: Node, key: string, value: unknown)
			local record = recordOf(node, "poke")
			record.properties[key] = value
			notifyObservers(record, key)
		end,

		step = function(delta: number)
			clock += delta
			for _, listener in table.clone(frameListeners) do
				listener(delta)
			end
		end,
		now = function(): number
			return clock
		end,

		failNext = function(operation: Operation, times: number?)
			failures[operation] = (failures[operation] or 0) + (if times ~= nil then times else 1)
		end,
		clearFailures = function()
			table.clear(failures)
		end,

		counts = function(): Counts
			return table.clone(counts)
		end,
		resetCounts = function()
			counts = zeroCounts()
		end,
		liveNodes = liveNodes,
		liveSubscriptions = liveSubscriptions,
		leaked = leaked,
		serialize = serialize,
	}
end

return {
	create = create,
}
