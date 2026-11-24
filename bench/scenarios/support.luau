--!strict

local Plain = require "../workloads/plain-support"

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
	local createMade: (number, Item?) -> { Item } = table.create
	local made: { Item } = createMade(count)
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
	local createMade: (number, Entity?) -> { Entity } = table.create
	local made: { Entity } = createMade(count)
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

local instances = Plain.instances

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
	destroyAll = Plain.destroyAll,
	sortKey = sortKey,
	matches = matches,
	KINDS = KINDS,
}
