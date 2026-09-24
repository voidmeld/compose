--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

type Message = { id: number, body: string }
type Combatant = { id: number, x: number, y: number, z: number }

local function chat(): (number, number)
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors
	local cell = Compose.cell

	local ROW = 20
	local messages = table.create(10000) :: { Message }
	for index = 1, 10000 do
		messages[index] = { id = index, body = "message " .. index }
	end
	local history = cell(messages)
	local viewport = cell({ offset = 10000 * ROW - 120, size = 120 } :: Compose.OrderedCollectionViewport)
	local status = cell({} :: Compose.OrderedCollectionStatus)

	local dispose, root = runtime.mount(function()
		return Host.Frame {
			Compose.OrderedCollection {
				from = history,
				key = function(message: Message): number
					return message.id
				end,

				mode = "windowed",
				viewport = viewport,
				layout = { itemSize = ROW } :: Compose.OrderedCollectionLayout,
				follow = "end",
				status = status,

				render = function(message, placement)
					return Host.Line {
						Text = function(use)
							return use(message).body
						end,
						Offset = function(use)
							return use(placement).offset
						end,
					}
				end,
			},
		}
	end, test.root)

	local mounted = #test.childrenOf(root)
	assert(status:peek().total == 10000, "the whole history is not there")
	assert(mounted == 6, "a windowed chat mounted more than its viewport")
	assert(status:peek().following, "a chat parked at the bottom is not following")

	local grown = table.clone(messages)
	table.insert(grown, { id = 10001, body = "message 10001" })
	test.resetCounts()
	history:set(grown)
	runtime:settle()

	assert(status:peek().following, "an append disengaged the follow")
	assert(status:peek().desiredOffset == 10001 * ROW - 120, "the follow did not target the new end")

	local built = test.counts().createNode
	assert(built == 1, "following the end did not mount the appended message")
	viewport:set { offset = status:peek().desiredOffset :: number, size = 120 }
	runtime:settle()
	assert(status:peek().desiredOffset == nil, "the applied scroll request remained pending")
	assert(test.counts().createNode == built, "acknowledging the scroll rebuilt a retained message")

	dispose()
	assert(test.liveNodes() == 1, "the chat leaked")
	return mounted, built
end

local function battlefield(): (number, number)
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors
	local cell = Compose.cell

	local units = table.create(4000) :: { Combatant }
	for index = 1, 4000 do
		units[index] = { id = index, x = (index - 1) * 10, y = 0, z = 0 }
	end
	local combatants = cell(units)
	local camera = cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
	local pinned = cell({} :: { [number]: boolean })
	local status = cell({} :: Compose.SpatialCollectionStatus)

	local dispose, field = runtime.mount(function()
		return Host.Frame {
			Compose.SpatialCollection {
				from = combatants,
				key = function(unit: Combatant): number
					return unit.id
				end,
				position = function(unit: Combatant): (number, number, number)
					return unit.x, unit.y, unit.z
				end,

				origin = camera,
				cellSize = 64,
				hysteresis = 24,
				tiers = {
					{ name = "full", radius = 80 },
					{ name = "simplified", radius = 180 },
					{ name = "marker", radius = 300 },
				},
				pinned = pinned,
				status = status,

				render = function(unit, representation)
					return Host.Unit {
						Id = function(use)
							return use(unit).id
						end,
						Tier = function(use)
							return use(representation).name
						end,
					}
				end,
			},
		}
	end, test.root)

	local published = status:peek()
	assert(published.total == 4000, "the whole population is not there")
	assert(published.queried < 200, "the broad phase scanned too much of the world")
	local retained = published.retained

	pinned:set { [400] = true }
	runtime:settle()
	local pinnedTier: string? = nil
	for _, child in test.childrenOf(field) do
		if test.propertyOf(child, "Id") == 400 then
			pinnedTier = tostring(test.propertyOf(child, "Tier"))
		end
	end
	assert(pinnedTier == "marker", "a pinned objective was not retained as a marker")

	test.resetCounts()
	for _ = 1, 20 do
		camera:set { x = 1, y = 0, z = 0 }
		runtime:settle()
		camera:set { x = 0, y = 0, z = 0 }
		runtime:settle()
	end
	local churn = test.counts().createNode + test.counts().destroyNode
	assert(churn == 0, "jitter on a tier boundary caused churn")

	dispose()
	assert(test.liveNodes() == 1, "the battlefield leaked")
	return retained, published.queried
end

local function run(): string
	local mounted, built = chat()
	local retained, queried = battlefield()
	return ("chat %d/%d built %d | field %d of 4000, queried %d"):format(mounted, 10000, built, retained, queried)
end

return {
	name = "collections",
	what = "a windowed chat and a relevance-retained battlefield, both doing work proportional to what is visible",
	expected = "chat 6/10000 built 1 | field 31 of 4000, queried 39",
	run = run,
}
