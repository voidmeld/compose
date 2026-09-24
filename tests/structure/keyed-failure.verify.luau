--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Item = { id: string }

local function items(...: string): { Item }
	local list: { Item } = {}
	for index = 1, select("#", ...) do
		table.insert(list, { id = (select(index, ...)) })
	end
	return list
end

local function idOf(item: Item): string
	return item.id
end

local function order(world: Support.World, parent: Compose.Node): { string }
	local names: { string } = {}
	for _, child in world.host.childrenOf(parent) do
		table.insert(names, tostring(world.host.propertyOf(child, "Id")))
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

local function mountList(world: Support.World, initial: { Item }, failing: { [string]: boolean })
	local list = Compose.cell(initial)
	local dispose, root = world.runtime.mount(function()
		return world.create "Frame" {
			Compose.keyed {
				from = function(use: Compose.Use)
					return use(list)
				end,
				render = function(value, index, key)
					if failing[key] then
						error(("row render exploded for %s"):format(tostring(key)), 0)
					end
					return world.create "Row" {
						Id = function(use)
							return use(value).id
						end,
						Order = function(use)
							return use(index)
						end,
					}
				end,
				key = idOf,
			},
		}
	end, world.root)
	return dispose, root, list
end

describe("keyed after a render failure", function()
	it("finishes independent rows before reporting a failed factory", function()
		local world = Support.world()
		local failing: { [string]: boolean } = { c = true }
		local dispose, root, list = mountList(world, items("a", "b"), failing)
		local before = nodesByKey(world, root)
		expect(function()
			list:set(items("d", "c", "a", "e"))
		end):toThrow "row render exploded for c"
		expect(order(world, root)):toEqual { "d", "a", "e" }
		expect(nodesByKey(world, root).a):toBe(before.a)
		list:set(items())
		expect(order(world, root)):toEqual {}
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("continues reordering around multiple failed factories and reports each failure", function()
		local world = Support.world()
		local failing: { [string]: boolean } = { x = true, y = true }
		local dispose, root, list = mountList(world, items("a", "b", "c"), failing)
		local before = nodesByKey(world, root)
		local ok, err = pcall(function()
			list:set(items("d", "x", "c", "y", "a", "b", "e"))
		end)
		expect(ok):toBe(false)
		expect(tostring(err)):toContain "row render exploded for x"
		expect(tostring(err)):toContain "row render exploded for y"
		expect(order(world, root)):toEqual { "d", "c", "a", "b", "e" }
		expect(nodesByKey(world, root).a):toBe(before.a)
		expect(nodesByKey(world, root).b):toBe(before.b)
		expect(nodesByKey(world, root).c):toBe(before.c)
		failing.x = false
		failing.y = false
		list:set(items("d", "x", "c", "y", "a", "b", "e"))
		expect(order(world, root)):toEqual { "d", "x", "c", "y", "a", "b", "e" }
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("retries a failed prefix addition without remounting successful rows", function()
		local world = Support.world()
		local failing: { [string]: boolean } = { c = true }
		local dispose, root, list = mountList(world, items("a", "b"), failing)
		local before = nodesByKey(world, root)
		expect(function()
			list:set(items("d", "c", "a"))
		end):toThrow "row render exploded for c"
		local partial = nodesByKey(world, root)
		failing.c = false
		list:set(items("d", "c", "a"))
		expect(order(world, root)):toEqual { "d", "c", "a" }
		expect(nodesByKey(world, root).a):toBe(before.a)
		expect(nodesByKey(world, root).d):toBe(partial.d)
		list:set(items())
		expect(order(world, root)):toEqual {}
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("clears unordered survivors after a mixed reorder and failed insertion", function()
		local world = Support.world { ordersChildren = false }
		local failing: { [string]: boolean } = { e = true }
		local dispose, root, list = mountList(world, items("a", "b", "c"), failing)
		expect(function()
			list:set(items("c", "d", "e", "a"))
		end):toThrow "row render exploded for e"
		list:set(items())
		expect(order(world, root)):toEqual {}
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("clears retained rows after a new prefix row succeeds and the next factory fails", function()
		local world = Support.world()
		local failing: { [string]: boolean } = { c = true }
		local dispose, root, list = mountList(world, items("a", "b"), failing)
		local before = nodesByKey(world, root)
		expect(function()
			list:set(items("d", "c", "a"))
		end):toThrow "row render exploded for c"
		expect(world.host.isAlive(before.a)):toBe(true)
		list:set(items())
		expect(order(world, root)):toEqual {}
		expect(world.host.isAlive(before.a)):toBe(false)
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("recovers fully when the failed key is later removed, then re-added", function()
		local world = Support.world()
		local failing: { [string]: boolean } = {}
		local dispose, root, list = mountList(world, items("a", "b", "c"), failing)
		local before = nodesByKey(world, root)
		local liveBefore = world.host.liveNodes()
		world.host.resetCounts()

		failing.d = true
		local ok, err: any = pcall(function()
			list:set(items("a", "b", "c", "d"))
			world.settle()
		end)
		expect(ok):toBe(false)
		expect(tostring(err)):toContain "row render exploded for d"
		expect(order(world, root)):toEqual { "a", "b", "c" }
		expect(world.host.liveNodes()):toBe(liveBefore)
		expect(world.host.counts().destroyNode):toBe(0)
		local held = nodesByKey(world, root)
		expect(held.a):toBe(before.a)
		expect(held.b):toBe(before.b)
		expect(held.c):toBe(before.c)

		list:set(items("a", "c"))
		world.settle()
		expect(order(world, root)):toEqual { "a", "c" }
		expect(world.host.isAlive(before.b)):toBe(false)
		expect(nodesByKey(world, root).a):toBe(before.a)
		expect(nodesByKey(world, root).c):toBe(before.c)

		failing.d = false
		list:set(items("a", "c", "d"))
		world.settle()
		expect(order(world, root)):toEqual { "a", "c", "d" }

		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("applies a reorder of the survivors after a failed addition", function()
		local world = Support.world()
		local failing: { [string]: boolean } = { d = true }
		local dispose, root, list = mountList(world, items("a", "b", "c"), failing)
		local before = nodesByKey(world, root)

		local ok = pcall(function()
			list:set(items("a", "b", "c", "d"))
			world.settle()
		end)
		expect(ok):toBe(false)
		expect(order(world, root)):toEqual { "a", "b", "c" }

		list:set(items("c", "a", "b"))
		world.settle()
		expect(order(world, root)):toEqual { "c", "a", "b" }
		local after = nodesByKey(world, root)
		expect(after.a):toBe(before.a)
		expect(after.b):toBe(before.b)
		expect(after.c):toBe(before.c)

		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("survives an update that removes one key while another key's render raises", function()
		local world = Support.world()
		local failing: { [string]: boolean } = {}
		local dispose, root, list = mountList(world, items("a", "b", "c"), failing)
		local before = nodesByKey(world, root)

		failing.e = true
		local ok, err: any = pcall(function()
			list:set(items("a", "c", "e"))
			world.settle()
		end)
		expect(ok):toBe(false)
		expect(tostring(err)):toContain "row render exploded for e"

		local held = nodesByKey(world, root)
		expect(held.a):toBe(before.a)
		expect(held.c):toBe(before.c)
		expect(held.e):toBe(nil)

		list:set(items("a", "c"))
		world.settle()
		expect(order(world, root)):toEqual { "a", "c" }

		failing.e = false
		list:set(items("a", "c", "e"))
		world.settle()
		expect(order(world, root)):toEqual { "a", "c", "e" }

		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("unwinds a failure at initial mount and mounts cleanly on retry", function()
		local world = Support.world()
		local failing: { [string]: boolean } = { d = true }

		local ok, err: any = pcall(function()
			mountList(world, items("a", "b", "c", "d"), failing)
		end)
		expect(ok):toBe(false)
		expect(tostring(err)):toContain "row render exploded for d"
		expect(world.host.liveNodes()):toBe(1)

		failing.d = false
		local dispose, root = mountList(world, items("a", "b", "c", "d"), failing)
		expect(order(world, root)):toEqual { "a", "b", "c", "d" }
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)
end)

return nil
