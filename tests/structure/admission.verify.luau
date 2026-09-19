--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect, beforeEach = Test.describe, Test.it, Test.expect, Test.beforeEach

type Item = { id: number, priority: number }
local world: Support.World

local function ids(root: Compose.Node): { number }
	local result: { number } = {}
	for _, node in world.host.childrenOf(root) do
		result[#result + 1] = world.host.propertyOf(node, "Id") :: number
	end
	return result
end

local function mountBudgeted(options: {
	initial: { Item },
	mountsPerFrame: number,
	status: Compose.Cell<Compose.MountBudgetStatus>?,
})
	local items = Compose.cell(options.initial)
	local dispose, root = world.runtime.mount(function()
		return world.create "Root" {
			Compose.MountBudget {
				from = items,
				key = function(item: Item)
					return item.id
				end,
				priority = function(item: Item)
					return item.priority
				end,
				mountsPerFrame = options.mountsPerFrame,
				status = options.status,
				render = function(value: Compose.Readable<Item>)
					return world.create "Item" {
						Id = function(use)
							return use(value).id
						end,
					}
				end,
			},
		}
	end, world.root)
	return dispose, root, items
end

describe("frame-driven admission", function()
	beforeEach(function()
		world = Support.world()
	end)

	describe("starvation", function()
		it("eventually mounts the lowest-priority item under a fixed adversarial backlog", function()
			local backlog: { Item } = {}
			for index = 1, 20 do
				backlog[index] = { id = index, priority = index }
			end
			local dispose, root = mountBudgeted { initial = backlog, mountsPerFrame = 1 }

			for _ = 1, 19 do
				world.host.step(1 / 60)
				world.settle()
			end

			expect(#ids(root)):toBe(20)
			expect(world.host.counts().frameListeners):toBe(0)
			dispose()
		end)

		it("still drains a low-priority item while higher-priority work keeps arriving", function()
			local status = Compose.cell({} :: Compose.MountBudgetStatus)
			local dispose, root, items = mountBudgeted {
				initial = { { id = 1, priority = 0 }, { id = 2, priority = 5 }, { id = 3, priority = 5 } },
				mountsPerFrame = 2,
				status = status,
			}

			local population: { Item } =
				{ { id = 1, priority = 0 }, { id = 2, priority = 5 }, { id = 3, priority = 5 } }
			for arrival = 1, 6 do
				population = table.clone(population)
				table.insert(population, { id = 100 + arrival, priority = 10 + arrival })
				items:set(population)
				world.settle()
				world.host.step(1 / 60)
				world.settle()
			end
			for _ = 1, 6 do
				world.host.step(1 / 60)
				world.settle()
			end

			expect(#ids(root)):toBe(#population)
			expect(status:peek().pending):toBe(0)
			local mounted = ids(root)
			table.sort(mounted)
			expect(mounted[1]):toBe(1)
			expect(world.host.counts().frameListeners):toBe(0)
			dispose()
		end)
	end)

	describe("teardown mid-drain", function()
		it("releases the frame subscription and every admitted node when disposed with a backlog", function()
			local backlog: { Item } = {}
			for index = 1, 12 do
				backlog[index] = { id = index, priority = 0 }
			end
			local dispose, root = mountBudgeted { initial = backlog, mountsPerFrame = 2 }
			world.host.step(1 / 60)
			world.settle()
			expect(#ids(root)):toBe(4)
			expect(world.host.counts().frameListeners):toBe(1)

			dispose()

			expect(world.host.counts().frameListeners):toBe(0)
			expect(world.host.liveNodes()):toBe(1)
			world.host.step(1 / 60)
			world.settle()
			expect(world.host.liveNodes()):toBe(1)
		end)

		it("releases a spatial collection disposed in the middle of filling in", function()
			type Unit = { id: string, x: number, y: number, z: number }
			local units: { Unit } = {}
			for index = 1, 30 do
				units[index] = { id = "u" .. index, x = (index - 1) * 5, y = 0, z = 0 }
			end
			local origin = Compose.cell({ x = 10000, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose = world.runtime.mount(function()
				return world.create "Frame" {
					Compose.SpatialCollection {
						from = Compose.cell(units),
						key = function(unit: Unit)
							return unit.id
						end,
						position = function(unit: Unit)
							return unit.x, unit.y, unit.z
						end,
						origin = origin,
						tiers = { { name = "full", radius = 300 } },
						budget = { mountsPerFrame = 4 },
						render = function()
							return world.create "Unit" {}
						end,
					},
				}
			end, world.root)

			origin:set { x = 0, y = 0, z = 0 }
			world.settle()
			world.host.step(1 / 60)
			world.settle()
			expect(world.host.counts().frameListeners):toBe(1)

			dispose()

			expect(world.host.counts().frameListeners):toBe(0)
			expect(world.host.liveNodes()):toBe(1)
		end)
	end)

	describe("failure during a pump step", function()
		it("keeps independent admissions and retries failed rows on later frames", function()
			local backlog: { Item } = {}
			for index = 1, 8 do
				backlog[index] = { id = index, priority = 0 }
			end
			local dispose, root = mountBudgeted { initial = backlog, mountsPerFrame = 2 }
			expect(#ids(root)):toBe(2)

			world.host.failNext("createNode", 1)
			expect(function()
				world.host.step(1 / 60)
				world.settle()
			end):toThrow "createNode"
			world.host.clearFailures()

			expect(ids(root)):toEqual { 1, 2, 4 }
			expect(world.host.liveNodes()):toBe(5)
			expect(world.host.counts().frameListeners):toBe(1)
			for _ = 1, 3 do
				world.host.step(1 / 60)
				world.settle()
			end
			expect(#ids(root)):toBe(8)
			expect(world.host.counts().frameListeners):toBe(0)

			dispose()
			expect(world.host.liveNodes()):toBe(1)
		end)

		it("survives a render body that raises mid-drain and disposes cleanly after", function()
			local poisoned = true
			local items = Compose.cell({} :: { Item })
			local dispose, root = world.runtime.mount(function()
				return world.create "Root" {
					Compose.MountBudget {
						from = items,
						key = function(item: Item)
							return item.id
						end,
						mountsPerFrame = 1,
						render = function(value: Compose.Readable<Item>)
							if poisoned and value:peek().id == 2 then
								error "row 2 refused to build"
							end
							return world.create "Item" {
								Id = function(use)
									return use(value).id
								end,
							}
						end,
					},
				}
			end, world.root)

			items:set { { id = 1, priority = 0 }, { id = 2, priority = 0 }, { id = 3, priority = 0 } }
			world.settle()
			expect(ids(root)):toEqual { 1 }

			expect(function()
				world.host.step(1 / 60)
				world.settle()
			end):toThrow "row 2 refused to build"

			poisoned = false
			for _ = 1, 3 do
				world.host.step(1 / 60)
				world.settle()
			end
			local mounted = ids(root)
			table.sort(mounted)
			expect(mounted):toEqual { 1, 2, 3 }
			expect(world.host.counts().frameListeners):toBe(0)

			dispose()
			expect(world.host.liveNodes()):toBe(1)
		end)
	end)

	describe("hosts without frames", function()
		it("refuses an admission budget where the host cannot supply frames", function()
			local frameless = table.clone(world.host.adapter)
			frameless.frames = nil
			local runtime = Compose.createRuntime(frameless)
			local create = runtime.create
			expect(function()
				runtime.mount(function()
					return create "Root" {
						Compose.MountBudget {
							from = Compose.cell({
								{ id = 1, priority = 0 },
								{ id = 2, priority = 0 },
								{ id = 3, priority = 0 },
							} :: { Item }),
							key = function(item: Item)
								return item.id
							end,
							mountsPerFrame = 1,
							render = function()
								return create "Item" {}
							end,
						},
					}
				end, world.root)
			end):toThrow "collection/no%-frames"
			expect(world.host.counts().frameListeners):toBe(0)
		end)
	end)
end)

return nil
