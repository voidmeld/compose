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

describe("MountBudget", function()
	beforeEach(function()
		world = Support.world()
	end)

	it("admits priority work over frames and stops pumping when drained", function()
		local items = Compose.cell({} :: { Item })
		local status = Compose.cell({} :: Compose.MountBudgetStatus)
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
					mountsPerFrame = 2,
					status = status,
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
		items:set {
			{ id = 1, priority = 1 },
			{ id = 2, priority = 10 },
			{ id = 3, priority = 5 },
			{ id = 4, priority = 0 },
		}
		world.settle()
		expect(#world.host.childrenOf(root)):toBe(2)
		expect(ids(root)):toEqual { 2, 3 }
		expect(status:peek().pending):toBe(2)
		world.host.step(1 / 60)
		world.settle()
		expect(#world.host.childrenOf(root)):toBe(4)
		expect(world.host.counts().frameListeners):toBe(0)
		dispose()
	end)

	it("budgets a full replacement instead of mounting it in one spike", function()
		local items = Compose.cell({} :: { Item })
		local initial: { Item } = {}
		for index = 1, 10 do
			initial[index] = { id = index, priority = 0 }
		end
		items:set(initial)
		local status = Compose.cell({} :: Compose.MountBudgetStatus)
		local dispose, root = world.runtime.mount(function()
			return world.create "Root" {
				Compose.MountBudget {
					from = items,
					key = function(item: Item)
						return item.id
					end,
					mountsPerFrame = 2,
					status = status,
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
		for _ = 1, 5 do
			world.host.step(1 / 60)
			world.settle()
		end
		local replacement: { Item } = {}
		for index = 1, 10 do
			replacement[index] = { id = 100 + index, priority = 0 }
		end
		items:set(replacement)
		world.settle()
		expect(#world.host.childrenOf(root)):toBe(2)
		expect(status:peek().pending):toBe(8)
		dispose()
	end)

	it("removes departed work immediately instead of budgeting correctness", function()
		local items = Compose.cell({ { id = 1, priority = 0 }, { id = 2, priority = 0 } } :: { Item })
		local dispose, root = world.runtime.mount(function()
			return world.create "Root" {
				Compose.MountBudget {
					from = items,
					key = function(item: Item)
						return item.id
					end,
					mountsPerFrame = 2,
					render = function()
						return world.create "Item" {}
					end,
				},
			}
		end, world.root)
		expect(#world.host.childrenOf(root)):toBe(2)
		items:set {}
		world.settle()
		expect(#world.host.childrenOf(root)):toBe(0)
		dispose()
	end)

	it("unsubscribes and unwinds admitted work when construction fails", function()
		expect(function()
			world.runtime.mount(function()
				return world.create "Root" {
					Compose.MountBudget {
						from = Compose.cell({ { id = 1, priority = 0 }, { id = 2, priority = 0 } } :: { Item }),
						key = function(item: Item)
							return item.id
						end,
						mountsPerFrame = 1,
						render = function(value: Compose.Readable<Item>)
							if value:peek().id == 1 then
								error "mount failed"
							end
							return world.create "Item" {}
						end,
					},
				}
			end, world.root)
		end):toThrow "mount failed"
		expect(world.host.liveNodes()):toBe(1)
		expect(world.host.counts().frameListeners):toBe(0)
	end)
end)

return nil
