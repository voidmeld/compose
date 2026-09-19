--!strict

local Scene = require "./scene"
local Trace = require "./trace"
local Types = require "../scenarios/types"
local Units = require "./units"

type Context = Types.Context
type Scale = Types.Scale

local function set(node: any, properties: { [string]: any })
	for key, value in properties do
		node[key] = value
	end
end

local function build(context: Context, scale: Scale, shared: any): any
	local Instance = context.env.globals.Instance
	local made: { any } = {}
	local function new(kind: string, parent: any, properties: { [string]: any }): any
		local node = Instance.new(kind)
		set(node, properties)
		node.Parent = parent
		table.insert(made, node)
		return node
	end

	local roster = shared.rosterFor(scale.size)

	local units = Units.copy(roster)

	local root = new("Frame", context.container, { Name = "Battle" })

	local raidParent = new("Frame", root, { Name = "Raid" })
	local raidNodes: { any } = {}
	for index = 1, math.min(shared.RAID_FRAMES, #units) do
		local unit = units[index]
		raidNodes[unit.id] = new("Frame", raidParent, {
			Text = Units.raidText(unit.name, unit.health, unit.maximum, unit.state),
			LayoutOrder = unit.group * 100 + index,
		})
	end

	local sceneRoot = Instance.new "Model"
	sceneRoot.Name = "EngineScene"
	sceneRoot.Parent = root

	local unitParent = new("Folder", root, { Name = "Units" })
	local modelNodes: { any } = {}
	local anchorNodes: { any } = {}
	local plateNodes: { any } = {}
	local meshNodes: { any } = {}
	local highlightNodes: { any } = {}
	for _, unit in units do
		local tier = Trace.tierOf(unit.distance)
		local model = new("Model", unitParent, {
			Name = ("Unit%d"):format(unit.id),
			LayoutOrder = unit.id,
			Transparency = Scene.transparencyFor(tier),
		})
		modelNodes[unit.id] = model

		local anchor = new("Attachment", model, { Name = "Anchor", Position = unit.distance })
		anchorNodes[unit.id] = anchor

		if unit.visible then
			plateNodes[unit.id] = new("BillboardGui", anchor, {
				Name = ("Plate%d"):format(unit.id),
				Text = Units.plateText(unit.name, unit.health, unit.maximum, unit.status, tier),
				Tier = tier,
			})
		end
		if Scene.drawsMesh(tier) then
			meshNodes[unit.id] = new("MeshPart", model, {
				Name = "Body",
				Position = unit.distance,
				Transparency = Scene.transparencyFor(tier),
			})
		end
	end

	local effectParent = new("Folder", root, { Name = "Effects" })
	local effectNodes = table.create(Scene.EFFECT_SLOTS)
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
	local blipNodes: { any } = {}
	for _, unit in units do
		blipNodes[unit.id] = new("Frame", minimapParent, {
			Position = unit.distance,
			Faction = unit.faction,
			LayoutOrder = unit.id,
		})
	end

	local function panel(name: string, unit: any): any
		return new("Frame", root, {
			Name = name,
			Text = Units.raidText(unit.name, unit.health, unit.maximum, unit.state),
			Status = Trace.effectsOf(unit.status),
		})
	end
	local targetNode = panel("Target", units[1])
	local focusNode = panel("Focus", units[2])
	local assistNode = panel("Assist", units[3])

	local objectiveParent = new("Frame", root, { Name = "Objectives" })
	local objectiveNodes = table.create(shared.OBJECTIVES)
	for index = 1, shared.OBJECTIVES do
		objectiveNodes[index] = new("Frame", objectiveParent, {
			Name = ("Objective%d"):format(index),
			Size = 0,
		})
	end

	local scoreNode = new("Frame", root, { Name = "Score", Value = 0 })

	local textParent = new("Frame", root, { Name = "CombatText" })
	local textNodes = table.create(shared.COMBAT_TEXT_SLOTS)
	for index = 1, shared.COMBAT_TEXT_SLOTS do
		textNodes[index] = new("TextLabel", textParent, {
			Name = ("Text%d"):format(index),
			Text = "",
			Visible = false,
		})
	end

	local logParent = new("Frame", root, { Name = "Log" })

	return {
		made = made,
		units = units,
		raidNodes = raidNodes,
		plateNodes = plateNodes,
		sceneRoot = sceneRoot,
		asset = asset,
		modelNodes = modelNodes,
		anchorNodes = anchorNodes,
		meshNodes = meshNodes,
		highlightNodes = highlightNodes,
		effectNodes = effectNodes,
		selectedIds = {} :: { [number]: true },
		blipNodes = blipNodes,
		targetNode = targetNode,
		focusNode = focusNode,
		assistNode = assistNode,
		objectiveNodes = objectiveNodes,
		scoreNode = scoreNode,
		textNodes = textNodes,
		logParent = logParent,
		logNodes = {} :: { [number]: any },
		lines = {} :: { string },
		Instance = Instance,
		shared = shared,
		written = 0,
	}
end

local function slideLog(state: any)
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

local function applyChanges(state: any, tick: Trace.Tick)
	local units = state.units

	for _, change in tick.changes do
		local unit = units[change.index]
		if unit == nil then
			continue
		end
		unit.health = change.health
		unit.state = change.state
		unit.status = change.status
		state.written += 3

		local raid = state.raidNodes[unit.id]
		if raid ~= nil then
			raid.Text = Units.raidText(unit.name, unit.health, unit.maximum, unit.state)
		end
		local plate = state.plateNodes[unit.id]
		if plate ~= nil then
			plate.Text = Units.plateText(unit.name, unit.health, unit.maximum, unit.status, Trace.tierOf(unit.distance))
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
		state.written += 2

		local tier = Trace.tierOf(unit.distance)
		local transparency = Scene.transparencyFor(tier)

		local blip = state.blipNodes[unit.id]
		if blip ~= nil then
			blip.Position = unit.distance
		end

		local model = state.modelNodes[unit.id]
		if model ~= nil then
			model.Transparency = transparency
		end
		local anchor = state.anchorNodes[unit.id]
		if anchor ~= nil then
			anchor.Position = unit.distance
		end

		local mesh = state.meshNodes[unit.id]
		if Scene.drawsMesh(tier) then
			if mesh == nil then
				mesh = state.Instance.new "MeshPart"
				mesh.Name = "Body"
				mesh.Parent = model
				state.meshNodes[unit.id] = mesh
			end
			mesh.Position = unit.distance
			mesh.Transparency = transparency
		elseif mesh ~= nil then
			mesh:Destroy()
			state.meshNodes[unit.id] = nil
		end

		local plate = state.plateNodes[unit.id]
		if unit.visible then
			if plate == nil then
				plate = state.Instance.new "BillboardGui"
				plate.Name = ("Plate%d"):format(unit.id)
				plate.Parent = anchor
				state.plateNodes[unit.id] = plate
			end
			plate.Text = Units.plateText(unit.name, unit.health, unit.maximum, unit.status, tier)
			plate.Tier = tier
		elseif wasVisible and plate ~= nil then
			plate:Destroy()
			state.plateNodes[unit.id] = nil
		end
	end
end

local function reselect(state: any, tick: Trace.Tick)
	local wanted: { [number]: true } = {}
	for _, index in { tick.target, tick.focus, tick.assist } do
		local unit = state.units[index]
		if unit ~= nil then
			wanted[unit.id] = true
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

local function lightEffects(state: any, tick: Trace.Tick)
	local wanted = math.min(Scene.EFFECT_SLOTS, tick.combatText)
	for index = 1, Scene.EFFECT_SLOTS do
		local node = state.effectNodes[index]
		local on = index <= wanted
		node.Enabled = on
		node.Rate = if on then (tick.snapshot * 3 + index) % 40 else 0
	end
end

local function repanelAll(state: any, tick: Trace.Tick)
	local units = state.units
	local function repanel(node: any, unit: any)
		node.Text = Units.raidText(unit.name, unit.health, unit.maximum, unit.state)
		node.Status = Trace.effectsOf(unit.status)
	end
	repanel(state.targetNode, units[tick.target])
	repanel(state.focusNode, units[tick.focus])
	repanel(state.assistNode, units[tick.assist])
end

local function apply(state: any, tick: Trace.Tick, frame: number)
	local shared = state.shared
	applyChanges(state, tick)
	repanelAll(state, tick)
	reselect(state, tick)
	lightEffects(state, tick)

	for index = 1, shared.COMBAT_TEXT_SLOTS do
		local node = state.textNodes[index]
		if index <= tick.combatText then
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
		table.insert(lines, shared.logLine(#lines + 1, frame, tick.target, #tick.changes))
		slideLog(state)
		for index = 1, shared.OBJECTIVES do
			state.objectiveNodes[index].Size = ((frame + index) % 100) / 100
		end
		state.scoreNode.Value = #lines
	end
end

local function burst(state: any, tick: Trace.Tick, round: number, lineCount: number)
	local shared = state.shared
	applyChanges(state, tick)
	repanelAll(state, tick)
	reselect(state, tick)
	lightEffects(state, tick)
	for index = 1, shared.COMBAT_TEXT_SLOTS do
		local node = state.textNodes[index]
		node.Text = ("%d"):format((round * 13 + index) % 999)
		node.Visible = true
	end
	local lines = state.lines
	for index = 1, lineCount do
		table.insert(lines, shared.logLine(#lines + 1, round, index, #tick.changes))
	end
	slideLog(state)
	state.scoreNode.Value = #lines
end

local function teardown(state: any)
	for _, node in state.logNodes do
		node:Destroy()
	end
	state.logNodes = {}
	for _, node in state.plateNodes do
		node:Destroy()
	end
	state.plateNodes = {}
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
