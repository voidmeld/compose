--!strict

local Json = require "@std/json"
local Support = require "../support"

local function value(input: unknown): Json.Value
	if input == nil then
		return nil
	end
	if type(input) == "string" or type(input) == "number" or type(input) == "boolean" then
		return input
	end
	local fields = Support.record(input)
	local array: Json.Array = {}
	local object: Json.Object = {}
	local hasNames = false
	for key, element in fields do
		if type(key) == "string" then
			hasNames = true
			object[key] = value(element)
		else
			assert(type(key) == "number")
			array[key] = value(element)
		end
	end
	return if hasNames then object else array
end

local function object(input: unknown): Json.Object
	local fields = Support.record(input)
	local result: Json.Object = {}
	for key, element in fields do
		assert(type(key) == "string")
		result[key] = value(element)
	end
	return result
end

return { value = value, object = object }
