--!strict

local Environment = require "../cost-model"
local Types = require "./types"

local reason =
	"Iris emits its own immediate-mode widget hierarchy, not arbitrary retained Instance trees. Its widgets cannot match this workload's observable tree or retained identity contract."

local function create(_environment: Environment.Environment): Types.Driver
	error(reason, 0)
end

return {
	create = create,
	unsupported = function(_id: string): string
		return reason
	end,
}
