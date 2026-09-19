--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function expectNothingLeft(world: Support.World)
	expect(world.host.leaked()):toEqual { "Root#1" }
	expect(world.host.liveSubscriptions()):toBe(0)
	expect(world.host.childrenOf(world.root)):toEqual {}
	expect(Compose.outstandingMounts()):toBe(0)
end

describe("unwinding a failed render", function()
	it("leaves nothing behind when createNode fails at the root", function()
		local world = Support.world()
		world.host.failNext "createNode"
		local ok = pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" {}
			end, world.root)
		end)
		expect(ok):toBe(false)
		expectNothingLeft(world)
	end)

	it("destroys the node whose property write failed", function()
		local world = Support.world()
		world.host.failNext "setProperty"
		local ok = pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" { Title = "x" }
			end, world.root)
		end)
		expect(ok):toBe(false)
		expectNothingLeft(world)
	end)

	it("unwinds a deep subtree when a leaf's property write fails", function()
		local world = Support.world()
		world.host.failNext("setProperty", 1)
		local ok = pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					world.create "Row" {
						world.create "Text" { Text = "deep" },
					},
				}
			end, world.root)
		end)
		expect(ok):toBe(false)
		expectNothingLeft(world)
	end)

	it("unwinds when a component raises before returning", function()
		local world = Support.world()
		local ok = pcall(function()
			world.runtime.mount(function(): Compose.Node
				world.create "Frame" {}
				world.create "Text" {}
				error "component gave up"
			end, world.root)
		end)
		expect(ok):toBe(false)
		expectNothingLeft(world)
	end)

	it("unwinds when insertChild fails", function()
		local world = Support.world()
		world.host.failNext "insertChild"
		local ok = pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" {}
			end, world.root)
		end)
		expect(ok):toBe(false)
		expectNothingLeft(world)
	end)

	it("removes the nodes it already inserted when a later insert fails", function()
		local world = Support.world()
		world.host.failNext("insertChild", 1)
		local ok = pcall(function()
			world.runtime.mountFragment(function()
				return {
					world.create "A" {},
					world.create "B" {},
					world.create "C" {},
				}
			end, world.root)
		end)
		expect(ok):toBe(false)
		expectNothingLeft(world)
	end)

	it("unwinds when connectEvent fails", function()
		local world = Support.world()
		world.host.failNext "connectEvent"
		local ok = pcall(function()
			world.runtime.mount(function()
				return world.create "Button" {
					[Compose.event "Activated"] = function() end,
				}
			end, world.root)
		end)
		expect(ok):toBe(false)
		expectNothingLeft(world)
	end)

	it("releases the subscriptions it already made when a later one fails", function()
		local world = Support.world()
		world.host.failNext("connectEvent", 1)
		local ok = pcall(function()
			world.runtime.mount(function()
				return world.create "Button" {
					[Compose.event "First"] = function() end,
					[Compose.event "Second"] = function() end,
					[Compose.event "Third"] = function() end,
				}
			end, world.root)
		end)
		expect(ok):toBe(false)
		expectNothingLeft(world)
	end)

	it("unwinds a failing show branch without disturbing its siblings", function()
		local world = Support.world()
		local open = Compose.cell(false)
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "Header" {},
				Compose.show(function(use)
					return use(open)
				end, function()
					return world.create "Panel" { Title = "boom" }
				end),
				world.create "Footer" {},
			}
		end, world.root)

		local before = world.host.liveNodes()
		world.host.failNext "setProperty"
		local ok = pcall(function()
			open:set(true)
			world.settle()
		end)
		expect(ok):toBe(false)
		expect(world.host.liveNodes()):toBe(before)
		expect(world.host.childrenOf(root)):toHaveLength(2)

		world.host.clearFailures()
		open:set(false)
		open:set(true)
		world.settle()
		expect(world.host.childrenOf(root)):toHaveLength(3)

		dispose()
		expectNothingLeft(world)
	end)

	it("unwinds a failing keyed row without disturbing the rows around it", function()
		local world = Support.world()
		local list = Compose.cell { "a", "b" }
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.keyed {
					from = function(use)
						return use(list)
					end,
					render = function(value)
						return world.create "Row" {
							Id = function(use)
								return use(value)
							end,
						}
					end,
				},
			}
		end, world.root)

		local before = world.host.liveNodes()
		world.host.failNext "createNode"
		local ok = pcall(function()
			list:set { "a", "b", "c" }
			world.settle()
		end)
		expect(ok):toBe(false)
		expect(world.host.liveNodes()):toBe(before)
		expect(world.host.childrenOf(root)):toHaveLength(2)

		dispose()
		expectNothingLeft(world)
	end)

	it("still destroys the rest of a subtree when one destructor raises", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "A" {},
				world.create "B" {},
			}
		end, world.root)

		world.host.failNext "destroyNode"
		local ok = pcall(dispose)
		expect(ok):toBe(false)

		expect(world.host.liveNodes()):toBeLessThanOrEqual(2)
		expect(Compose.outstandingMounts()):toBe(0)
	end)

	describe("when several disposers raise", function()
		it("runs all of them and reports every error", function()
			local owner = Compose.createOwner()
			local ran: { string } = {}
			owner.own(function()
				table.insert(ran, "first")
			end)
			owner.own(function()
				table.insert(ran, "second")
				error "second failed"
			end)
			owner.own(function()
				table.insert(ran, "third")
			end)
			owner.own(function()
				table.insert(ran, "fourth")
				error "fourth failed"
			end)
			owner.own(function()
				table.insert(ran, "fifth")
			end)

			local ok, err: any = pcall(owner.dispose)
			expect(ok):toBe(false)
			expect(ran):toEqual { "fifth", "fourth", "third", "second", "first" }
			expect(tostring(err)):toContain "2 errors while disposing an owner"
			expect(tostring(err)):toContain "fourth failed"
			expect(tostring(err)):toContain "second failed"
			expect(owner.isDisposed()):toBe(true)
			expect(owner.size()):toBe(0)
		end)

		it("reports a single failure on its own, unwrapped", function()
			local owner = Compose.createOwner()
			local ran = 0
			owner.own(function()
				ran += 1
			end)
			owner.own(function()
				error "only failure"
			end)
			expect(function()
				owner.dispose()
			end):toThrow "only failure"
			expect(ran):toBe(1)
		end)

		it("releases the rest of a subtree when a child's disposer raises", function()
			local root = Compose.createOwner()
			local released: { string } = {}
			local first = root.createChild()
			first.own(function()
				table.insert(released, "first")
			end)
			local failing = root.createChild()
			failing.own(function()
				table.insert(released, "failing")
				error "child failed"
			end)
			local last = root.createChild()
			last.own(function()
				table.insert(released, "last")
			end)

			local ok = pcall(root.dispose)
			expect(ok):toBe(false)
			expect(released):toEqual { "last", "failing", "first" }
			expect(first.isDisposed()):toBe(true)
			expect(failing.isDisposed()):toBe(true)
			expect(last.isDisposed()):toBe(true)
		end)

		it("keeps a rollback going past a disposer that raises", function()
			local owner = Compose.createOwner()
			local ran: { string } = {}
			owner.own(function()
				table.insert(ran, "kept")
			end)
			local mark = owner.checkpoint()
			owner.own(function()
				table.insert(ran, "a")
			end)
			owner.own(function()
				table.insert(ran, "b")
				error "b failed"
			end)
			owner.own(function()
				table.insert(ran, "c")
				error "c failed"
			end)

			local ok, err: any = pcall(owner.rollbackTo, mark)
			expect(ok):toBe(false)
			expect(ran):toEqual { "c", "b", "a" }
			expect(tostring(err)):toContain "2 errors while disposing an owner"
			expect(owner.size()):toBe(1)
			owner.dispose()
			expect(ran):toEqual { "c", "b", "a", "kept" }
		end)
	end)

	it("does not leave the scheduler wedged after an unwind", function()
		local world = Support.world()
		world.host.failNext "createNode"
		pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" {}
			end, world.root)
		end)

		expect(world.pending()):toBe(0)
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {}
		end, world.root)
		expect(world.host.childrenOf(world.root)):toHaveLength(1)
		dispose()
		expectNothingLeft(world)
	end)
end)

return nil
