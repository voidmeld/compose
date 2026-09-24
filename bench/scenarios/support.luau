--!strict

export type Item = {
	id: number,
	name: string,
	kind: string,
	rarity: number,
	quantity: number,
	equipped: boolean,
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

local KINDS = { "weapon", "armour", "consumable", "quest", "material", "trinket" }
local PREFIXES = { "Ashen", "Gilded", "Hollow", "Riven", "Sable", "Thornbound", "Verdant", "Wrought" }
local NOUNS = { "Blade", "Cuirass", "Draught", "Ledger", "Ingot", "Sigil", "Cloak", "Lantern" }

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
			rarity = math.floor(next() * 5) + 1,
			quantity = math.floor(next() * 99) + 1,
			equipped = false,
		}
	end
	return made
end

export type Combatant = {
	id: number,
	name: string,
	health: number,
	maximum: number,
	status: string,
	visible: boolean,
}

local function combatants(count: number, prefix: string): { Combatant }
	local next = sequence(19770401)
	local made = table.create(count) :: { Combatant }
	for index = 1, count do
		made[index] = {
			id = index,
			name = ("%s-%03d"):format(prefix, index),
			health = math.floor(next() * 100) + 1,
			maximum = 100,
			status = "none",
			visible = true,
		}
	end
	return made
end

local function instances(context: any): any
	return context.env.globals.Instance
end

local function destroyAll(nodes: { any })
	for index = #nodes, 1, -1 do
		local node = nodes[index]
		if node ~= nil then
			node:Destroy()
			nodes[index] = nil
		end
	end
end

local function fill(
	context: any,
	parent: any,
	count: number,
	kind: string,
	made: { any },
	configure: (any, number) -> ()
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
	return ("%02d:%s"):format(99 - item.rarity, item.name)
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
	combatants = combatants,
	instances = instances,
	destroyAll = destroyAll,
	fill = fill,
	sortKey = sortKey,
	matches = matches,
	KINDS = KINDS,
}
