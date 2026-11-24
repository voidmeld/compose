--!strict

local Layout = require "../../src/core/collection/layout"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function list(count: number, size: number, gap: number?): Layout.Geometry
	return Layout.create {
		count = count,
		columns = 1,
		rowSize = size,
		gap = gap or 0,
		crossSize = 100,
		crossGap = 0,
	}
end

describe("scroll geometry", function()
	describe("uniform rows", function()
		it("places an item by arithmetic, without building a tree", function()
			local geometry = list(100, 50)
			expect(geometry.uniform):toBe(true)
			expect(geometry.rows):toBeNil()
			expect(Layout.totalExtent(geometry)):toBe(5000)
			local placement = Layout.placementOf(geometry, 5)
			expect(placement.offset):toBe(200)
			expect(placement.size):toBe(50)
			expect(placement.row):toBe(5)
			expect(placement.column):toBe(1)
		end)

		it("retains exactly the rows the viewport covers", function()
			local geometry = list(100, 50)
			for _, scenario in
				{
					{ offset = 0, size = 200, overscan = 0, first = 1, last = 4 },
					{ offset = 125, size = 200, overscan = 0, first = 3, last = 7 },
					{ offset = 125, size = 200, overscan = 2, first = 1, last = 9 },
					{ offset = 0, size = 100, overscan = 0, first = 1, last = 2 },
				}
			do
				local range = Layout.rangeFor(geometry, scenario.offset, scenario.size, scenario.overscan)
				expect(range.first):toBe(scenario.first)
				expect(range.last):toBe(scenario.last)
			end
		end)

		it("counts a gap between rows but not after the last one", function()
			local geometry = list(10, 20, 5)
			expect(Layout.totalExtent(geometry)):toBe(245)
			expect(Layout.offsetOf(geometry, 3)):toBe(50)
		end)
	end)

	describe("grids", function()
		local function grid(count: number, columns: number): Layout.Geometry
			return Layout.create {
				count = count,
				columns = columns,
				rowSize = 72,
				gap = 8,
				crossSize = 72,
				crossGap = 8,
			}
		end

		it("wraps items into rows at the column count", function()
			local geometry = grid(20, 8)
			expect(geometry.rowCount):toBe(3)
			local placement = Layout.placementOf(geometry, 10)
			expect(placement.row):toBe(2)
			expect(placement.column):toBe(2)
			expect(placement.crossOffset):toBe(80)
			local range = Layout.rangeFor(geometry, 0, 80, 0)
			expect(range.first):toBe(1)
			expect(range.last):toBe(8)
			expect(Layout.rangeFor(geometry, 0, 1000, 0).last):toBe(20)
		end)
	end)

	describe("measured rows", function()
		it("stays uniform until a measurement disagrees with the estimate", function()
			local geometry = list(5, 10)
			expect(Layout.setItemSize(geometry, 2, 10)):toBe(false)
			expect(geometry.uniform):toBe(true)
			expect(Layout.setItemSize(geometry, 2, 40)):toBe(true)
			expect(geometry.uniform):toBe(false)
			expect(Layout.totalExtent(geometry)):toBe(80)
			expect(Layout.offsetOf(geometry, 3)):toBe(50)
			local range = Layout.rangeFor(geometry, 50, 10, 0)
			expect(range.first):toBe(3)
			expect(range.last):toBe(3)
		end)

		it("gives a grid row the height of its tallest item", function()
			local geometry = Layout.create {
				count = 4,
				columns = 2,
				rowSize = 10,
				gap = 0,
				crossSize = 10,
				crossGap = 0,
			}
			Layout.setItemSize(geometry, 1, 30)
			Layout.setItemSize(geometry, 2, 20)
			expect(Layout.offsetOf(geometry, 3)):toBe(30)
			Layout.setItemSize(geometry, 1, 5)
			expect(Layout.offsetOf(geometry, 3)):toBe(20)
		end)

		it("ignores a measurement for an item that is no longer there", function()
			local geometry = list(3, 10)
			expect(Layout.setItemSize(geometry, 9, 50)):toBe(false)
			expect(Layout.totalExtent(geometry)):toBe(30)
		end)
	end)

	describe("alignment and edges", function()
		it("reports an empty range for an empty collection", function()
			local geometry = list(0, 10)
			local range = Layout.rangeFor(geometry, 0, 100, 3)
			expect(range.first):toBe(1)
			expect(range.last):toBe(0)
			expect(Layout.totalExtent(geometry)):toBe(0)
		end)

		it("retains one row for a viewport with no size", function()
			local geometry = list(10, 10)
			local range = Layout.rangeFor(geometry, 25, 0, 0)
			expect(range.first):toBe(3)
			expect(range.last):toBe(3)
		end)

		it("clamps a negative offset to the start", function()
			local geometry = list(10, 10)
			local range = Layout.rangeFor(geometry, -500, 20, 0)
			expect(range.first):toBe(1)
		end)
	end)
end)

return nil
