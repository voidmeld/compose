--!strict

local fs = require "@std/fs"

local Diagnostics = require "./diagnostics"
local Digest = require "./digest"
local Set = require "./set"

type Entry = Set.Entry
type EntrySet = Set.EntrySet

export type AttributeValue = string | number | boolean

export type MappingRow = {
	field: string,
	attribute: string,
	optional: boolean?,
}

export type AttributeMapping = { MappingRow }

export type PlannedAttribute = { key: string, value: AttributeValue }

export type AttributePlan = { PlannedAttribute }

export type RegistrySpec = {
	name: string,
	set: EntrySet,
	mapping: AttributeMapping,
}

export type DataValue = string | number | boolean | { DataValue } | { [string]: DataValue }

export type DataRecord = { [string]: unknown }

export type DataSpec = {
	name: string,
	idKey: string,
	entries: { DataRecord },
}

local function attributePlan(entry: Entry, mapping: AttributeMapping): AttributePlan
	local plan: AttributePlan = {}
	for _, row in mapping do
		local value = entry[row.field]
		if value == nil then
			if row.optional == true then
				continue
			end
			Diagnostics.raise("bake/missing-field", ("entry has no %q field to bake"):format(row.field), {
				key = row.field,
				expected = ("a value for attribute %q"):format(row.attribute),
				fix = "add the field, or mark the mapping row optional",
			})
		end
		if not Diagnostics.isScalar(value) then
			Diagnostics.raise("bake/not-attribute-shaped", ("field %q cannot become an attribute"):format(row.field), {
				key = row.field,
				actual = Diagnostics.describe(value),
				expected = "a string, finite number, or boolean",
				contract = "an attribute carries a scalar, never a structure",
			})
		end
		table.insert(plan, { key = row.attribute, value = value :: AttributeValue })
	end
	return plan
end

local function renderValue(value: AttributeValue): string
	if type(value) == "string" then
		return string.format("%q", value)
	elseif type(value) == "number" then
		return ("%.17g"):format(value)
	end
	return tostring(value)
end

local function isDataValue(value: unknown): boolean
	if Diagnostics.isScalar(value) then
		return true
	end
	if type(value) ~= "table" then
		return false
	end
	local candidate = value :: { [any]: any }
	local arrayCount = #candidate
	local totalCount = 0
	for _ in candidate do
		totalCount += 1
	end
	if arrayCount == totalCount then
		for index = 1, arrayCount do
			if not isDataValue(candidate[index]) then
				return false
			end
		end
		return true
	end
	for key, item in candidate do
		if type(key) ~= "string" then
			return false
		end
		if not isDataValue(item) then
			return false
		end
	end
	return true
end

local function renderDataValue(value: unknown, indent: string): string
	if type(value) == "string" then
		return string.format("%q", value)
	elseif type(value) == "number" then
		return ("%.17g"):format(value)
	elseif type(value) == "boolean" then
		return tostring(value)
	end

	local candidate = value :: { [any]: any }
	local arrayCount = #candidate
	local totalCount = 0
	for _ in candidate do
		totalCount += 1
	end
	local childIndent = indent .. "\t"

	if arrayCount == totalCount then
		if arrayCount == 0 then
			return "{}"
		end
		local pieces: { string } = {}
		for index = 1, arrayCount do
			table.insert(pieces, childIndent .. renderDataValue(candidate[index], childIndent) .. ",")
		end
		return "{\n" .. table.concat(pieces, "\n") .. "\n" .. indent .. "}"
	end

	local keys: { string } = {}
	for key in candidate do
		table.insert(keys, key :: string)
	end
	table.sort(keys)
	local pieces: { string } = {}
	for _, key in keys do
		table.insert(
			pieces,
			childIndent .. ("[%q] = "):format(key) .. renderDataValue(candidate[key], childIndent) .. ","
		)
	end
	return "{\n" .. table.concat(pieces, "\n") .. "\n" .. indent .. "}"
end

