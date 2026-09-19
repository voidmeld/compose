--!strict

local Prefix = require "../../src/core/collection/prefix"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("prefix tree", function()
	it("starts every row at the seeded extent", function()
		local tree = Prefix.create(8, 10)
		expect(tree.sum):toBe(80)
		expect(Prefix.startOf(tree, 1)):toBe(0)
		expect(Prefix.startOf(tree, 5)):toBe(40)
		expect(Prefix.extentOf(tree, 3)):toBe(10)
	end)

	it("finds the row covering an offset, and where it starts", function()
		local tree = Prefix.create(8, 10)
		local row, at = Prefix.find(tree, 45)
		expect(row):toBe(5)
		expect(at):toBe(40)
	end)

	it("treats an offset on a boundary as belonging to the row it opens", function()
		local tree = Prefix.create(8, 10)
		local row, at = Prefix.find(tree, 40)
		expect(row):toBe(5)
		expect(at):toBe(40)
	end)

	it("moves every later row when one is corrected", function()
		local tree = Prefix.create(8, 10)
		expect(Prefix.set(tree, 3, 30)):toBe(true)
		expect(tree.sum):toBe(100)
		expect(Prefix.startOf(tree, 3)):toBe(20)
		expect(Prefix.startOf(tree, 4)):toBe(50)
		local row, at = Prefix.find(tree, 55)
		expect(row):toBe(4)
		expect(at):toBe(50)
	end)

	it("reports a measurement that changed nothing, so a caller can skip the work", function()
		local tree = Prefix.create(4, 10)
		expect(Prefix.set(tree, 2, 10)):toBe(false)
		expect(Prefix.set(tree, 2, 25)):toBe(true)
		expect(Prefix.set(tree, 2, 25)):toBe(false)
	end)

	it("clamps an over-scrolled offset to the last row rather than raising", function()
		local tree = Prefix.create(5, 10)
		local row, at = Prefix.find(tree, 1000)
		expect(row):toBe(5)
		expect(at):toBe(40)
	end)

	it("answers an empty tree without raising", function()
		local tree = Prefix.create(0, 10)
		expect(tree.sum):toBe(0)
		local row = Prefix.find(tree, 25)
		expect(row):toBe(0)
	end)

	it("agrees with a linear accumulation over a run of corrections", function()
		local count = 64
		local tree = Prefix.create(count, 7)
		local extents: { number } = table.create(count, 7)
		for index = 1, count, 3 do
			local size = 3 + index % 11
			extents[index] = size
			Prefix.set(tree, index, size)
		end

		local running = 0
		for index = 1, count do
			expect(Prefix.startOf(tree, index)):toBe(running)
			local row, at = Prefix.find(tree, running)
			expect(row):toBe(index)
			expect(at):toBe(running)
			running += extents[index]
		end
		expect(tree.sum):toBe(running)
	end)
end)

return nil
