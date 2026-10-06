--!strict

local Grid = require "../../src/core/collection/grid"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Point = { x: number, y: number, z: number }

local function positionOf(point: Point): (number, number, number)
	return point.x, point.y, point.z
end

local function entries<V>(map: { [number]: V }): number
	local count = 0
	for _ in map do
		count += 1
	end
	return count
end

describe("spatial grid", function()
	it("retains bucket capacity without retaining cells a population left", function()
		local grid = Grid.create(10)
		for step = 1, 200 do
			Grid.build(grid, { { x = step * 1000, y = 0, z = 0 } }, positionOf)
		end

		expect(#grid.activeKeys):toBe(1)
		expect(entries(grid.buckets)):toBe(1)
		expect(entries(grid.lengths)):toBe(1)
		expect(#grid.pool):toBe(0)
	end)

	it("reports the actual cells visited after intersecting occupied bounds", function()
		local grid = Grid.create(10)
		Grid.build(grid, {
			{ x = 0, y = 0, z = 0 },
			{ x = 25, y = 0, z = 0 },
		}, positionOf)
		local candidates = 0
		local visited = Grid.query(grid, 0, 0, 0, 1000, function()
			candidates += 1
		end)

		expect(visited):toBe(3)
		expect(candidates):toBe(2)
	end)
end)

return nil
