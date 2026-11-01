--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect, beforeEach = Test.describe, Test.it, Test.expect, Test.beforeEach

type Row = { id: string, label: string }

local function rows(count: number): { Row }
	local allocateList: (number, Row?) -> { Row } = table.create
	local list: { Row } = allocateList(count)
	for index = 1, count do
		list[index] = { id = "r" .. index, label = "row " .. index }
	end
	return list
end

local function idOf(row: Row): string
	return row.id
end

local world: Support.World

local function mount(options: {
	count: number,
	mode: Compose.OrderedCollectionMode,
	viewport: Compose.Value<Compose.OrderedCollectionViewport>?,
	layout: (
		Compose.OrderedCollectionLayout
		| Compose.ReadOnlyValue<Compose.OrderedCollectionLayout>
		| Compose.Body<Compose.OrderedCollectionLayout>
	)?,
	overscan: number?,
	follow: ("end" | "none")?,
	measured: Compose.Value<{ [string]: number }>?,
	status: Compose.Value<Compose.OrderedCollectionStatus>?,
	controls: Compose.OrderedCollectionControls<string>?,
})
	local items = Compose.cell(rows(options.count))
	local dispose, root = world.runtime.mount(function()
		return world.create "Frame" {
			Compose.OrderedCollection {
				from = items,
				key = idOf,
				mode = options.mode,
				viewport = options.viewport,
				layout = options.layout
					or (function(value: Compose.OrderedCollectionLayout): Compose.OrderedCollectionLayout
						return value
					end) { itemSize = 10 },
				overscan = options.overscan,
				follow = options.follow,
				measured = options.measured,
				status = options.status,
				controls = options.controls,
				render = function(value, placement)
					return world.create "Row" {
						Id = function(use)
							return use(value).id
						end,
						Offset = function(use)
							return use(placement).offset
						end,
					}
				end,
			},
		}
	end, world.root)
	return dispose, root, items
end

local function idsOf(root: Compose.Node): { string }
	local names: { string } = {}
	for _, child in world.host.childrenOf(root) do
		table.insert(names, tostring(world.host.propertyOf(child, "Id")))
	end
	return names
end

describe("OrderedCollection recycle", function()
	beforeEach(function()
		world = Support.world()
	end)

	local function mountRecycled(
		items: Compose.Value<{ Row }>,
		viewport: Compose.Value<Compose.OrderedCollectionViewport>
	)
		local renders = 0
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.OrderedCollection {
					from = items,
					key = idOf,
					mode = "windowed",
					viewport = viewport,
					layout = (function(value: Compose.OrderedCollectionLayout): Compose.OrderedCollectionLayout
						return value
					end) { itemSize = 10 },
					overscan = 0,
					recycle = function(value, placement, key)
						renders += 1
						return world.create "Row" {
							Id = function(use)
								return use(value).id
							end,
							Key = function(use)
								return use(key)
							end,
							Offset = function(use)
								return use(placement).offset
							end,
						}
					end,
				},
			}
		end, world.root)
		return dispose, root, function(): number
			return renders
		end
	end

	it("reuses mounted rows when the window scrolls to new keys", function()
		local items = Compose.cell(rows(500))
		local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
		local viewport = Compose.cell(initialViewport)
		local dispose, root, renders = mountRecycled(items, viewport)
		local before = world.host.childrenOf(root)
		expect(idsOf(root)):toEqual { "r1", "r2", "r3" }
		expect(renders()):toBe(3)
		viewport:set((function(value: Compose.OrderedCollectionViewport): Compose.OrderedCollectionViewport
			return value
		end) { offset = 2000, size = 30 })
		expect(idsOf(root)):toEqual { "r201", "r202", "r203" }
		expect(renders()):toBe(3)
		local after = world.host.childrenOf(root)
		for _, node in after do
			expect(table.find(before, node) ~= nil):toBe(true)
			expect(world.host.propertyOf(node, "Key")):toBe(world.host.propertyOf(node, "Id"))
		end
		dispose()
	end)

	it("keeps a row for a key that stays in the window", function()
		local items = Compose.cell(rows(500))
		local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
		local viewport = Compose.cell(initialViewport)
		local dispose, root, renders = mountRecycled(items, viewport)
		local second
		for _, node in world.host.childrenOf(root) do
			if world.host.propertyOf(node, "Id") == "r2" then
				second = node
			end
		end
		viewport:set((function(value: Compose.OrderedCollectionViewport): Compose.OrderedCollectionViewport
			return value
		end) { offset = 10, size = 30 })
		expect(idsOf(root)):toEqual { "r2", "r3", "r4" }
		for _, node in world.host.childrenOf(root) do
			if world.host.propertyOf(node, "Id") == "r2" then
				expect(node):toBe(second)
			end
		end
		expect(renders()):toBe(3)
		dispose()
	end)

	it("reuses every row when the order reverses", function()
		local items = Compose.cell(rows(3))
		local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
		local viewport = Compose.cell(initialViewport)
		local dispose, root, renders = mountRecycled(items, viewport)
		local reversed = table.clone(items:peek())
		table.sort(reversed, function(a: Row, b: Row): boolean
			return a.id > b.id
		end)
		items:set(reversed)
		expect(idsOf(root)):toEqual { "r3", "r2", "r1" }
		expect(renders()):toBe(3)
		dispose()
	end)

	it("needs exactly one of render and recycle", function()
		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.OrderedCollection {
						from = Compose.cell(rows(3)),
						render = function()
							return world.create "Row" {}
						end,
						recycle = function()
							return world.create "Row" {}
						end,
					},
				}
			end, world.root)
		end):toThrow "collection/render-or-recycle"
	end)
