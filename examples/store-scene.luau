--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

type Member = { id: number, name: string, pose: number, fade: number, tint: number }

type Store = {
	members: { Member },
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

	local overlay = test.makeNode "Overlay"

	local store: Store = {
		members = {
			{ id = 1, name = "ada", pose = 10, fade = 0, tint = 200 },
			{ id = 2, name = "grace", pose = 20, fade = 0, tint = 40 },
		},
		daylight = true,
		listeners = {},
	}

	local function Marker(member: Compose.Readable<Member>, index: Compose.Readable<number>)
		return Host.Part {
			LayoutOrder = index,
			[group { "Pose", "Fade", "Tint" }] = function(use)
				local it = use(member)
				return it.pose, it.fade, it.tint
			end,
		}
	end

	local function Summary(members: Compose.Readable<{ Member }>)
		local expanded = cell(false)

		return Host.Frame "Summary" {
			Host.Button "Toggle" {

				Text = function(use: Compose.Use)
					if use(expanded) then
						return "Hide"
					end
					return ("%d present"):format(#use(members))
				end,
				[event "Activated"] = function()
					expanded:set(not expanded:peek())
				end,
			},

			show(expanded, function()
				return Host.Frame "Rows" {
					keyed {
						from = members,
						render = function(member, index)
							return Host.Label {
								LayoutOrder = index,
								Text = function(use)
									return use(member).name
								end,
							}
						end,
						key = function(member: Member)
							return member.id
						end,
					},
				}
			end),
		}
	end

	local function World()
		local members = cell(store.members)
		local daylight = cell(store.daylight)

		local function onChange(snapshot: Store)
			runtime:batch(function()
				members:set(snapshot.members)
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

		return Host.Model "World" {
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

			Host.Folder "Members" {
				keyed {
					from = members,
					render = Marker,
					key = function(member: Member)
						return member.id
					end,
				},
			},

			portal(overlay, function()
				return { Host.ScreenGui "SummaryGui" { Summary(members) } }
			end),
		}
	end

	local dispose, world = runtime.mount(World, test.root)

	local function child(parent: Compose.Node, name: string): Compose.Node
		for _, candidate in test.childrenOf(parent) do
			if Compose.labelOf(candidate) == name or test.propertyOf(candidate, "Name") == name then
				return candidate
			end
		end
		error(("no child %q"):format(name))
	end

	local sun = child(child(child(world, "SunLamp"), "Emitter"), "Sun")
	local membersFolder = child(world, "Members")
	local gui = child(overlay, "SummaryGui")
	local summary = child(gui, "Summary")
	local toggle = child(summary, "Toggle")

	local labelled = Compose.labelOf(sun)

	store.members = {
		{ id = 2, name = "grace", pose = 21, fade = 0.5, tint = 40 },
		{ id = 3, name = "alan", pose = 30, fade = 0, tint = 90 },
		{ id = 1, name = "ada", pose = 11, fade = 0, tint = 200 },
	}
	store.daylight = false
	publish(store)
	runtime:settle()

	local brightness = test.propertyOf(sun, "Brightness")
	local markers = #test.childrenOf(membersFolder)

	test.dispatch(toggle, "Activated")
	runtime:settle()
	local rows = #test.childrenOf(child(summary, "Rows"))

	dispose()

	assert(test.isAlive(overlay), "disposal destroyed the borrowed Gui container")
	assert(#test.childrenOf(overlay) == 0, "disposal left the portalled interface behind")
	assert(test.liveNodes() == 2, "disposal left nodes behind")
	assert(#store.listeners == 0, "disposal left the store subscription behind")

	return ("%s | brightness=%s | markers=%d | rows=%d | listeners=%d"):format(
		tostring(labelled),
		tostring(brightness),
		markers,
		rows,
		#store.listeners
	)
end

return {
	name = "store-scene",
	what = "a whole scene: a root that owns external state, local component state, a keyed collection, and one mount",
	expected = "Sun | brightness=0.4 | markers=3 | rows=3 | listeners=0",
	run = run,
}
