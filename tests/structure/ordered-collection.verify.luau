--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect, beforeEach = Test.describe, Test.it, Test.expect, Test.beforeEach

type Row = { id: string, label: string }

local function rows(count: number): { Row }
	local list = table.create(count) :: { Row }
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
	viewport: Compose.Cell<Compose.OrderedCollectionViewport>?,
	layout: (
		Compose.OrderedCollectionLayout
		| Compose.Readable<Compose.OrderedCollectionLayout>
		| Compose.Body<Compose.OrderedCollectionLayout>
	)?,
	overscan: number?,
	follow: ("end" | "none")?,
	measured: Compose.Cell<{ [string]: number }>?,
	status: Compose.Cell<Compose.OrderedCollectionStatus>?,
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
				layout = options.layout or { itemSize = 10 } :: Compose.OrderedCollectionLayout,
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
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
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
			end):toThrow "collection/no%-viewport"
		end)

		it("names a mode it does not have rather than guessing one", function()
			expect(function()
				world.runtime.mount(function()
					return world.create "Frame" {
						Compose.OrderedCollection {
							from = Compose.cell(rows(3)),
							mode = "virtual" :: any,
							render = function()
								return world.create "Row" {}
							end,
						},
					}
				end, world.root)
			end):toThrow "collection/unknown%-mode"
		end)
	end)

	describe("scrolling", function()
		it("keeps the rows that stayed visible instead of rebuilding them", function()
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
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
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
			local dispose = mount { count = 100, mode = "windowed", viewport = viewport }
			world.host.resetCounts()
			viewport:set { offset = 0, size = 30 }
			world.settle()
			expect(world.host.counts().createNode):toBe(0)
			dispose()
		end)

		it("moves a retained row's placement without rebuilding it", function()
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
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
			local viewport = Compose.cell({ offset = 50, size = 30 } :: Compose.OrderedCollectionViewport)
			local dispose, root = mount { count = 100, mode = "windowed", viewport = viewport, overscan = 2 }
			expect(idsOf(root)):toEqual { "r4", "r5", "r6", "r7", "r8", "r9", "r10" }
			dispose()
		end)
	end)

	describe("grids", function()
		it("wraps into rows and retains whole rows", function()
			local viewport = Compose.cell({ offset = 0, size = 20 } :: Compose.OrderedCollectionViewport)
			local dispose, root = mount {
				count = 40,
				mode = "windowed",
				viewport = viewport,
				layout = { kind = "grid", columns = 4, itemSize = 10, crossSize = 10 } :: Compose.OrderedCollectionLayout,
			}
			expect(#idsOf(root)):toBe(8)
			dispose()
		end)
	end)

	describe("reactive layout", function()
		it("settles a formula-driven reflow with an adapter acknowledging the requested offset", function()
			local columns = Compose.cell(2)
			local viewport = Compose.cell({ offset = 22, size = 10 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			adapterOwner.watch(function(use)
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
			adapterOwner.dispose()
			dispose()
			layout:dispose()
			expect(world.host.liveNodes()):toBe(1)
		end)

		it("clamps a removed anchor and clears an empty window", function()
			local layout = Compose.cell({ itemSize = 10 } :: Compose.OrderedCollectionLayout)
			local viewport = Compose.cell({ offset = 82, size = 10 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local layout = Compose.cell({ itemSize = 10 } :: Compose.OrderedCollectionLayout)
			local viewport = Compose.cell({ offset = 80, size = 20 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local layout = Compose.cell(
				{ kind = "grid", columns = 2, itemSize = 10, crossSize = 20 } :: Compose.OrderedCollectionLayout
			)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
			local states: { [string]: Compose.Cell<number> } = {}
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
				local viewport = Compose.cell({ offset = 23, size = 20 } :: Compose.OrderedCollectionViewport)
				local layout =
					Compose.cell({ kind = "grid", columns = 2, itemSize = 10 } :: Compose.OrderedCollectionLayout)
				local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
				expect((controls.offsetOf :: any)(7, "start", 20)):toBe(50)
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
			local viewport = Compose.cell({ offset = 42, size = 20 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local layout = Compose.cell({ itemSize = 10 } :: Compose.OrderedCollectionLayout)
			local viewport = Compose.cell({ offset = 42, size = 20 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local layout = Compose.cell({ itemSize = 10 } :: Compose.OrderedCollectionLayout)
			local viewport = Compose.cell({ offset = 80, size = 20 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local layout =
				Compose.cell({ kind = "grid", columns = 2, itemSize = 10 } :: Compose.OrderedCollectionLayout)
			local measured = Compose.cell({ r1 = 40, r3 = 30 } :: { [string]: number })
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local layout = Compose.cell({ itemSize = 10 } :: Compose.OrderedCollectionLayout)
			local dispose, root = mount { count = 3, mode = "all", layout = layout }
			local before = table.clone(world.host.childrenOf(root))
			expect(function()
				layout:set({ kind = "unknown" } :: any)
				world.settle()
			end):toThrow "collection/unknown%-layout"
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
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
			local measured = Compose.cell({} :: { [string]: number })
			local dispose, root = mount { count = 50, mode = "windowed", viewport = viewport, measured = measured }
			expect(idsOf(root)):toEqual { "r1", "r2", "r3" }

			measured:set { r1 = 25 }
			world.settle()

			expect(idsOf(root)):toEqual { "r1", "r2" }
			dispose()
		end)

		it("reports how many rows have a real measurement", function()
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
			local measured = Compose.cell({} :: { [string]: number })
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
			local measured = Compose.cell({ r1 = 25 } :: { [string]: number })
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local measured = Compose.cell({ r1 = 25 } :: { [string]: number })
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local viewport = Compose.cell({ offset = 70, size = 30 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local viewport = Compose.cell({ offset = 70, size = 30 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local viewport = Compose.cell({ offset = 10, size = 30 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local viewport = Compose.cell({ offset = 40, size = 30 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
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
					layout = { itemSize = 10 } :: Compose.OrderedCollectionLayout,
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
			local indexOfKey = controls.indexOfKey :: (string) -> number?
			expect(indexOfKey "r1"):toBe(1)
			dispose()
		end)

		it("computes the offset that brings an item to each alignment", function()
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
			local controls: Compose.OrderedCollectionControls<string> = {}
			local dispose = mount { count = 50, mode = "windowed", viewport = viewport, controls = controls }
			local offsetOf = controls.offsetOf :: (number, Compose.OrderedCollectionAlign?, number?) -> number
			expect(offsetOf(11, "start", 30)):toBe(100)
			expect(offsetOf(11, "end", 30)):toBe(80)
			expect(offsetOf(11, "center", 30)):toBe(90)
			expect(offsetOf(50, "start", 30)):toBe(470)
			local indexOfKey = controls.indexOfKey :: (string) -> number?
			expect(indexOfKey "r11"):toBe(11)
			expect(indexOfKey "nope"):toBeNil()
			dispose()
		end)
	end)

	describe("scrolling inside one window", function()
		it("hands back the same placement for a row the window keeps", function()
			local viewport = Compose.cell({ offset = 0, size = 100 } :: Compose.OrderedCollectionViewport)
			local controls: Compose.OrderedCollectionControls<string> = {}
			local dispose = mount { count = 10000, mode = "windowed", viewport = viewport, controls = controls }
			local placementOf = controls.placementOf :: (number) -> Compose.Placement
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
			local viewport = Compose.cell({ offset = 0, size = 100 } :: Compose.OrderedCollectionViewport)
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
			local viewport = Compose.cell({ offset = 0, size = 100 } :: Compose.OrderedCollectionViewport)
			local status = Compose.cell({} :: Compose.OrderedCollectionStatus)
			local dispose = mount { count = 10000, mode = "windowed", viewport = viewport, status = status }
			viewport:set { offset = 1, size = 100 }
			world.settle()
			local writes = 0
			local owner = Compose.createOwner(world.runtime.reactor)
			owner.watch(function(use)
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
			owner.dispose()
			dispose()
		end)

		it("drops the cached placements when a measurement moves a later row", function()
			local viewport = Compose.cell({ offset = 0, size = 100 } :: Compose.OrderedCollectionViewport)
			local measured = Compose.cell({} :: { [string]: number })
			local controls: Compose.OrderedCollectionControls<string> = {}
			local dispose = mount {
				count = 10000,
				mode = "windowed",
				viewport = viewport,
				measured = measured,
				controls = controls,
			}
			local placementOf = controls.placementOf :: (number) -> Compose.Placement
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
			local viewport = Compose.cell({ offset = 0, size = 100 } :: Compose.OrderedCollectionViewport)
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
						layout = { itemSize = 10 } :: Compose.OrderedCollectionLayout,
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
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
			local before = world.host.liveNodes()
			local dispose = mount { count = 200, mode = "windowed", viewport = viewport }
			dispose()
			expect(world.host.liveNodes()):toBe(before)
		end)

		it("returns every node after a long scroll, not only the last window", function()
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
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
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
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
							renderer = function() end :: any,
							render = function()
								return world.create "Row" {}
							end,
						} :: any,
					}
				end, world.root)
			end):toThrow "structure/unknown%-option"
		end)

		it("names a layout option it does not have", function()
			expect(function()
				world.runtime.mount(function()
					return world.create "Frame" {
						Compose.OrderedCollection {
							from = Compose.cell(rows(3)),
							layout = { rowHeight = 10 } :: any,
							render = function()
								return world.create "Row" {}
							end,
						},
					}
				end, world.root)
			end):toThrow "structure/unknown%-option"
		end)
	end)
end)

return nil
