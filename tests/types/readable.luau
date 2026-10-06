--!strict

local Types = require "../../src/core/reactive/types"
local cellModule = require "../../src/core/reactive/cell"

type Phase = "loading" | "ready"
type Edge = { index: number }

local cell = cellModule.cell

local annotatedPhase: Types.Cell<Phase> = cell("loading" :: Phase)
local annotatedEdge: Types.Cell<Edge?> = cell(nil :: Edge?)

local function cellAsReadable<T>(value: Types.Cell<T>): Types.Readable<T>
	return value
end

local function formulaAsReadable<T>(value: Types.Formula<T>): Types.Readable<T>
	return value
end

local function plainValueAsValue(value: number): Types.Value<number>
	return value
end

local function cellAsValue<T>(value: Types.Cell<T>): Types.Value<T>
	return value
end

local function formulaAsValue<T>(value: Types.Formula<T>): Types.Value<T>
	return value
end

local function bodyAsValue<T>(value: Types.Body<T>): Types.Value<T>
	return value
end

local function sourceAsValue<T>(value: Types.Source<T>): Types.Value<T>
	return value
end

return {
	annotatedPhase = annotatedPhase,
	annotatedEdge = annotatedEdge,
	cellAsReadable = cellAsReadable,
	formulaAsReadable = formulaAsReadable,
	plainValueAsValue = plainValueAsValue,
	cellAsValue = cellAsValue,
	formulaAsValue = formulaAsValue,
	bodyAsValue = bodyAsValue,
	sourceAsValue = sourceAsValue,
}
