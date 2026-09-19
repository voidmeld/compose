--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Item = { id: string }

local function idOf(item: Item): string
	return item.id
end

local function itemList(count: number): { Item }
	local list: { Item } = table.create(count)
	for index = 1, count do
		list[index] = { id = "k" .. index }
	end
	return list
end

local function generator(seed: number): () -> number
	local state = seed % 4294967296
	return function(): number
		state = (state * 1664525 + 1013904223) % 4294967296
		return state
	end
end

local function shuffled(list: { Item }, next: () -> number): { Item }
	local result = table.clone(list)
	for index = #result, 2, -1 do
		local swap = (next() % index) + 1
		result[index], result[swap] = result[swap], result[index]
	end
	return result
end

local function order(world: Support.World, parent: Compose.Node): { string }
	local names: { string } = {}
	for _, child in world.host.childrenOf(parent) do
		table.insert(names, tostring(world.host.propertyOf(child, "Id")))
	end
	return names
end

local function idsOf(list: { Item }): { string }
	local names: { string } = table.create(#list)
	for index, item in list do
		names[index] = item.id
	end
	return names
end

local function nodesByKey(world: Support.World, parent: Compose.Node): { [string]: Compose.Node }
	local map: { [string]: Compose.Node } = {}
	for _, child in world.host.childrenOf(parent) do
		map[tostring(world.host.propertyOf(child, "Id"))] = child
	end
	return map
end

local function mountList(world: Support.World, initial: { Item })
	local list = Compose.cell(initial)
	local dispose, root = world.runtime.mount(function()
		return world.create "Frame" {
			Compose.keyed {
				from = function(use)
					return use(list)
				end,
				render = function(value)
					return world.create "Row" {
						Id = function(use)
							return use(value).id
						end,
					}
				end,
				key = idOf,
			},
		}
	end, world.root)
	return dispose, root, list
end

describe("keyed reordering under permutations", function()
	it("keeps order and identity through random permutations, without a single rebuild", function()
		for seed = 1, 5 do
			local world = Support.world()
			local next = generator(seed * 7919)
			local base = itemList(24)
			local dispose, root, list = mountList(world, base)

			local current = base
			for round = 1, 8 do
				local before = nodesByKey(world, root)
				world.host.resetCounts()

				current = shuffled(current, next)
				list:set(current)
				world.settle()

				local got, want = order(world, root), idsOf(current)
				if not Test.deepEquals(got, want) then
					error(("order diverged at seed %d round %d"):format(seed, round), 0)
				end
				expect(got):toEqual(want)
				expect(world.host.counts().createNode):toBe(0)
				expect(world.host.counts().destroyNode):toBe(0)
				local after = nodesByKey(world, root)
				for key, node in before do
					expect(after[key]):toBe(node)
				end
			end
			dispose()
			expect(world.host.leaked()):toEqual { "Root#1" }
		end
	end)

	it("keeps identity through permutations mixed with churn", function()
		local world = Support.world()
		local next = generator(99991)
		local dispose, root, list = mountList(world, itemList(12))

		local population = 12
		local current = itemList(12)
		for _ = 1, 10 do
			local before = nodesByKey(world, root)

			local mutated = table.clone(current)
			table.remove(mutated, (next() % #mutated) + 1)
			table.remove(mutated, (next() % #mutated) + 1)
			population += 1
			table.insert(mutated, { id = "k" .. population })
			population += 1
			table.insert(mutated, { id = "k" .. population })
			current = shuffled(mutated, next)

			list:set(current)
			world.settle()

			expect(order(world, root)):toEqual(idsOf(current))
			local after = nodesByKey(world, root)
			for key, node in after do
				if before[key] ~= nil then
					expect(node):toBe(before[key])
				end
			end
		end
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	describe("edge shapes", function()
		it("grows from empty to many", function()
			local world = Support.world()
			local dispose, root, list = mountList(world, {})
			expect(order(world, root)):toEqual {}

			list:set(itemList(8))
			world.settle()
			expect(order(world, root)):toEqual(idsOf(itemList(8)))
			dispose()
		end)

		it("shrinks from many to empty and destroys every row", function()
			local world = Support.world()
			local dispose, root, list = mountList(world, itemList(8))
			local rows = world.host.childrenOf(root)

			list:set {}
			world.settle()
			expect(order(world, root)):toEqual {}
			for _, row in rows do
				expect(world.host.isAlive(row)):toBe(false)
			end
			dispose()
			expect(world.host.leaked()):toEqual { "Root#1" }
		end)

		it("replaces every key wholesale", function()
			local world = Support.world()
			local dispose, root, list = mountList(world, itemList(6))
			local before = world.host.childrenOf(root)

			local replacement: { Item } = {}
			for index = 1, 6 do
				replacement[index] = { id = "fresh" .. index }
			end
			list:set(replacement)
			world.settle()

			expect(order(world, root)):toEqual(idsOf(replacement))
			for _, old in before do
				expect(world.host.isAlive(old)):toBe(false)
			end
			dispose()
		end)

		it("performs a single move without touching identity", function()
			local world = Support.world()
			local dispose, root, list = mountList(world, itemList(10))
			local before = nodesByKey(world, root)
			world.host.resetCounts()

			local moved = itemList(10)
			table.insert(moved, 4, table.remove(moved, 9) :: Item)
			list:set(moved)
			world.settle()

			expect(order(world, root)):toEqual(idsOf(moved))
			expect(world.host.counts().createNode):toBe(0)
			expect(world.host.counts().destroyNode):toBe(0)
			local after = nodesByKey(world, root)
			for key, node in before do
				expect(after[key]):toBe(node)
			end
			dispose()
		end)

		it("reverses, which defeats a diff whose increasing-run logic is inverted", function()
			local world = Support.world()
			local dispose, root, list = mountList(world, itemList(16))
			local before = nodesByKey(world, root)
			world.host.resetCounts()

			local reversed = itemList(16)
			local flipped: { Item } = table.create(16)
			for index = 16, 1, -1 do
				table.insert(flipped, reversed[index])
			end
			list:set(flipped)
			world.settle()

			expect(order(world, root)):toEqual(idsOf(flipped))
			expect(world.host.counts().createNode):toBe(0)
			local after = nodesByKey(world, root)
			for key, node in before do
				expect(after[key]):toBe(node)
			end
			dispose()
		end)

		it("rejects a duplicate key introduced by an update, not only at mount", function()
			local world = Support.world()
			local dispose, _root, list = mountList(world, itemList(3))
			expect(function()
				list:set { { id = "k1" }, { id = "k2" }, { id = "k1" } }
				world.settle()
			end):toThrow "duplicate%-key"
			dispose()
		end)

		it("handles a permutation of two", function()
			local world = Support.world()
			local dispose, root, list = mountList(world, itemList(2))
			local before = nodesByKey(world, root)
			world.host.resetCounts()

			list:set { { id = "k2" }, { id = "k1" } }
			world.settle()

			expect(order(world, root)):toEqual { "k2", "k1" }
			expect(world.host.counts().createNode):toBe(0)
			expect(nodesByKey(world, root).k1):toBe(before.k1)
			expect(nodesByKey(world, root).k2):toBe(before.k2)
			dispose()
		end)
	end)
end)

return nil