end)

describe("OrderedCollection", function()
	beforeEach(function()
		world = Support.world()
	end)

	describe("mode", function()
		it("mounts every item in all mode", function()
			local dispose, root = mount { count = 6, mode = "all" }
			expect(#idsOf(root)):toBe(6)
			dispose()
		end)

		it("mounts only what the viewport covers in windowed mode", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local dispose, root = mount { count = 500, mode = "windowed", viewport = viewport }
			expect(idsOf(root)):toEqual { "r1", "r2", "r3" }
			dispose()
		end)

		it("refuses windowed mode without a viewport, where the mistake was made", function()
			expect(function()
				world.runtime.mount(function()
					return world.create "Frame" {
						Compose.OrderedCollection {
							from = Compose.cell(rows(3)),
							mode = "windowed",
							render = function()
								return world.create "Row" {}
							end,
						},
					}
				end, world.root)
			end):toThrow "collection/no-viewport"
		end)

		it("names a mode it does not have rather than guessing one", function()
			expect(function()
				world.runtime.mount(function()
					return world.create "Frame" {
						Support.invoke(Compose.OrderedCollection, {
							from = Compose.cell(rows(3)),
							mode = "virtual",
							render = function()
								return world.create "Row" {}
							end,
						}),
					}
				end, world.root)
			end):toThrow "collection/unknown-mode"
		end)
	end)

	describe("scrolling", function()
		it("keeps the rows that stayed visible instead of rebuilding them", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local dispose, root = mount { count = 100, mode = "windowed", viewport = viewport }
			expect(idsOf(root)):toEqual { "r1", "r2", "r3" }

			world.host.resetCounts()
			viewport:set { offset = 10, size = 30 }
			world.settle()

			expect(idsOf(root)):toEqual { "r2", "r3", "r4" }
			expect(world.host.counts().createNode):toBe(1)
			expect(world.host.counts().destroyNode):toBe(1)
			dispose()
		end)

		it("mounts nothing at all when the viewport does not move", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local dispose = mount { count = 100, mode = "windowed", viewport = viewport }
			world.host.resetCounts()
			viewport:set { offset = 0, size = 30 }
			world.settle()
			expect(world.host.counts().createNode):toBe(0)
			dispose()
		end)

		it("moves a retained row's placement without rebuilding it", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local dispose, root = mount { count = 100, mode = "windowed", viewport = viewport }
			local second = world.host.childrenOf(root)[2]
			expect(world.host.propertyOf(second, "Offset")):toBe(10)

			viewport:set { offset = 10, size = 30 }
			world.settle()

			local first = world.host.childrenOf(root)[1]
			expect(first):toBe(second)
			expect(world.host.propertyOf(first, "Offset")):toBe(10)
			dispose()
		end)

		it("retains overscan rows on both sides", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 50, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local dispose, root = mount { count = 100, mode = "windowed", viewport = viewport, overscan = 2 }
			expect(idsOf(root)):toEqual { "r4", "r5", "r6", "r7", "r8", "r9", "r10" }
			dispose()
		end)
	end)

	describe("grids", function()
		it("wraps into rows and retains whole rows", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 20 }
			local viewport = Compose.cell(initialViewport)
			local dispose, root = mount {
				count = 40,
				mode = "windowed",
				viewport = viewport,
				layout = (function(value: Compose.OrderedCollectionLayout): Compose.OrderedCollectionLayout
					return value
				end) { kind = "grid", columns = 4, itemSize = 10, crossSize = 10 },
			}
			expect(#idsOf(root)):toBe(8)
			dispose()
		end)
	end)

	describe("reactive layout", function()
		for _, explicit in { false, true } do
			it(
				if explicit
					then "rejects a pending permutation offset with an unchanged explicit report"
					else "keeps a pending permutation offset without an explicit report",
				function()
					local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 20 }
					local viewport = Compose.cell(initialViewport)
					local status = Support.orderedStatus()
					local dispose, root, items =
						mount { count = 10, mode = "windowed", viewport = viewport, status = status }
					local reordered = rows(10)
					local first = assert(table.remove(reordered, 1))
					table.insert(reordered, 6, first)
					items:set(reordered)
					world.settle()
					expect(status:peek().desiredOffset):toBe(50)
					expect(idsOf(root)):toEqual { "r1", "r7" }
					viewport:set { offset = 0, size = 20, offsetRevision = if explicit then 1 else nil }
					world.settle()
					expect(viewport:peek().offset):toBe(0)
					if explicit then
						expect(status:peek().desiredOffset):toBeNil()
						expect(idsOf(root)):toEqual { "r2", "r3" }
					else
						expect(status:peek().desiredOffset):toBe(50)
						expect(idsOf(root)):toEqual { "r1", "r7" }
					end
					viewport:set { offset = 0, size = 30, offsetRevision = if explicit then 1 else nil }
					world.settle()
					if explicit then
						expect(status:peek().desiredOffset):toBeNil()
						expect(idsOf(root)):toEqual { "r2", "r3", "r4" }
						items:set(rows(10))
						world.settle()
						expect(status:peek().desiredOffset):toBe(10)
					else
						expect(status:peek().desiredOffset):toBe(50)
						expect(idsOf(root)):toEqual { "r1", "r7", "r8" }
					end
					dispose()
				end
			)
		end

		it("honors an unchanged explicit offset in the same batch as a permutation", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 20, offsetRevision = 1 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose, root, items = mount { count = 10, mode = "windowed", viewport = viewport, status = status }
			world.batch(function()
				local reordered = rows(10)
				local first = assert(table.remove(reordered, 1))
				table.insert(reordered, 6, first)
				items:set(reordered)
				viewport:set { offset = 0, size = 20, offsetRevision = 2 }
			end)
			world.settle()
			expect(status:peek().desiredOffset):toBeNil()
			expect(idsOf(root)):toEqual { "r2", "r3" }
			dispose()
		end)

		it("settles a formula-driven reflow with an adapter acknowledging the requested offset", function()
			local columns = Compose.cell(2)
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 22, size = 10 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local layout = Compose.formula(function(use): Compose.OrderedCollectionLayout
				return { kind = "grid", columns = use(columns), itemSize = 10 }
			end)
			local dispose, root = mount {
				count = 30,
				mode = "windowed",
				viewport = viewport,
				status = status,
				layout = layout,
			}
			local anchor = world.host.childrenOf(root)[1]
			local adapterOwner = Compose.createOwner()
			Compose.owner.watch(adapterOwner, function(use)
				local requested = use(status).desiredOffset
				if requested ~= nil then
					viewport:set { offset = requested, size = 10 }
				end
			end)
			columns:set(3)
			world.settle()
			expect(viewport:peek().offset):toBe(12)
			expect(status:peek().desiredOffset):toBeNil()
			expect(world.host.childrenOf(root)[2]):toBe(anchor)
			expect(idsOf(root)):toEqual { "r4", "r5", "r6", "r7", "r8", "r9" }
			Compose.owner.dispose(adapterOwner)
			dispose()
			layout:dispose()
			expect(world.host.liveNodes()):toBe(1)
		end)

		it("clamps a removed anchor and clears an empty window", function()
			local initialLayout: Compose.OrderedCollectionLayout = { itemSize = 10 }
			local layout = Compose.cell(initialLayout)
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 82, size = 10 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose, root, items = mount {
				count = 20,
				mode = "windowed",
				viewport = viewport,
				status = status,
				layout = layout,
			}
			world.batch(function()
				layout:set { itemSize = 20 }
				items:set(rows(2))
			end)
			world.settle()
			expect(status:peek().desiredOffset):toBe(30)
			expect(idsOf(root)):toEqual { "r2" }
			items:set {}
			world.settle()
			expect(status:peek().desiredOffset):toBe(0)
			expect(status:peek().extent):toBe(0)
			expect(idsOf(root)):toEqual {}
			dispose()
			expect(world.host.liveNodes()):toBe(1)
		end)

		it("cancels an unacknowledged end request when reflow restores the reported end", function()
			local initialLayout: Compose.OrderedCollectionLayout = { itemSize = 10 }
			local layout = Compose.cell(initialLayout)
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 80, size = 20 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose, root = mount {
				count = 10,
				mode = "windowed",
				viewport = viewport,
				status = status,
				layout = layout,
				follow = "end",
			}
			layout:set { itemSize = 20 }
			world.settle()
			expect(status:peek().desiredOffset):toBe(180)
			layout:set { itemSize = 10 }
			world.settle()
			expect(status:peek().desiredOffset):toBeNil()
			expect(status:peek().following):toBe(true)
			expect(idsOf(root)):toEqual { "r9", "r10" }
			dispose()
		end)

		it("reflows retained nodes and their component state from a layout cell", function()
			local initialLayout: Compose.OrderedCollectionLayout =
				{ kind = "grid", columns = 2, itemSize = 10, crossSize = 20 }
			local layout = Compose.cell(initialLayout)
			local status = Support.orderedStatus()
			local states: { [string]: Compose.Value<number> } = {}
			local dispose, root = world.runtime.mount(function()
				return world.runtime.constructors.Frame {
					Compose.OrderedCollection {
						from = Compose.cell(rows(6)),
						key = idOf,
						layout = layout,
						status = status,
						render = function(_, placement, key)
							local state = Compose.cell(0)
							states[key] = state
							return world.runtime.constructors.Row {
								Placement = function(use)
									return use(placement)
								end,
								State = function(use)
									return use(state)
								end,
							}
						end,
					},
				}
			end, world.root)
			local before = table.clone(world.host.childrenOf(root))
			states.r4:set(7)
			world.settle()
			world.host.resetCounts()
			layout:set { kind = "grid", columns = 3, itemSize = 15, gap = 4, crossSize = 30, crossGap = 5 }
			world.settle()
			expect(world.host.childrenOf(root)):toEqual(before)
			expect(world.host.counts().createNode):toBe(0)
			expect(world.host.counts().destroyNode):toBe(0)
			expect(world.host.propertyOf(before[4], "State")):toBe(7)
			expect(world.host.propertyOf(before[5], "Placement")):toEqual {
				index = 5,
				row = 2,
				column = 2,
				offset = 19,
				size = 15,
				crossOffset = 35,
				crossSize = 30,
			}
			expect(status:peek().extent):toBe(34)
			expect(status:peek().rowCount):toBe(2)
			dispose()
			layout:set { itemSize = 100 }
			world.settle()
			expect(world.host.liveNodes()):toBe(1)
			expect(status:peek().extent):toBe(34)
		end)

		it(
			"anchors the visible row rather than overscan and retains the requested window until acknowledged",
			function()
				local initialViewport: Compose.OrderedCollectionViewport = { offset = 23, size = 20 }
				local viewport = Compose.cell(initialViewport)
				local initialLayout: Compose.OrderedCollectionLayout = { kind = "grid", columns = 2, itemSize = 10 }
				local layout = Compose.cell(initialLayout)
				local status = Support.orderedStatus()
				local controls: Compose.OrderedCollectionControls<string> = {}
				local dispose, root = mount {
					count = 40,
					mode = "windowed",
					viewport = viewport,
					layout = layout,
					status = status,
					controls = controls,
					overscan = 1,
				}
				local anchor = world.host.childrenOf(root)[3]
				expect(world.host.propertyOf(anchor, "Id")):toBe "r5"
				layout:set { kind = "grid", columns = 3, itemSize = 20, gap = 5 }
				world.settle()
				expect(status:peek().desiredOffset):toBe(28)
				expect(status:peek().extent):toBe(345)
				expect(idsOf(root)):toEqual { "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9" }
				expect(world.host.childrenOf(root)[5]):toBe(anchor)
				expect((Support.required(controls.offsetOf))(7, "start", 20)):toBe(50)
				viewport:set { offset = 23, size = 20 }
				world.settle()
				expect(status:peek().desiredOffset):toBe(28)
				expect(world.host.childrenOf(root)[5]):toBe(anchor)
				viewport:set { offset = 28, size = 20 }
				world.settle()
				expect(status:peek().desiredOffset):toBeNil()
				expect(world.host.childrenOf(root)[5]):toBe(anchor)
				dispose()
			end
		)

		it("tracks a layout body and combines successive reflows before scroll acknowledgement", function()
			local size = Compose.cell(10)
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 42, size = 20 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose, root = mount {
				count = 30,
				mode = "windowed",
				viewport = viewport,
				status = status,
				layout = function(use)
					return { itemSize = use(size) }
				end,
			}
			local anchor = world.host.childrenOf(root)[1]
			size:set(20)
			world.settle()
			expect(status:peek().desiredOffset):toBe(82)
			expect(world.host.childrenOf(root)[1]):toBe(anchor)
			size:set(30)
			world.settle()
			expect(status:peek().desiredOffset):toBe(122)
			expect(world.host.childrenOf(root)[1]):toBe(anchor)
			viewport:set { offset = 122, size = 20 }
			world.settle()
			expect(status:peek().desiredOffset):toBeNil()
			dispose()
		end)

		it("honors an explicit scroll in the same batch as a reflow", function()
			local initialLayout: Compose.OrderedCollectionLayout = { itemSize = 10 }
			local layout = Compose.cell(initialLayout)
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 42, size = 20 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose, root =
				mount { count = 30, mode = "windowed", viewport = viewport, status = status, layout = layout }
			world.batch(function()
				layout:set { itemSize = 20 }
				viewport:set { offset = 100, size = 20 }
			end)
			world.settle()
			expect(idsOf(root)):toEqual { "r6" }
			expect(status:peek().desiredOffset):toBeNil()
			dispose()
		end)

		it("follows the end through reflow and clamps a shortened population", function()
			local initialLayout: Compose.OrderedCollectionLayout = { itemSize = 10 }
			local layout = Compose.cell(initialLayout)
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 80, size = 20 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose, root, items = mount {
				count = 10,
				mode = "windowed",
				viewport = viewport,
				status = status,
				layout = layout,
				follow = "end",
			}
			layout:set { kind = "grid", columns = 2, itemSize = 30 }
			world.settle()
			expect(status:peek().desiredOffset):toBe(130)
			expect(status:peek().following):toBe(true)
			expect(idsOf(root)):toEqual { "r9", "r10" }
			viewport:set { offset = 130, size = 20 }
			world.settle()
			items:set(rows(1))
			layout:set { itemSize = 10 }
			world.settle()
			expect(status:peek().desiredOffset):toBe(0)
			expect(idsOf(root)):toEqual { "r1" }
			dispose()
		end)

		it("reapplies measured sizes to new grid rows and restores the new estimate", function()
			local initialLayout: Compose.OrderedCollectionLayout = { kind = "grid", columns = 2, itemSize = 10 }
			local layout = Compose.cell(initialLayout)
			local initialMeasured: { [string]: number } = { r1 = 40, r3 = 30 }
			local measured = Compose.cell(initialMeasured)
			local status = Support.orderedStatus()
			local dispose = mount { count = 6, mode = "all", layout = layout, measured = measured, status = status }
			expect(status:peek().extent):toBe(80)
			layout:set { kind = "grid", columns = 3, itemSize = 20, gap = 5 }
			world.settle()
			expect(status:peek().extent):toBe(65)
			expect(status:peek().measured):toBe(2)
			measured:set {}
			world.settle()
			expect(status:peek().extent):toBe(45)
			expect(status:peek().measured):toBe(0)
			dispose()
		end)

		it("rejects invalid reactive layout output without losing mounted rows and recovers", function()
			local initialLayout: Compose.OrderedCollectionLayout = { itemSize = 10 }
			local layout = Compose.cell(initialLayout)
			local dispose, root = mount { count = 3, mode = "all", layout = layout }
			local before = table.clone(world.host.childrenOf(root))
			expect(function()
				Support.invokeMethod(layout, "set", { kind = "unknown" })
				world.settle()
			end):toThrow "collection/unknown-layout"
			expect(world.host.childrenOf(root)):toEqual(before)
			layout:set { itemSize = 20 }
			world.settle()
			expect(world.host.childrenOf(root)):toEqual(before)
			expect(world.host.propertyOf(before[2], "Offset")):toBe(20)
			dispose()
		end)
	end)

	describe("measurement", function()
		it("moves the retained range when a row turns out to be taller", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local initialMeasured: { [string]: number } = {}
			local measured = Compose.cell(initialMeasured)
			local dispose, root = mount { count = 50, mode = "windowed", viewport = viewport, measured = measured }
			expect(idsOf(root)):toEqual { "r1", "r2", "r3" }

			measured:set { r1 = 25 }
			world.settle()

			expect(idsOf(root)):toEqual { "r1", "r2" }
			dispose()
		end)

		it("reports how many rows have a real measurement", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local initialMeasured: { [string]: number } = {}
			local measured = Compose.cell(initialMeasured)
			local status = Support.orderedStatus()
			local dispose = mount {
				count = 50,
				mode = "windowed",
				viewport = viewport,
				measured = measured,
				status = status,
			}
			expect(status:peek().measured):toBe(0)
			measured:set { r1 = 25, r2 = 30 }
			world.settle()
			expect(status:peek().measured):toBe(2)
			dispose()
		end)

		it("forgets a removed measurement and restores the estimate", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local initialMeasured: { [string]: number } = { r1 = 25 }
			local measured = Compose.cell(initialMeasured)
			local status = Support.orderedStatus()
			local dispose, root = mount {
				count = 50,
				mode = "windowed",
				viewport = viewport,
				measured = measured,
				status = status,
			}
			expect(idsOf(root)):toEqual { "r1", "r2" }
			expect(status:peek().measured):toBe(1)

			measured:set {}
			world.settle()

			expect(idsOf(root)):toEqual { "r1", "r2", "r3" }
			expect(status:peek().measured):toBe(0)
			dispose()
		end)

		it("drops measurements for keys that leave the population", function()
			local initialMeasured: { [string]: number } = { r1 = 25 }
			local measured = Compose.cell(initialMeasured)
			local status = Support.orderedStatus()
			local dispose, _, items = mount {
				count = 2,
				mode = "all",
				measured = measured,
				status = status,
			}
			expect(status:peek().measured):toBe(1)

			items:set { { id = "r2", label = "row 2" } }
			world.settle()

			expect(status:peek().measured):toBe(0)
			expect(status:peek().extent):toBe(10)
			dispose()
		end)
	end)

	describe("following the end", function()
		it("asks to move to the end while the viewport is at it", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 70, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose, _, items =
				mount { count = 10, mode = "windowed", viewport = viewport, follow = "end", status = status }
			expect(status:peek().following):toBe(true)

			local grown = rows(20)
			items:set(grown)
			world.settle()

			expect(status:peek().following):toBe(true)
			expect(status:peek().desiredOffset):toBe(170)
			dispose()
		end)

		it("lets go once the reader scrolls away from the end", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 70, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose = mount {
				count = 10,
				mode = "windowed",
				viewport = viewport,
				follow = "end",
				status = status,
			}
			expect(status:peek().following):toBe(true)

			viewport:set { offset = 10, size = 30 }
			world.settle()
			expect(status:peek().following):toBe(false)
			expect(status:peek().desiredOffset):toBeNil()
			dispose()
		end)

		it("re-engages when the reader returns to the end", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 10, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose = mount {
				count = 10,
				mode = "windowed",
				viewport = viewport,
				follow = "end",
				status = status,
			}
			expect(status:peek().following):toBe(false)
			viewport:set { offset = 70, size = 30 }
			world.settle()
			expect(status:peek().following):toBe(true)
			dispose()
		end)
	end)

	describe("holding position", function()
		it("asks to shift the view by exactly what was inserted above it", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 40, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose, _, items = mount { count = 20, mode = "windowed", viewport = viewport, status = status }
			expect(status:peek().first):toBe(5)

			local older: { Row } = {}
			for index = 1, 5 do
				older[index] = { id = "older" .. index, label = "older" }
			end
			local combined: { Row } = {}
			table.move(older, 1, 5, 1, combined)
			table.move(rows(20), 1, 20, 6, combined)
			items:set(combined)
			world.settle()

			expect(status:peek().desiredOffset):toBe(90)
			dispose()
		end)
	end)

	describe("status and controls", function()
		it("publishes the retained range and the full extent", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose = mount { count = 50, mode = "windowed", viewport = viewport, status = status }
			local published = status:peek()
			expect(published.total):toBe(50)
			expect(published.retained):toBe(3)
			expect(published.first):toBe(1)
			expect(published.last):toBe(3)
			expect(published.extent):toBe(500)
			expect(published.mode):toBe "windowed"
			dispose()
		end)

		it("answers no index for any key before the first layout", function()
			local controls: Compose.OrderedCollectionControls<string> = {}
			local items = Compose.cell(rows(3))
			local before: { number? } = {}
			local dispose = world.runtime.mount(function()
				local collection = Compose.OrderedCollection {
					from = items,
					key = idOf,
					mode = "all",
					layout = (function(value: Compose.OrderedCollectionLayout): Compose.OrderedCollectionLayout
						return value
					end) { itemSize = 10 },
					controls = controls,
					render = function()
						return world.create "Row" {}
					end,
				}
				local indexOfKey = controls.indexOfKey
				if indexOfKey ~= nil then
					table.insert(before, indexOfKey "r1")
				end
				return world.create "Frame" { collection }
			end, world.root)
			expect(before[1]):toBeNil()
			local indexOfKey = Support.required(controls.indexOfKey)
			expect(indexOfKey "r1"):toBe(1)
			dispose()
		end)

		it("computes the offset that brings an item to each alignment", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local controls: Compose.OrderedCollectionControls<string> = {}
			local dispose = mount { count = 50, mode = "windowed", viewport = viewport, controls = controls }
			local offsetOf = Support.required(controls.offsetOf)
			expect(offsetOf(11, "start", 30)):toBe(100)
			expect(offsetOf(11, "end", 30)):toBe(80)
			expect(offsetOf(11, "center", 30)):toBe(90)
			expect(offsetOf(50, "start", 30)):toBe(470)
			local indexOfKey = Support.required(controls.indexOfKey)
			expect(indexOfKey "r11"):toBe(11)
			expect(indexOfKey "nope"):toBeNil()
			dispose()
		end)
	end)

	describe("scrolling inside one window", function()
		it("hands back the same placement for a row the window keeps", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 100 }
			local viewport = Compose.cell(initialViewport)
			local controls: Compose.OrderedCollectionControls<string> = {}
			local dispose = mount { count = 10000, mode = "windowed", viewport = viewport, controls = controls }
			local placementOf = Support.required(controls.placementOf)
			local held = placementOf(5)
			expect(table.isfrozen(held)):toBe(true)
			for offset = 0, 9 do
				viewport:set { offset = offset, size = 100 }
				world.settle()
				expect(placementOf(5)):toBe(held)
			end
			dispose()
		end)

		it("touches the host no further once the retained range settles", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 100 }
			local viewport = Compose.cell(initialViewport)
			local dispose = mount { count = 10000, mode = "windowed", viewport = viewport }
			viewport:set { offset = 1, size = 100 }
			world.settle()
			world.host.resetCounts()
			for offset = 1, 9 do
				viewport:set { offset = offset, size = 100 }
				world.settle()
			end
			local counts = world.host.counts()
			expect(counts.createNode):toBe(0)
			expect(counts.destroyNode):toBe(0)
			expect(counts.setProperty):toBe(0)
			expect(counts.insertChild):toBe(0)
			expect(counts.moveChild):toBe(0)
			expect(counts.removeChild):toBe(0)
			dispose()
		end)

		it("leaves the status alone while every published field stays the same", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 100 }
			local viewport = Compose.cell(initialViewport)
			local status = Support.orderedStatus()
			local dispose = mount { count = 10000, mode = "windowed", viewport = viewport, status = status }
			viewport:set { offset = 1, size = 100 }
			world.settle()
			local writes = 0
			local owner = Compose.createOwner(world.runtime.reactor)
			Compose.owner.watch(owner, function(use)
				use(status)
				writes += 1
			end)
			expect(writes):toBe(1)
			for offset = 1, 9 do
				viewport:set { offset = offset, size = 100 }
				world.settle()
			end
			expect(writes):toBe(1)
			viewport:set { offset = 40, size = 100 }
			world.settle()
			expect(writes):toBe(2)
			expect(status:peek().first):toBe(5)
			Compose.owner.dispose(owner)
			dispose()
		end)

		it("drops the cached placements when a measurement moves a later row", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 100 }
			local viewport = Compose.cell(initialViewport)
			local initialMeasured: { [string]: number } = {}
			local measured = Compose.cell(initialMeasured)
			local controls: Compose.OrderedCollectionControls<string> = {}
			local dispose = mount {
				count = 10000,
				mode = "windowed",
				viewport = viewport,
				measured = measured,
				controls = controls,
			}
			local placementOf = Support.required(controls.placementOf)
			local before = placementOf(5)
			expect(before.offset):toBe(40)
			measured:set { r2 = 30 }
			world.settle()
			local after = placementOf(5)
			expect(after).never:toBe(before)
			expect(after.offset):toBe(60)
			dispose()
		end)

		it("re-reads a list a body hands back after changing it in place", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 100 }
			local viewport = Compose.cell(initialViewport)
			local list = rows(40)
			local revision = Compose.cell(0)
			local dispose, root = world.runtime.mount(function()
				return world.create "Frame" {
					Compose.OrderedCollection {
						from = function(use)
							use(revision)
							return list
						end,
						key = idOf,
						mode = "windowed",
						viewport = viewport,
						layout = (function(value: Compose.OrderedCollectionLayout): Compose.OrderedCollectionLayout
							return value
						end) { itemSize = 10 },
						render = function(value)
							return world.create "Row" {
								Id = function(use)
									return use(value).id
								end,
							}
						end,
					},
				}
			end, world.root)
			expect(idsOf(root)[1]):toBe "r1"
			list[1] = { id = "moved", label = "row 1" }
			revision:set(1)
			world.settle()
			expect(idsOf(root)[1]):toBe "moved"
			dispose()
		end)
	end)

	describe("lifetime", function()
		it("returns every node when the collection goes", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local before = world.host.liveNodes()
			local dispose = mount { count = 200, mode = "windowed", viewport = viewport }
			dispose()
			expect(world.host.liveNodes()):toBe(before)
		end)

		it("returns every node after a long scroll, not only the last window", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local before = world.host.liveNodes()
			local dispose = mount { count = 500, mode = "windowed", viewport = viewport }
			for offset = 0, 400, 10 do
				viewport:set { offset = offset, size = 30 }
				world.settle()
			end
			dispose()
			expect(world.host.liveNodes()):toBe(before)
		end)

		it("unwinds completely when a row fails to build", function()
			local initialViewport: Compose.OrderedCollectionViewport = { offset = 0, size = 30 }
			local viewport = Compose.cell(initialViewport)
			local before = world.host.liveNodes()
			world.host.failNext("createNode", 1)
			expect(function()
				mount { count = 50, mode = "windowed", viewport = viewport }
			end):toThrow()
			world.host.clearFailures()
			expect(world.host.liveNodes()):toBe(before)
		end)
	end)

	describe("arguments", function()
		it("names an option it does not have", function()
			expect(function()
				world.runtime.mount(function()
					return world.create "Frame" {
						Compose.OrderedCollection {
							from = Compose.cell(rows(3)),
							renderer = function() end,
							render = function()
								return world.create "Row" {}
							end,
						},
					}
				end, world.root)
			end):toThrow "structure/unknown-option"
		end)

		it("names a layout option it does not have", function()
			expect(function()
				world.runtime.mount(function()
					return world.create "Frame" {
						Support.invoke(Compose.OrderedCollection, {
							from = Compose.cell(rows(3)),
							layout = { rowHeight = 10 },
							render = function()
								return world.create "Row" {}
							end,
						}),
					}
				end, world.root)
			end):toThrow "structure/unknown-option"
		end)
	end)
end)

return nil
