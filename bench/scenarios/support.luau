--!strict

local Environment = require "../cost-model"

export type Item = {
	id: number,
	name: string,
	kind: string,
	priority: number,
	quantity: number,
	pinned: boolean,
}

local function sequence(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(): number
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
end

local KINDS = { "document", "image", "audio", "video", "archive", "other" }
local PREFIXES = { "Annual", "Brief", "Daily", "Draft", "Final", "Interim", "Monthly", "Weekly" }
local NOUNS = { "Report", "Summary", "Invoice", "Ledger", "Memo", "Notice", "Receipt", "Survey" }

local function items(count: number): { Item }
	local next = sequence(20260828)
	local made = table.create(count) :: { Item }
	for index = 1, count do
		local prefix = PREFIXES[math.floor(next() * #PREFIXES) + 1]
		local noun = NOUNS[math.floor(next() * #NOUNS) + 1]
		made[index] = {
			id = index,
			name = ("%s %s %d"):format(prefix, noun, index),
			kind = KINDS[math.floor(next() * #KINDS) + 1],
			priority = math.floor(next() * 5) + 1,
			quantity = math.floor(next() * 99) + 1,
			pinned = false,
		}
	end
	return made
end

export type Entity = {
	id: number,
	name: string,
	level: number,
	maximum: number,
	status: string,
	visible: boolean,
}

local function entities(count: number, prefix: string): { Entity }
	local next = sequence(19770401)
	local made = table.create(count) :: { Entity }
	for index = 1, count do
		made[index] = {
			id = index,
			name = ("%s-%03d"):format(prefix, index),
			level = math.floor(next() * 100) + 1,
			maximum = 100,
			status = "none",
			visible = true,
		}
	end
	return made
end

local function instances(context: { env: Environment.Environment }): Environment.InstanceFactory
	return context.env.globals.Instance
end

local function destroyAll(nodes: { Environment.Instance })
	for index = #nodes, 1, -1 do
		local node = nodes[index]
		if node ~= nil then
			node:Destroy()
			nodes[index] = nil
		end
	end
end

local function fill(
	context: { env: Environment.Environment },
	parent: Environment.Instance,
	count: number,
	kind: string,
	made: { Environment.Instance },
	configure: (Environment.Instance, number) -> ()
)
	local Instance = instances(context)
	for index = 1, count do
		local node = Instance.new(kind)
		configure(node, index)
		node.Parent = parent
		table.insert(made, node)
	end
end

local function sortKey(item: Item, mode: string): string
	if mode == "name" then
		return item.name
	elseif mode == "kind" then
		return ("%s:%s"):format(item.kind, item.name)
	end
	return ("%02d:%s"):format(99 - item.priority, item.name)
end

local function matches(item: Item, filter: string): boolean
	if filter == "" then
		return true
	end
	return string.find(item.kind, filter, 1, true) ~= nil or string.find(item.name, filter, 1, true) ~= nil
end

return {
	sequence = sequence,
	items = items,
	entities = entities,
	instances = instances,
	destroyAll = destroyAll,
	fill = fill,
	sortKey = sortKey,
	matches = matches,
	KINDS = KINDS,
}
