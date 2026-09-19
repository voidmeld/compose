--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect, beforeEach = Test.describe, Test.it, Test.expect, Test.beforeEach

type Row = { id: string, label: string }

local function rows(count: number): { Row }
	local list: { Row } = table.create(count)
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
	layout: Compose.OrderedCollectionLayout?,
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
				layout = options.layout or { itemSize = 10 },
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
				layout = { kind = "grid", columns = 4, itemSize = 10, crossSize = 10 },
			}
			expect(#idsOf(root)):toBe(8)
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