local function dataModule(spec: DataSpec, outPath: string?): string
	if type(spec) ~= "table" then
		Diagnostics.raise("bake/not-a-spec", "Author.bake.dataModule was not given a spec table", {
			actual = Diagnostics.describe(spec),
			expected = "a table with name, idKey, and entries",
		})
	end
	if type(spec.name) ~= "string" or spec.name == "" then
		Diagnostics.raise("bake/missing-name", "the spec has no name", {
			actual = Diagnostics.describe(spec.name),
			expected = "a non-empty string",
		})
	end
	if type(spec.idKey) ~= "string" or spec.idKey == "" then
		Diagnostics.raise("bake/missing-id-key", "the spec has no idKey", {
			actual = Diagnostics.describe(spec.idKey),
			expected = "the name of the record field that carries the identity",
		})
	end
	if type(spec.entries) ~= "table" then
		Diagnostics.raise("bake/missing-entries", "the spec has no entries array", {
			actual = Diagnostics.describe(spec.entries),
			expected = "an array of plain record tables",
		})
	end

	local ids: { string } = {}
	local seen: { [string]: true } = {}
	local byId: { [string]: DataRecord } = {}

	for index, entry in ipairs(spec.entries) do
		if type(entry) ~= "table" then
			Diagnostics.raise("bake/entry-not-a-table", ("entry %d is not a table"):format(index), {
				index = index,
				actual = Diagnostics.describe(entry),
				expected = "a plain record table",
			})
		end
		local record = entry :: DataRecord
		local id = record[spec.idKey]
		if type(id) ~= "string" or id == "" then
			Diagnostics.raise("bake/entry-missing-id", ("entry %d has no %q id field"):format(index, spec.idKey), {
				index = index,
				key = spec.idKey,
				actual = Diagnostics.describe(id),
				expected = "a non-empty string",
				contract = "a data module dispatches on ids of its own",
			})
		end
		local recordId = id :: string
		if seen[recordId] ~= nil then
			Diagnostics.raise("bake/duplicate-id", ("id %q appears more than once in %q"):format(recordId, spec.name), {
				entryId = recordId,
				contract = "a data module dispatches on unique ids",
				fix = "remove or rename the duplicate entry",
			})
		end
		seen[recordId] = true
		table.insert(ids, recordId)

		for key, fieldValue in record do
			if type(key) ~= "string" then
				Diagnostics.raise("bake/not-data-shaped", ("entry %q has a non-string field key"):format(recordId), {
					entryId = recordId,
					actual = Diagnostics.describe(key),
					expected = "a string field name",
				})
			end
			if not isDataValue(fieldValue) then
				Diagnostics.raise(
					"bake/not-data-shaped",
					("field %q of entry %q cannot become data"):format(key, recordId),
					{
						entryId = recordId,
						key = key,
						actual = Diagnostics.describe(fieldValue),
						expected = "a string, finite number, boolean, or nested table of them",
						contract = "a data record carries plain data, never a function or userdata",
					}
				)
			end
		end

		byId[recordId] = record
	end
	table.sort(ids)

	local bodyLines: { string } = {
		"export type DataValue = string | number | boolean | { DataValue } | { [string]: DataValue }",
		"",
		"--- One authored record; the id itself lives in the surrounding table's key.",
		"export type Record = { [string]: DataValue }",
		"",
		"local RECORDS: { [string]: Record } = {",
	}

	for _, id in ids do
		table.insert(bodyLines, ("\t[%q] = %s,"):format(id, renderDataValue(byId[id], "\t")))
	end

	table.insert(bodyLines, "}")
	table.insert(bodyLines, "")
	table.insert(bodyLines, "return RECORDS")

	local body = table.concat(bodyLines, "\n")
	local bodyDigest = Digest.digestText(body)
	local recordsDigest = Digest.digestText(Digest.canonical(byId))

	local headerLines: { string } = {
		"--!strict",
		"--[[",
		"\tGENERATED FILE -- do not edit; regenerate instead.",
		"",
		"\tgenerator: Author.bake.dataModule (authoring/bake.luau)",
		("\tname: %s"):format(spec.name),
		("\trecords digest: %s"):format(recordsDigest),
		("\tbody digest: %s"):format(bodyDigest),
		"]]",
		"",
	}

	local source = table.concat(headerLines, "\n") .. "\n" .. body .. "\n"

	if outPath ~= nil then
		fs.writeStringToFile(outPath, source)
	end

	return source
