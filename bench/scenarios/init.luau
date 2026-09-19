--!strict

local Arcade = require "@self/arcade"
local Game = require "@self/game"
local Mixed = require "@self/mixed"
local Spatial = require "@self/spatial"
local Virtual = require "@self/virtual"
local Types = require "@self/types"

local all: { Types.Scenario } = {
	Game.combatHud,
	Arcade.arcade,
	Game.raidNameplates,
	Game.raidNameplatesSparse,
	Virtual.inventory,
	Virtual.grid,
	Mixed.animatedNavigation,
	Mixed.sessionCycle,
	Mixed.inspector,
	Spatial.spatial,
}

return {
	all = all,
}
