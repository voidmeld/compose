--!strict

local Environment = require "../cost-model"
local Support = require "./support"
local Types = require "./types"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

type SparseEntity = {
	id: number,
	name: string,
	level: Types.Cell<number>,
	status: Types.Cell<string>,
	visible: Types.Cell<boolean>,
}

type Label = {
	id: number,
	name: string,
	level: number,
	maximum: number,
	status: string,
	visible: boolean,
}

local function build1(context: Types.ComposeContext, scale: Scale)
	local Compose = context.library
	local runtime = context.extras.runtime
	local Host = runtime.constructors

	local level = Compose.cell(100)
	local reserve = Compose.cell(100)
	local charge = Compose.cell(100)
	local casting = Compose.cell(0)
	local timers = table.create(scale.timers) :: { Types.Cell<number> }
	for index = 1, scale.timers do
		timers[index] = Compose.cell(0)
	end
	local badges = Compose.cell({} :: { { id: number, name: string } })
	local texts = Compose.cell({} :: { { id: number, text: string } })

	local levelPercent = Compose.formula(function(use: Types.Use): number
		return (use(level) :: number) / 100
	end)

	local dispose = runtime.mount(function()
		local bars = {}
		for _, pair in
			{ { "Level", levelPercent }, { "Reserve", reserve }, { "Charge", charge } } :: { { string | Types.Readable<number> } }
		do
			local bar = Host.Frame {
				Name = pair[1],
				Size = pair[2],
			}
			table.insert(bars, bar)
		end
		local slots = table.create(scale.timers) :: { unknown }
		for index = 1, scale.timers do
			local cell = timers[index]
			slots[index] = Host.Frame {
				Name = ("Timer%d"):format(index),
				Size = cell,
				Visible = function(use: Types.Use)
					return use(cell) > 0
				end,
			}
		end
		return Host.Frame {
			Host.Frame(bars),
			Host.Frame(slots),
			Host.Frame {
				Name = "Progress",
				Size = casting,
				Visible = function(use: Types.Use)
					return use(casting) > 0
				end,
			},
			Compose.keyed {
				from = function(use: Types.Use)
					return use(badges)
				end,
				render = function(value: Types.Readable<{ id: number, name: string }>, index: Types.Readable<number>)
					return Host.Frame {
						Name = function(use: Types.Use)
							return use(value).name
						end,
						LayoutOrder = index,
					}
				end,
				key = function(badge: { id: number, name: string })
					return badge.id
				end,
			},
			Compose.keyed {
				from = function(use: Types.Use)
					return use(texts)
				end,
				render = function(value: Types.Readable<{ id: number, text: string }>, index: Types.Readable<number>)
					return Host.TextLabel {
						Text = function(use: Types.Use)
							return use(value).text
						end,
						LayoutOrder = index,
					}
				end,
				key = function(line: { id: number, text: string })
					return line.id
				end,
			},
		}
	end, context.container)

	return {
		dispose = dispose,
		runtime = runtime,
		level = level,
		reserve = reserve,
		charge = charge,
		casting = casting,
		timers = timers,
		badges = badges,
		texts = texts,
		scale = scale,
		nextId = 1,
	}
end
type State1 = typeof(build1({} :: Types.ComposeContext, {} :: Scale))

local function build2(context: Types.BareContext, scale: Scale)
	local Instance = Support.instances(context)
	local made: { Environment.Instance } = {}
	local root = Instance.new "Frame"
	table.insert(made, root)

	local barFrame = Instance.new "Frame"
	barFrame.Parent = root
	table.insert(made, barFrame)
	local bars = {}
	for _, name in { "Level", "Reserve", "Charge" } do
		local bar = Instance.new "Frame"
		bar.Name = name
		bar.Size = 1
		bar.Parent = barFrame
		table.insert(made, bar)
		bars[name] = bar
	end

	local slotFrame = Instance.new "Frame"
	slotFrame.Parent = root
	table.insert(made, slotFrame)
	local slots = table.create(scale.timers) :: { Environment.Instance }
	for index = 1, scale.timers do
		local slot = Instance.new "Frame"
		slot.Name = ("Timer%d"):format(index)
		slot.Size = 0
		slot.Visible = false
		slot.Parent = slotFrame
		table.insert(made, slot)
		slots[index] = slot
	end

	local progress = Instance.new "Frame"
	progress.Name = "Progress"
	progress.Size = 0
	progress.Visible = false
	progress.Parent = root
	table.insert(made, progress)

	root.Parent = context.container
	return {
		made = made,
		root = root,
		bars = bars,
		slots = slots,
		progress = progress,
		badgeNodes = {} :: { Environment.Instance },
		textNodes = {} :: { Environment.Instance },
		scale = scale,
		timerValues = table.create(scale.timers, 0),
	}
