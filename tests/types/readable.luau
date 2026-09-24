--!strict

local Types = require "../../src/core/reactive/types"

type Phase = "loading" | "ready"
type Edge = { index: number }

local cell: <T>(initial: Types.Initial<T>, equals: Types.Equals<T>?) -> Types.Cell<T> = nil :: any

local annotatedPhase: Types.Cell<Phase> = cell("loading" :: Phase)
local annotatedEdge: Types.Cell<Edge?> = cell(nil :: Edge?)

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
	annotatedPhase = annotatedPhase,
	annotatedEdge = annotatedEdge,
	cellAsReadable = cellAsReadable,
	plainValueAsGiven = plainValueAsGiven,
	cellAsGiven = cellAsGiven,
	formulaAsGiven = formulaAsGiven,
	bodyAsGiven = bodyAsGiven,
	sourceAsGiven = sourceAsGiven,
}
