--!strict
--!nolint DeprecatedApi

type Environment = {
	pcall: (target: unknown, ...unknown) -> (boolean, ...unknown),
}

local environment: Environment = if getfenv ~= nil then getfenv(0) else _G
local protectedCall = environment.pcall

local function results(ok: boolean, ...: unknown): ...unknown
	if not ok then
		error((...), 0)
	end
	return ...
end

local function invoke(target: unknown, ...: unknown): ...unknown
	return results(protectedCall(target, ...))
end

local function indexed(object: { [unknown]: unknown }, key: unknown): unknown
	return object[key]
end

local function read(object: unknown, key: unknown): unknown
	return (invoke(indexed, object, key))
end

return { invoke = invoke, read = read }
