--!strict

local Trace = require "./trace"
local Compose = require "../../src/core"

export type Item = {
	id: number,
	name: string,
	level: Compose.Cell<number>,
	maximum: number,
	state: Compose.Cell<number>,
	status: Compose.Cell<number>,
	distance: Compose.Cell<number>,
	visible: Compose.Cell<boolean>,
	category: Compose.Cell<number>,
	group: Compose.Cell<number>,
}

local function sparse(entities: { Trace.Entity }, cell: typeof(Compose.cell)): { Item }
	local items = table.create(#entities) :: { Item }
	for index, entity in entities do
		items[index] = {
			id = entity.id,
			name = entity.name,
			level = cell(entity.level),
			maximum = entity.maximum,
			state = cell(entity.state),
			status = cell(entity.status),
			distance = cell(entity.distance),
			visible = cell(entity.visible),
			category = cell(entity.category),
			group = cell(entity.group),
		}
	end
	return items
end

local function copy(entities: { Trace.Entity }): { Trace.Entity }
	local out = table.create(#entities) :: { Trace.Entity }
	for index, entity in entities do
		out[index] = {
			id = entity.id,
			name = entity.name,
			category = entity.category,
			group = entity.group,
			level = entity.level,
			maximum = entity.maximum,
			state = entity.state,
			status = entity.status,
			distance = entity.distance,
			visible = entity.visible,
		}
	end
	return out
end

local function applyChanges(entities: { Trace.Entity }, tick: Trace.Tick)
	for _, change in tick.changes do
		local entity = entities[change.index]
		if entity ~= nil then
			entity.level = change.level
			entity.state = change.state
			entity.status = change.status
		end
	end
	for _, change in tick.visibility do
		local entity = entities[change.index]
		if entity ~= nil then
			entity.visible = change.visible
			entity.distance = change.distance
		end
	end
end

local function applySparse(items: { Item }, tick: Trace.Tick): number
	local written = 0
	for _, change in tick.changes do
		local item = items[change.index]
		if item ~= nil then
			item.level:set(change.level)
			item.state:set(change.state)
			item.status:set(change.status)
			written += 3
		end
	end
	for _, change in tick.visibility do
		local item = items[change.index]
		if item ~= nil then
			item.visible:set(change.visible)
			item.distance:set(change.distance)
			written += 2
		end
	end
	return written
end

local function labelText(name: string, level: number, maximum: number, status: number, tier: number): string
	if tier == 3 then
		return ("%d"):format(math.floor((level / maximum) * 100))
	elseif tier == 2 then
		return ("%s %d"):format(name, math.floor((level / maximum) * 100))
	end
	return ("%s %d %s"):format(name, math.floor((level / maximum) * 100), Trace.effectsOf(status))
end

local function summaryText(name: string, level: number, maximum: number, state: number): string
	if state == 0 then
		return ("%s OFF"):format(name)
	elseif state == 2 then
		return ("%s HELD"):format(name)
	end
	return ("%s %d/%d"):format(name, level, maximum)
end

return {
	sparse = sparse,
	copy = copy,
	applyChanges = applyChanges,
	applySparse = applySparse,
	labelText = labelText,
	summaryText = summaryText,
}
