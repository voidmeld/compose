--!strict

local Environment = require "../cost-model"
local Trace = require "./trace"
local Types = require "../scenarios/types"
local Items = require "./items"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local PARITY_KEYS = { "Name", "Text", "Category", "Group", "LayoutOrder" }

local entityLists: { [number]: { Trace.Entity } } = {}
local function entitiesFor(count: number): { Trace.Entity }
	local held = entityLists[count]
	if held == nil then
		held = Trace.entities(count)
		entityLists[count] = held
	end
	return held
end

local traces: { [string]: { Trace.Tick } } = {}
local function traceFor(count: number, fraction: number): { Trace.Tick }
	local key = ("%d:%.2f"):format(count, fraction)
	local held = traces[key]
	if held == nil then
		held = Trace.generate {
			count = count,
			frames = 480,
			snapshotHz = 20,
			renderHz = 60,
			churnLow = 0.05,
			churnHigh = 0.15,
			burstEvery = 0,
			identityEvery = 6,
			identityFraction = fraction,
			sweepEvery = 0,
		}
		traces[key] = held
	end
	return held
end

local function editEntities(entities: { Trace.Entity }, tick: Trace.Tick, nextId: { value: number }): boolean
	local structural = false
	for _, edit in tick.identity do
		local count = #entities
		if count == 0 then
			break
		end
		local at = ((edit.index - 1) % count) + 1
		if edit.kind == "leave" and count > 8 then
			table.remove(entities, at)
			structural = true
		elseif edit.kind == "join" then
			nextId.value += 1
			local template = entities[at]
			table.insert(entities, at, {
				id = nextId.value,
				name = ("Recruit %d"):format(nextId.value),
				category = template.category,
				group = template.group,
				level = 1000,
				maximum = 1000,
				state = 1,
				status = 0,
				distance = 100,
				visible = true,
			})
			structural = true
		elseif edit.kind == "reorder" and at < count then
			entities[at], entities[at + 1] = entities[at + 1], entities[at]
			structural = true
		elseif edit.kind == "death" then
			entities[at].state = 0
		elseif edit.kind == "rez" then
			entities[at].state = 1
			entities[at].level = entities[at].maximum
		elseif edit.kind == "category" then
			entities[at].category = edit.value
		elseif edit.kind == "group" then
			entities[at].group = edit.value
		end
	end
	return structural
end

