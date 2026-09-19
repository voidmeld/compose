--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function expectClean(world: Support.World)
	expect(world.host.leaked()):toEqual { "Root#1" }
	expect(world.host.liveSubscriptions()):toBe(0)
	expect(Compose.outstandingMounts()):toBe(0)
end

describe("the custody of a mount target", function()
	describe("a target Compose destroys", function()
		it("keeps owned custody, and stays in the destruction set", function()
			local world = Support.world()
			local container: Compose.Node? = nil
			local child: Compose.Node? = nil

			local dispose = world.runtime.mount(function()
				local frame = world.create "Frame" { Name = "Container" }
				container = frame
				local _, mounted = world.runtime.mount(function()
					return world.create "Text" { Text = "inner" }
				end, frame)
				child = mounted
				return frame
			end, world.root)

			local owned = container :: Compose.Node
			expect(Compose.custodyOf(owned)):toBe "owned"
			expect(world.host.childrenOf(owned)):toEqual { child }

			dispose()
			expect(world.host.isAlive(owned)):toBe(false)
			expect(world.host.isAlive(child :: Compose.Node)):toBe(false)
			expectClean(world)
		end)

		it("keeps adopted custody, so an adopted target is still destroyed", function()
			local world = Support.world()
			local external = world.host.makeNode "External"

			local dispose = world.runtime.mount(function()
				world.runtime.adopt(external)
				world.runtime.mount(function()
					return world.create "Text" { Text = "inner" }
				end, external)
				return world.create "Frame" {}
			end, world.root)

			expect(Compose.custodyOf(external)):toBe "adopted"
			dispose()
			expect(world.host.isAlive(external)):toBe(false)
			expectClean(world)
		end)

		it("disposes what was mounted there before destroying the target", function()
			local world = Support.world()
			local order: { string } = {}
			local container: Compose.Node? = nil

			local dispose = world.runtime.mount(function()
				local frame = world.create "Frame" {}
				container = frame
				Compose.cleanup(function()
					table.insert(order, "target-scope")
				end)
				world.runtime.mount(function()
					Compose.cleanup(function()
						table.insert(order, "mounted-into-target")
					end)
					return world.create "Text" {}
				end, frame)
				return frame
			end, world.root)

			dispose()
			expect(order):toEqual { "mounted-into-target", "target-scope" }
			expect(world.host.isAlive(container :: Compose.Node)):toBe(false)
			expectClean(world)
		end)

		it("leaves the target standing when only the mounted child is unmounted", function()
			local world = Support.world()
			local container: Compose.Node? = nil
			local detach: (() -> ())? = nil

			local dispose = world.runtime.mount(function()
				local frame = world.create "Frame" {}
				container = frame
				local unmount = world.runtime.mount(function()
					return world.create "Text" { Text = "inner" }
				end, frame)
				detach = unmount
				return frame
			end, world.root)

			local owned = container :: Compose.Node
			expect(#world.host.childrenOf(owned)):toBe(1)

			world.host.resetCounts();
			(detach :: () -> ())()
			expect(world.host.isAlive(owned)):toBe(true)
			expect(Compose.custodyOf(owned)):toBe "owned"
			expect(world.host.childrenOf(owned)):toEqual {}
			expect(world.host.counts().destroyNode):toBe(1)

			dispose()
			expect(world.host.isAlive(owned)):toBe(false)
			expectClean(world)
		end)

		it("keeps owned custody for a fragment mounted into it", function()
			local world = Support.world()
			local container: Compose.Node? = nil

			local dispose = world.runtime.mount(function()
				local frame = world.create "Frame" {}
				container = frame
				world.runtime.mountFragment(function()
					return {
						world.create "Text" { Text = "a" },
						world.create "Text" { Text = "b" },
					}
				end, frame)
				return frame
			end, world.root)

			local owned = container :: Compose.Node
			expect(Compose.custodyOf(owned)):toBe "owned"
			expect(#world.host.childrenOf(owned)):toBe(2)

			dispose()
			expect(world.host.isAlive(owned)):toBe(false)
			expectClean(world)
		end)
	end)

	describe("a target Compose does not destroy", function()
		it("is borrowed and left standing, as before", function()
			local world = Support.world()
			local external = world.host.makeNode "External"

			local dispose = world.runtime.mount(function()
				world.runtime.mount(function()
					return world.create "Text" { Text = "inner" }
				end, external)
				return world.create "Frame" {}
			end, world.root)

			expect(Compose.custodyOf(external)):toBe "borrowed"
			dispose()
			expect(world.host.isAlive(external)):toBe(true)
			expect(world.host.childrenOf(external)):toEqual {}
			expect(Compose.custodyOf(external)):toBe "borrowed"
		end)

		it("is borrowed at the top level, and the mount target is never destroyed", function()
			local world = Support.world()
			local dispose = world.runtime.mount(function()
				return world.create "Frame" {}
			end, world.root)
			dispose()
			expect(world.host.isAlive(world.root)):toBe(true)
			expect(Compose.custodyOf(world.root)):toBe "borrowed"
		end)

		it("is borrowed when a fragment is mounted into it", function()
			local world = Support.world()
			local external = world.host.makeNode "External"

			local dispose = world.runtime.mountFragment(function()
				return { world.create "Text" { Text = "a" } }
			end, external)

			expect(Compose.custodyOf(external)):toBe "borrowed"
			dispose()
			expect(world.host.isAlive(external)):toBe(true)
			expect(Compose.custodyOf(external)):toBe "borrowed"
		end)
	end)

	describe("a top-level mount into a target Compose destroys", function()
		it("keeps the target owned, and mounts into it", function()
			local world = Support.world()
			local container, owner = Support.owned(function()
				return world.create "Frame" { Name = "Container" }
			end)

			local detach, child = world.runtime.mount(function()
				return world.create "Text" { Text = "inner" }
			end, container)

			expect(Compose.custodyOf(container)):toBe "owned"
			expect(world.host.childrenOf(container)):toEqual { child }
			expect(Compose.outstandingMounts()):toBe(1)

			detach()
			owner.dispose()
			expectClean(world)
		end)

		it("disposes the block before destroying the target when the owning tree goes", function()
			local world = Support.world()
			local order: { string } = {}
			local container, owner = Support.owned(function()
				Compose.cleanup(function()
					table.insert(order, "target-scope")
				end)
				return world.create "Frame" { Name = "Container" }
			end)

			world.runtime.mount(function()
				Compose.cleanup(function()
					table.insert(
						order,
						if world.host.isAlive(container) then "block:target-alive" else "block:target-gone"
					)
				end)
				return world.create "Text" { Text = "inner" }
			end, container)

			owner.dispose()
			expect(order):toEqual { "block:target-alive", "target-scope" }
			expect(world.host.isAlive(container)):toBe(false)
			expectClean(world)
		end)

		it("leaves the target alive and owned when the block is unmounted by hand", function()
			local world = Support.world()
			local container, owner = Support.owned(function()
				return world.create "Frame" { Name = "Container" }
			end)

			local detach = world.runtime.mount(function()
				return world.create "Text" { Text = "inner" }
			end, container)

			world.host.resetCounts()
			detach()
			expect(world.host.isAlive(container)):toBe(true)
			expect(Compose.custodyOf(container)):toBe "owned"
			expect(world.host.childrenOf(container)):toEqual {}
			expect(world.host.counts().destroyNode):toBe(1)
			expect(Compose.outstandingMounts()):toBe(0)

			detach()
			expect(world.host.isAlive(container)):toBe(true)

			owner.dispose()
			expect(world.host.isAlive(container)):toBe(false)
			expectClean(world)
		end)

		it("disposes two blocks in one target in reverse mount order", function()
			local world = Support.world()
			local order: { string } = {}
			local container, owner = Support.owned(function()
				return world.create "Frame" { Name = "Container" }
			end)

			for _, name in { "first", "second" } do
				world.runtime.mount(function()
					Compose.cleanup(function()
						table.insert(order, name)
					end)
					return world.create "Text" { Text = name }
				end, container)
			end
			expect(Compose.outstandingMounts()):toBe(2)

			owner.dispose()
			expect(order):toEqual { "second", "first" }
			expectClean(world)
		end)

		it("orders a fragment against an adopted target the same way", function()
			local world = Support.world()
			local order: { string } = {}
			local external = world.host.makeNode "External"
			local _, owner = Support.owned(function()
				return world.runtime.adopt(external)
			end)
			expect(Compose.custodyOf(external)):toBe "adopted"

			world.runtime.mountFragment(function()
				Compose.cleanup(function()
					table.insert(
						order,
						if world.host.isAlive(external) then "block:target-alive" else "block:target-gone"
					)
				end)
				return { world.create "Text" { Text = "a" } }
			end, external)

			expect(Compose.custodyOf(external)):toBe "adopted"
			expect(#world.host.childrenOf(external)):toBe(1)

			owner.dispose()
			expect(order):toEqual { "block:target-alive" }
			expect(world.host.isAlive(external)):toBe(false)
			expectClean(world)
		end)

		it("still holds only the mount when the target is one Compose does not destroy", function()
			local world = Support.world()
			local external = world.host.makeNode "External"

			local detach = world.runtime.mount(function()
				return world.create "Text" { Text = "inner" }
			end, external)

			expect(Compose.custodyOf(external)):toBe "borrowed"
			detach()
			expect(world.host.isAlive(external)):toBe(true)
			expect(world.host.childrenOf(external)):toEqual {}
			expect(Compose.outstandingMounts()):toBe(0)
		end)

		it("unwinds a failed top-level mount and leaves the target orderable", function()
			local world = Support.world()
			local order: { string } = {}
			local container, owner = Support.owned(function()
				return world.create "Frame" { Name = "Container" }
			end)

			world.host.failNext "createNode"
			expect(function()
				world.runtime.mount(function()
					return world.create "Text" { Text = "never built" }
				end, container)
			end):toThrow "createNode"

			expect(Compose.custodyOf(container)):toBe "owned"
			expect(world.host.isAlive(container)):toBe(true)
			expect(world.host.childrenOf(container)):toEqual {}
			expect(Compose.outstandingMounts()):toBe(0)

			world.runtime.mount(function()
				Compose.cleanup(function()
					table.insert(order, "retry")
				end)
				return world.create "Text" { Text = "second" }
			end, container)

			owner.dispose()
			expect(order):toEqual { "retry" }
			expectClean(world)
		end)
	end)

	describe("refusals", function()
		it("still refuses a target that is not a node at all", function()
			local world = Support.world()
			expect(function()
				world.runtime.mount(function()
					return world.create "Text" {}
				end, 7 :: any)
			end):toThrow "mount/target-not-a-node"
		end)
	end)

	describe("failure injection", function()
		it("unwinds a failed mount into an owned target and leaves the target intact", function()
			local world = Support.world()
			local container: Compose.Node? = nil
			local raised = false

			local dispose = world.runtime.mount(function()
				local frame = world.create "Frame" {}
				container = frame
				world.host.failNext "createNode"
				local ok = pcall(function()
					world.runtime.mount(function()
						return world.create "Text" { Text = "never built" }
					end, frame)
				end)
				raised = not ok
				return frame
			end, world.root)

			local owned = container :: Compose.Node
			expect(raised):toBe(true)
			expect(Compose.custodyOf(owned)):toBe "owned"
			expect(world.host.isAlive(owned)):toBe(true)
			expect(world.host.childrenOf(owned)):toEqual {}

			local retry = world.runtime.mount(function()
				return world.create "Text" { Text = "second" }
			end, world.root)
			retry()

			dispose()
			expect(world.host.isAlive(owned)):toBe(false)
			expectClean(world)
		end)

		it("unwinds a failed insert into an owned target without demoting it", function()
			local world = Support.world()
			local container: Compose.Node? = nil
			local raised = false

			local dispose = world.runtime.mount(function()
				local frame = world.create "Frame" {}
				container = frame
				world.host.failNext "insertChild"
				local ok = pcall(function()
					world.runtime.mountFragment(function()
						return { world.create "Text" { Text = "never placed" } }
					end, frame)
				end)
				raised = not ok
				return frame
			end, world.root)

			local owned = container :: Compose.Node
			expect(raised):toBe(true)
			expect(Compose.custodyOf(owned)):toBe "owned"
			expect(world.host.childrenOf(owned)):toEqual {}

			dispose()
			expect(world.host.isAlive(owned)):toBe(false)
			expectClean(world)
		end)
	end)
end)

return nil
