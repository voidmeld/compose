--!strict

local Bare = require "./bare"
local Scene = require "./scene"
local Trace = require "./trace"
local Types = require "../scenarios/types"
local Units = require "./units"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local RAID_FRAMES = 40
local BURST_LOG_LINES = 16
local LOG_WINDOW = 32
local COMBAT_TEXT_SLOTS = 24
local OBJECTIVES = 6

local traces: { [number]: { Trace.Tick } } = {}
local rosters: { [number]: { Trace.Combatant } } = {}

local function traceFor(count: number): { Trace.Tick }
	local held = traces[count]
	if held == nil then
		held = Trace.generate {
			count = count,
			frames = 900,
			snapshotHz = 20,
			renderHz = 60,
			churnLow = 0.05,
			churnHigh = 0.20,
			burstEvery = 0,
			identityEvery = 0,
			identityFraction = 0,
			sweepEvery = 30,
		}
		traces[count] = held
	end
	return held
end

local function rosterFor(count: number): { Trace.Combatant }
	local held = rosters[count]
	if held == nil then
		held = Trace.roster(count)
		rosters[count] = held
	end
	return held
end

local burstTraces: { [number]: { Trace.Tick } } = {}
local function burstFor(count: number): { Trace.Tick }
	local held = burstTraces[count]
	if held == nil then
		held = Trace.generate {
			count = count,
			frames = 16,
			snapshotHz = 20,
			renderHz = 60,
			churnLow = 0.05,
			churnHigh = 0.20,
			burstEvery = 1,
			identityEvery = 0,
			identityFraction = 0,
			sweepEvery = 0,
		}
		burstTraces[count] = held
	end
	return held
end

export type LogEntry = { id: number, text: string }

local function logLine(id: number, tick: number, source: number, amount: number): LogEntry
	return { id = id, text = ("%d: %d hits for %d"):format(tick, source, amount) }
end

local PARITY_KEYS = {
	"Name",
	"Text",
	"Status",
	"Size",
	"Visible",
	"Tier",
	"Position",
	"Faction",
	"Value",
	"Transparency",
	"Enabled",
	"Rate",
	"FillTransparency",
	"LayoutOrder",
}

local function snapshotOf(context: Context): string
	return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
end

local function retarget(state: any, tick: Trace.Tick)
	local units = state.units
	local selected = state.selected
	local function move(slot: any, index: number)
		local previous = slot:peek()
		local wanted = units[index]
		if previous == wanted then
			return
		end
		if previous ~= nil and selected[previous.id] ~= nil then
			selected[previous.id]:set(false)
		end
		slot:set(wanted)
		if wanted ~= nil and selected[wanted.id] ~= nil then
			selected[wanted.id]:set(true)
		end
	end
	move(state.target, tick.target)
	move(state.focus, tick.focus)
	move(state.assist, tick.assist)
end

local function lightEffects(state: any, tick: Trace.Tick)
	local wanted = math.min(Scene.EFFECT_SLOTS, tick.combatText)
	for index = 1, Scene.EFFECT_SLOTS do
		local on = index <= wanted
		state.effectEnabled[index]:set(on)
		state.effectRate[index]:set(if on then (tick.snapshot * 3 + index) % 40 else 0)
	end
end

