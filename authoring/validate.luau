--!strict

local Diagnostics = require "./diagnostics"
local Set = require "./set"

type Entry = Set.Entry
type EntrySet = Set.EntrySet

export type RefRule = {
	field: string,
	into: EntrySet?,
	oneOf: { string }?,
}

export type Rules = {
	idPattern: string?,
	unique: boolean?,
	required: { string }?,
	refs: { RefRule }?,
}

export type Violation = {
	setName: string,
	entryId: string,
	rule: "idPattern" | "unique" | "required" | "refs",
	detail: string,
}

local function quoteList(values: { string }): string
	local quoted = table.create(#values)
	for _, value in values do
		table.insert(quoted, string.format("%q", value))
	end
	return table.concat(quoted, ", ")
end

local function validate(set: EntrySet, rules: Rules): (boolean, { Violation })
	local refs = rules.refs
	if refs ~= nil then
		for index, rule in ipairs(refs) do
			if rule.into == nil and rule.oneOf == nil then
				Diagnostics.raise(
					"rules/refs-without-target",
					("refs rule %d has neither into nor oneOf"):format(index),
					{
						set = set.name,
						key = rule.field,
						expected = "into = <EntrySet> or oneOf = { ... }",
						contract = "a reference rule names what it references",
					}
				)
			end
		end
	end

	local violations: { Violation } = {}
	local function violate(entryId: string, rule: "idPattern" | "unique" | "required" | "refs", detail: string)
		table.insert(violations, { setName = set.name, entryId = entryId, rule = rule, detail = detail })
	end

	local firstIndexOf: { [string]: number } = {}
	for index, entry in ipairs(set.entries) do
		local id = set:idOf(entry)

		if rules.idPattern ~= nil and string.match(id, rules.idPattern) == nil then
			violate(id, "idPattern", ("id %q does not match pattern %q"):format(id, rules.idPattern))
		end

		if rules.unique == true then
			local first = firstIndexOf[id]
			if first ~= nil then
				violate(
					id,
					"unique",
					("id %q appears more than once (first at entry %d, again at entry %d)"):format(id, first, index)
				)
			else
				firstIndexOf[id] = index
			end
		end

		if rules.required ~= nil then
			for _, field in rules.required do
				if entry[field] == nil then
					violate(id, "required", ("required field %q is missing"):format(field))
				end
			end
		end

		if refs ~= nil then
			for _, rule in refs do
				local value = entry[rule.field]
				if value == nil then
					continue
				end
				local into = rule.into
				if into ~= nil then
					if type(value) ~= "string" or into:byId(value) == nil then
						violate(
							id,
							"refs",
							("field %q = %s is not an id in set %q"):format(
								rule.field,
								Diagnostics.describe(value),
								into.name
							)
						)
					end
				end
				local oneOf = rule.oneOf
				if oneOf ~= nil and (type(value) ~= "string" or table.find(oneOf, value) == nil) then
					violate(
						id,
						"refs",
						("field %q = %s is not one of: %s"):format(
							rule.field,
							Diagnostics.describe(value),
							quoteList(oneOf)
						)
					)
				end
			end
		end
	end

	return #violations == 0, violations
end

return {
	validate = validate,
}