end
type State2 = typeof(build2({} :: Types.BareContext, {} :: Scale))

local dashboard: Scenario = {
	id = "dense-dashboard",
	title = "Dense dashboard under routine and burst load",
	what = "Resource bars, timers, a progress bar, a badge tray and floating text. The steady "
		.. "frame updates the fraction that a real frame updates; the burst updates all of it.",
	lane = "scene",
	steadyBudgetSeconds = 0.0008,
	scales = {
		{ name = "medium", size = 12, timers = 8, badges = 12, texts = 8 },
		{ name = "large", size = 30, timers = 16, badges = 30, texts = 20 },
		{ name = "extreme", size = 60, timers = 32, badges = 60, texts = 40 },
	},
	steadyFrames = 120,
	burstRounds = 8,
	samples = 9,
	warmup = 2,
	cases = {
		compose = (({
			build = build1,
			steady = function(state: State1, _context: Types.ComposeContext, tick: number)
				local scale = state.scale
				state.runtime:batch(function()
					state.level:set(60 + (tick % 40))
					state.reserve:set(50 + (tick % 50))
					state.casting:set((tick % 20) / 20)
					local slot = (tick % scale.timers) + 1
					state.timers[slot]:set(1 - (tick % 10) / 10)
				end)
			end,
			burst = function(state: State1, _context: Types.ComposeContext, round: number)
				local scale = state.scale
				state.runtime:batch(function()
					state.level:set(1 + (round % 5))
					state.reserve:set(2 + (round % 7))
					state.charge:set(3 + (round % 11))
					for index = 1, scale.timers do
						state.timers[index]:set(1)
					end
					local badges = table.create(scale.badges) :: { { id: number, name: string } }
					for index = 1, scale.badges do
						badges[index] = { id = (round * 1000) + index, name = ("badge-%d-%d"):format(round, index) }
					end
					state.badges:set(badges)
					local texts = table.create(scale.texts) :: { { id: number, text: string } }
					for index = 1, scale.texts do
						texts[index] = { id = (round * 2000) + index, text = ("%d"):format(round * index) }
					end
					state.texts:set(texts)
				end)
			end,
			teardown = function(state: State1, _context: Types.ComposeContext)
				state.dispose()
			end,
			snapshot = function(_state: State1, context: Types.ComposeContext): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		} :: Types.Case<State1, Types.ComposeContext>) :: unknown) :: Types.Case<unknown, Types.Context>,

		bare = (({
			build = build2,
			steady = function(state: State2, _context: Types.BareContext, tick: number)
				local scale = state.scale
				state.bars.Level.Size = (60 + (tick % 40)) / 100
				state.bars.Reserve.Size = 50 + (tick % 50)
				local casting = (tick % 20) / 20
				state.progress.Size = casting
				state.progress.Visible = casting > 0
				local slot = (tick % scale.timers) + 1
				local value = 1 - (tick % 10) / 10
				state.timerValues[slot] = value
				state.slots[slot].Size = value
				state.slots[slot].Visible = value > 0
			end,
			burst = function(state: State2, context: Types.BareContext, round: number)
				local Instance = Support.instances(context)
				local scale = state.scale
				state.bars.Level.Size = (1 + (round % 5)) / 100
				state.bars.Reserve.Size = 2 + (round % 7)
				state.bars.Charge.Size = 3 + (round % 11)
				for index = 1, scale.timers do
					state.timerValues[index] = 1
					state.slots[index].Size = 1
					state.slots[index].Visible = true
				end

				Support.destroyAll(state.badgeNodes)
				for index = 1, scale.badges do
					local node = Instance.new "Frame"
					node.Name = ("badge-%d-%d"):format(round, index)
					node.LayoutOrder = index
					node.Parent = state.root
					table.insert(state.badgeNodes, node)
				end
				Support.destroyAll(state.textNodes)
				for index = 1, scale.texts do
					local node = Instance.new "TextLabel"
					node.Text = ("%d"):format(round * index)
					node.LayoutOrder = index
					node.Parent = state.root
					table.insert(state.textNodes, node)
				end
			end,
			teardown = function(state: State2, _context: Types.BareContext)
				Support.destroyAll(state.badgeNodes)
				Support.destroyAll(state.textNodes)
				Support.destroyAll(state.made)
			end,
			snapshot = function(_state: State2, context: Types.BareContext): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		} :: Types.Case<State2, Types.BareContext>) :: unknown) :: Types.Case<unknown, Types.Context>,
	},
}

