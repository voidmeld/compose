--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

local function run(): string
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors
	local viewport = Compose.cell({ x = 0, y = 0, width = 96, height = 64 } :: Compose.TileCollectionViewport)
	local edited = Compose.cell("grass" :: string?)
	local reads = 0
	local rectangles: { Compose.FocusRect } = {}
	local dispose, root = runtime.mount(function()
		return Host.Frame {
			Compose.TileCollection {
				viewport = viewport,
				tileSize = { width = 32, height = 32 },
				read = function(use: Compose.Use, column: number, row: number): string?
					reads += 1
					if column < 0 or row < 0 or column >= 1000 or row >= 1000 then
						return nil
					end
					return if column == 1 and row == 0 then use(edited) else "grass"
				end,
				render = function(value: Compose.Readable<string>, placement: Compose.TileCollectionPlacement)
					table.insert(
						rectangles,
						{ x = placement.x, y = placement.y, width = placement.width, height = placement.height }
					)
					return Host.Tile {
						Image = value,
						X = placement.x,
						Y = placement.y,
					}
				end,
			},
		}
	end, test.root)
	assert(reads == 6, "mount scanned beyond the viewport")
	assert(#test.childrenOf(root) == 6, "mount retained more than the visible tiles")
	local selected = Compose.focusNeighbor(rectangles[1], rectangles, "right")
	assert(selected == 2, "directional focus did not reach the adjacent tile")

	test.resetCounts()
	edited:set "water"
	assert(test.counts().setProperty == 1, "editing one tile wrote unrelated host properties")
	assert(test.counts().createNode == 0, "editing a tile rebuilt it")

	test.resetCounts()
	viewport:set { x = 32, y = 0, width = 96, height = 64 }
	assert(test.counts().createNode == 2, "panning rebuilt retained tiles")
	assert(test.counts().destroyNode == 2, "panning kept departed tiles")
	assert(#test.childrenOf(root) == 6, "panning grew the mounted population")
	dispose()
	assert(test.liveNodes() == 1, "tile map disposal leaked nodes")
	return "6 of 1000000 tiles | edit 1 write | pan 2 enter, 2 leave | focus 2"
end

return {
	name = "tile-map",
	what = "a camera window on a tile map with local edits and rectangle focus",
	expected = "6 of 1000000 tiles | edit 1 write | pan 2 enter, 2 leave | focus 2",
	run = run,
}
