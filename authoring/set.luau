--!strict

local Diagnostics = require "./diagnostics"

export type Entry = { [string]: unknown }

export type SetOptions = {
	name: string,
	idKey: string,

	entries: { Entry },
	role: string?,
	roleKey: string?,
}

export type EntrySet = {
	name: string,
	idKey: string,
	entries: { Entry },
	role: string?,
	roleKey: string?,
	byId: (self: EntrySet, id: string) -> Entry?,
	byRole: (self: EntrySet, role: string) -> { Entry },
	idOf: (self: EntrySet, entry: Entry) -> string,
	roleOf: (self: EntrySet, entry: Entry) -> string?,
}

local function byId(self: EntrySet, id: string): Entry?
	for _, entry in self.entries do
		if entry[self.idKey] == id then
			return entry
		end
	end
	return nil
end

local function byRole(self: EntrySet, role: string): { Entry }
	local found: { Entry } = {}
	for _, entry in self.entries do
		if self:roleOf(entry) == role then
			table.insert(found, entry)
		end
	end
	return found
end

local function idOf(self: EntrySet, entry: Entry): string
	return entry[self.idKey] :: string
end

local function roleOf(self: EntrySet, entry: Entry): string?
	if self.role ~= nil then
		return self.role
	end
	local roleKey = self.roleKey
	if roleKey == nil then
		return nil
	end
	local role = entry[roleKey]
	if type(role) == "string" then
		return role
	end
	return nil
end

local function set(options: SetOptions): EntrySet
	if type(options) ~= "table" then
		Diagnostics.raise("set/not-a-declaration", "Author.set was not given a declaration table", {
			actual = Diagnostics.describe(options),
			expected = "a table with name, idKey, and entries",
		})
	end
	if type(options.name) ~= "string" or options.name == "" then
		Diagnostics.raise("set/missing-name", "the declaration has no name", {
			actual = Diagnostics.describe(options.name),
			expected = "a non-empty string",
			contract = "violations, digests, and generated headers all name their set",
		})
	end
	if type(options.idKey) ~= "string" or options.idKey == "" then
		Diagnostics.raise("set/missing-id-key", "the declaration has no idKey", {
			set = options.name,
			actual = Diagnostics.describe(options.idKey),
			expected = "the name of the entry field that carries the identity",
		})
	end
	if options.role ~= nil and options.roleKey ~= nil then
		Diagnostics.raise("set/role-conflict", "the declaration names both a fixed role and a roleKey", {
			set = options.name,
			contract = "an entry's role comes from exactly one place",
			fix = "keep role for a homogeneous set, roleKey for a mixed one",
		})
	end
	if type(options.entries) ~= "table" then
		Diagnostics.raise("set/missing-entries", "the declaration has no entries array", {
			set = options.name,
			actual = Diagnostics.describe(options.entries),
			expected = "an array of plain entry tables",
		})
	end
	for index, entry in ipairs(options.entries) do
		if type(entry) ~= "table" then
			Diagnostics.raise("set/entry-not-a-table", ("entry %d is not a table"):format(index), {
				set = options.name,
				index = index,
				actual = Diagnostics.describe(entry),
				expected = "a plain table of authored fields",
			})
		end
		local id = (entry :: Entry)[options.idKey]
		if type(id) ~= "string" or id == "" then
			Diagnostics.raise("set/entry-missing-id", ("entry %d has no %q id field"):format(index, options.idKey), {
				set = options.name,
				index = index,
				key = options.idKey,
				actual = Diagnostics.describe(id),
				expected = "a non-empty string",
				contract = "every entry carries its idKey as a string",
			})
		end
	end

	return {
		name = options.name,
		idKey = options.idKey,
		entries = options.entries,
		role = options.role,
		roleKey = options.roleKey,
		byId = byId,
		byRole = byRole,
		idOf = idOf,
		roleOf = roleOf,
	}
end

return {
	set = set,
}
