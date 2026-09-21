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

describe("ownership", function()
	describe("owners", function()
		it("disposes newest first", function()
			local order: { string } = {}
			local owner = Compose.createOwner()
			owner.own(function()
				table.insert(order, "first")
			end)
			owner.own(function()
				table.insert(order, "second")
			end)
			owner.own(function()
				table.insert(order, "third")
			end)
			owner.dispose()
			expect(order):toEqual { "third", "second", "first" }
		end)

		it("disposes each entry exactly once, however it is reached", function()
			local runs = 0
			local owner = Compose.createOwner()
			local detach = owner.own(function()
				runs += 1
			end)
			detach()
			detach()
			owner.dispose()
			owner.dispose()
			expect(runs):toBe(1)
		end)

		it("runs every disposer even when one raises, and reports them all", function()
			local ran: { string } = {}
			local owner = Compose.createOwner()
			owner.own(function()
				table.insert(ran, "bottom")
			end)
			owner.own(function()
				error "middle blew up"
			end)
			owner.own(function()
				error "top blew up"
			end)

			local ok, err: any = pcall(owner.dispose)
			expect(ok):toBe(false)
			expect(ran):toEqual { "bottom" }
			expect(tostring(err)):toContain "top blew up"
			expect(tostring(err)):toContain "middle blew up"
		end)

		it("hands back the one failure exactly as it was raised", function()
			local raised = { code = "cleanup/exploded" }
			local owner = Compose.createOwner()
			local ran = false
			owner.own(function()
				ran = true
			end)
			owner.own(function()
				error(raised, 0)
			end)

			local ok, err: any = pcall(owner.dispose)
			expect(ok):toBe(false)
			expect(err):toBe(raised)
			expect(ran):toBe(true)
		end)

		it("runs a cleanup a failing cleanup registered on the way out", function()
			local ran: { string } = {}
			local owner = Compose.createOwner()
			owner.own(function()
				table.insert(ran, "bottom")
			end)
			owner.own(function()
				owner.own(function()
					table.insert(ran, "late")
				end)
				error "top blew up"
			end)

			local ok, err: any = pcall(owner.dispose)
			expect(ok):toBe(false)
			expect(tostring(err)):toContain "top blew up"
			expect(ran):toEqual { "late", "bottom" }
			expect(owner.size()):toBe(0)
		end)

		it("keeps disposing a parent whose child cleanup raised, and reports both levels", function()
			local ran: { string } = {}
			local parent = Compose.createOwner()
			parent.own(function()
				table.insert(ran, "parent bottom")
			end)
			local child = parent.createChild()
			child.own(function()
				table.insert(ran, "child bottom")
			end)
			child.own(function()
				error "child blew up"
			end)
			parent.own(function()
				error "parent top blew up"
			end)

			local ok, err: any = pcall(parent.dispose)
			expect(ok):toBe(false)
			expect(ran):toEqual { "child bottom", "parent bottom" }
			expect(tostring(err)):toContain "child blew up"
			expect(tostring(err)):toContain "parent top blew up"
			expect(child.isDisposed()):toBe(true)
			expect(parent.size()):toBe(0)
		end)

		it("disposes a child when its parent goes", function()
			local owner = Compose.createOwner()
			local child = owner.createChild()
			local released = false
			child.own(function()
				released = true
			end)
			owner.dispose()
			expect(released):toBe(true)
			expect(child.isDisposed()):toBe(true)
		end)

		it("detaches a child that disposes itself first", function()
			local owner = Compose.createOwner()
			local child = owner.createChild()
			expect(owner.size()):toBe(1)
			child.dispose()
			expect(owner.size()):toBe(0)
			owner.dispose()
		end)

		it("does not skip older cleanup when a disposer detaches the next entry", function()
			local parent = Compose.createOwner()
			local ran: { string } = {}
			parent.own(function()
				table.insert(ran, "older")
			end)
			local child = parent.createChild()
			child.own(function()
				table.insert(ran, "child")
			end)
			parent.own(function()
				table.insert(ran, "later")
				child.dispose()
			end)

			parent.dispose()
			parent.dispose()
			expect(ran):toEqual { "later", "child", "older" }
			expect(child.isDisposed()):toBe(true)
			expect(parent.size()):toBe(0)
		end)

		it("runs a disposer immediately when registered after disposal", function()
			local owner = Compose.createOwner()
			owner.dispose()
			local ran = false
			owner.own(function()
				ran = true
			end)
			expect(ran):toBe(true)
			expect(owner.size()):toBe(0)
		end)
	end)

	describe("custody", function()
		it("destroys what it created", function()
			local world = Support.world()
			local dispose, node = world.runtime.mount(function()
				return world.create "Frame" {}
			end, world.root)
			expect(Compose.custodyOf(node)):toBe "owned"
			dispose()
			expect(world.host.isAlive(node)):toBe(false)
			expectClean(world)
		end)

		it("never destroys a node it did not create", function()
			local world = Support.world()
			local external = world.host.makeNode "External"
			local dispose = world.runtime.mount(function()
				local frame = world.create "Frame" {}
				world.runtime.borrow(external)
				return frame
			end, world.root)

			dispose()
			expect(world.host.isAlive(external)):toBe(true)
			expect(Compose.custodyOf(external)):toBe "borrowed"
		end)

		it("treats an unknown node as borrowed", function()
			local world = Support.world()
			local stranger = world.host.makeNode "Stranger"
			expect(Compose.custodyOf(stranger)):toBe "borrowed"
		end)

		it("destroys an adopted node exactly once", function()
			local world = Support.world()
			local external = world.host.makeNode "External"
			local dispose = world.runtime.mount(function()
				world.runtime.adopt(external)
				return world.create "Frame" {}
			end, world.root)

			expect(Compose.custodyOf(external)):toBe "adopted"
			dispose()
			expect(world.host.isAlive(external)):toBe(false)
			expect(world.host.counts().destroyNode):toBe(2)
		end)

		it("refuses to adopt a node it already owns", function()
			local world = Support.world()
			local ok, err: any = pcall(function()
				world.runtime.mount(function()
					local frame = world.create "Frame" {}
					world.runtime.adopt(frame)
					return frame
				end, world.root)
			end)
			expect(ok):toBe(false)
			expect(tostring(err)):toContain "owner/already-owned"
		end)

		it("clears properties it wrote onto a borrowed node", function()
			local world = Support.world()
			local external = world.host.makeNode "External"
			world.host.declareEvent("External", "Poked")
			local tint = Compose.cell "red"
			local pokes = 0

			local dispose = world.runtime.mount(function()
				world.runtime.decorate(external, {
					Tint = function(use)
						return use(tint)
					end,
					Label = "static",
					Poked = function()
						pokes += 1
					end,
				})
				return world.create "Frame" {}
			end, world.root)

			expect(world.host.propertyOf(external, "Tint")):toBe "red"
			tint:set "blue"
			world.settle()
			expect(world.host.propertyOf(external, "Tint")):toBe "blue"
			world.host.dispatch(external, "Poked")
			expect(pokes):toBe(1)

			dispose()

			expect(world.host.isAlive(external)):toBe(true)
			expect(world.host.propertyOf(external, "Tint")):toBeNil()
			expect(world.host.propertyOf(external, "Label")):toBeNil()
			world.host.dispatch(external, "Poked")
			expect(pokes):toBe(1)
			expect(world.host.liveSubscriptions()):toBe(0)
		end)

		it("refuses to add children through decorate", function()
			local world = Support.world()
			local external = world.host.makeNode "External"
			expect(function()
				world.runtime.mount(function()
					world.runtime.decorate(external, { world.create "Text" {} })
					return world.create "Frame" {}
				end, world.root)
			end):toThrow "props/decorate-has-children"
		end)
	end)

	describe("cleanup", function()
		it("registers a function with the active owner", function()
			local world = Support.world()
			local released = false
			local dispose = world.runtime.mount(function()
				Compose.cleanup(function()
					released = true
				end)
				return world.create "Frame" {}
			end, world.root)

			expect(released):toBe(false)
			dispose()
			expect(released):toBe(true)
			expectClean(world)
		end)

		it("accepts an object with destroy or dispose", function()
			local world = Support.world()
			local destroyed = false
			local disposed = false
			local dispose = world.runtime.mount(function()
				Compose.cleanup {
					destroy = function()
						destroyed = true
					end,
				}
				Compose.cleanup {
					dispose = function()
						disposed = true
					end,
				}
				return world.create "Frame" {}
			end, world.root)

			dispose()
			expect(destroyed):toBe(true)
			expect(disposed):toBe(true)
		end)

		it("refuses something it cannot tear down", function()
			local world = Support.world()
			expect(function()
				world.runtime.mount(function()
					Compose.cleanup(42)
					return world.create "Frame" {}
				end, world.root)
			end):toThrow "owner/uncleanable"
		end)

		it("refuses outside a mount", function()
			Compose.__resetForTests()
			expect(function()
				Compose.cleanup(function() end)
			end):toThrow "owner/no-active-owner"
		end)
	end)
	describe("across yields", function()
		it("keeps a body that resumed after another mount began under its own owner", function()
			local world = Support.world()
			world.host.declareEvent("Frame", "Activated")

			local firstDispose: (() -> ())? = nil
			local lateNode: Compose.Node? = nil
			local suspended = coroutine.create(function()
				firstDispose = world.runtime.mount(function()
					local frame = world.create "Frame" {}
					coroutine.yield()
					local late = world.create "Frame" {}
					world.runtime.connect(late, "Activated", function() end)
					lateNode = late
					return frame
				end, world.root)
			end)

			coroutine.resume(suspended)
			local secondDispose = world.runtime.mount(function()
				return world.create "Frame" {}
			end, world.root)
			coroutine.resume(suspended)

			expect(Compose.outstandingMounts()):toBe(2)

			secondDispose()
			expect(world.host.isAlive(lateNode :: Compose.Node)):toBe(true)
			expect(world.host.liveSubscriptions()):toBe(1)

			local releaseFirst = firstDispose :: () -> ()
			releaseFirst()
			expect(world.host.isAlive(lateNode :: Compose.Node)):toBe(false)
			expectClean(world)
		end)

		it("disposes neither of two interleaved mounts when the other goes", function()
			local world = Support.world()
			world.host.declareEvent("Frame", "Activated")

			local pokes = { first = 0, second = 0 }
			local disposes: { [string]: () -> () } = {}
			local nodes: { [string]: Compose.Node } = {}

			local function mountLater(name: string): thread
				return coroutine.create(function()
					disposes[name] = world.runtime.mount(function()
						local frame = world.create "Frame" {}
						coroutine.yield()
						nodes[name] = world.create "Frame" {}
						world.runtime.connect(nodes[name], "Activated", function()
							pokes[name] += 1
						end)
						return frame
					end, world.root)
				end)
			end

			local first, second = mountLater "first", mountLater "second"
			coroutine.resume(first)
			coroutine.resume(second)
			coroutine.resume(first)
			coroutine.resume(second)

			expect(Compose.outstandingMounts()):toBe(2)

			disposes.first()
			world.host.dispatch(nodes.second, "Activated")
			expect(pokes.second):toBe(1)
			expect(pokes.first):toBe(0)
			expect(world.host.liveSubscriptions()):toBe(1)

			disposes.second()
			expectClean(world)
		end)

		it("inherits the owner of the body that resumed it", function()
			local world = Support.world()
			local inner: Compose.Node? = nil
			local dispose = world.runtime.mount(function()
				local nested = coroutine.create(function()
					inner = world.create "Frame" {}
				end)
				coroutine.resume(nested)
				return world.create "Frame" {}
			end, world.root)

			expect(world.host.isAlive(inner :: Compose.Node)):toBe(true)
			dispose()
			expect(world.host.isAlive(inner :: Compose.Node)):toBe(false)
			expectClean(world)
		end)

		it("still refuses a callback that runs on its own thread after the mount finished", function()
			local world = Support.world()
			world.host.declareEvent("Frame", "Activated")
			local external = world.host.makeNode "Frame"

			local dispose = world.runtime.mount(function()
				return world.create "Frame" {}
			end, world.root)

			local failure: unknown = nil
			local later = coroutine.create(function()
				local ok, err: any = pcall(world.runtime.connect, external, "Activated", function() end)
				failure = if ok then nil else err
			end)
			coroutine.resume(later)

			expect(tostring(failure)):toContain "owner/no-active-owner"
			dispose()
			expect(world.host.liveSubscriptions()):toBe(0)
			expect(Compose.outstandingMounts()):toBe(0)
		end)
	end)

	describe("bindOwner", function()
		it("re-enters the owner that created the callback", function()
			local world = Support.world()
			world.host.declareEvent("Frame", "Activated")
			local external = world.host.makeNode "Frame"

			local bound: ((Compose.Node) -> number)? = nil
			local firstDispose = world.runtime.mount(function()
				bound = Compose.bindOwner(function(node: Compose.Node): number
					world.runtime.connect(node, "Activated", function() end)
					return 7
				end)
				return world.create "Frame" {}
			end, world.root)

			local secondDispose = world.runtime.mount(function()
				return world.create "Frame" {}
			end, world.root)

			local answer: number? = nil
			local later = coroutine.create(function()
				answer = (bound :: (Compose.Node) -> number)(external)
			end)
			coroutine.resume(later)

			expect(answer):toBe(7)
			expect(world.host.liveSubscriptions()):toBe(1)

			secondDispose()
			expect(world.host.liveSubscriptions()):toBe(1)

			firstDispose()
			expect(world.host.liveSubscriptions()):toBe(0)
			expect(Compose.outstandingMounts()):toBe(0)
		end)

		it("refuses outside any owner, and refuses something that is not a function", function()
			Compose.__resetForTests()
			expect(function()
				Compose.bindOwner(function() end)
			end):toThrow "owner/no-active-owner"

			local owner = Compose.createOwner()
			expect(function()
				Compose.withOwner(owner, function()
					Compose.bindOwner(42 :: any)
				end)
			end):toThrow "owner/bind-body-not-a-function"
			owner.dispose()
		end)
	end)
end)

return nil
