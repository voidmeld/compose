--!strict

local Support = require "./support"
local Types = require "./types"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local PANELS = 6
local EFFECTS = 12
local NEAR, MID = 1, 2

export type Widget = {
	id: number,
	x: number,
	y: number,
	z: number,
	kind: string,
}

local fields: { [number]: { Widget } } = {}
local function field(count: number): { Widget }
	local held = fields[count]
	if held ~= nil then
		return held
	end
	local next = Support.sequence(19940812)
	local made = table.create(count)
	for index = 1, count do
		made[index] = {
			id = index,
			x = math.floor(next() * 2000) - 1000,
			y = math.floor(next() * 400) - 100,
			z = math.floor(next() * 2000) - 1000,
			kind = if next() < 0.5 then "marker" else "panel",
		}
	end
	fields[count] = made
	return made
end

local function poseAt(frame: number): (number, number, number)
	local yaw = (frame * 3) % 3600
	local pitch = ((frame * 7) % 400) - 200
	local roll = ((frame * 2) % 60) - 30
	return yaw, pitch, roll
end

local function inCone(widget: Widget, yaw: number): boolean
	local bearing = (widget.id * 37 + widget.x) % 3600
	local delta = math.abs(((bearing - yaw + 1800) % 3600) - 1800)
	return delta < 550
end

local function tierOf(widget: Widget, yaw: number): number
	local bearing = (widget.id * 37 + widget.x) % 3600
	local delta = math.abs(((bearing - yaw + 1800) % 3600) - 1800)
	if delta < 200 then
		return NEAR
	elseif delta < 400 then
		return MID
	end
	return 3
end

