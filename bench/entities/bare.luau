--!strict

local Environment = require "../cost-model"
local Scene = require "./scene"
local Trace = require "./trace"
local Types = require "../scenarios/types"
local Items = require "./items"

type Context = Types.BareContext
type Scale = Types.Scale

export type Shared = {
	entitiesFor: (number) -> { Trace.Entity },
	logLine: (number, number, number, number) -> { id: number, text: string },
	SUMMARY_ROWS: number,
	LOG_WINDOW: number,
	FLOATING_TEXT_SLOTS: number,
	METERS: number,
}

local function set(node: Environment.Instance, properties: { [string]: unknown })
	for key, value in properties do
		node[key] = value
	end
end

local function build(context: Context, scale: Scale, shared: Shared)
	local Instance = context.env.globals.Instance
	local made: { Environment.Instance } = {}
	local function new(
		kind: string,
		parent: Environment.Instance,
		properties: { [string]: unknown }
	): Environment.Instance
		local node = Instance.new(kind)
		set(node, properties)
		node.Parent = parent
		table.insert(made, node)
		return node
	end

	local entities = shared.entitiesFor(scale.size)

	local items = Items.copy(entities)

	local root = new("Frame", context.container, { Name = "Entities" })

	local summaryParent = new("Frame", root, { Name = "Summary" })
	local summaryNodes: { Environment.Instance } = {}
	for index = 1, math.min(shared.SUMMARY_ROWS, #items) do
		local item = items[index]
		summaryNodes[item.id] = new("Frame", summaryParent, {
			Text = Items.summaryText(item.name, item.level, item.maximum, item.state),
			LayoutOrder = item.group * 100 + index,
		})
	end

	local sceneRoot = Instance.new "Model"
	sceneRoot.Name = "EngineScene"
	sceneRoot.Parent = root

	local itemParent = new("Folder", root, { Name = "Items" })
	local modelNodes: { Environment.Instance } = {}
	local anchorNodes: { Environment.Instance } = {}
	local labelNodes: { Environment.Instance } = {}
	local meshNodes: { Environment.Instance } = {}
	local highlightNodes: { Environment.Instance } = {}
	for _, item in items do
		local tier = Trace.tierOf(item.distance)
		local model = new("Model", itemParent, {
			Name = ("Item%d"):format(item.id),
			LayoutOrder = item.id,
			Transparency = Scene.transparencyFor(tier),
		})
		modelNodes[item.id] = model

		local anchor = new("Attachment", model, { Name = "Anchor", Position = item.distance })
		anchorNodes[item.id] = anchor

		if item.visible then
			labelNodes[item.id] = new("BillboardGui", anchor, {
				Name = ("Label%d"):format(item.id),
				Text = Items.labelText(item.name, item.level, item.maximum, item.status, tier),
				Tier = tier,
			})
		end
		if Scene.drawsMesh(tier) then
			meshNodes[item.id] = new("MeshPart", model, {
				Name = "Body",
				Position = item.distance,
				Transparency = Scene.transparencyFor(tier),
			})
		end
	end

	local effectParent = new("Folder", root, { Name = "Effects" })
	local effectNodes = table.create(Scene.EFFECT_SLOTS) :: { Environment.Instance }
	for index = 1, Scene.EFFECT_SLOTS do
		effectNodes[index] = new("ParticleEmitter", effectParent, {
			Name = ("Effect%d"):format(index),
			LayoutOrder = index,
			Enabled = false,
			Rate = 0,
		})
	end

	local asset = Scene.authored(Instance, "AuthoredBanner")
	asset.Parent = root

	local minimapParent = new("Frame", root, { Name = "Minimap" })
	local blipNodes: { Environment.Instance } = {}
	for _, item in items do
		blipNodes[item.id] = new("Frame", minimapParent, {
			Position = item.distance,
			Category = item.category,
			LayoutOrder = item.id,
		})
	end

	local function panel(name: string, item: Trace.Entity): Environment.Instance
		return new("Frame", root, {
			Name = name,
			Text = Items.summaryText(item.name, item.level, item.maximum, item.state),
			Status = Trace.effectsOf(item.status),
		})
	end
	local primaryNode = panel("Primary", items[1])
	local secondaryNode = panel("Secondary", items[2])
	local tertiaryNode = panel("Tertiary", items[3])

	local meterParent = new("Frame", root, { Name = "Meters" })
	local meterNodes = table.create(shared.METERS) :: { Environment.Instance }
	for index = 1, shared.METERS do
		meterNodes[index] = new("Frame", meterParent, {
			Name = ("Meter%d"):format(index),
			Size = 0,
		})
	end

	local scoreNode = new("Frame", root, { Name = "Score", Value = 0 })

	local textParent = new("Frame", root, { Name = "FloatingText" })
	local textNodes = table.create(shared.FLOATING_TEXT_SLOTS) :: { Environment.Instance }
	for index = 1, shared.FLOATING_TEXT_SLOTS do
		textNodes[index] = new("TextLabel", textParent, {
			Name = ("Text%d"):format(index),
			Text = "",
			Visible = false,
		})
	end

	local logParent = new("Frame", root, { Name = "Log" })

	return {
		made = made,
		items = items,
		summaryNodes = summaryNodes,
		labelNodes = labelNodes,
		sceneRoot = sceneRoot,
		asset = asset,
		modelNodes = modelNodes,
		anchorNodes = anchorNodes,
		meshNodes = meshNodes,
		highlightNodes = highlightNodes,
		effectNodes = effectNodes,
		selectedIds = {} :: { [number]: true },
		blipNodes = blipNodes,
		primaryNode = primaryNode,
		secondaryNode = secondaryNode,
		tertiaryNode = tertiaryNode,
		meterNodes = meterNodes,
		scoreNode = scoreNode,
		textNodes = textNodes,
		logParent = logParent,
		logNodes = {} :: { [number]: Environment.Instance },
		lines = {} :: { { id: number, text: string } },
		Instance = Instance,
		shared = shared,
		written = 0,
	}
end

export type State = typeof(build({} :: Context, {} :: Scale, {} :: Shared))

local function slideLog(state: State)
	local lines = state.lines
	local window = state.shared.LOG_WINDOW
	local first = math.max(1, #lines - window + 1)
	local wanted: { [number]: number } = {}
	for absolute = first, #lines do
		wanted[lines[absolute].id] = absolute
	end
	for id, node in state.logNodes do
		if wanted[id] == nil then
			node:Destroy()
			state.logNodes[id] = nil
		end
	end
	for absolute = first, #lines do
		local entry = lines[absolute]
		local node = state.logNodes[entry.id]
		if node == nil then
			node = state.Instance.new "TextLabel"
			node.Text = entry.text
			node.Parent = state.logParent
			state.logNodes[entry.id] = node
		end
		node.LayoutOrder = absolute
	end
end

local function applyChanges(state: State, tick: Trace.Tick)
	local items = state.items

	for _, change in tick.changes do
		local item = items[change.index]
		if item == nil then
			continue
		end
		item.level = change.level
		item.state = change.state
		item.status = change.status
		state.written += 3

		local summary = state.summaryNodes[item.id]
		if summary ~= nil then
			summary.Text = Items.summaryText(item.name, item.level, item.maximum, item.state)
		end
		local label = state.labelNodes[item.id]
		if label ~= nil then
			label.Text = Items.labelText(item.name, item.level, item.maximum, item.status, Trace.tierOf(item.distance))
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
		state.written += 2

		local tier = Trace.tierOf(item.distance)
		local transparency = Scene.transparencyFor(tier)

		local blip = state.blipNodes[item.id]
		if blip ~= nil then
			blip.Position = item.distance
		end

		local model = state.modelNodes[item.id]
		if model ~= nil then
			model.Transparency = transparency
		end
		local anchor = state.anchorNodes[item.id]
		if anchor ~= nil then
			anchor.Position = item.distance
		end

		local mesh = state.meshNodes[item.id]
		if Scene.drawsMesh(tier) then
			if mesh == nil then
				mesh = state.Instance.new "MeshPart"
				mesh.Name = "Body"
				mesh.Parent = model
				state.meshNodes[item.id] = mesh
			end
			mesh.Position = item.distance
			mesh.Transparency = transparency
		elseif mesh ~= nil then
			mesh:Destroy()
			state.meshNodes[item.id] = nil
		end

		local label = state.labelNodes[item.id]
		if item.visible then
			if label == nil then
				label = state.Instance.new "BillboardGui"
				label.Name = ("Label%d"):format(item.id)
				label.Parent = anchor
				state.labelNodes[item.id] = label
			end
			label.Text = Items.labelText(item.name, item.level, item.maximum, item.status, tier)
			label.Tier = tier
		elseif wasVisible and label ~= nil then
			label:Destroy()
			state.labelNodes[item.id] = nil
		end
	end
end

local function reselect(state: State, tick: Trace.Tick)
	local wanted: { [number]: true } = {}
	for _, index in { tick.primary, tick.secondary, tick.tertiary } do
		local item = state.items[index]
		if item ~= nil then
			wanted[item.id] = true
		end
	end
	for id in state.selectedIds do
		if not wanted[id] then
			local node = state.highlightNodes[id]
			if node ~= nil then
				node:Destroy()
				state.highlightNodes[id] = nil
			end
			state.selectedIds[id] = nil
		end
	end
	for id in wanted do
		if state.highlightNodes[id] == nil then
			local node = state.Instance.new "Highlight"
			node.Name = "Selected"
			node.FillTransparency = 0.5
			node.Parent = state.modelNodes[id]
			state.highlightNodes[id] = node
		end
		state.selectedIds[id] = true
	end
end

local function lightEffects(state: State, tick: Trace.Tick)
	local wanted = math.min(Scene.EFFECT_SLOTS, tick.floatingText)
	for index = 1, Scene.EFFECT_SLOTS do
		local node = state.effectNodes[index]
		local on = index <= wanted
		node.Enabled = on
		node.Rate = if on then (tick.snapshot * 3 + index) % 40 else 0
	end
end

local function repanelAll(state: State, tick: Trace.Tick)
	local items = state.items
	local function repanel(node: Environment.Instance, item: Trace.Entity)
		node.Text = Items.summaryText(item.name, item.level, item.maximum, item.state)
		node.Status = Trace.effectsOf(item.status)
	end
	repanel(state.primaryNode, items[tick.primary])
	repanel(state.secondaryNode, items[tick.secondary])
	repanel(state.tertiaryNode, items[tick.tertiary])
end

local function apply(state: State, tick: Trace.Tick, frame: number)
	local shared = state.shared
	applyChanges(state, tick)
	repanelAll(state, tick)
	reselect(state, tick)
	lightEffects(state, tick)

	for index = 1, shared.FLOATING_TEXT_SLOTS do
		local node = state.textNodes[index]
		if index <= tick.floatingText then
			local text = ("%d"):format((tick.snapshot * 7 + index) % 999)
			node.Text = text
			node.Visible = true
		else
			node.Text = ""
			node.Visible = false
		end
	end

	if #tick.changes > 0 then
		local lines = state.lines
		table.insert(lines, (shared.logLine(#lines + 1, frame, tick.primary, #tick.changes)))
		slideLog(state)
		for index = 1, shared.METERS do
			state.meterNodes[index].Size = ((frame + index) % 100) / 100
		end
		state.scoreNode.Value = #lines
	end
end

local function burst(state: State, tick: Trace.Tick, round: number, lineCount: number)
	local shared = state.shared
	applyChanges(state, tick)
	repanelAll(state, tick)
	reselect(state, tick)
	lightEffects(state, tick)
	for index = 1, shared.FLOATING_TEXT_SLOTS do
		local node = state.textNodes[index]
		node.Text = ("%d"):format((round * 13 + index) % 999)
		node.Visible = true
	end
	local lines = state.lines
	for index = 1, lineCount do
		table.insert(lines, (shared.logLine(#lines + 1, round, index, #tick.changes)))
	end
	slideLog(state)
	state.scoreNode.Value = #lines
end

local function teardown(state: State)
	for _, node in state.logNodes do
		node:Destroy()
	end
	state.logNodes = {}
	for _, node in state.labelNodes do
		node:Destroy()
	end
	state.labelNodes = {}
	for _, node in state.meshNodes do
		node:Destroy()
	end
	state.meshNodes = {}
	for _, node in state.highlightNodes do
		node:Destroy()
	end
	state.highlightNodes = {}
	state.asset:Destroy()
	state.sceneRoot:Destroy()
	local made = state.made
	for index = #made, 1, -1 do
		local node = made[index]
		if node ~= nil then
			node:Destroy()
			made[index] = nil
		end
	end
end

return {
	build = build,
	apply = apply,
	burst = burst,
	slideLog = slideLog,
	teardown = teardown,
}