local composeCase: Types.Case = {
	build = function(context: Context, scale: Scale): any
		local Compose = context.library
		local runtime = context.extras.runtime
		local Host = runtime.constructors

		local Instance = context.env.globals.Instance
		local roster = rosterFor(scale.size)
		local units = Units.sparse(roster, Compose.cell)

		local selected = table.create(#units)
		for index = 1, #units do
			selected[index] = Compose.cell(false)
		end

		local effectEnabled = table.create(Scene.EFFECT_SLOTS)
		local effectRate = table.create(Scene.EFFECT_SLOTS)
		for index = 1, Scene.EFFECT_SLOTS do
			effectEnabled[index] = Compose.cell(false)
			effectRate[index] = Compose.cell(0)
		end

		local asset = Scene.authored(Instance, "AuthoredBanner")
		local sceneRoot = Instance.new "Model"
		sceneRoot.Name = "EngineScene"

		local order = Compose.cell(units)
		local target = Compose.cell(units[1])
		local focus = Compose.cell(units[2])
		local assist = Compose.cell(units[3])

		local lines: { LogEntry } = {}
		local logLength = Compose.cell(0)
		local logFirst = Compose.cell(1)
		local combatText = table.create(COMBAT_TEXT_SLOTS)
		for index = 1, COMBAT_TEXT_SLOTS do
			combatText[index] = Compose.cell ""
		end
		local objectives = table.create(OBJECTIVES)
		for index = 1, OBJECTIVES do
			objectives[index] = Compose.cell(0)
		end
		local score = Compose.cell(0)

		local function Panel(name: string, which: any)
			return Host.Frame {
				Name = name,
				Text = function(use: any): string
					local unit = use(which)
					return Units.raidText(unit.name, use(unit.health), unit.maximum, use(unit.state))
				end,
				Status = function(use: any): string
					return Trace.effectsOf(use(use(which).status))
				end,
			}
		end

		local dispose = runtime.mount(function()
			local objectiveNodes = table.create(OBJECTIVES)
			for index = 1, OBJECTIVES do
				local cell = objectives[index]
				objectiveNodes[index] = Host.Frame {
					Name = ("Objective%d"):format(index),
					Size = cell,
				}
			end

			local textNodes = table.create(COMBAT_TEXT_SLOTS)
			for index = 1, COMBAT_TEXT_SLOTS do
				local cell = combatText[index]
				textNodes[index] = Host.TextLabel {
					Name = ("Text%d"):format(index),
					Text = cell,
					Visible = function(use: any): boolean
						return use(cell) ~= ""
					end,
				}
			end

			local function group(kind: string, name: string, nodes: { any }): any
				local props: any = table.clone(nodes)
				props.Name = name
				return runtime.create(kind)(props)
			end

			return Host.Frame {
				Name = "Battle",

				Host.Frame {
					Name = "Raid",
					Compose.keyed {
						from = function(use: any): { Units.Unit }
							local all = use(order)
							local shown = table.create(RAID_FRAMES) :: { Units.Unit }
							for index = 1, math.min(RAID_FRAMES, #all) do
								shown[index] = all[index]
							end
							return shown
						end,
						key = function(unit: any): number
							return unit.id
						end,
						render = function(value: any, index: any)
							return Host.Frame {
								Text = function(use: any): string
									local unit = use(value)
									return Units.raidText(unit.name, use(unit.health), unit.maximum, use(unit.state))
								end,
								LayoutOrder = function(use: any): number
									return use(use(value).group) * 100 + use(index)
								end,
							}
						end,
					},
				},

				runtime.borrow(sceneRoot),
				Host.Folder {
					Name = "Units",
					Compose.keyed {
						from = function(use: any): { Units.Unit }
							return use(order)
						end,
						render = function(value: any)
							local unit = value:peek()
							local chosen = selected[unit.id]
							return Host.Model {
								Name = ("Unit%d"):format(unit.id),
								LayoutOrder = unit.id,
								Transparency = function(use: any): number
									return Scene.transparencyFor(Trace.tierOf(use(use(value).distance)))
								end,

								Host.Attachment {
									Name = "Anchor",
									Position = function(use: any): number
										return use(use(value).distance)
									end,
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
								},

								Compose.show(function(use: any): boolean
									return Scene.drawsMesh(Trace.tierOf(use(use(value).distance)))
								end, function()
									return Host.MeshPart {
										Name = "Body",
										Position = function(use: any): number
											return use(use(value).distance)
										end,
										Transparency = function(use: any): number
											return Scene.transparencyFor(Trace.tierOf(use(use(value).distance)))
										end,
									}
								end),

								Compose.show(function(use: any): boolean
									return use(chosen)
								end, function()
									return Host.Highlight {
										Name = "Selected",
										FillTransparency = 0.5,
									}
								end),
							}
						end,
						key = function(unit: any): number
							return unit.id
						end,
					},
				},

				(function()
					local emitters = table.create(Scene.EFFECT_SLOTS)
					for index = 1, Scene.EFFECT_SLOTS do
						local enabled, rate = effectEnabled[index], effectRate[index]
						emitters[index] = Host.ParticleEmitter {
							Name = ("Effect%d"):format(index),
							LayoutOrder = index,
							Enabled = enabled,
							Rate = rate,
						}
					end
					return group("Folder", "Effects", emitters)
				end)(),

				runtime.adopt(asset),

				Host.Frame {
					Name = "Minimap",
					Compose.keyed {
						from = function(use: any): { Units.Unit }
							return use(order)
						end,
						render = function(value: any)
							local blip = value:peek()
							return Host.Frame {
								Position = function(use: any): number
									return use(use(value).distance)
								end,
								Faction = function(use: any): number
									return use(use(value).faction)
								end,
								LayoutOrder = blip.id,
							}
						end,
						key = function(unit: any): number
							return unit.id
						end,
					},
				},

				Panel("Target", target),
				Panel("Focus", focus),
				Panel("Assist", assist),

				group("Frame", "Objectives", objectiveNodes),
				Host.Frame { Name = "Score", Value = score },
				group("Frame", "CombatText", textNodes),

				Host.Frame {
					Name = "Log",
					Compose.OrderedCollection {
						from = function(use: any): { LogEntry }
							use(logLength)
							return table.clone(lines)
						end,
						mode = "windowed",
						layout = { itemSize = 1 },
						viewport = function(use: any)
							return { offset = use(logFirst) - 1, size = LOG_WINDOW }
						end,
						key = function(entry: any): number
							return entry.id
						end,
						render = function(value: any, absolute: any)
							return Host.TextLabel {
								Text = function(use: any): string
									return use(value).text
								end,
								LayoutOrder = function(use: any)
									return use(absolute).index
								end,
							}
						end,
					},
				},
			}
		end, context.container)

		return {
			dispose = dispose,
			units = units,
			target = target,
			focus = focus,
			assist = assist,
			logLength = logLength,
			logFirst = logFirst,
			lines = lines,
			combatText = combatText,
			objectives = objectives,
			score = score,
			runtime = runtime,
			selected = selected,
			effectEnabled = effectEnabled,
			effectRate = effectRate,
			sceneRoot = sceneRoot,
			written = 0,
			peakPending = 0,
		}
	end,

	steady = function(state: any, _context: Context, frame: number)
		local trace = traceFor(#state.units)
		local tick = trace[((frame - 1) % #trace) + 1]
		local runtime = state.runtime

		runtime:batch(function()
			state.written += Units.applySparse(state.units, tick)
			retarget(state, tick)
			lightEffects(state, tick)

			for index = 1, COMBAT_TEXT_SLOTS do
				local slot = state.combatText[index]
				if index <= tick.combatText then
					slot:set(("%d"):format((tick.snapshot * 7 + index) % 999))
				else
					slot:set ""
				end
			end

			if #tick.changes > 0 then
				local entries = state.lines
				table.insert(entries, logLine(#entries + 1, frame, tick.target, #tick.changes))
				state.logLength:set(#entries)
				state.logFirst:set(math.max(1, #entries - LOG_WINDOW + 1))
				for index = 1, OBJECTIVES do
					state.objectives[index]:set(((frame + index) % 100) / 100)
				end
				state.score:set(#entries)
			end
		end)

		local pending = runtime:pending()
		if pending > state.peakPending then
			state.peakPending = pending
		end
	end,

	burst = function(state: any, _context: Context, round: number)
		local trace = burstFor(#state.units)
		local tick = trace[((round - 1) % #trace) + 1]
		local runtime = state.runtime
		runtime:batch(function()
			state.written += Units.applySparse(state.units, tick)
			retarget(state, tick)
			lightEffects(state, tick)
			for index = 1, COMBAT_TEXT_SLOTS do
				state.combatText[index]:set(("%d"):format((round * 13 + index) % 999))
			end
			local entries = state.lines
			for index = 1, BURST_LOG_LINES do
				table.insert(entries, logLine(#entries + 1, round, index, #tick.changes))
			end
			state.logLength:set(#entries)
			state.logFirst:set(math.max(1, #entries - LOG_WINDOW + 1))
			state.score:set(#entries)
		end)
		local pending = runtime:pending()
		if pending > state.peakPending then
			state.peakPending = pending
		end
	end,

	teardown = function(state: any, _context: Context)
		state.dispose()

		state.sceneRoot:Destroy()
	end,

	snapshot = function(_state: any, context: Context): string
		return snapshotOf(context)
	end,

	probe = function(state: any, _context: Context): { [string]: number }
		return {
			peakPending = state.peakPending,
			pendingAtEnd = state.runtime:pending(),
			cellWritesIssued = state.written,
		}
	end,
}

local shared: any
local bareCase: Types.Case = {
	build = function(context: Context, scale: Scale): any
		return Bare.build(context, scale, shared)
	end,
	steady = function(state: any, _context: Context, frame: number)
		local trace = traceFor(#state.units)
		Bare.apply(state, trace[((frame - 1) % #trace) + 1], frame)
	end,
	burst = function(state: any, _context: Context, round: number)
		local trace = burstFor(#state.units)
		Bare.burst(state, trace[((round - 1) % #trace) + 1], round, BURST_LOG_LINES)
	end,
	teardown = function(state: any, _context: Context)
		Bare.teardown(state)
	end,
	snapshot = function(_state: any, context: Context): string
		return snapshotOf(context)
	end,
}

local integrated: Scenario = {
	id = "battle-integrated",
	title = "Integrated 200-player battle frame",
	what = "Raid frames, nameplates at three detail tiers, target/focus/assist, objectives, a "
		.. "scoreboard, a minimap, combat text and a windowed combat log, driven by a fixed trace "
		.. "at 20 Hz snapshots and 60 Hz rendering.",
	lane = "game",
	steadyBudgetSeconds = 0.001,
	scales = {
		{ name = "medium", size = 200 },
		{ name = "large", size = 400 },
		{ name = "extreme", size = 1000 },
	},
	steadyFrames = 180,
	burstRounds = 8,
	samples = 7,
	warmup = 2,
	cases = { compose = composeCase, bare = bareCase },
}

shared = {
	rosterFor = rosterFor,
	logLine = logLine,
	RAID_FRAMES = RAID_FRAMES,
	LOG_WINDOW = LOG_WINDOW,
	COMBAT_TEXT_SLOTS = COMBAT_TEXT_SLOTS,
	OBJECTIVES = OBJECTIVES,
}

return {
	integrated = integrated,
	traceFor = traceFor,
	rosterFor = rosterFor,
	burstFor = burstFor,
	logLine = logLine,
	snapshotOf = snapshotOf,
	RAID_FRAMES = RAID_FRAMES,
	LOG_WINDOW = LOG_WINDOW,
	COMBAT_TEXT_SLOTS = COMBAT_TEXT_SLOTS,
	OBJECTIVES = OBJECTIVES,
}