local function pointedAt(all: { Widget }, frame: number): number
	if #all == 0 then
		return 0
	end
	return all[((frame * 5) % #all) + 1].id
end

local function panelPlacement(slot: number, yaw: number, pitch: number, roll: number): number
	return ((yaw + slot * 600) % 3600) * 1000 + (pitch + 200) * 2 + (roll + 30) % 7
end

local function widgetText(widget: Widget, tier: number): string
	if tier == NEAR then
		return ("%s %d %d"):format(widget.kind, widget.id, widget.y)
	elseif tier == MID then
		return ("%s %d"):format(widget.kind, widget.id)
	end
	return ""
end

local PARITY_KEYS = { "Name", "Text", "Position", "Tier", "Visible", "Enabled", "FillTransparency", "LayoutOrder" }

local composeCase: Types.Case = {
	build = function(context: Context, scale: Scale): any
		local Compose = context.library
		local runtime = context.extras.runtime
		local create = runtime.create

		local all = field(scale.size)

		local startYaw, startPitch, startRoll = poseAt(0)
		local yaw = Compose.cell(startYaw)
		local pitch = Compose.cell(startPitch)
		local roll = Compose.cell(startRoll)

		local tiers = table.create(#all)
		local pointed = table.create(#all)
		for index = 1, #all do
			tiers[index] = Compose.cell(tierOf(all[index], startYaw))
			pointed[index] = Compose.cell(false)
		end
		local startingCone: { Widget } = {}
		for _, widget in all do
			if inCone(widget, startYaw) then
				table.insert(startingCone, widget)
			end
		end
		local inView = Compose.cell(startingCone)
		local effects = table.create(EFFECTS)
		for index = 1, EFFECTS do
			effects[index] = Compose.cell(false)
		end

		local dispose = runtime.mount(function()
			local panels = table.create(PANELS)
			for index = 1, PANELS do
				local placement = Compose.formula(function(use: any): number
					return panelPlacement(index, use(yaw), use(pitch), use(roll))
				end)
				panels[index] = create "Frame" {
					Name = ("Panel%d"):format(index),
					LayoutOrder = index,
					Position = placement,
				}
			end
			local headRelative: any = table.clone(panels)
			headRelative.Name = "HeadRelative"

			local effectNodes = table.create(EFFECTS)
			for index = 1, EFFECTS do
				local cell = effects[index]
				effectNodes[index] = create "ParticleEmitter" {
					Name = ("Effect%d"):format(index),
					LayoutOrder = index,
					Enabled = cell,
				}
			end
			local burst: any = table.clone(effectNodes)
			burst.Name = "Effects"

			return create "Frame" {
				Name = "Spatial",
				create "Frame"(headRelative),

				create "Folder" {
					Name = "World",
					Compose.keyed {
						from = function(use: any): { Widget }
							return use(inView)
						end,
						render = function(value: any)
							local widget = value:peek()
							local tier = tiers[widget.id]
							local aimed = pointed[widget.id]
							return create "Model" {
								Name = ("Widget%d"):format(widget.id),
								LayoutOrder = widget.id,
								create "BillboardGui" {
									Name = "Label",
									Text = function(use: any): string
										return widgetText(use(value), use(tier))
									end,
									Tier = tier,
								},
								Compose.show(function(use: any): boolean
									return use(aimed)
								end, function()
									return create "Highlight" { Name = "Aimed", FillTransparency = 0.25 }
								end),
							}
						end,
						key = function(widget: any): number
							return widget.id
						end,
					},
				},

				create "Folder"(burst),
			}
		end, context.container)

		return {
			dispose = dispose,
			all = all,
			yaw = yaw,
			pitch = pitch,
			roll = roll,
			tiers = tiers,
			pointed = pointed,
			inView = inView,
			effects = effects,
			aimedAt = 0,
			runtime = runtime,
			peakPending = 0,
		}
	end,

	steady = function(state: any, _context: Context, frame: number)
		local runtime = state.runtime
		runtime:batch(function()
			local y, p, r = poseAt(frame)
			state.yaw:set(y)
			state.pitch:set(p)
			state.roll:set(r)

			local shown: { Widget } = {}
			for _, widget in state.all do
				if inCone(widget, y) then
					table.insert(shown, widget)
					state.tiers[widget.id]:set(tierOf(widget, y))
				end
			end
			state.inView:set(shown)

			local aimed = pointedAt(state.all, frame)
			if aimed ~= state.aimedAt then
				if state.aimedAt ~= 0 then
					state.pointed[state.aimedAt]:set(false)
				end
				state.aimedAt = aimed
				if aimed ~= 0 then
					state.pointed[aimed]:set(true)
				end
			end

			for index = 1, EFFECTS do
				state.effects[index]:set((frame + index) % 7 < 2)
			end
		end)
		local pending = runtime:pending()
		if pending > state.peakPending then
			state.peakPending = pending
		end
	end,

	burst = function(state: any, _context: Context, round: number)
		local runtime = state.runtime
		runtime:batch(function()
			local y = (round * 1800) % 3600
			state.yaw:set(y)
			local shown: { Widget } = {}
			for _, widget in state.all do
				if inCone(widget, y) then
					table.insert(shown, widget)
					state.tiers[widget.id]:set(tierOf(widget, y))
				end
			end
			state.inView:set(shown)
			for index = 1, EFFECTS do
				state.effects[index]:set(true)
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

local bareCase: Types.Case = {
	build = function(context: Context, scale: Scale): any
		local Instance = Support.instances(context)
		local made: { any } = {}
		local function new(kind: string, parent: any, properties: { [string]: any }): any
			local node = Instance.new(kind)
			for key, value in properties do
				node[key] = value
			end
			node.Parent = parent
			table.insert(made, node)
			return node
		end

		local all = field(scale.size)
		local root = new("Frame", context.container, { Name = "Spatial" })

		local headParent = new("Frame", root, { Name = "HeadRelative" })
		local panels = table.create(PANELS)
		for index = 1, PANELS do
			panels[index] = new("Frame", headParent, {
				Name = ("Panel%d"):format(index),
				LayoutOrder = index,
				Position = panelPlacement(index, 0, 0, 0),
			})
		end

		local worldParent = new("Folder", root, { Name = "World" })
		local effectParent = new("Folder", root, { Name = "Effects" })
		local effects = table.create(EFFECTS)
		for index = 1, EFFECTS do
			effects[index] = new("ParticleEmitter", effectParent, {
				Name = ("Effect%d"):format(index),
				LayoutOrder = index,
				Enabled = false,
			})
		end

		local state = {
			made = made,
			all = all,
			panels = panels,
			worldParent = worldParent,
			effects = effects,
			widgets = {} :: { [number]: any },
			labels = {} :: { [number]: any },
			highlights = {} :: { [number]: any },
			aimedAt = 0,
			Instance = Instance,
		}

		local y, p, r = poseAt(0)
		for index = 1, PANELS do
			panels[index].Position = panelPlacement(index, y, p, r)
		end
		for _, widget in all do
			if inCone(widget, y) then
				local tier = tierOf(widget, y)
				local model = Instance.new "Model"
				model.Name = ("Widget%d"):format(widget.id)
				model.LayoutOrder = widget.id
				model.Parent = worldParent
				state.widgets[widget.id] = model
				local label = Instance.new "BillboardGui"
				label.Name = "Label"
				label.Text = widgetText(widget, tier)
				label.Tier = tier
				label.Parent = model
				state.labels[widget.id] = label
			end
		end
		return state
	end,

	steady = function(state: any, _context: Context, frame: number)
		local y, p, r = poseAt(frame)
		for index = 1, PANELS do
			state.panels[index].Position = panelPlacement(index, y, p, r)
		end

		local wanted: { [number]: number } = {}
		for _, widget in state.all do
			if inCone(widget, y) then
				wanted[widget.id] = tierOf(widget, y)
			end
		end
		for id, node in state.widgets do
			if wanted[id] == nil then
				node:Destroy()
				state.widgets[id] = nil
				state.labels[id] = nil
				state.highlights[id] = nil
			end
		end
		for _, widget in state.all do
			local tier = wanted[widget.id]
			if tier == nil then
				continue
			end
			local model = state.widgets[widget.id]
			if model == nil then
				model = state.Instance.new "Model"
				model.Name = ("Widget%d"):format(widget.id)
				model.LayoutOrder = widget.id
				model.Parent = state.worldParent
				state.widgets[widget.id] = model
				local label = state.Instance.new "BillboardGui"
				label.Name = "Label"
				label.Parent = model
				state.labels[widget.id] = label
			end
			local label = state.labels[widget.id]
			label.Text = widgetText(widget, tier)
			label.Tier = tier
		end

		local aimed = pointedAt(state.all, frame)
		if aimed ~= state.aimedAt then
			local previous = state.highlights[state.aimedAt]
			if previous ~= nil then
				previous:Destroy()
				state.highlights[state.aimedAt] = nil
			end
			state.aimedAt = aimed
		end
		if aimed ~= 0 and state.widgets[aimed] ~= nil and state.highlights[aimed] == nil then
			local node = state.Instance.new "Highlight"
			node.Name = "Aimed"
			node.FillTransparency = 0.25
			node.Parent = state.widgets[aimed]
			state.highlights[aimed] = node
		end

		for index = 1, EFFECTS do
			state.effects[index].Enabled = (frame + index) % 7 < 2
		end
	end,

	burst = function(state: any, _context: Context, round: number)
		local y = (round * 1800) % 3600
		local wanted: { [number]: number } = {}
		for _, widget in state.all do
			if inCone(widget, y) then
				wanted[widget.id] = tierOf(widget, y)
			end
		end
		for id, node in state.widgets do
			if wanted[id] == nil then
				node:Destroy()
				state.widgets[id] = nil
				state.labels[id] = nil
				state.highlights[id] = nil
			end
		end
		for _, widget in state.all do
			local tier = wanted[widget.id]
			if tier == nil then
				continue
			end
			local model = state.widgets[widget.id]
			if model == nil then
				model = state.Instance.new "Model"
				model.Name = ("Widget%d"):format(widget.id)
				model.LayoutOrder = widget.id
				model.Parent = state.worldParent
				state.widgets[widget.id] = model
				local label = state.Instance.new "BillboardGui"
				label.Name = "Label"
				label.Parent = model
				state.labels[widget.id] = label
			end
			local label = state.labels[widget.id]
			label.Text = widgetText(widget, tier)
			label.Tier = tier
		end
		for index = 1, EFFECTS do
			state.effects[index].Enabled = true
		end
	end,

	teardown = function(state: any, _context: Context)
		for _, node in state.highlights do
			node:Destroy()
		end
		state.highlights = {}
		for _, node in state.widgets do
			node:Destroy()
		end
		state.widgets = {}
		state.labels = {}
		Support.destroyAll(state.made)
	end,

	snapshot = function(_state: any, context: Context): string
		return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
	end,
}

local spatial: Scenario = {
	id = "spatial-scene",
	title = "A head-driven spatial scene at headset frame rates",
	what = "Head-relative panels replaced every frame from a moving pose, world-anchored widgets "
		.. "mounted inside a view cone at three detail tiers, continuous spatial selection, and a "
		.. "bounded effect pool. Host-side CPU only: no rendering claim of any kind.",
	lane = "spatial",
	steadyBudgetSeconds = 0.0015,
	frameBudgets = {
		{ name = "72 Hz", seconds = 1 / 72 },
		{ name = "90 Hz", seconds = 1 / 90 },
		{ name = "120 Hz", seconds = 1 / 120 },
	},
	scales = {
		{ name = "medium", size = 150 },
		{ name = "large", size = 400 },
		{ name = "extreme", size = 1200 },
	},
	steadyFrames = 180,
	burstRounds = 8,
	samples = 7,
	warmup = 2,
	cases = { compose = composeCase, bare = bareCase },
}

return {
	spatial = spatial,
	poseAt = poseAt,
	inCone = inCone,
	tierOf = tierOf,
}
