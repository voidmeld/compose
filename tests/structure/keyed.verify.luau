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

local function mountList(world: Support.World, initial: { Item })
	local list = Compose.cell(initial)
	local dispose, root = world.runtime.mount(function()
		return world.create "Frame" {
			Compose.keyed {
				from = function(use)
					return use(list)
				end,
				render = function(value, index)
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

describe("keyed", function()
	it("mounts one row per item in order", function()
		local world = Support.world()
		local dispose, root = mountList(world, items("a", "b", "c"))
		expect(order(world, root)):toEqual { "a", "b", "c" }
		dispose()
	end)

	it("keeps node identity across a reorder", function()
		local world = Support.world()
		local dispose, root, list = mountList(world, items("a", "b", "c"))
		local before = world.host.childrenOf(root)

		list:set(items("c", "a", "b"))
		world.settle()

		local after = world.host.childrenOf(root)
		expect(order(world, root)):toEqual { "c", "a", "b" }
		expect(after[1]):toBe(before[3])
		expect(after[2]):toBe(before[1])
		expect(after[3]):toBe(before[2])
		dispose()
	end)

	it("creates and destroys nothing when only the order changes", function()
		local world = Support.world()
		local dispose, _root, list = mountList(world, items("a", "b", "c", "d"))
		world.host.resetCounts()

		list:set(items("d", "c", "b", "a"))
		world.settle()

		local counts = world.host.counts()
		expect(counts.createNode):toBe(0)
		expect(counts.destroyNode):toBe(0)
		dispose()
	end)

	it("moves the first row to the end in exactly one host move", function()
		local world = Support.world()
		local dispose, root, list = mountList(world, items("a", "b", "c", "d", "e"))
		world.host.resetCounts()

		list:set(items("b", "c", "d", "e", "a"))
		world.settle()

		expect(order(world, root)):toEqual { "b", "c", "d", "e", "a" }
		expect(world.host.counts().moveChild):toBe(1)
		dispose()
	end)

	it("rotates a long list in exactly one host move", function()
		local world = Support.world()
		local initial: { Item } = {}
		for index = 1, 200 do
			table.insert(initial, { id = tostring(index) })
		end
		local dispose, _root, list = mountList(world, initial)
		world.host.resetCounts()

		local rotated = table.clone(initial)
		table.insert(rotated, 1, table.remove(rotated, #rotated) :: Item)
		list:set(rotated)
		world.settle()

		expect(world.host.counts().moveChild):toBe(1)
		expect(world.host.counts().createNode):toBe(0)
		dispose()
	end)

	it("reverses a list in n-1 host moves", function()
		local world = Support.world()
		local dispose, root, list = mountList(world, items("a", "b", "c", "d"))
		world.host.resetCounts()

		list:set(items("d", "c", "b", "a"))
		world.settle()

		expect(order(world, root)):toEqual { "d", "c", "b", "a" }
		expect(world.host.counts().moveChild):toBe(3)
		dispose()
	end)

	it("appends without touching the rows already there", function()
		local world = Support.world()
		local dispose, root, list = mountList(world, items("a", "b"))
		world.host.resetCounts()

		list:set(items("a", "b", "c"))
		world.settle()

		expect(order(world, root)):toEqual { "a", "b", "c" }
		expect(world.host.counts().createNode):toBe(1)
		expect(world.host.counts().moveChild):toBe(0)
		dispose()
	end)

	it("prepends with one create and no moves", function()
		local world = Support.world()
		local dispose, root, list = mountList(world, items("b", "c"))
		world.host.resetCounts()

		list:set(items("a", "b", "c"))
		world.settle()

		expect(order(world, root)):toEqual { "a", "b", "c" }
		expect(world.host.counts().createNode):toBe(1)
		expect(world.host.counts().moveChild):toBe(0)
		dispose()
	end)

	it("inserts into the middle without moving its neighbours", function()
		local world = Support.world()
		local dispose, root, list = mountList(world, items("a", "b", "d"))
		world.host.resetCounts()

		list:set(items("a", "b", "c", "d"))
		world.settle()

		expect(order(world, root)):toEqual { "a", "b", "c", "d" }
		expect(world.host.counts().createNode):toBe(1)
		expect(world.host.counts().moveChild):toBe(0)
		dispose()
	end)

	it("removes from the middle and destroys exactly that row", function()
		local world = Support.world()
		local dispose, root, list = mountList(world, items("a", "b", "c"))
		local before = world.host.childrenOf(root)
		world.host.resetCounts()

		list:set(items("a", "c"))
		world.settle()

		expect(order(world, root)):toEqual { "a", "c" }
		expect(world.host.counts().destroyNode):toBe(1)
		expect(world.host.isAlive(before[2])):toBe(false)
		expect(world.host.isAlive(before[1])):toBe(true)
		dispose()
	end)

	it("replaces every key by destroying and rebuilding all rows", function()
		local world = Support.world()
		local dispose, root, list = mountList(world, items("a", "b"))
		world.host.resetCounts()

		list:set(items("x", "y"))
		world.settle()

		expect(order(world, root)):toEqual { "x", "y" }
		expect(world.host.counts().createNode):toBe(2)
		expect(world.host.counts().destroyNode):toBe(2)
		dispose()
	end)

	it("updates a row whose data changed but whose key did not", function()
		local world = Support.world()
		local list = Compose.cell { { id = "a", label = "first" } }
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.keyed {
					from = function(use)
						return use(list)
					end,
					render = function(value)
						return world.create "Row" {
							Label = function(use)
								return use(value).label
							end,
						}
					end,
					key = function(item)
						return item.id
					end,
				},
			}
		end, world.root)

		local row = world.host.childrenOf(root)[1]
		world.host.resetCounts()

		list:set { { id = "a", label = "second" } }
		world.settle()

		expect(world.host.childrenOf(root)[1]):toBe(row)
		expect(world.host.propertyOf(row, "Label")):toBe "second"
		expect(world.host.counts().createNode):toBe(0)
		expect(world.host.counts().setProperty):toBe(1)
		dispose()
	end)

	it("keeps the index signal correct after a reorder", function()
		local world = Support.world()
		local dispose, root, list = mountList(world, items("a", "b", "c"))
		list:set(items("c", "b", "a"))
		world.settle()

		local children = world.host.childrenOf(root)
		expect(world.host.propertyOf(children[1], "Order")):toBe(1)
		expect(world.host.propertyOf(children[2], "Order")):toBe(2)
		expect(world.host.propertyOf(children[3], "Order")):toBe(3)
		dispose()
	end)

	it("rejects duplicate keys with a diagnostic that names the collision", function()
		local world = Support.world()
		local ok, err: any = pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.keyed {
						from = function()
							return items("a", "a")
						end,
						render = function()
							return world.create "Row" {}
						end,
						key = idOf,
					},
				}
			end, world.root)
		end)
		expect(ok):toBe(false)
		expect(tostring(err)):toContain "structure/duplicate-key"
		expect(tostring(err)):toContain "also used at index 1"
	end)

	it("leaves no nodes behind after disposal", function()
		local world = Support.world()
		local dispose = mountList(world, items("a", "b", "c"))
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("keeps static siblings in place around a growing list", function()
		local world = Support.world()
		local list = Compose.cell(items "a")
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "Header" { Id = "header" },
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
				world.create "Footer" { Id = "footer" },
			}
		end, world.root)

		expect(order(world, root)):toEqual { "header", "a", "footer" }
		list:set(items("a", "b", "c"))
		world.settle()
		expect(order(world, root)):toEqual { "header", "a", "b", "c", "footer" }
		list:set {}
		world.settle()
		expect(order(world, root)):toEqual { "header", "footer" }
		dispose()
	end)
end)

describe("keyed below the root", function()
	local function listOf(world: any, items: any)
		local Label = world.create "Label"
		return Compose.keyed {
			from = function(use)
				return use(items)
			end,
			render = function(item)
				return Label {
					Text = function(use)
						return tostring(use(item).id)
					end,
				}
			end,
			key = function(item: { id: number })
				return item.id
			end,
		}
	end

	it("disposes cleanly one level below the mount root", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local items = Compose.cell { { id = 1 }, { id = 2 } }

		local dispose = world.runtime.mount(function()
			return Frame { Frame { listOf(world, items) } }
		end, world.root)
		world.settle()

		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("disposes cleanly with two lists under two parents", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local items = Compose.cell { { id = 1 }, { id = 2 } }

		local dispose = world.runtime.mount(function()
			return Frame {
				Frame { listOf(world, items) },
				Frame { listOf(world, items) },
			}
		end, world.root)
		world.settle()

		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)
end)

return nil