local function build3(context: Types.ComposeContext, scale: Scale)
	local Compose = context.library
	local runtime = context.extras.runtime
	local Host = runtime.constructors

	local summary = Compose.cell(Support.entities(scale.summary, "member"))
	local labels = Compose.cell(Support.entities(scale.size, "label"))
	local culled = Compose.cell(false)

	local function row(value: Types.Readable<Support.Entity>, index: Types.Readable<number>)
		return Host.Frame {
			Name = function(use: Types.Use)
				return use(value).name
			end,
			Size = function(use: Types.Use): number
				local item = use(value)
				return item.level / item.maximum
			end,
			Text = function(use: Types.Use)
				return use(value).status
			end,
			LayoutOrder = index,
		}
	end

	local dispose = runtime.mount(function()
		return Host.Frame {
			Host.Frame {
				Compose.keyed {
					from = function(use: Types.Use)
						return use(summary)
					end,
					render = row,
					key = function(item: { id: number })
						return item.id
					end,
				},
			},
			Host.Frame {
				Compose.keyed {
					from = function(use: Types.Use)
						return use(labels)
					end,
					render = function(value: Types.Readable<Support.Entity>, index: Types.Readable<number>)
						return Host.Frame {
							Name = function(use: Types.Use)
								return use(value).name
							end,
							Size = function(use: Types.Use): number
								local item = use(value)
								return item.level / item.maximum
							end,
							Visible = function(use: Types.Use)
								return use(value).visible and not use(culled)
							end,
							LayoutOrder = index,
						}
					end,
					key = function(item: { id: number })
						return item.id
					end,
				},
			},
		}
	end, context.container)

	return {
		dispose = dispose,
		runtime = runtime,
		summary = summary,
		labels = labels,
		culled = culled,
		scale = scale,
		generation = 0,
	}
end
type State3 = typeof(build3({} :: Types.ComposeContext, {} :: Scale))

local function build4(context: Types.BareContext, scale: Scale)
	local Instance = Support.instances(context)
	local made: { Environment.Instance } = {}
	local root = Instance.new "Frame"
	table.insert(made, root)
	local summaryFrame = Instance.new "Frame"
	summaryFrame.Parent = root
	table.insert(made, summaryFrame)
	local labelFrame = Instance.new "Frame"
	labelFrame.Parent = root
	table.insert(made, labelFrame)

	local summary = Support.entities(scale.summary, "member")
	local labels = Support.entities(scale.size, "label")

	local summaryNodes: { [number]: Environment.Instance } = {}
	local labelNodes: { [number]: Environment.Instance } = {}
	for index, item in summary do
		local node = Instance.new "Frame"
		node.Name = item.name
		node.Size = item.level / item.maximum
		node.Text = item.status
		node.LayoutOrder = index
		node.Parent = summaryFrame
		summaryNodes[item.id] = node
	end
	for index, item in labels do
		local node = Instance.new "Frame"
		node.Name = item.name
		node.Size = item.level / item.maximum
		node.Visible = item.visible
		node.LayoutOrder = index
		node.Parent = labelFrame
		labelNodes[item.id] = node
	end

	root.Parent = context.container
	return {
		made = made,
		root = root,
		summaryFrame = summaryFrame,
		labelFrame = labelFrame,
		summary = summary,
		labels = labels,
		summaryNodes = summaryNodes,
		labelNodes = labelNodes,
		culled = false,
		scale = scale,
		generation = 0,
	}
end
type State4 = typeof(build4({} :: Types.BareContext, {} :: Scale))

