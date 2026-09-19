--!strict

local Trace = require "./trace"
local Types = require "../scenarios/types"
local Units = require "./units"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local PARITY_KEYS = { "Name", "Text", "Tier", "LayoutOrder", "Visible" }

local traces: { [string]: { Trace.Tick } } = {}
local rosters: { [number]: { Trace.Combatant } } = {}

local function rosterFor(count: number): { Trace.Combatant }
	local held = rosters[count]
	if held == nil then
		held = Trace.roster(count)
		rosters[count] = held
	end
	return held
end

local function traceFor(count: number, every: number): { Trace.Tick }
	local key = ("%d:%d"):format(count, every)
	local held = traces[key]
	if held == nil then
		held = Trace.generate {
			count = count,
			frames = 600,
			snapshotHz = 30,
			renderHz = 60,
			churnLow = 0.05,
			churnHigh = 0.10,
			burstEvery = 0,
			identityEvery = 0,
			identityFraction = 0,
			sweepEvery = every,
		}
		traces[key] = held
	end
	return held
end

local function saturate(tick: Trace.Tick, count: number): Trace.Tick
	local visibility = table.create(count)
	for index = 1, count do
		visibility[index] = { index = index, visible = true, distance = (index * 7) % 79 }
	end
	return {
		snapshot = tick.snapshot,
		changes = tick.changes,
		visibility = visibility,
		identity = {},
		combatText = 0,
		target = tick.target,
		focus = tick.focus,
		assist = tick.assist,
		burst = false,
	}
end

