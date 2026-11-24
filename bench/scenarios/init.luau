--!strict

local Dense = require "@self/dense"
local Mixed = require "@self/mixed"
local Spatial = require "@self/spatial"
local Scene2d = require "@self/scene-2d"
local Virtual = require "@self/virtual"
local Types = require "@self/types"

local all: { Types.Scenario } = {
	Dense.dashboard,
	Scene2d.scene2d,
	Dense.entityLabels,
	Dense.entityLabelsSparse,
	Virtual.filteredList,
	Virtual.grid,
	Mixed.animatedNavigation,
	Mixed.sessionCycle,
	Mixed.inspector,
	Spatial.spatial,
}

return {
	all = all,
}