local function composeCase(fraction: number): Types.Case<unknown, Types.Context>
	local function build1(context: Types.ComposeContext, scale: Scale)
		local Compose = context.library
		local runtime = context.extras.runtime
		local Host = runtime.constructors

		local items = Items.sparse(entitiesFor(scale.size), Compose.cell)
		local byId: { [number]: Items.Item } = {}
		for _, item in items do
			byId[item.id] = item
		end
		local order = Compose.cell(items)

		local dispose = runtime.mount(function()
			return Host.Frame {
				Name = "Entities",
				Compose.keyed {
					from = function(use: Types.Use): { Items.Item }
						return use(order)
					end,
					render = function(value: Types.Readable<Items.Item>, index: Types.Readable<number>)
						local item = value:peek()
						return Host.Frame {
							Name = ("Row%d"):format(item.id),
							Text = function(use: Types.Use): string
								local current = use(value)
								return Items.summaryText(
									current.name,
									use(current.level),
									current.maximum,
									use(current.state)
								)
							end,
							Category = function(use: Types.Use): number
								return use(use(value).category)
							end,
							Group = function(use: Types.Use): number
								return use(use(value).group)
							end,
							LayoutOrder = function(use: Types.Use): number
								return use(index)
							end,
						}
					end,
					key = function(item: Items.Item): number
						return item.id
					end,
				},
			}
		end, context.container)

		return {
			dispose = dispose,
			items = items,
			byId = byId,
			order = order,
			cell = Compose.cell,
			runtime = runtime,

			size = scale.size,
			nextId = { value = scale.size },
			peakPending = 0,
		}
	end
	type State1 = typeof(build1({} :: Types.ComposeContext, {} :: Scale))

	return (
		(
			{
				build = build1,

				steady = function(state: State1, _context: Types.ComposeContext, frame: number)
					local trace = traceFor(state.size, fraction)
					local tick = trace[((frame - 1) % #trace) + 1]
					local runtime = state.runtime

					runtime:batch(function()
						for _, change in tick.changes do
							local item = state.order:peek()[((change.index - 1) % #state.order:peek()) + 1]
							if item ~= nil then
								item.level:set(change.level)
								item.state:set(change.state)
								item.status:set(change.status)
							end
						end

						if #tick.identity == 0 then
							return
						end

						local current = table.clone((state.order:peek()))
						local structural = false
						for _, edit in tick.identity do
							local count = #current
							if count == 0 then
								break
							end
							local at = ((edit.index - 1) % count) + 1
							local item = current[at]
							if edit.kind == "leave" and count > 8 then
								table.remove(current, at)
								structural = true
							elseif edit.kind == "join" then
								state.nextId.value += 1
								local id = state.nextId.value
								local made = {
									id = id,
									name = ("Recruit %d"):format(id),
									maximum = 1000,
									level = state.cell(1000),
									state = state.cell(1),
									status = state.cell(0),
									distance = state.cell(100),
									visible = state.cell(true),
									category = state.cell(item.category:peek()),
									group = state.cell(item.group:peek()),
								}
								table.insert(current, at, made)
								structural = true
							elseif edit.kind == "reorder" and at < count then
								current[at], current[at + 1] = current[at + 1], current[at]
								structural = true
							elseif edit.kind == "death" then
								item.state:set(0)
							elseif edit.kind == "rez" then
								item.state:set(1)
								item.level:set(item.maximum)
							elseif edit.kind == "category" then
								item.category:set(edit.value)
							elseif edit.kind == "group" then
								item.group:set(edit.value)
							end
						end
						if structural then
							state.order:set(current)
						end
					end)

					local pending = runtime:pending()
					if pending > state.peakPending then
						state.peakPending = pending
					end
				end,

				burst = function(state: State1, _context: Types.ComposeContext, round: number)
					local runtime = state.runtime
					runtime:batch(function()
						local current = table.clone((state.order:peek()))
						local removing = #current // 2
						for _ = 1, removing do
							if #current > 8 then
								table.remove(current, ((round * 3) % #current) + 1)
							end
						end
						for index = 1, removing // 2 do
							state.nextId.value += 1
							local id = state.nextId.value
							table.insert(current, {
								id = id,
								name = ("Recruit %d"):format(id),
								maximum = 1000,
								level = state.cell(1000),
								state = state.cell(1),
								status = state.cell(0),
								distance = state.cell(100),
								visible = state.cell(true),
								category = state.cell((index % 2) + 1),
								group = state.cell(index),
							})
						end
						state.order:set(current)
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

local function bareCase(fraction: number): Types.Case<unknown, Types.Context>
	local function reconcile(state: {
		entities: { Trace.Entity },
		nodes: { [number]: Environment.Instance },
		parent: Environment.Instance,
		Instance: Environment.InstanceFactory,
	})
		local entities = state.entities
		local wanted: { [number]: number } = {}
		for index, item in entities do
			wanted[item.id] = index
		end
		for id, node in state.nodes do
			if wanted[id] == nil then
				node:Destroy()
				state.nodes[id] = nil
			end
		end
		for index, item in entities do
			local node = state.nodes[item.id]
			if node == nil then
				node = state.Instance.new "Frame"
				node.Name = ("Row%d"):format(item.id)
				node.Parent = state.parent
				state.nodes[item.id] = node
			end
			node.Text = Items.summaryText(item.name, item.level, item.maximum, item.state)
			node.Category = item.category
			node.Group = item.group
			node.LayoutOrder = index
		end
	end

	local function build2(context: Types.BareContext, scale: Scale)
		local Instance = context.env.globals.Instance
		local parent = Instance.new "Frame"
		parent.Name = "Entities"
		parent.Parent = context.container
		local state = {
			entities = Items.copy(entitiesFor(scale.size)),
			nodes = {} :: { [number]: Environment.Instance },
			parent = parent,
			Instance = Instance,
			size = scale.size,
			nextId = { value = scale.size },
		}
		reconcile(state)
		return state
	end
	type State2 = typeof(build2({} :: Types.BareContext, {} :: Scale))

	return (
		(
			{
				build = build2,

				steady = function(state: State2, _context: Types.BareContext, frame: number)
					local trace = traceFor(state.size, fraction)
					local tick = trace[((frame - 1) % #trace) + 1]
					for _, change in tick.changes do
						local at = ((change.index - 1) % #state.entities) + 1
						local item = state.entities[at]
						item.level = change.level
						item.state = change.state
						item.status = change.status
						local node = state.nodes[item.id]
						if node ~= nil then
							node.Text = Items.summaryText(item.name, item.level, item.maximum, item.state)
						end
					end
					if #tick.identity > 0 then
						editEntities(state.entities, tick, state.nextId)
						reconcile(state)
					end
				end,

				burst = function(state: State2, _context: Types.BareContext, round: number)
					local entities = state.entities
					local removing = #entities // 2
					for _ = 1, removing do
						if #entities > 8 then
							table.remove(entities, ((round * 3) % #entities) + 1)
						end
					end
					for index = 1, removing // 2 do
						state.nextId.value += 1
						local id = state.nextId.value
						table.insert(entities, {
							id = id,
							name = ("Recruit %d"):format(id),
							category = (index % 2) + 1,
							group = index,
							level = 1000,
							maximum = 1000,
							state = 1,
							status = 0,
							distance = 100,
							visible = true,
						})
					end
					reconcile(state)
				end,

				teardown = function(state: State2, _context: Types.BareContext)
					for _, node in state.nodes do
						node:Destroy()
					end
					state.nodes = {}
					state.parent:Destroy()
				end,

				snapshot = function(_state: State2, context: Types.BareContext): string
					return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
				end,
			} :: Types.Case<State2, Types.BareContext>
		) :: unknown
	) :: Types.Case<unknown, Types.Context>
end

local churn: Scenario = {
	id = "entities-identity-churn",
	title = "Identity churn: joins, leaves, state flips, category and group changes, reorders",
	what = "Every sixth frame replaces a fraction of the membership while values keep "
		.. "changing underneath. Measured for cost and audited for exact disposal.",
	lane = "scene",
	steadyBudgetSeconds = 0.0012,
	scales = {
		{ name = "medium", size = 200 },
		{ name = "large", size = 400 },
		{ name = "extreme", size = 1000 },
	},
	steadyFrames = 120,
	burstRounds = 6,
	samples = 7,
	warmup = 2,
	cases = { compose = composeCase(0.25), bare = bareCase(0.25) },
}

local function at(rate: number, id: string, budget: number): Scenario
	local made = table.clone(churn)
	made.id = id
	made.title = ("Identity churn at %d%% replacement"):format(math.floor(rate * 100))
	made.steadyBudgetSeconds = budget
	made.cases = { compose = composeCase(rate), bare = bareCase(rate) }
	return made
end

return {
	churn = churn,
	churnLight = at(0.10, "entities-identity-churn-10", 0.0006),
	churnHeavy = at(0.50, "entities-identity-churn-50", 0.0024),
}
