--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local TestScene = require "../../src/test-scene"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Row = { id: number, label: string }

local function rows(ids: { number }): { Row }
	local made = table.create(#ids)
	for index, id in ids do
		made[index] = { id = id, label = ("row-%d"):format(id) }
	end
	return made
end

local function mountRows(options: TestScene.Options, initial: { number })
	local world = Support.world(options)
	local list = Compose.cell(rows(initial))
	local seenIndex: { [number]: number } = {}
	local dispose = world.runtime.mount(function()
		return world.create "Frame" {
			Compose.keyed {
				from = function(use)
					return use(list)
				end,
				render = function(value, index, key: number)
					return world.create "Row" {
						Label = function()
							return Compose.sample(value).label
						end,
						Order = function(use)
							local at = use(index)
							seenIndex[key] = at
							return at
						end,
					}
				end,
				key = function(row: Row)
					return row.id
				end,
			},
		}
	end, world.root)
	local function set(ids: { number })
		list:set(rows(ids))
		world.settle()
	end
	return world, set, dispose, seenIndex
end

local function idsUnder(world: Support.World, frame: Compose.Node): { number }
	local found: { number } = {}
	for _, child in world.host.childrenOf(frame) do
		table.insert(found, world.host.propertyOf(child, "Order") :: number)
	end
	return found
end

describe("a host that cannot order children", function()
	Test.beforeEach(function()
		Compose.__resetForTests()
	end)

	it("accepts a renderer with no moveChild", function()
		local world = Support.world { ordersChildren = false }
		expect(world.runtime).never:toBe(nil)
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {}
		end, world.root)
		expect(#world.host.childrenOf(world.root)):toBe(1)
		dispose()
	end)

	it("still rejects a renderer missing a method that is not optional", function()
		expect(function()
			Compose.createRuntime({
				name = "broken",
				render = {
					createNode = function()
						return {}
					end,
					setProperty = function() end,
					clearProperty = function() end,
					insertChild = function() end,

					destroyNode = function() end,
				} :: any,
			} :: any)
		end):toThrow "removeChild"
	end)

	it("reverses without asking the host to move anything", function()
		local world, set, dispose = mountRows({ ordersChildren = false }, { 1, 2, 3, 4, 5 })
		local frame = world.host.childrenOf(world.root)[1]
		local before = world.host.childrenOf(frame)

		world.host.resetCounts()
		set { 5, 4, 3, 2, 1 }

		local counts = world.host.counts()
		expect(counts.moveChild):toBe(0)
		expect(counts.createNode):toBe(0)
		expect(counts.destroyNode):toBe(0)
		expect(counts.insertChild):toBe(0)
		expect(counts.removeChild):toBe(0)

		local after = world.host.childrenOf(frame)
		expect(#after):toBe(5)
		for index = 1, 5 do
			expect(after[index]):toBe(before[index])
		end
		dispose()
	end)

	it("keeps each row's reactive index correct through a reversal", function()
		local _world, set, dispose, seenIndex = mountRows({ ordersChildren = false }, { 1, 2, 3, 4, 5 })
		expect(seenIndex):toEqual { [1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5 }

		set { 5, 4, 3, 2, 1 }
		expect(seenIndex):toEqual { [1] = 5, [2] = 4, [3] = 3, [4] = 2, [5] = 1 }

		set { 3, 1, 5 }
		expect(seenIndex[3]):toBe(1)
		expect(seenIndex[1]):toBe(2)
		expect(seenIndex[5]):toBe(3)
		dispose()
	end)

	it("adds, removes, and reuses the right rows", function()
		local world, set, dispose = mountRows({ ordersChildren = false }, { 1, 2, 3 })
		local frame = world.host.childrenOf(world.root)[1]
		local rowTwo = world.host.childrenOf(frame)[2]

		world.host.resetCounts()
		set { 1, 2, 3, 4 }
		expect(world.host.counts().createNode):toBe(1)
		expect(world.host.counts().destroyNode):toBe(0)

		world.host.resetCounts()
		set { 2, 4 }
		expect(world.host.counts().destroyNode):toBe(2)
		expect(world.host.counts().createNode):toBe(0)

		expect(world.host.isAlive(rowTwo)):toBe(true)
		expect(#world.host.childrenOf(frame)):toBe(2)
		dispose()
	end)

	it("destroys every row on disposal, leaving the borrowed root standing", function()
		local world, set, dispose = mountRows({ ordersChildren = false }, { 1, 2, 3, 4 })
		local frame = world.host.childrenOf(world.root)[1]
		local made = world.host.childrenOf(frame)

		set { 4, 3, 2, 1 }
		dispose()

		for _, node in made do
			expect(world.host.isAlive(node)):toBe(false)
		end
		expect(world.host.isAlive(world.root)):toBe(true)
		expect(#world.host.childrenOf(world.root)):toBe(0)
	end)

	it("produces the same rows an ordering host produces, with the same reactive indexes", function()
		local steps = { { 6, 5, 4, 3, 2, 1 }, { 3, 6, 1 }, { 1, 2, 3, 7, 8 }, { 8, 7, 3, 2, 1 } }

		local function run(options: TestScene.Options)
			local world, set, dispose, seenIndex = mountRows(options, { 1, 2, 3, 4, 5, 6 })
			local frame = world.host.childrenOf(world.root)[1]
			for _, step in steps do
				set(step)
			end
			local indexes = table.clone(seenIndex)
			local held = #world.host.childrenOf(frame)
			local arranged = idsUnder(world, frame)
			dispose()
			return indexes, held, arranged
		end

		local orderingIndexes, orderingHeld, arranged = run {}
		local plainIndexes, plainHeld = run { ordersChildren = false }

		expect(plainIndexes):toEqual(orderingIndexes)
		expect(plainHeld):toBe(orderingHeld)
		expect(plainHeld):toBe(5)
		expect(arranged):toEqual { 1, 2, 3, 4, 5 }
	end)

	it("costs the same whether or not the arrangement is skipped, in host writes", function()
		local function trace(options: TestScene.Options): { [string]: number }
			local world, set, dispose = mountRows(options, { 1, 2, 3, 4, 5, 6, 7, 8 })
			world.host.resetCounts()
			set { 8, 1, 7, 2, 6, 3, 5, 4 }
			set { 4, 5, 3, 6, 2, 7, 1, 8 }
			set { 1, 2, 3 }
			local counts = world.host.counts()
			dispose()
			return {
				createNode = counts.createNode,
				destroyNode = counts.destroyNode,
				setProperty = counts.setProperty,
				insertChild = counts.insertChild,
				removeChild = counts.removeChild,
			}
		end

		expect(trace { ordersChildren = false }):toEqual(trace {})
	end)
end)

return nil
