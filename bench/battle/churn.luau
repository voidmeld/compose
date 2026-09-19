--!strict

local Trace = require "./trace"
local Types = require "../scenarios/types"
local Units = require "./units"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local PARITY_KEYS = { "Name", "Text", "Faction", "Group", "LayoutOrder" }

local rosters: { [number]: { Trace.Combatant } } = {}
local function rosterFor(count: number): { Trace.Combatant }
	local held = rosters[count]
	if held == nil then
		held = Trace.roster(count)
		rosters[count] = held
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

local function editRoster(roster: { any }, tick: Trace.Tick, nextId: { value: number }): boolean
	local structural = false
	for _, edit in tick.identity do
		local count = #roster
		if count == 0 then
			break
		end
		local at = ((edit.index - 1) % count) + 1
		if edit.kind == "leave" and count > 8 then
			table.remove(roster, at)
			structural = true
		elseif edit.kind == "join" then
			nextId.value += 1
			local template = roster[at]
			table.insert(roster, at, {
				id = nextId.value,
				name = ("Recruit %d"):format(nextId.value),
				faction = template.faction,
				group = template.group,
				health = 1000,
				maximum = 1000,
				state = 1,
				status = 0,
				distance = 100,
				visible = true,
			})
			structural = true
		elseif edit.kind == "reorder" and at < count then
			roster[at], roster[at + 1] = roster[at + 1], roster[at]
			structural = true
		elseif edit.kind == "death" then
			roster[at].state = 0
		elseif edit.kind == "rez" then
			roster[at].state = 1
			roster[at].health = roster[at].maximum
		elseif edit.kind == "faction" then
			roster[at].faction = edit.value
		elseif edit.kind == "group" then
			roster[at].group = edit.value
		end
	end
	return structural
end

