--!strict

local Set = require "./set"

type EntrySet = Set.EntrySet

export type Coverage = {
	missingIds: { string },
	missingRoles: { string },
	unknownKeys: { string },
}

local function coverage(set: EntrySet, keys: { string }): Coverage
	local keyed: { [string]: true } = {}
	for _, key in keys do
		keyed[key] = true
	end

	local missingIds: { string } = {}
	local missingRoleSet: { [string]: true } = {}
	local authored: { [string]: true } = {}
	for _, entry in set.entries do
		local id = set:idOf(entry)
		authored[id] = true
		if keyed[id] == nil then
			table.insert(missingIds, id)
			local role = set:roleOf(entry)
			if role ~= nil then
				missingRoleSet[role] = true
			end
		end
	end

	local unknownKeys: { string } = {}
	local reported: { [string]: true } = {}
	for _, key in keys do
		if authored[key] == nil and reported[key] == nil then
			reported[key] = true
			table.insert(unknownKeys, key)
		end
	end

	local missingRoles: { string } = {}
	for role in pairs(missingRoleSet) do
		table.insert(missingRoles, role)
	end

	table.sort(missingIds)
	table.sort(missingRoles)
	table.sort(unknownKeys)

	return {
		missingIds = missingIds,
		missingRoles = missingRoles,
		unknownKeys = unknownKeys,
	}
end

return {
	coverage = coverage,
}
