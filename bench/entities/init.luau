--!strict

local Churn = require "@self/churn"
local Integrated = require "@self/integrated"
local Relevance = require "@self/relevance"
local Types = require "@self/../scenarios/types"

local all: { Types.Scenario } = {
	Integrated.integrated,
	Relevance.sweep,
	Relevance.saturated,
	Churn.churnLight,
	Churn.churn,
	Churn.churnHeavy,
}

return {
	all = all,
}