local function composeCase(fraction: number): Types.Case
	return {
		build = function(context: Context, scale: Scale): any
			local Compose = context.library
			local runtime = context.extras.runtime
			local Host = runtime.constructors

			local units = Units.sparse(rosterFor(scale.size), Compose.cell)
			local byId: { [number]: any } = {}
			for _, unit in units do
				byId[unit.id] = unit
			end
			local order = Compose.cell(units)

			local dispose = runtime.mount(function()
				return Host.Frame {
					Name = "Roster",
					Compose.keyed {
						from = function(use: any): { Units.Unit }
							return use(order)
						end,
						render = function(value: any, index: any)
							local unit = value:peek()
							return Host.Frame {
								Name = ("Row%d"):format(unit.id),
								Text = function(use: any): string
									local current = use(value)
									return Units.raidText(
										current.name,
										use(current.health),
										current.maximum,
										use(current.state)
									)
								end,
								Faction = function(use: any): number
									return use(use(value).faction)
								end,
								Group = function(use: any): number
									return use(use(value).group)
								end,
								LayoutOrder = function(use: any): number
									return use(index)
								end,
							}
						end,
						key = function(unit: any): number
							return unit.id
						end,
					},
				}
			end, context.container)

			return {
				dispose = dispose,
				units = units,
				byId = byId,
				order = order,
				cell = Compose.cell,
				runtime = runtime,

				size = scale.size,
				nextId = { value = scale.size },
				peakPending = 0,
			}
		end,

		steady = function(state: any, _context: Context, frame: number)
			local trace = traceFor(state.size, fraction)
			local tick = trace[((frame - 1) % #trace) + 1]
			local runtime = state.runtime

			runtime:batch(function()
				for _, change in tick.changes do
					local unit = state.order:peek()[((change.index - 1) % #state.order:peek()) + 1]
					if unit ~= nil then
						unit.health:set(change.health)
						unit.state:set(change.state)
						unit.status:set(change.status)
					end
				end

				if #tick.identity == 0 then
					return
				end

				local current = table.clone(state.order:peek())
				local structural = false
				for _, edit in tick.identity do
					local count = #current
					if count == 0 then
						break
					end
					local at = ((edit.index - 1) % count) + 1
					local unit = current[at]
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
							health = state.cell(1000),
							state = state.cell(1),
							status = state.cell(0),
							distance = state.cell(100),
							visible = state.cell(true),
							faction = state.cell(unit.faction:peek()),
							group = state.cell(unit.group:peek()),
						}
						table.insert(current, at, made)
						structural = true
					elseif edit.kind == "reorder" and at < count then
						current[at], current[at + 1] = current[at + 1], current[at]
						structural = true
					elseif edit.kind == "death" then
						unit.state:set(0)
					elseif edit.kind == "rez" then
						unit.state:set(1)
						unit.health:set(unit.maximum)
					elseif edit.kind == "faction" then
						unit.faction:set(edit.value)
					elseif edit.kind == "group" then
						unit.group:set(edit.value)
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

		burst = function(state: any, _context: Context, round: number)
			local runtime = state.runtime
			runtime:batch(function()
				local current = table.clone(state.order:peek())
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
						health = state.cell(1000),
						state = state.cell(1),
						status = state.cell(0),
						distance = state.cell(100),
						visible = state.cell(true),
						faction = state.cell((index % 2) + 1),
						group = state.cell(index),
					})
				end
				state.order:set(current)
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

local function bareCase(fraction: number): Types.Case
	local function reconcile(state: any)
		local roster = state.roster
		local wanted: { [number]: number } = {}
		for index, unit in roster do
			wanted[unit.id] = index
		end
		for id, node in state.nodes do
			if wanted[id] == nil then
				node:Destroy()
				state.nodes[id] = nil
			end
		end
		for index, unit in roster do
			local node = state.nodes[unit.id]
			if node == nil then
				node = state.Instance.new "Frame"
				node.Name = ("Row%d"):format(unit.id)
				node.Parent = state.parent
				state.nodes[unit.id] = node
			end
			node.Text = Units.raidText(unit.name, unit.health, unit.maximum, unit.state)
			node.Faction = unit.faction
			node.Group = unit.group
			node.LayoutOrder = index
		end
	end

	return {
		build = function(context: Context, scale: Scale): any
			local Instance = context.env.globals.Instance
			local parent = Instance.new "Frame"
			parent.Name = "Roster"
			parent.Parent = context.container
			local state = {
				roster = Units.copy(rosterFor(scale.size)),
				nodes = {} :: { [number]: any },
				parent = parent,
				Instance = Instance,
				size = scale.size,
				nextId = { value = scale.size },
			}
			reconcile(state)
			return state
		end,

		steady = function(state: any, _context: Context, frame: number)
			local trace = traceFor(state.size, fraction)
			local tick = trace[((frame - 1) % #trace) + 1]
			for _, change in tick.changes do
				local at = ((change.index - 1) % #state.roster) + 1
				local unit = state.roster[at]
				unit.health = change.health
				unit.state = change.state
				unit.status = change.status
				local node = state.nodes[unit.id]
				if node ~= nil then
					node.Text = Units.raidText(unit.name, unit.health, unit.maximum, unit.state)
				end
			end
			if #tick.identity > 0 then
				editRoster(state.roster, tick, state.nextId)
				reconcile(state)
			end
		end,

		burst = function(state: any, _context: Context, round: number)
			local roster = state.roster
			local removing = #roster // 2
			for _ = 1, removing do
				if #roster > 8 then
					table.remove(roster, ((round * 3) % #roster) + 1)
				end
			end
			for index = 1, removing // 2 do
				state.nextId.value += 1
				local id = state.nextId.value
				table.insert(roster, {
					id = id,
					name = ("Recruit %d"):format(id),
					faction = (index % 2) + 1,
					group = index,
					health = 1000,
					maximum = 1000,
					state = 1,
					status = 0,
					distance = 100,
					visible = true,
				})
			end
			reconcile(state)
		end,

		teardown = function(state: any, _context: Context)
			for _, node in state.nodes do
				node:Destroy()
			end
			state.nodes = {}
			state.parent:Destroy()
		end,

		snapshot = function(_state: any, context: Context): string
			return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
		end,
	}
end

local churn: Scenario = {
	id = "battle-identity-churn",
	title = "Identity churn: joins, leaves, deaths, faction and group changes, reorders",
	what = "Every sixth frame replaces a fraction of the roster's membership while values keep "
		.. "changing underneath. Measured for cost and audited for exact disposal.",
	lane = "game",
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
	churnLight = at(0.10, "battle-identity-churn-10", 0.0006),
	churnHeavy = at(0.50, "battle-identity-churn-50", 0.0024),
}
