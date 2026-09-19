--!strict

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
	return {
		id = id,
		title = title,
		what = what,
		lane = lane,
		steadyBudgetSeconds = budget,
		scales = scales,
		steadyFrames = 90,
		burstRounds = 6,
		samples = 7,
		warmup = 2,
		cases = {
			compose = {
				build = function(context: Context, scale: Scale): any
					local Compose = context.library
					local runtime = context.extras.runtime
					local create = runtime.create

					local pool = Support.items(scale.size)
					local quantities = table.create(#pool)
					for index, item in pool do
						quantities[index] = Compose.cell(item.quantity)
					end
					local byId: { [number]: any } = {}
					for index, item in pool do
						byId[item.id] = quantities[index]
					end
					local filter = Compose.cell ""
					local sort = Compose.cell "rarity"
					local first = Compose.cell(1)
					local selected = Compose.cell {}
					local logical = Compose.formula(function(use)
						return project(pool, use(filter), use(sort))
					end)

					local dispose = runtime.mount(function()
						return create "Frame" {
							Compose.OrderedCollection {
								from = logical,
								mode = "windowed",
								layout = { itemSize = 1 },
								viewport = function(use)
									return { offset = (use(first) :: number) - 1, size = scale.visible }
								end,
								key = function(item: Item)
									return item.id
								end,
								render = function(value: any, absolute: any, key: any)
									return create "Frame" {
										Name = function(use): string
											return (use(value) :: any).name
										end,
										Text = function(use): string
											local item: any = use(value)
											return ("%d"):format(use(byId[item.id]) :: number)
										end,
										Visible = function(use)
											return (use(selected) :: any)[key] == true
										end,
										LayoutOrder = function(use: any)
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
				end,
				steady = function(state: any, _context: Context, tick: number)
					local scale = state.scale
					state.runtime:batch(function()
						state.first:set(((tick * 3) % (scale.size - scale.visible)) + 1)
						local at = ((tick * 17) % scale.size) + 1
						state.byId[state.pool[at].id]:set((tick % 99) + 1)
					end)
				end,
				burst = function(state: any, _context: Context, round: number)
					local kinds = Support.KINDS
					state.runtime:batch(function()
						state.filter:set(if round % 3 == 0 then "" else kinds[(round % #kinds) + 1])
						state.sort:set(if round % 2 == 0 then "name" else "rarity")
						local chosen: { [number]: boolean } = {}
						for index = 1, state.scale.size, 7 do
							chosen[index] = true
						end
						state.selected:set(chosen)
					end)
				end,
				teardown = function(state: any, _context: Context)
					state.dispose()
				end,
				snapshot = function(_state: any, context: Context): string
					return context.env.snapshot(context.container, { "Name", "Text", "Visible", "LayoutOrder" })
				end,
			},

			bare = {
				build = function(context: Context, scale: Scale): any
					local Instance = Support.instances(context)
					local pool = Support.items(scale.size)
					local root = Instance.new "Frame"
					root.Parent = context.container
					local quantities: { [number]: number } = {}
					for _, item in pool do
						quantities[item.id] = item.quantity
					end
					local state = {
						root = root,
						pool = pool,
						filter = "",
						sort = "rarity",
						first = 1,
						selected = {} :: { [number]: boolean },
						scale = scale,
						logical = project(pool, "", "rarity"),
						quantities = quantities,
						nodes = {} :: { [number]: any },
						order = {} :: { number },
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
					(state :: any).slice = slice
					slice()
					return state
				end,
				steady = function(state: any, _context: Context, tick: number)
					local scale = state.scale
					state.first = ((tick * 3) % (scale.size - scale.visible)) + 1
					local at = ((tick * 17) % scale.size) + 1
					state.quantities[state.pool[at].id] = (tick % 99) + 1
					state.slice()
				end,
				burst = function(state: any, _context: Context, round: number)
					local kinds = Support.KINDS
					state.filter = if round % 3 == 0 then "" else kinds[(round % #kinds) + 1]
					state.sort = if round % 2 == 0 then "name" else "rarity"
					local chosen: { [number]: boolean } = {}
					for index = 1, state.scale.size, 7 do
						chosen[index] = true
					end
					state.selected = chosen
					state.logical = project(state.pool, state.filter, state.sort)
					state.slice()
				end,
				teardown = function(state: any, _context: Context)
					for id, node in state.nodes do
						node:Destroy()
						state.nodes[id] = nil
					end
					state.root:Destroy()
				end,
				snapshot = function(_state: any, context: Context): string
					return context.env.snapshot(context.container, { "Name", "Text", "Visible", "LayoutOrder" })
				end,
			},
		},
	}
end

local inventory = make(
	"virtual-inventory",
	"Virtualized inventory over a large item pool",
	"10 000 logical items behind a window of 60. The steady frame scrolls one row and updates one "
		.. "cell; the burst changes the filter, the sort, and a selection spanning the whole list.",
	"game",
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
	inventory = inventory,
	grid = grid,
}
