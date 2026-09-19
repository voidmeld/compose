--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

type Combatant = { userId: number, name: string, pose: number, fade: number, tint: number }

type Store = {
	combatants: { Combatant },
	daylight: boolean,
	listeners: { (Store) -> () },
}

local function publish(store: Store)
	for _, listener in table.clone(store.listeners) do
		listener(store)
	end
end

local function run(): string
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)

	local cell = Compose.cell
	local cleanup = Compose.cleanup
	local event = Compose.event
	local group = Compose.group
	local keyed = Compose.keyed
	local show = Compose.show

	local portal = Compose.portal

	local Host = runtime.constructors

	test.declareEvent("Button", "Activated")

	local playerGui = test.makeNode "PlayerGui"

	local store: Store = {
		combatants = {
			{ userId = 1, name = "ada", pose = 10, fade = 0, tint = 200 },
			{ userId = 2, name = "grace", pose = 20, fade = 0, tint = 40 },
		},
		daylight = true,
		listeners = {},
	}

	local function Fighter(unit: Compose.Readable<Combatant>, index: Compose.Readable<number>)
		return Host.Part {
			LayoutOrder = index,
			[group { "Pose", "Fade", "Tint" }] = function(use)
				local it = use(unit)
				return it.pose, it.fade, it.tint
			end,
		}
	end

	local function Scoreboard(combatants: Compose.Readable<{ Combatant }>)
		local expanded = cell(false)

		return Host.Frame "Scoreboard" {
			Host.Button "Toggle" {

				Text = function(use: Compose.Use)
					if use(expanded) then
						return "Hide"
					end
					return ("%d fighting"):format(#use(combatants))
				end,
				[event "Activated"] = function()
					expanded:set(not expanded:peek())
				end,
			},

			show(expanded, function()
				return Host.Frame "Rows" {
					keyed {
						from = combatants,
						render = function(unit, index)
							return Host.Label {
								LayoutOrder = index,
								Text = function(use)
									return use(unit).name
								end,
							}
						end,
						key = function(unit: Combatant)
							return unit.userId
						end,
					},
				}
			end),
		}
	end

	local function Arena()
		local combatants = cell(store.combatants)
		local daylight = cell(store.daylight)

		local function onChange(snapshot: Store)
			runtime:batch(function()
				combatants:set(snapshot.combatants)
				daylight:set(snapshot.daylight)
			end)
		end
		table.insert(store.listeners, onChange)
		cleanup(function()
			local at = table.find(store.listeners, onChange)
			if at ~= nil then
				table.remove(store.listeners, at)
			end
		end)

		return Host.Model "Arena" {
			Host.Part "Ground" { Anchored = true },

			Host.Part "SunLamp" {
				Anchored = true,
				Host.Attachment "Emitter" {
					Host.PointLight "Sun" {
						Brightness = function(use)
							return if use(daylight) then 3 else 0.4
						end,
					},
				},
			},

			Host.Folder "Combatants" {
				keyed {
					from = combatants,
					render = Fighter,
					key = function(unit: Combatant)
						return unit.userId
					end,
				},
			},

			portal(playerGui, function()
				return { Host.ScreenGui "ArenaHud" { Scoreboard(combatants) } }
			end),
		}
	end

	local dispose, arena = runtime.mount(Arena, test.root)

	local function child(parent: Compose.Node, name: string): Compose.Node
		for _, candidate in test.childrenOf(parent) do
			if Compose.labelOf(candidate) == name or test.propertyOf(candidate, "Name") == name then
				return candidate
			end
		end
		error(("no child %q"):format(name))
	end

	local sun = child(child(child(arena, "SunLamp"), "Emitter"), "Sun")
	local combatantsFolder = child(arena, "Combatants")
	local hud = child(playerGui, "ArenaHud")
	local scoreboard = child(hud, "Scoreboard")
	local toggle = child(scoreboard, "Toggle")

	local labelled = Compose.labelOf(sun)

	store.combatants = {
		{ userId = 2, name = "grace", pose = 21, fade = 0.5, tint = 40 },
		{ userId = 3, name = "alan", pose = 30, fade = 0, tint = 90 },
		{ userId = 1, name = "ada", pose = 11, fade = 0, tint = 200 },
	}
	store.daylight = false
	publish(store)
	runtime:settle()

	local brightness = test.propertyOf(sun, "Brightness")
	local fighters = #test.childrenOf(combatantsFolder)

	test.dispatch(toggle, "Activated")
	runtime:settle()
	local rows = #test.childrenOf(child(scoreboard, "Rows"))

	dispose()

	assert(test.isAlive(playerGui), "disposal destroyed the borrowed Gui container")
	assert(#test.childrenOf(playerGui) == 0, "disposal left the portalled interface behind")
	assert(test.liveNodes() == 2, "disposal left nodes behind")
	assert(#store.listeners == 0, "disposal left the store subscription behind")

	return ("%s | brightness=%s | fighters=%d | rows=%d | listeners=%d"):format(
		tostring(labelled),
		tostring(brightness),
		fighters,
		rows,
		#store.listeners
	)
end

return {
	name = "arena",
	what = "a whole scene: a root that owns external state, local component state, a keyed collection, and one mount",
	expected = "Sun | brightness=0.4 | fighters=3 | rows=3 | listeners=0",
	run = run,
}
