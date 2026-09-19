--!strict

local Diagnostics = require "./diagnostics"
local Set = require "./set"

type EntrySet = Set.EntrySet

local function canonical(value: unknown): string
	local kind = type(value)
	if kind == "string" then
		local text = value :: string
		return ("s%d:%s"):format(#text, text)
	elseif kind == "number" then
		return ("n:%.17g"):format(value :: number)
	elseif kind == "boolean" then
		return "b:" .. tostring(value)
	elseif kind == "table" then
		local subject = value :: { [unknown]: unknown }
		local pieces: { string } = { "[" }
		local count = #subject
		for index = 1, count do
			table.insert(pieces, canonical(subject[index]))
			table.insert(pieces, ",")
		end
		local keyed: { string } = {}
		for key, item in pairs(subject) do
			if type(key) == "number" and key >= 1 and key <= count and key % 1 == 0 then
				continue
			end
			table.insert(keyed, canonical(key) .. "=" .. canonical(item))
		end
		table.sort(keyed)
		table.insert(pieces, "|")
		table.insert(pieces, table.concat(keyed, ","))
		table.insert(pieces, "]")
		return table.concat(pieces)
	end
	Diagnostics.raise("set/not-digestable", "a value of this type has no canonical form", {
		actual = kind,
		expected = "string, number, boolean, or a table of them",
		contract = "authored content is plain data",
	})
	return ""
end

local function lane(text: string, seed: number): number
	local hash = seed
	for index = 1, #text do
		hash = bit32.bxor(hash, string.byte(text, index))
		local low = bit32.band(hash, 0xFFFF) * 16777619
		local high = bit32.rshift(hash, 16) * 16777619
		hash = bit32.band(low + bit32.lshift(bit32.band(high, 0xFFFF), 16), 0xFFFFFFFF)
	end
	return hash
end

local function digest(set: EntrySet): string
	local entries = table.create(#set.entries)
	for _, entry in set.entries do
		table.insert(entries, canonical(entry))
	end
	table.sort(entries)

	local header = {
		("s%d:%s"):format(#set.name, set.name),
		("s%d:%s"):format(#set.idKey, set.idKey),
		if set.role ~= nil then "role=" .. canonical(set.role) else "",
		if set.roleKey ~= nil then "roleKey=" .. canonical(set.roleKey) else "",
	}
	local text = table.concat(header, ";") .. ";" .. table.concat(entries, ";")

	return ("%08x%08x"):format(lane(text, 2166136261), lane(text, 0x811C9DC7))
end

local function digestText(text: string): string
	return ("%08x%08x"):format(lane(text, 2166136261), lane(text, 0x811C9DC7))
end

return {
	canonical = canonical,
	digest = digest,
	digestText = digestText,
}