end

local function registryModule(spec: RegistrySpec, outPath: string?): string
	local set = spec.set

	local ids: { string } = {}
	local seen: { [string]: true } = {}
	for _, entry in set.entries do
		local id = set:idOf(entry)
		if seen[id] ~= nil then
			Diagnostics.raise("bake/duplicate-id", ("id %q appears more than once in set %q"):format(id, set.name), {
				set = set.name,
				entryId = id,
				contract = "a registry dispatches on unique ids",
				fix = "run Author.validate with unique = true and fix the authored data",
			})
		end
		seen[id] = true
		table.insert(ids, id)
	end
	table.sort(ids)

	local mappingEntries: { Entry } = {}
	for _, row in spec.mapping do
		local entry: Entry = { field = row.field, attribute = row.attribute, optional = row.optional }
		table.insert(mappingEntries, entry)
	end
	local mappingDigest = Digest.digest(Set.set {
		name = "mapping",
		idKey = "attribute",
		entries = mappingEntries,
	})

	local bodyLines: { string } = {
		"export type AttributeValue = string | number | boolean",
		"",
		"--- One baked attribute write, in plan order.",
		"export type PlannedAttribute = { key: string, value: AttributeValue }",
		"",
		"--- The host-specific setter the application supplies. This module plans",
		"--- attribute writes; it never performs one itself.",
		"export type SetAttribute = (node: unknown, key: string, value: AttributeValue) -> ()",
		"",
		"--- The public mount-point surface this module touches: `parent`, the node the",
		"--- slot belongs to. Structurally compatible with Compose's MountPoint.",
		"export type MountPoint = { parent: unknown }",
		"",
		"export type Directive = (mountPoint: MountPoint) -> ()",
		"",
		('local SET_NAME = "%s"'):format(set.name),
		"",
		"--- Every entry's attribute plan, keyed by id: the attribute-to-entry join.",
		"local PLAN: { [string]: { PlannedAttribute } } = {",
	}

	for _, id in ids do
		local entry = set:byId(id) :: Entry
		table.insert(bodyLines, ("\t[%q] = {"):format(id))
		for _, planned in attributePlan(entry, spec.mapping) do
			table.insert(bodyLines, ("\t\t{ key = %q, value = %s },"):format(planned.key, renderValue(planned.value)))
		end
		table.insert(bodyLines, "\t},")
	end

	local tail = ([[
}

--- The plan for `id`. Refuses an id the registry was not baked with, because a
--- silent nil here is how an authored entry disappears without a trace.
local function planFor(id: string): { PlannedAttribute }
	local plan = PLAN[id]
	if plan == nil then
		error(("%s[registry/unknown-id]: %%q is not an id in set %%q"):format(id, SET_NAME), 2)
	end
	return plan
end

--- An attribute-setter directive: mounted into a slot, it applies the entry's
--- plan to the slot's parent node through the supplied setter, in plan order.
local function apply(id: string, setAttribute: SetAttribute): Directive
	local plan = planFor(id)
	return function(mountPoint: MountPoint)
		for _, planned in plan do
			setAttribute(mountPoint.parent, planned.key, planned.value)
		end
	end
end

return {
	setName = SET_NAME,
	plan = PLAN,
	planFor = planFor,
	apply = apply,
}
]]):format(spec.name)

	table.insert(bodyLines, tail)
	local body = table.concat(bodyLines, "\n")
	local bodyDigest = Digest.digestText(body)

	local headerLines: { string } = {
		"--!strict",
		"--[[",
		"\tGENERATED FILE -- do not edit; regenerate instead.",
		"",
		"\tgenerator: Author.bake.registryModule (authoring/bake.luau)",
		("\tset: %s"):format(set.name),
		("\tset digest: %s"):format(Digest.digest(set)),
		("\tmapping digest: %s"):format(mappingDigest),
		("\tbody digest: %s"):format(bodyDigest),
		"]]",
		"",
	}

	local source = table.concat(headerLines, "\n") .. "\n" .. body

	if outPath ~= nil then
		fs.writeStringToFile(outPath, source)
	end

	return source
end

return {
	attributePlan = attributePlan,
	registryModule = registryModule,
	dataModule = dataModule,
}
