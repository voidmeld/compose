--!strict

local Environment = require "../cost-model"
local Trace = require "./trace"
local Types = require "../scenarios/types"
local Items = require "./items"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local PARITY_KEYS = { "Name", "Text", "Tier", "LayoutOrder", "Visible" }

local traces: { [string]: { Trace.Tick } } = {}
local entityLists: { [number]: { Trace.Entity } } = {}

local function entitiesFor(count: number): { Trace.Entity }
	local held = entityLists[count]
	if held == nil then
		held = Trace.entities(count)
		entityLists[count] = held
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
	local visibility = table.create(count) :: { Trace.Visibility }
	for index = 1, count do
		visibility[index] = { index = index, visible = true, distance = (index * 7) % 79 }
	end
	return {
		snapshot = tick.snapshot,
		changes = tick.changes,
		visibility = visibility,
		identity = {},
		floatingText = 0,
		primary = tick.primary,
		secondary = tick.secondary,
		tertiary = tick.tertiary,
		burst = false,
	}
end

local function composeCase(every: number, saturated: boolean): Types.Case<unknown, Types.Context>
	local function build1(context: Types.ComposeContext, scale: Scale)
		local Compose = context.library
		local runtime = context.extras.runtime
		local Host = runtime.constructors
		local items = Items.sparse(entitiesFor(scale.size), Compose.cell)
		local order = Compose.cell(items)

		local dispose = runtime.mount(function()
			return Host.Frame {
				Name = "Labels",
				Compose.keyed {
					from = function(use: Types.Use): { Items.Item }
						return use(order)
					end,
					render = function(value: Types.Readable<Items.Item>)
						local item = value:peek()

						return Host.Frame {
							Name = ("Anchor%d"):format(item.id),
							LayoutOrder = item.id,
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
						}
					end,
					key = function(item: Items.Item): number
						return item.id
					end,
				},
			}
		end, context.container)

		return { dispose = dispose, items = items, runtime = runtime, peakPending = 0 }
	end
	type State1 = typeof(build1({} :: Types.ComposeContext, {} :: Scale))

	return (
		(
			{
				build = build1,

				steady = function(state: State1, _context: Types.ComposeContext, frame: number)
					local trace = traceFor(#state.items, every)
					local tick = trace[((frame - 1) % #trace) + 1]
					if saturated then
						tick = saturate(tick, #state.items)
					end
					local runtime = state.runtime
					runtime:batch(function()
						Items.applySparse(state.items, tick)
					end)
					local pending = runtime:pending()
					if pending > state.peakPending then
						state.peakPending = pending
					end
				end,

				burst = function(state: State1, _context: Types.ComposeContext, round: number)
					local runtime = state.runtime
					local visible = round % 2 == 1
					runtime:batch(function()
						for _, item in state.items do
							item.visible:set(visible)
							item.distance:set((item.id * 11) % 400)
						end
					end)
				end,

				teardown = function(state: State1, _context: Types.ComposeContext)
					state.dispose()
				end,

				snapshot = function(_state: State1, context: Types.ComposeContext): string
					return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
				end,

				probe = function(state: State1, _context: Types.ComposeContext): { [string]: number }
					return { peakPending = state.peakPending, pendingAtEnd = state.runtime:pending() }
				end,
			} :: Types.Case<State1, Types.ComposeContext>
		) :: unknown
	) :: Types.Case<unknown, Types.Context>
end

local function bareCase(every: number, saturated: boolean): Types.Case<unknown, Types.Context>
	local function refresh(
		state: {
			items: { Trace.Entity },
			labels: { [number]: Environment.Instance },
			anchors: { [number]: Environment.Instance },
			Instance: Environment.InstanceFactory,
		},
		tick: Trace.Tick
	)
		local items = state.items
		for _, change in tick.changes do
			local item = items[change.index]
			if item == nil then
				continue
			end
			item.level = change.level
			item.state = change.state
			item.status = change.status
			local label = state.labels[item.id]
			if label ~= nil then
				label.Text =
					Items.labelText(item.name, item.level, item.maximum, item.status, Trace.tierOf(item.distance))
			end
		end
		for _, change in tick.visibility do
			local item = items[change.index]
			if item == nil then
				continue
			end
			local wasVisible = item.visible
			item.visible = change.visible
			item.distance = change.distance
			local label = state.labels[item.id]
			if item.visible then
				if label == nil then
					label = state.Instance.new "BillboardGui"
					label.Name = ("Label%d"):format(item.id)
					label.Parent = state.anchors[item.id]
					state.labels[item.id] = label
				end
				local tier = Trace.tierOf(item.distance)
				label.Text = Items.labelText(item.name, item.level, item.maximum, item.status, tier)
				label.Tier = tier
			elseif wasVisible and label ~= nil then
				label:Destroy()
				state.labels[item.id] = nil
			end
		end
	end

	local function build2(context: Types.BareContext, scale: Scale)
		local Instance = context.env.globals.Instance
		local items = Items.copy(entitiesFor(scale.size))
		local parent = Instance.new "Frame"
		parent.Name = "Labels"
		parent.Parent = context.container

		local anchors: { [number]: Environment.Instance } = {}
		local labels: { [number]: Environment.Instance } = {}
		for _, item in items do
			local anchor = Instance.new "Frame"
			anchor.Name = ("Anchor%d"):format(item.id)
			anchor.LayoutOrder = item.id
			anchor.Parent = parent
			anchors[item.id] = anchor
			if item.visible then
				local tier = Trace.tierOf(item.distance)
				local label = Instance.new "BillboardGui"
				label.Name = ("Label%d"):format(item.id)
				label.Text = Items.labelText(item.name, item.level, item.maximum, item.status, tier)
				label.Tier = tier
				label.Parent = anchor
				labels[item.id] = label
			end
		end
		return { items = items, labels = labels, anchors = anchors, parent = parent, Instance = Instance }
	end
	type State2 = typeof(build2({} :: Types.BareContext, {} :: Scale))

	return (
		(
			{
				build = build2,

				steady = function(state: State2, _context: Types.BareContext, frame: number)
					local trace = traceFor(#state.items, every)
					local tick = trace[((frame - 1) % #trace) + 1]
					refresh(state, if saturated then saturate(tick, #state.items) else tick)
				end,

				burst = function(state: State2, _context: Types.BareContext, round: number)
					local visible = round % 2 == 1
					local visibility = table.create(#state.items) :: { Trace.Visibility }
					for index = 1, #state.items do
						visibility[index] = { index = index, visible = visible, distance = (index * 11) % 400 }
					end
					refresh(state, {
						snapshot = 0,
						changes = {},
						visibility = visibility,
						identity = {},
						floatingText = 0,
						primary = 1,
						secondary = 1,
						tertiary = 1,
						burst = true,
					})
				end,

				teardown = function(state: State2, _context: Types.BareContext)
					for _, label in state.labels do
						label:Destroy()
					end
					state.labels = {}
					for _, anchor in state.anchors do
						anchor:Destroy()
					end
					state.anchors = {}
					state.parent:Destroy()
				end,

				snapshot = function(_state: State2, context: Types.BareContext): string
					return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
				end,
			} :: Types.Case<State2, Types.BareContext>
		) :: unknown
	) :: Types.Case<unknown, Types.Context>
end

local sweep: Scenario = {
	id = "entities-relevance-sweep",
	title = "Camera sweep: labels entering and leaving relevance",
	what = "A quarter of the entities changes relevance every four frames while distances re-tier the "
		.. "labels that stay. Labels mount and unmount rather than toggling a property.",
	lane = "scene",
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
	id = "entities-relevance-saturated",
	title = "Pathological relevance: every entity visible at full detail",
	what = "Every label relevant, at the nearest detail tier, re-tiered every frame. The case "
		.. "nobody designs for and everybody hits when every entity lands in one place.",
	lane = "scene",
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
