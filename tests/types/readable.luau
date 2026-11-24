--!strict

local Types = require "../../src/core/reactive/types"
local cellModule = require "../../src/core/reactive/cell"

type Phase = "loading" | "ready"
type Edge = { index: number }

local cell = cellModule.cell

local initialPhase: Phase = "loading"
local annotatedPhase: Types.Value<Phase> = cell(initialPhase)
local noEdge: Edge? = nil
local annotatedEdge: Types.Value<Edge?> = cell(noEdge)

local function valueAsReadOnly<T>(value: Types.ReadOnlyValue<T>): Types.ReadOnlyValue<T>
	return value
end

local function plainValueAsInput(value: number): Types.Input<number>
	return value
end

local function valueAsInput<T>(value: Types.Value<T>): Types.Input<T>
	return value
end

local function readOnlyAsSource<T>(value: Types.ReadOnlyValue<T>): Types.Source<T>
	return value
end

local function bodyAsInput<T>(value: Types.Body<T>): Types.Input<T>
	return value
end

local function sourceAsInput<T>(value: Types.Source<T>): Types.Input<T>
	return value
end

return {
	annotatedPhase = annotatedPhase,
	annotatedEdge = annotatedEdge,
	valueAsReadOnly = valueAsReadOnly,
	plainValueAsInput = plainValueAsInput,
	valueAsInput = valueAsInput,
	readOnlyAsSource = readOnlyAsSource,
	bodyAsInput = bodyAsInput,
	sourceAsInput = sourceAsInput,
}
