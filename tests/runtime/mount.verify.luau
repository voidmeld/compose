--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("mounting", function()
	it("creates a node and puts it in the target", function()
		local world = Support.world()
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" { Title = "hello" }
		end, world.root)

		expect(world.host.kindOf(root)):toBe "Frame"
		expect(world.host.propertyOf(root, "Title")):toBe "hello"
		expect(world.host.childrenOf(world.root)):toEqual { root }
		expect(world.host.parentOf(root)):toBe(world.root)

		dispose()
		expect(world.host.isAlive(root)):toBe(false)
		expect(world.host.childrenOf(world.root)):toEqual {}
	end)

	it("never destroys the mount target", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {}
		end, world.root)
		dispose()
		expect(world.host.isAlive(world.root)):toBe(true)
		expect(Compose.custodyOf(world.root)):toBe "borrowed"
	end)

	it("binds a function property reactively and writes only what changed", function()
		local world = Support.world()
		local name = Compose.cell "first"
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Static = 7,
				Label = function(use)
					return use(name)
				end,
			}
		end, world.root)

		expect(world.host.propertyOf(root, "Label")):toBe "first"
		world.host.resetCounts()

		name:set "second"
		world.settle()
		expect(world.host.propertyOf(root, "Label")):toBe "second"
		expect(world.host.propertyOf(root, "Static")):toBe(7)
		expect(world.host.counts().setProperty):toBe(1)
		expect(world.host.counts().createNode):toBe(0)

		dispose()
	end)

	it("stops writing properties after disposal", function()
		local world = Support.world()
		local name = Compose.cell "first"
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {
				Label = function(use)
					return use(name)
				end,
			}
		end, world.root)

		dispose()
		world.host.resetCounts()
		name:set "second"
		world.settle()
		expect(world.host.counts().setProperty):toBe(0)
	end)

	it("subscribes to a wrapped event key on any host", function()
		local world = Support.world()
		local clicks = 0
		local dispose, root = world.runtime.mount(function()
			return world.create "Button" {
				[Compose.event "Activated"] = function()
					clicks += 1
				end,
			}
		end, world.root)

		expect(world.host.handlerCount(root, "Activated")):toBe(1)
		world.host.dispatch(root, "Activated")
		expect(clicks):toBe(1)

		dispose()
		expect(world.host.liveSubscriptions()):toBe(0)
	end)

	it("subscribes to a plain key the host classifies as an event", function()
		local world = Support.world()
		world.host.declareEvent("Button", "Activated")
		local clicks = 0
		local dispose, root = world.runtime.mount(function()
			return world.create "Button" {
				Activated = function()
					clicks += 1
				end,
			}
		end, world.root)

		world.host.dispatch(root, "Activated")
		expect(clicks):toBe(1)
		expect(world.host.propertyOf(root, "Activated")):toBeNil()
		dispose()
	end)

	it("writes a function value literally when it is wrapped in static", function()
		local world = Support.world()
		local handler = function() end
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" { OnRequest = Compose.static(handler) }
		end, world.root)

		expect(world.host.propertyOf(root, "OnRequest")):toBe(handler)
		dispose()
	end)

	it("nests children in source order", function()
		local world = Support.world()
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "Text" { Text = "a" },
				world.create "Text" { Text = "b" },
				world.create "Text" { Text = "c" },
			}
		end, world.root)

		local children = world.host.childrenOf(root)
		expect(children):toHaveLength(3)
		expect(world.host.propertyOf(children[1], "Text")):toBe "a"
		expect(world.host.propertyOf(children[3], "Text")):toBe "c"
		dispose()
	end)

	it("destroys the whole subtree exactly once", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "Text" {},
				world.create "Frame" {
					world.create "Text" {},
				},
			}
		end, world.root)

		expect(world.host.liveNodes()):toBe(5)
		dispose()
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
		expect(world.host.counts().destroyNode):toBe(4)
	end)

	it("mounts a fragment as siblings", function()
		local world = Support.world()
		local dispose, nodes = world.runtime.mountFragment(function()
			return {
				world.create "Text" { Text = "one" },
				world.create "Text" { Text = "two" },
			}
		end, world.root)

		expect(nodes):toHaveLength(2)
		expect(world.host.childrenOf(world.root)):toHaveLength(2)
		dispose()
		expect(world.host.childrenOf(world.root)):toEqual {}
	end)

	it("mounts structural directives beside static top-level siblings", function()
		local world = Support.world()
		local visible = Compose.cell(false)
		local summary: any
		local dispose, roots = world.runtime.mountFragment(function()
			summary = world.create "Summary" {}
			return {
				summary,
				Compose.show(visible, function()
					return world.create "Detail" {}
				end),
			}
		end, world.root)

		expect(roots):toEqual { summary }
		expect(world.host.serialize(world.root)):toContain "Summary"
		expect((string.find(world.host.serialize(world.root), "Detail", 1, true))):toBe(nil)
		visible:set(true)
		expect(world.host.serialize(world.root)):toContain "Detail"
		visible:set(false)
		expect((string.find(world.host.serialize(world.root), "Detail", 1, true))):toBe(nil)

		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("serializes to a stable string", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {
				Title = "outer",
				world.create "Text" { Text = "inner" },
			}
		end, world.root)

		expect(world.host.serialize(world.root)):toBe 'Root\n  Frame { Title="outer" }\n    Text { Text="inner" }'
		dispose()
	end)

	it("holds a top-level mount so its effects cannot be collected", function()
		local world = Support.world()
		expect(Compose.outstandingMounts()):toBe(0)
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {}
		end, world.root)
		expect(Compose.outstandingMounts()):toBe(1)
		dispose()
		expect(Compose.outstandingMounts()):toBe(0)
	end)

	it("owns a nested mount through its parent", function()
		local world = Support.world()
		local inner: Compose.Node
		local dispose = world.runtime.mount(function()
			local outer = world.create "Frame" {}
			local _, node = world.runtime.mount(function()
				return world.create "Text" {}
			end, outer)
			inner = node
			return outer
		end, world.root)

		expect(Compose.outstandingMounts()):toBe(1)
		expect(world.host.isAlive(inner)):toBe(true)
		dispose()
		expect(world.host.isAlive(inner)):toBe(false)
	end)

	it("disposes the top-level owner when a cleanup raises during stop", function()
		for _, useFragment in { false, true } do
			local world = Support.world()
			Compose.inspect.start()
			local stop = if useFragment
				then world.runtime.mountFragment(function()
					Compose.cleanup(function()
						error "cleanup failed"
					end)
					return { world.create "Frame" {} }
				end, world.root)
				else world.runtime.mount(function()
					Compose.cleanup(function()
						error "cleanup failed"
					end)
					return world.create "Frame" {}
				end, world.root)
			local ok, err: any = pcall(stop)
			local report = Compose.inspect.snapshot()
			Compose.inspect.stop()
			expect(ok):toBe(false)
			expect(tostring(err)):toContain "cleanup failed"
			expect(#report.mounts):toBe(1)
			expect(report.mounts[1].disposed):toBe(true)
			expect(Compose.outstandingMounts()):toBe(0)
		end
	end)

	describe("rejections", function()
		it("refuses a props table that is not a table", function()
			local world = Support.world()
			expect(function()
				world.runtime.mount(function()
					return (world.create "Frame" :: any)(3)
				end, world.root)
			end):toThrow "props/not-a-table"
		end)

		it("refuses a component that returns something that is not a node", function()
			local world = Support.world()
			expect(function()
				world.runtime.mount(function(): any
					return 42
				end, world.root)
			end):toThrow "mount/not-a-node"
		end)

		it("refuses a child that is neither a node nor a directive", function()
			local world = Support.world()
			expect(function()
				world.runtime.mount(function()
					return world.create "Frame" { 42 :: any }
				end, world.root)
			end):toThrow "mount/not-a-child"
		end)

		it("names the property that was being applied when a host raised", function()
			local world = Support.world()
			world.host.failNext "setProperty"
			local ok, err: any = pcall(function()
				world.runtime.mount(function()
					return world.create "Frame" { Colour = "red" }
				end, world.root)
			end)
			expect(ok):toBe(false)
			expect(tostring(err)):toContain "while applying: Frame.Colour"
		end)

		it("refuses mount and mountFragment after the runtime is disposed", function()
			local world = Support.world()
			world.runtime:dispose()
			local ran = false
			expect(function()
				world.runtime.mount(function()
					ran = true
					return world.create "Frame" {}
				end, world.root)
			end):toThrow "runtime/disposed"
			expect(function()
				world.runtime.mountFragment(function()
					ran = true
					return {}
				end, world.root)
			end):toThrow "runtime/disposed"
			expect(ran):toBe(false)
			expect(Compose.outstandingMounts()):toBe(0)
		end)

		it("refuses create outside a mount", function()
			local world = Support.world()
			expect(function()
				world.create "Frame" {}
			end):toThrow "owner/no-active-owner"
		end)
	end)
end)

return nil
