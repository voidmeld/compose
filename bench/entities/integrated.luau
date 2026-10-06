--!strict

local Environment = require "../cost-model"
local Bare = require "./bare"
local Scene = require "./scene"
local Trace = require "./trace"
local Types = require "../scenarios/types"
local Items = require "./items"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local SUMMARY_ROWS = 40
local BURST_LOG_LINES = 16
local LOG_WINDOW = 32
local FLOATING_TEXT_SLOTS = 24
local METERS = 6

local traces: { [number]: { Trace.Tick } } = {}
local entityLists: { [number]: { Trace.Entity } } = {}

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

local function entitiesFor(count: number): { Trace.Entity }
	local held = entityLists[count]
	if held == nil then
		held = Trace.entities(count)
		entityLists[count] = held
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
	return { id = id, text = ("%d: %d changed by %d"):format(tick, source, amount) }
end

local PARITY_KEYS = {
	"Name",
	"Text",
	"Status",
	"Size",
	"Visible",
	"Tier",
	"Position",
	"Category",
	"Value",
	"Transparency",
	"Enabled",
	"Rate",
	"FillTransparency",
	"LayoutOrder",
}

local function snapshotOf(context: { env: Environment.Environment, container: Environment.Instance }): string
	return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
end

local function retarget(
	state: {
		items: { Items.Item },
		selected: { Types.Cell<boolean> },
		primary: Types.Cell<Items.Item>,
		secondary: Types.Cell<Items.Item>,
		tertiary: Types.Cell<Items.Item>,
	},
	tick: Trace.Tick
)
	local items = state.items
	local selected = state.selected
	local function move(slot: Types.Cell<Items.Item>, index: number)
		local previous = slot:peek()
		local wanted = items[index]
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
	move(state.primary, tick.primary)
	move(state.secondary, tick.secondary)
	move(state.tertiary, tick.tertiary)
end

local function lightEffects(
	state: { effectEnabled: { Types.Cell<boolean> }, effectRate: { Types.Cell<number> } },
	tick: Trace.Tick
)
	local wanted = math.min(Scene.EFFECT_SLOTS, tick.floatingText)
	for index = 1, Scene.EFFECT_SLOTS do
		local on = index <= wanted
		state.effectEnabled[index]:set(on)
		state.effectRate[index]:set(if on then (tick.snapshot * 3 + index) % 40 else 0)
	end
end

