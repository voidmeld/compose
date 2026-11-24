--!strict

local Environment = require "../cost-model"
local Support = require "./support"
local Types = require "./types"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario
type Item = Support.Item

local function project(pool: { Item }, filter: string, sort: string): { Item }
	local kept: { Item } = {}
	for _, item in pool do
		if Support.matches(item, filter) then
			table.insert(kept, item)
		end
	end
	table.sort(kept, function(left: Item, right: Item): boolean
		return Support.sortKey(left, sort) < Support.sortKey(right, sort)
	end)
	return kept
end

local function make(id: string, title: string, what: string, lane: string, budget: number, scales: { Scale }): Scenario
	local function build1(context: Types.ComposeContext, scale: Scale)
		local Compose = context.library
		local runtime = context.extras.runtime
		local Host = runtime.constructors

		local pool = Support.items(scale.size)
		local createQuantities: (number, Types.Cell<number>?) -> { Types.Cell<number> } = table.create
		local quantities: { Types.Cell<number> } = createQuantities(#pool)
		for index, item in pool do
			quantities[index] = Compose.cell(item.quantity)
		end
		local byId: { [number]: Types.Cell<number> } = {}
		for index, item in pool do
			byId[item.id] = quantities[index]
		end
		local filter = Compose.cell ""
		local sort = Compose.cell "priority"
		local first = Compose.cell(1)
		local initialselected: { [number]: boolean } = {}
		local selected = Compose.cell(initialselected)
		local logical = Compose.formula(function(use: Types.Use)
			return project(pool, use(filter), use(sort))
		end)

		local layout: Types.OrderedCollectionLayout = { itemSize = 1 }
		local dispose = runtime.mount(function()
			return Host.Frame {
				Compose.OrderedCollection {
					from = logical,
					mode = "windowed",
					layout = layout,
					viewport = function(use: Types.Use): Types.OrderedCollectionViewport
						return { offset = (use(first)) - 1, size = scale.visible }
					end,
					key = function(item: Item)
						return item.id
					end,
					render = function(
						value: Types.Readable<Item>,
						absolute: Types.Readable<Types.Placement>,
						key: number
					)
						return Host.Frame {
							Name = function(use: Types.Use): string
								return use(value).name
							end,
							Text = function(use: Types.Use): string
								local item = use(value)
								return ("%d"):format(use(byId[item.id]))
							end,
							Visible = function(use: Types.Use)
								return use(selected)[key] == true
							end,
							LayoutOrder = function(use: Types.Use)
								return use(absolute).index
							end,
						}
					end,
				},
			}
		end, context.container)

		return {
			dispose = dispose,
			runtime = runtime,
			pool = pool,
			filter = filter,
			sort = sort,
			first = first,
			selected = selected,
			byId = byId,
			scale = scale,
		}
	end
	type State1 = typeof(Types.resultOf(build1))

	local function build2(context: Types.PlainContext, scale: Scale)
		local Instance = Support.instances(context)
		local pool = Support.items(scale.size)
		local root = Instance.new "Frame"
		root.Parent = context.container
		local quantities: { [number]: number } = {}
		for _, item in pool do
			quantities[item.id] = item.quantity
		end
		local orderValue: { number } = {}
		local selectedValue: { [number]: boolean } = {}
		local nodesValue: { [number]: Environment.Instance } = {}
		local state = {
			root = root,
			pool = pool,
			filter = "",
			sort = "priority",
			first = 1,
			selected = selectedValue,
			scale = scale,
			logical = project(pool, "", "priority"),
			quantities = quantities,
			nodes = nodesValue,
			order = orderValue,
		}

		local function slice()
			local from = math.max(1, state.first)
			local to = math.min(#state.logical, from + scale.visible - 1)
			local wanted: { [number]: boolean } = {}
			local order: { number } = {}
			for index = from, to do
				local item = state.logical[index]
				wanted[item.id] = true
				table.insert(order, item.id)
				local node = state.nodes[item.id]
				if node == nil then
					node = Instance.new "Frame"
					node.Parent = root
					state.nodes[item.id] = node
				end
				node.Name = item.name
				node.Text = ("%d"):format(state.quantities[item.id])
				node.Visible = state.selected[item.id] == true
				node.LayoutOrder = index
			end
			for id, node in state.nodes do
				if not wanted[id] then
					node:Destroy()
					state.nodes[id] = nil
				end
			end
			state.order = order
		end
		state.slice = slice
		slice()
		return state
	end
	type State2 = typeof(Types.resultOf(build2))

	return {
		id = id,
		title = title,
		what = what,
		lane = lane,
		steadyBudgetSeconds = budget,
		scales = scales,
		steadyFrames = 90,
		burstRounds = 6,
		warmup = 2,
		cases = {
			compose = Types.compose {
				build = build1,
				steady = function(state: State1, _context: Types.ComposeContext, tick: number)
					local scale = state.scale
					state.runtime:batch(function()
						state.first:set(((tick * 3) % (scale.size - scale.visible)) + 1)
						local at = ((tick * 17) % scale.size) + 1
						state.byId[state.pool[at].id]:set((tick % 99) + 1)
					end)
				end,
				burst = function(state: State1, _context: Types.ComposeContext, round: number)
					local kinds = Support.KINDS
					state.runtime:batch(function()
						state.filter:set(if round % 3 == 0 then "" else kinds[(round % #kinds) + 1])
						state.sort:set(if round % 2 == 0 then "name" else "priority")
						local chosen: { [number]: boolean } = {}
						for index = 1, state.scale.size, 7 do
							chosen[index] = true
						end
						state.selected:set(chosen)
					end)
				end,
				teardown = function(state: State1, _context: Types.ComposeContext)
					state.dispose()
				end,
				snapshot = function(_state: State1, context: Types.ComposeContext): string
					return context.env.snapshot(context.container, { "Name", "Text", "Visible", "LayoutOrder" })
				end,
			},

			plain = Types.plain {
				build = build2,
				steady = function(state: State2, _context: Types.PlainContext, tick: number)
					local scale = state.scale
					state.first = ((tick * 3) % (scale.size - scale.visible)) + 1
					local at = ((tick * 17) % scale.size) + 1
					state.quantities[state.pool[at].id] = (tick % 99) + 1
					state.slice()
				end,
				burst = function(state: State2, _context: Types.PlainContext, round: number)
					local kinds = Support.KINDS
					state.filter = if round % 3 == 0 then "" else kinds[(round % #kinds) + 1]
					state.sort = if round % 2 == 0 then "name" else "priority"
					local chosen: { [number]: boolean } = {}
					for index = 1, state.scale.size, 7 do
						chosen[index] = true
					end
					state.selected = chosen
					state.logical = project(state.pool, state.filter, state.sort)
					state.slice()
				end,
				teardown = function(state: State2, _context: Types.PlainContext)
					for id, node in state.nodes do
						node:Destroy()
						state.nodes[id] = nil
					end
					state.root:Destroy()
				end,
				snapshot = function(_state: State2, context: Types.PlainContext): string
					return context.env.snapshot(context.container, { "Name", "Text", "Visible", "LayoutOrder" })
				end,
			},
		},
	}
end

local filteredList = make(
	"virtual-filtered-list",
	"Virtualized filtered list over a large item pool",
	"10 000 logical items behind a window of 60. The steady frame scrolls one row and updates one "
		.. "cell; the burst changes the filter, the sort, and a selection spanning the whole list.",
	"scene",
	0.0015,
	{
		{ name = "medium", size = 2000, visible = 40 },
		{ name = "large", size = 10000, visible = 60 },
		{ name = "extreme", size = 50000, visible = 100 },
	}
)

local grid = make(
	"data-grid",
	"Virtualized data grid with sorting, filtering and multi-selection",
	"The same virtualization at editor scale: 10 000 rows behind a window of 100, sorted and "
		.. "filtered, with a selection spanning the whole grid and sparse cell updates.",
	"app",
	0.002,
	{
		{ name = "medium", size = 5000, visible = 60 },
		{ name = "large", size = 10000, visible = 100 },
		{ name = "extreme", size = 50000, visible = 200 },
	}
)

return {
	filteredList = filteredList,
	grid = grid,
}
