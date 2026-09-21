--!strict

local Types = require "../../src/core/reactive/types"

local function cellAsReadable<T>(value: Types.Cell<T>): Types.Readable<T>
	return value
end

local function plainValueAsGiven(value: number): Types.Given<number>
	return value
end

local function cellAsGiven<T>(value: Types.Cell<T>): Types.Given<T>
	return value
end

local function formulaAsGiven<T>(value: Types.Formula<T>): Types.Given<T>
	return value
end

local function bodyAsGiven<T>(value: Types.Body<T>): Types.Given<T>
	return value
end

local function sourceAsGiven<T>(value: Types.Source<T>): Types.Given<T>
	return value
end

return {
	cellAsReadable = cellAsReadable,
	plainValueAsGiven = plainValueAsGiven,
	cellAsGiven = cellAsGiven,
	formulaAsGiven = formulaAsGiven,
	bodyAsGiven = bodyAsGiven,
	sourceAsGiven = sourceAsGiven,
}