local entityLabels: Scenario = {
	id = "entity-labels",
	title = "Summary rows and world-space labels",
	what = "40 keyed summary frames plus up to 1000 keyed labels. The steady frame changes a "
		.. "handful of them; the burst reorders the entities and flips every label's visibility.",
	lane = "scene",
	steadyBudgetSeconds = 0.001,
	scales = {
		{ name = "medium", size = 200, summary = 40, churn = 4 },
		{ name = "large", size = 500, summary = 40, churn = 10 },
		{ name = "extreme", size = 1000, summary = 40, churn = 20 },
	},
	steadyFrames = 120,
	burstRounds = 6,
	samples = 7,
	warmup = 2,
	cases = {
		compose = (({
			build = build3,
			steady = function(state: State3, _context: Types.ComposeContext, tick: number)
				local scale = state.scale
				state.runtime:batch(function()
					local entities = state.labels:peek()
					local next = table.clone(entities)
					for offset = 0, scale.churn - 1 do
						local at = ((tick * 7 + offset * 13) % #next) + 1
						local item = table.clone(next[at])
						item.level = ((tick + offset) % 100) + 1
						item.status = if (tick + offset) % 3 == 0 then "burning" else "none"
						next[at] = item
					end
					state.labels:set(next)
					local party = table.clone((state.summary:peek()))
					local partyAt = (tick % #party) + 1
					local member = table.clone(party[partyAt])
					member.level = (tick % 100) + 1
					party[partyAt] = member
					state.summary:set(party)
				end)
			end,
			burst = function(state: State3, _context: Types.ComposeContext, round: number)
				local _scale = state.scale
				state.generation += 1
				state.runtime:batch(function()
					local entities = state.labels:peek()
					local leaving = math.max(1, math.floor(#entities / 10))
					local next = table.create(#entities) :: { Support.Entity }
					for index = leaving + 1, #entities do
						table.insert(next, entities[index])
					end
					for index = 1, leaving do
						table.insert(next, {
							id = 100000 * state.generation + index,
							name = ("label-new-%d-%d"):format(state.generation, index),
							level = (index % 100) + 1,
							maximum = 100,
							status = "none",
							visible = true,
						})
					end
					state.labels:set(next)
					state.culled:set(round % 2 == 1)
				end)
			end,
			teardown = function(state: State3, _context: Types.ComposeContext)
				state.dispose()
			end,
			snapshot = function(_state: State3, context: Types.ComposeContext): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		} :: Types.Case<State3, Types.ComposeContext>) :: unknown) :: Types.Case<unknown, Types.Context>,

		bare = (({
			build = build4,
			steady = function(state: State4, _context: Types.BareContext, tick: number)
				local scale = state.scale
				for offset = 0, scale.churn - 1 do
					local at = ((tick * 7 + offset * 13) % #state.labels) + 1
					local item = state.labels[at]
					item.level = ((tick + offset) % 100) + 1
					item.status = if (tick + offset) % 3 == 0 then "burning" else "none"
					local node = state.labelNodes[item.id]
					node.Size = item.level / item.maximum
				end
				local partyAt = (tick % #state.summary) + 1
				local member = state.summary[partyAt]
				member.level = (tick % 100) + 1
				state.summaryNodes[member.id].Size = member.level / member.maximum
			end,
			burst = function(state: State4, context: Types.BareContext, round: number)
				local Instance = Support.instances(context)
				state.generation += 1
				local entities = state.labels
				local leaving = math.max(1, math.floor(#entities / 10))
				local next = table.create(#entities) :: { Label }
				for index = leaving + 1, #entities do
					table.insert(next, entities[index])
				end
				for index = 1, leaving do
					table.insert(next, {
						id = 100000 * state.generation + index,
						name = ("label-new-%d-%d"):format(state.generation, index),
						level = (index % 100) + 1,
						maximum = 100,
						status = "none",
						visible = true,
					})
				end

				local wanted: { [number]: boolean } = {}
				for _, item in next do
					wanted[item.id] = true
				end
				for id, node in state.labelNodes do
					if not wanted[id] then
						node:Destroy()
						state.labelNodes[id] = nil
					end
				end
				state.culled = round % 2 == 1
				for index, item in next do
					local node = state.labelNodes[item.id]
					if node == nil then
						node = Instance.new "Frame"
						node.Name = item.name
						node.Size = item.level / item.maximum
						node.Parent = state.labelFrame
						state.labelNodes[item.id] = node
					end
					node.LayoutOrder = index
					node.Visible = item.visible and not state.culled
				end
				state.labels = next
			end,
			teardown = function(state: State4, _context: Types.BareContext)
				for id, node in state.labelNodes do
					node:Destroy()
					state.labelNodes[id] = nil
				end
				for id, node in state.summaryNodes do
					node:Destroy()
					state.summaryNodes[id] = nil
				end
				Support.destroyAll(state.made)
			end,
			snapshot = function(_state: State4, context: Types.BareContext): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		} :: Types.Case<State4, Types.BareContext>) :: unknown) :: Types.Case<unknown, Types.Context>,
	},
}

local function build5(context: Types.ComposeContext, scale: Scale)
	local Compose = context.library
	local runtime = context.extras.runtime
	local Host = runtime.constructors

	local function entities(count: number, prefix: string)
		local items = Support.entities(count, prefix)
		local held = table.create(count) :: { SparseEntity }
		for index, item in items do
			held[index] = {
				id = item.id,
				name = item.name,
				level = Compose.cell(item.level),
				status = Compose.cell(item.status),
				visible = Compose.cell(item.visible),
			}
		end
		return held
	end

	local summary = entities(scale.summary, "member")
	local labels = entities(scale.size, "label")
	local summaryList = Compose.cell(summary)
	local labelList = Compose.cell(labels)
	local culled = Compose.cell(false)

	local dispose = runtime.mount(function()
		return Host.Frame {
			Host.Frame {
				Compose.keyed {
					from = function(use: Types.Use)
						return use(summaryList)
					end,
					render = function(value: Types.Readable<SparseEntity>, index: Types.Readable<number>)
						local item = value:peek()
						return Host.Frame {
							Name = item.name,
							Size = function(use: Types.Use): number
								return (use(item.level) :: number) / 100
							end,
							Text = item.status,
							LayoutOrder = index,
						}
					end,
					key = function(item: { id: number })
						return item.id
					end,
				},
			},
			Host.Frame {
				Compose.keyed {
					from = function(use: Types.Use)
						return use(labelList)
					end,
					render = function(value: Types.Readable<SparseEntity>, index: Types.Readable<number>)
						local item = value:peek()
						return Host.Frame {
							Name = item.name,
							Size = function(use: Types.Use): number
								return (use(item.level) :: number) / 100
							end,
							Visible = function(use: Types.Use)
								return use(item.visible) and not use(culled)
							end,
							LayoutOrder = index,
						}
					end,
					key = function(item: { id: number })
						return item.id
					end,
				},
			},
		}
	end, context.container)

	return {
		dispose = dispose,
		runtime = runtime,
		summary = summary,
		labels = labels,
		labelList = labelList,
		culled = culled,
		scale = scale,
		generation = 0,
		Compose = Compose,
	}
end
type State5 = typeof(build5({} :: Types.ComposeContext, {} :: Scale))

local function build6(context: Types.BareContext, scale: Scale)
	local Instance = Support.instances(context)
	local made: { Environment.Instance } = {}
	local root = Instance.new "Frame"
	table.insert(made, root)
	local summaryFrame = Instance.new "Frame"
	summaryFrame.Parent = root
	table.insert(made, summaryFrame)
	local labelFrame = Instance.new "Frame"
	labelFrame.Parent = root
	table.insert(made, labelFrame)

	local summary = Support.entities(scale.summary, "member")
	local labels = Support.entities(scale.size, "label")
	local summaryNodes: { [number]: Environment.Instance } = {}
	local labelNodes: { [number]: Environment.Instance } = {}
	for index, item in summary do
		local node = Instance.new "Frame"
		node.Name = item.name
		node.Size = item.level / item.maximum
		node.Text = item.status
		node.LayoutOrder = index
		node.Parent = summaryFrame
		summaryNodes[item.id] = node
	end
	for index, item in labels do
		local node = Instance.new "Frame"
		node.Name = item.name
		node.Size = item.level / item.maximum
		node.Visible = item.visible
		node.LayoutOrder = index
		node.Parent = labelFrame
		labelNodes[item.id] = node
	end
	root.Parent = context.container
	return {
		made = made,
		labelFrame = labelFrame,
		summary = summary,
		labels = labels,
		summaryNodes = summaryNodes,
		labelNodes = labelNodes,
		culled = false,
		scale = scale,
		generation = 0,
	}
end
type State6 = typeof(build6({} :: Types.BareContext, {} :: Scale))

local entityLabelsSparse: Scenario = {
	id = "entity-labels-sparse",
	title = "Summary rows and labels, updated per item",
	what = "The same screen as `entity-labels`, with a stable list identity and one cell per "
		.. "item. Both implementations touch only the items that changed.",
	lane = "scene",
	steadyBudgetSeconds = 0.001,
	scales = {
		{ name = "medium", size = 200, summary = 40, churn = 4 },
		{ name = "large", size = 500, summary = 40, churn = 10 },
		{ name = "extreme", size = 1000, summary = 40, churn = 20 },
	},
	steadyFrames = 120,
	burstRounds = 6,
	samples = 7,
	warmup = 2,
	cases = {
		compose = (({
			build = build5,
			steady = function(state: State5, _context: Types.ComposeContext, tick: number)
				local scale = state.scale
				state.runtime:batch(function()
					for offset = 0, scale.churn - 1 do
						local at = ((tick * 7 + offset * 13) % #state.labels) + 1
						local item = state.labels[at]
						item.level:set(((tick + offset) % 100) + 1)
						item.status:set(if (tick + offset) % 3 == 0 then "burning" else "none")
					end
					local partyAt = (tick % #state.summary) + 1
					state.summary[partyAt].level:set((tick % 100) + 1)
				end)
			end,
			burst = function(state: State5, _context: Types.ComposeContext, round: number)
				local Compose = state.Compose
				state.generation += 1
				state.runtime:batch(function()
					local entities = state.labelList:peek()
					local leaving = math.max(1, math.floor(#entities / 10))
					local next = table.create(#entities) :: { SparseEntity }
					for index = leaving + 1, #entities do
						table.insert(next, entities[index])
					end
					for index = 1, leaving do
						table.insert(next, {
							id = 100000 * state.generation + index,
							name = ("label-new-%d-%d"):format(state.generation, index),
							level = Compose.cell((index % 100) + 1),
							status = Compose.cell "none",
							visible = Compose.cell(true),
						})
					end
					state.labels = next
					state.labelList:set(next)
					state.culled:set(round % 2 == 1)
				end)
			end,
			teardown = function(state: State5, _context: Types.ComposeContext)
				state.dispose()
			end,
			snapshot = function(_state: State5, context: Types.ComposeContext): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		} :: Types.Case<State5, Types.ComposeContext>) :: unknown) :: Types.Case<unknown, Types.Context>,

		bare = (({
			build = build6,
			steady = function(state: State6, _context: Types.BareContext, tick: number)
				local scale = state.scale
				for offset = 0, scale.churn - 1 do
					local at = ((tick * 7 + offset * 13) % #state.labels) + 1
					local item = state.labels[at]
					item.level = ((tick + offset) % 100) + 1
					item.status = if (tick + offset) % 3 == 0 then "burning" else "none"
					state.labelNodes[item.id].Size = item.level / item.maximum
				end
				local partyAt = (tick % #state.summary) + 1
				local member = state.summary[partyAt]
				member.level = (tick % 100) + 1
				state.summaryNodes[member.id].Size = member.level / member.maximum
			end,
			burst = function(state: State6, context: Types.BareContext, round: number)
				local Instance = Support.instances(context)
				state.generation += 1
				local entities = state.labels
				local leaving = math.max(1, math.floor(#entities / 10))
				local next = table.create(#entities) :: { Label }
				for index = leaving + 1, #entities do
					table.insert(next, entities[index])
				end
				for index = 1, leaving do
					table.insert(next, {
						id = 100000 * state.generation + index,
						name = ("label-new-%d-%d"):format(state.generation, index),
						level = (index % 100) + 1,
						maximum = 100,
						status = "none",
						visible = true,
					})
				end
				local wanted: { [number]: boolean } = {}
				for _, item in next do
					wanted[item.id] = true
				end
				for id, node in state.labelNodes do
					if not wanted[id] then
						node:Destroy()
						state.labelNodes[id] = nil
					end
				end
				state.culled = round % 2 == 1
				for index, item in next do
					local node = state.labelNodes[item.id]
					if node == nil then
						node = Instance.new "Frame"
						node.Name = item.name
						node.Size = item.level / item.maximum
						node.Parent = state.labelFrame
						state.labelNodes[item.id] = node
					end
					node.LayoutOrder = index
					node.Visible = item.visible and not state.culled
				end
				state.labels = next
			end,
			teardown = function(state: State6, _context: Types.BareContext)
				for id, node in state.labelNodes do
					node:Destroy()
					state.labelNodes[id] = nil
				end
				for id, node in state.summaryNodes do
					node:Destroy()
					state.summaryNodes[id] = nil
				end
				Support.destroyAll(state.made)
			end,
			snapshot = function(_state: State6, context: Types.BareContext): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		} :: Types.Case<State6, Types.BareContext>) :: unknown) :: Types.Case<unknown, Types.Context>,
	},
}

return {
	dashboard = dashboard,
	entityLabels = entityLabels,
	entityLabelsSparse = entityLabelsSparse,
}
