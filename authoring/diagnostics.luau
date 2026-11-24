--!strict

export type Fields = {
	read set: string?,
	read entryId: string?,
	read key: string?,
	read index: number?,
	read expected: string?,
	read actual: string?,
	read contract: string?,
	read fix: string?,
	read detail: string?,
}

export type RojoValue = string | number | boolean | { number } | { [string]: RojoValue }

local function format(code: string, summary: string, fields: Fields?): string
	local lines = { ("Authoring[%s]: %s"):format(code, summary) }

	if fields ~= nil then
		local function line(name: string, value: (string | number)?)
			if value ~= nil then
				table.insert(lines, ("  %s: %s"):format(name, tostring(value)))
			end
		end
		line("set", fields.set)
		line("entryId", fields.entryId)
		line("key", fields.key)
		line("index", fields.index)
		line("expected", fields.expected)
		line("actual", fields.actual)
		line("contract", fields.contract)
		line("fix", fields.fix)
		line("detail", fields.detail)
	end

	return table.concat(lines, "\n")
end

local function raise<R...>(code: string, summary: string, fields: Fields?): R...
	error(format(code, summary, fields), 0)
end

local function describe(value: unknown): string
	local kind = type(value)
	if type(value) == "string" then
		return string.format("%q", value)
	elseif kind == "number" or kind == "boolean" then
		return tostring(value)
	end
	return "<" .. kind .. ">"
end

local function isScalar(value: unknown): boolean
	local kind = type(value)
	if kind == "string" or kind == "boolean" then
		return true
	end
	if kind == "number" then
		local number = value
		return number == number and number ~= math.huge and number ~= -math.huge
	end
	return false
end

local function fields(value: unknown): { [unknown]: unknown }?
	if type(value) ~= "table" then
		return nil
	end
	local result: { [unknown]: unknown } = {}
	for key, item in value do
		result[key] = item
	end
	return result
end

local function isFiniteNumberArray(value: unknown): boolean
	if type(value) ~= "table" then
		return false
	end
	local count = 0
	for key, element in value do
		if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
			return false
		end
		if not isScalar(element) or type(element) ~= "number" then
			return false
		end
		count += 1
	end
	return count == #value
end

local function isRojoValue(value: unknown): boolean
	if isScalar(value) then
		return true
	end
	if type(value) ~= "table" then
		return false
	end
	local candidate = value
	if isFiniteNumberArray(candidate) then
		return true
	end
	local count = 0
	for tableKey, tableValue in candidate do
		count += 1
		if count > 1 or type(tableKey) ~= "string" then
			return false
		end
		if not isRojoValue(tableValue) then
			return false
		end
	end
	return count == 1
end

local function copyRojoValue(value: RojoValue): RojoValue
	if type(value) ~= "table" then
		return value
	end
	local array: { number } = {}
	local object: { [string]: RojoValue } = {}
	local isArray = false
	for key, element in value do
		if type(key) == "number" then
			assert(type(element) == "number")
			array[key] = element
			isArray = true
		else
			object[key] = copyRojoValue(element)
		end
	end
	return if isArray then array else object
end

return {
	raise = raise,
	format = format,
	describe = describe,
	fields = fields,
	isScalar = isScalar,
	isRojoValue = isRojoValue,
	copyRojoValue = copyRojoValue,
}
