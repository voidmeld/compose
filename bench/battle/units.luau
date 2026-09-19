--!strict

local Trace = require "./trace"

export type Unit = {
	id: number,
	name: string,
	health: any,
	maximum: number,
	state: any,
	status: any,
	distance: any,
	visible: any,
	faction: any,
	group: any,
}

local function sparse(roster: { Trace.Combatant }, cell: (any) -> any): { Unit }
	local units = table.create(#roster)
	for index, combatant in roster do
		units[index] = {
			id = combatant.id,
			name = combatant.name,
			health = cell(combatant.health),
			maximum = combatant.maximum,
			state = cell(combatant.state),
			status = cell(combatant.status),
			distance = cell(combatant.distance),
			visible = cell(combatant.visible),
			faction = cell(combatant.faction),
			group = cell(combatant.group),
		}
	end
	return units
end

local function copy(roster: { Trace.Combatant }): { Trace.Combatant }
	local out = table.create(#roster)
	for index, combatant in roster do
		out[index] = {
			id = combatant.id,
			name = combatant.name,
			faction = combatant.faction,
			group = combatant.group,
			health = combatant.health,
			maximum = combatant.maximum,
			state = combatant.state,
			status = combatant.status,
			distance = combatant.distance,
			visible = combatant.visible,
		}
	end
	return out
end

local function applyChanges(roster: { Trace.Combatant }, tick: Trace.Tick)
	for _, change in tick.changes do
		local combatant = roster[change.index]
		if combatant ~= nil then
			combatant.health = change.health
			combatant.state = change.state
			combatant.status = change.status
		end
	end
	for _, change in tick.visibility do
		local combatant = roster[change.index]
		if combatant ~= nil then
			combatant.visible = change.visible
			combatant.distance = change.distance
		end
	end
end

local function applySparse(units: { Unit }, tick: Trace.Tick): number
	local written = 0
	for _, change in tick.changes do
		local unit = units[change.index]
		if unit ~= nil then
			unit.health:set(change.health)
			unit.state:set(change.state)
			unit.status:set(change.status)
			written += 3
		end
	end
	for _, change in tick.visibility do
		local unit = units[change.index]
		if unit ~= nil then
			unit.visible:set(change.visible)
			unit.distance:set(change.distance)
			written += 2
		end
	end
	return written
end

local function plateText(name: string, health: number, maximum: number, status: number, tier: number): string
	if tier == 3 then
		return ("%d"):format(math.floor((health / maximum) * 100))
	elseif tier == 2 then
		return ("%s %d"):format(name, math.floor((health / maximum) * 100))
	end
	return ("%s %d %s"):format(name, math.floor((health / maximum) * 100), Trace.effectsOf(status))
end

local function raidText(name: string, health: number, maximum: number, state: number): string
	if state == 0 then
		return ("%s DEAD"):format(name)
	elseif state == 2 then
		return ("%s OUT"):format(name)
	end
	return ("%s %d/%d"):format(name, health, maximum)
end

return {
	sparse = sparse,
	copy = copy,
	applyChanges = applyChanges,
	applySparse = applySparse,
	plateText = plateText,
	raidText = raidText,
}