local function composeCase(every: number, saturated: boolean): Types.Case
	return {
		build = function(context: Context, scale: Scale): any
			local Compose = context.library
			local runtime = context.extras.runtime
			local Host = runtime.constructors
			local units = Units.sparse(rosterFor(scale.size), Compose.cell)
			local order = Compose.cell(units)

			local dispose = runtime.mount(function()
				return Host.Frame {
					Name = "Plates",
					Compose.keyed {
						from = function(use: any): { Units.Unit }
							return use(order)
						end,
						render = function(value: any)
							local unit = value:peek()

							return Host.Frame {
								Name = ("Anchor%d"):format(unit.id),
								LayoutOrder = unit.id,
								Compose.show(function(use: any): boolean
									return use(use(value).visible)
								end, function()
									return Host.BillboardGui {
										Name = ("Plate%d"):format(unit.id),
										Text = function(use: any): string
											local current = use(value)
											return Units.plateText(
												current.name,
												use(current.health),
												current.maximum,
												use(current.status),
												Trace.tierOf(use(current.distance))
											)
										end,
										Tier = function(use: any): number
											return Trace.tierOf(use(use(value).distance))
										end,
									}
								end),
							}
						end,
						key = function(unit: any): number
							return unit.id
						end,
					},
				}
			end, context.container)

			return { dispose = dispose, units = units, runtime = runtime, peakPending = 0 }
		end,

		steady = function(state: any, _context: Context, frame: number)
			local trace = traceFor(#state.units, every)
			local tick = trace[((frame - 1) % #trace) + 1]
			if saturated then
				tick = saturate(tick, #state.units)
			end
			local runtime = state.runtime
			runtime:batch(function()
				Units.applySparse(state.units, tick)
			end)
			local pending = runtime:pending()
			if pending > state.peakPending then
				state.peakPending = pending
			end
		end,

		burst = function(state: any, _context: Context, round: number)
			local runtime = state.runtime
			local visible = round % 2 == 1
			runtime:batch(function()
				for _, unit in state.units do
					unit.visible:set(visible)
					unit.distance:set((unit.id * 11) % 400)
				end
			end)
		end,

		teardown = function(state: any, _context: Context)
			state.dispose()
		end,

		snapshot = function(_state: any, context: Context): string
			return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
		end,

		probe = function(state: any, _context: Context): { [string]: number }
			return { peakPending = state.peakPending, pendingAtEnd = state.runtime:pending() }
		end,
	}
end

local function bareCase(every: number, saturated: boolean): Types.Case
	local function refresh(state: any, tick: Trace.Tick)
		local units = state.units
		for _, change in tick.changes do
			local unit = units[change.index]
			if unit == nil then
				continue
			end
			unit.health = change.health
			unit.state = change.state
			unit.status = change.status
			local plate = state.plates[unit.id]
			if plate ~= nil then
				plate.Text =
					Units.plateText(unit.name, unit.health, unit.maximum, unit.status, Trace.tierOf(unit.distance))
			end
		end
		for _, change in tick.visibility do
			local unit = units[change.index]
			if unit == nil then
				continue
			end
			local wasVisible = unit.visible
			unit.visible = change.visible
			unit.distance = change.distance
			local plate = state.plates[unit.id]
			if unit.visible then
				if plate == nil then
					plate = state.Instance.new "BillboardGui"
					plate.Name = ("Plate%d"):format(unit.id)
					plate.Parent = state.anchors[unit.id]
					state.plates[unit.id] = plate
				end
				local tier = Trace.tierOf(unit.distance)
				plate.Text = Units.plateText(unit.name, unit.health, unit.maximum, unit.status, tier)
				plate.Tier = tier
			elseif wasVisible and plate ~= nil then
				plate:Destroy()
				state.plates[unit.id] = nil
			end
		end
	end

	return {
		build = function(context: Context, scale: Scale): any
			local Instance = context.env.globals.Instance
			local units = Units.copy(rosterFor(scale.size))
			local parent = Instance.new "Frame"
			parent.Name = "Plates"
			parent.Parent = context.container

			local anchors: { [number]: any } = {}
			local plates: { [number]: any } = {}
			for _, unit in units do
				local anchor = Instance.new "Frame"
				anchor.Name = ("Anchor%d"):format(unit.id)
				anchor.LayoutOrder = unit.id
				anchor.Parent = parent
				anchors[unit.id] = anchor
				if unit.visible then
					local tier = Trace.tierOf(unit.distance)
					local plate = Instance.new "BillboardGui"
					plate.Name = ("Plate%d"):format(unit.id)
					plate.Text = Units.plateText(unit.name, unit.health, unit.maximum, unit.status, tier)
					plate.Tier = tier
					plate.Parent = anchor
					plates[unit.id] = plate
				end
			end
			return { units = units, plates = plates, anchors = anchors, parent = parent, Instance = Instance }
		end,

		steady = function(state: any, _context: Context, frame: number)
			local trace = traceFor(#state.units, every)
			local tick = trace[((frame - 1) % #trace) + 1]
			refresh(state, if saturated then saturate(tick, #state.units) else tick)
		end,

		burst = function(state: any, _context: Context, round: number)
			local visible = round % 2 == 1
			local visibility = table.create(#state.units)
			for index = 1, #state.units do
				visibility[index] = { index = index, visible = visible, distance = (index * 11) % 400 }
			end
			refresh(state, {
				snapshot = 0,
				changes = {},
				visibility = visibility,
				identity = {},
				combatText = 0,
				target = 1,
				focus = 1,
				assist = 1,
				burst = true,
			})
		end,

		teardown = function(state: any, _context: Context)
			for _, plate in state.plates do
				plate:Destroy()
			end
			state.plates = {}
			for _, anchor in state.anchors do
				anchor:Destroy()
			end
			state.anchors = {}
			state.parent:Destroy()
		end,

		snapshot = function(_state: any, context: Context): string
			return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
		end,
	}
end

local sweep: Scenario = {
	id = "battle-relevance-sweep",
	title = "Camera sweep: nameplates entering and leaving relevance",
	what = "A quarter of the roster changes relevance every four frames while distances re-tier the "
		.. "plates that stay. Plates mount and unmount rather than toggling a property.",
	lane = "game",
	steadyBudgetSeconds = 0.0006,
	scales = {
		{ name = "medium", size = 200 },
		{ name = "large", size = 400 },
		{ name = "extreme", size = 1000 },
	},
	steadyFrames = 180,
	burstRounds = 8,
	samples = 7,
	warmup = 2,
	cases = { compose = composeCase(4, false), bare = bareCase(4, false) },
}

local saturated: Scenario = {
	id = "battle-relevance-saturated",
	title = "Pathological relevance: every combatant visible at full detail",
	what = "Every plate relevant, at the nearest detail tier, re-tiered every frame. The case "
		.. "nobody designs for and everybody hits when the field stacks on one objective.",
	lane = "game",
	steadyBudgetSeconds = 0.004,
	scales = {
		{ name = "medium", size = 200 },
		{ name = "large", size = 400 },
		{ name = "extreme", size = 1000 },
	},
	steadyFrames = 90,
	burstRounds = 6,
	samples = 7,
	warmup = 2,
	cases = { compose = composeCase(1, true), bare = bareCase(1, true) },
}

return {
	sweep = sweep,
	saturated = saturated,
}