local function build1(context: Types.ComposeContext, scale: Scale)
	local Compose = context.library
	local runtime = context.extras.runtime
	local Host = runtime.constructors

	local Instance = context.env.globals.Instance
	local entities = entitiesFor(scale.size)
	local items = Items.sparse(entities, Compose.cell)

	local selected = table.create(#items) :: { Types.Cell<boolean> }
	for index = 1, #items do
		selected[index] = Compose.cell(false)
	end

	local effectEnabled = table.create(Scene.EFFECT_SLOTS) :: { Types.Cell<boolean> }
	local effectRate = table.create(Scene.EFFECT_SLOTS) :: { Types.Cell<number> }
	for index = 1, Scene.EFFECT_SLOTS do
		effectEnabled[index] = Compose.cell(false)
		effectRate[index] = Compose.cell(0)
	end

	local asset = Scene.authored(Instance, "AuthoredBanner")
	local sceneRoot = Instance.new "Model"
	sceneRoot.Name = "EngineScene"

	local order = Compose.cell(items)
	local primary = Compose.cell(items[1])
	local secondary = Compose.cell(items[2])
	local tertiary = Compose.cell(items[3])

	local lines: { LogEntry } = {}
	local logLength = Compose.cell(0)
	local logFirst = Compose.cell(1)
	local floatingText = table.create(FLOATING_TEXT_SLOTS) :: { Types.Cell<string> }
	for index = 1, FLOATING_TEXT_SLOTS do
		floatingText[index] = Compose.cell ""
	end
	local meters = table.create(METERS) :: { Types.Cell<number> }
	for index = 1, METERS do
		meters[index] = Compose.cell(0)
	end
	local score = Compose.cell(0)

	local function Panel(name: string, which: Types.Cell<Items.Item>)
		return Host.Frame {
			Name = name,
			Text = function(use: Types.Use): string
				local item = use(which)
				return Items.summaryText(item.name, use(item.level), item.maximum, use(item.state))
			end,
			Status = function(use: Types.Use): string
				return Trace.effectsOf(use(use(which).status))
			end,
		}
	end

	local dispose = runtime.mount(function()
		local meterNodes = table.create(METERS) :: { unknown }
		for index = 1, METERS do
			local cell = meters[index]
			meterNodes[index] = Host.Frame {
				Name = ("Meter%d"):format(index),
				Size = cell,
			}
		end

		local textNodes = table.create(FLOATING_TEXT_SLOTS) :: { unknown }
		for index = 1, FLOATING_TEXT_SLOTS do
			local cell = floatingText[index]
			textNodes[index] = Host.TextLabel {
				Name = ("Text%d"):format(index),
				Text = cell,
				Visible = function(use: Types.Use): boolean
					return use(cell) ~= ""
				end,
			}
		end

		local function group(kind: string, name: string, nodes: { unknown }): unknown
			local props: Types.Props = (table.clone(nodes) :: unknown) :: Types.Props
			props.Name = name
			return runtime.create(kind)(props)
		end

		return Host.Frame {
			Name = "Entities",

			Host.Frame {
				Name = "Summary",
				Compose.keyed {
					from = function(use: Types.Use): { Items.Item }
						local all = use(order)
						local shown = table.create(SUMMARY_ROWS) :: { Items.Item }
						for index = 1, math.min(SUMMARY_ROWS, #all) do
							shown[index] = all[index]
						end
						return shown
					end,
					key = function(item: Items.Item): number
						return item.id
					end,
					render = function(value: Types.Readable<Items.Item>, index: Types.Readable<number>)
						return Host.Frame {
							Text = function(use: Types.Use): string
								local item = use(value)
								return Items.summaryText(item.name, use(item.level), item.maximum, use(item.state))
							end,
							LayoutOrder = function(use: Types.Use): number
								return use(use(value).group) * 100 + use(index)
							end,
						}
					end,
				},
			},

			runtime.borrow(sceneRoot),
			Host.Folder {
				Name = "Items",
				Compose.keyed {
					from = function(use: Types.Use): { Items.Item }
						return use(order)
					end,
					render = function(value: Types.Readable<Items.Item>)
						local item = value:peek()
						local chosen = selected[item.id]
						return Host.Model {
							Name = ("Item%d"):format(item.id),
							LayoutOrder = item.id,
							Transparency = function(use: Types.Use): number
								return Scene.transparencyFor(Trace.tierOf(use(use(value).distance)))
							end,

							Host.Attachment {
								Name = "Anchor",
								Position = function(use: Types.Use): number
									return use(use(value).distance)
								end,
								Compose.show(function(use: Types.Use): boolean
									return use(use(value).visible)
								end, function()
									return Host.BillboardGui {
										Name = ("Label%d"):format(item.id),
										Text = function(use: Types.Use): string
											local current = use(value)
											return Items.labelText(
												current.name,
												use(current.level),
												current.maximum,
												use(current.status),
												Trace.tierOf(use(current.distance))
											)
										end,
										Tier = function(use: Types.Use): number
											return Trace.tierOf(use(use(value).distance))
										end,
									}
								end),
							},

							Compose.show(function(use: Types.Use): boolean
								return Scene.drawsMesh(Trace.tierOf(use(use(value).distance)))
							end, function()
								return Host.MeshPart {
									Name = "Body",
									Position = function(use: Types.Use): number
										return use(use(value).distance)
									end,
									Transparency = function(use: Types.Use): number
										return Scene.transparencyFor(Trace.tierOf(use(use(value).distance)))
									end,
								}
							end),

							Compose.show(function(use: Types.Use): boolean
								return use(chosen)
							end, function()
								return Host.Highlight {
									Name = "Selected",
									FillTransparency = 0.5,
								}
							end),
						}
					end,
					key = function(item: Items.Item): number
						return item.id
					end,
				},
			},

			(function()
				local emitters = table.create(Scene.EFFECT_SLOTS) :: { unknown }
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
					from = function(use: Types.Use): { Items.Item }
						return use(order)
					end,
					render = function(value: Types.Readable<Items.Item>)
						local blip = value:peek()
						return Host.Frame {
							Position = function(use: Types.Use): number
								return use(use(value).distance)
							end,
							Category = function(use: Types.Use): number
								return use(use(value).category)
							end,
							LayoutOrder = blip.id,
						}
					end,
					key = function(item: Items.Item): number
						return item.id
					end,
				},
			},

			Panel("Primary", primary),
			Panel("Secondary", secondary),
			Panel("Tertiary", tertiary),

			group("Frame", "Meters", meterNodes),
			Host.Frame { Name = "Score", Value = score },
			group("Frame", "FloatingText", textNodes),

			Host.Frame {
				Name = "Log",
				Compose.OrderedCollection {
					from = function(use: Types.Use): { LogEntry }
						use(logLength)
						return table.clone(lines)
					end,
					mode = "windowed",
					layout = { itemSize = 1 } :: Types.OrderedCollectionLayout,
					viewport = function(use: Types.Use)
						return { offset = use(logFirst) - 1, size = LOG_WINDOW }
					end,
					key = function(entry: LogEntry): number
						return entry.id
					end,
					render = function(value: Types.Readable<LogEntry>, absolute: Types.Readable<Types.Placement>)
						return Host.TextLabel {
							Text = function(use: Types.Use): string
								return use(value).text
							end,
							LayoutOrder = function(use: Types.Use)
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
		items = items,
		primary = primary,
		secondary = secondary,
		tertiary = tertiary,
		logLength = logLength,
		logFirst = logFirst,
		lines = lines,
		floatingText = floatingText,
		meters = meters,
		score = score,
		runtime = runtime,
		selected = selected,
		effectEnabled = effectEnabled,
		effectRate = effectRate,
		sceneRoot = sceneRoot,
		written = 0,
		peakPending = 0,
	}
end
type State1 = typeof(build1({} :: Types.ComposeContext, {} :: Scale))

local composeCase: Types.Case<State1, Types.ComposeContext> = {
	build = build1,

	steady = function(state: State1, _context: Types.ComposeContext, frame: number)
		local trace = traceFor(#state.items)
		local tick = trace[((frame - 1) % #trace) + 1]
		local runtime = state.runtime

		runtime:batch(function()
			state.written += Items.applySparse(state.items, tick)
			retarget(state, tick)
			lightEffects(state, tick)

			for index = 1, FLOATING_TEXT_SLOTS do
				local slot = state.floatingText[index]
				if index <= tick.floatingText then
					slot:set(("%d"):format((tick.snapshot * 7 + index) % 999))
				else
					slot:set ""
				end
			end

			if #tick.changes > 0 then
				local entries = state.lines
				table.insert(entries, logLine(#entries + 1, frame, tick.primary, #tick.changes))
				state.logLength:set(#entries)
				state.logFirst:set(math.max(1, #entries - LOG_WINDOW + 1))
				for index = 1, METERS do
					state.meters[index]:set(((frame + index) % 100) / 100)
				end
				state.score:set(#entries)
			end
		end)

		local pending = runtime:pending()
		if pending > state.peakPending then
			state.peakPending = pending
		end
	end,

	burst = function(state: State1, _context: Types.ComposeContext, round: number)
		local trace = burstFor(#state.items)
		local tick = trace[((round - 1) % #trace) + 1]
		local runtime = state.runtime
		runtime:batch(function()
			state.written += Items.applySparse(state.items, tick)
			retarget(state, tick)
			lightEffects(state, tick)
			for index = 1, FLOATING_TEXT_SLOTS do
				state.floatingText[index]:set(("%d"):format((round * 13 + index) % 999))
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

	teardown = function(state: State1, _context: Types.ComposeContext)
		state.dispose()

		state.sceneRoot:Destroy()
	end,

	snapshot = function(_state: State1, context: Types.ComposeContext): string
		return snapshotOf(context)
	end,

	probe = function(state: State1, _context: Types.ComposeContext): { [string]: number }
		return {
			peakPending = state.peakPending,
			pendingAtEnd = state.runtime:pending(),
			cellWritesIssued = state.written,
		}
	end,
}

local shared: Bare.Shared
local function build2(context: Types.BareContext, scale: Scale)
	return Bare.build(context, scale, shared)
end
type State2 = typeof(build2({} :: Types.BareContext, {} :: Scale))

local bareCase: Types.Case<State2, Types.BareContext> = {
	build = build2,
	steady = function(state: State2, _context: Types.BareContext, frame: number)
		local trace = traceFor(#state.items)
		Bare.apply(state, trace[((frame - 1) % #trace) + 1], frame)
	end,
	burst = function(state: State2, _context: Types.BareContext, round: number)
		local trace = burstFor(#state.items)
		Bare.burst(state, trace[((round - 1) % #trace) + 1], round, BURST_LOG_LINES)
	end,
	teardown = function(state: State2, _context: Types.BareContext)
		Bare.teardown(state)
	end,
	snapshot = function(_state: State2, context: Types.BareContext): string
		return snapshotOf(context)
	end,
}

local integrated: Scenario = {
	id = "entities-integrated",
	title = "Integrated 200-entity frame",
	what = "Summary rows, labels at three detail tiers, primary/secondary/tertiary, meters, a "
		.. "counter, a minimap, floating text and a windowed event log, driven by a fixed trace "
		.. "at 20 Hz snapshots and 60 Hz rendering.",
	lane = "scene",
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
	cases = {
		compose = (composeCase :: unknown) :: Types.Case<unknown, Types.Context>,
		bare = (bareCase :: unknown) :: Types.Case<unknown, Types.Context>,
	},
}

shared = {
	entitiesFor = entitiesFor,
	logLine = logLine,
	SUMMARY_ROWS = SUMMARY_ROWS,
	LOG_WINDOW = LOG_WINDOW,
	FLOATING_TEXT_SLOTS = FLOATING_TEXT_SLOTS,
	METERS = METERS,
}

return {
	integrated = integrated,
	traceFor = traceFor,
	entitiesFor = entitiesFor,
	burstFor = burstFor,
	logLine = logLine,
	snapshotOf = snapshotOf,
	SUMMARY_ROWS = SUMMARY_ROWS,
	LOG_WINDOW = LOG_WINDOW,
	FLOATING_TEXT_SLOTS = FLOATING_TEXT_SLOTS,
	METERS = METERS,
}
