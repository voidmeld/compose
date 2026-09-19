--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local TestScene = require "../../src/test-scene"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("named constructors", function()
	it("caches runtime constructors without allocating nodes", function()
		local world = Support.world()
		local Host = world.runtime.constructors
		expect(Host.Text == Host.Text):toBe(true)
		expect(Host.Text == Host.Panel):toBe(false)
		expect(world.host.liveNodes()):toBe(1)
		expect(function()
			Host.Text {}
		end):toThrow "owner/no-active-owner"
	end)

	it("binds constructor namespaces to separate hosts", function()
		local world = Support.world()
		local other = TestScene.create()
		local runtime = Compose.createRuntime(other.adapter)
		local first = world.runtime.constructors
		local second = runtime.constructors
		expect(first.Text == second.Text):toBe(false)
		local disposeFirst, nodeFirst = world.runtime.mount(function()
			return first.Text "First" { Value = 1 }
		end, world.root)
		local disposeSecond, nodeSecond = runtime.mount(function()
			return second.Text "Second" { Value = 2 }
		end, other.root)
		expect(world.host.childrenOf(world.root)):toEqual { nodeFirst }
		expect(other.childrenOf(other.root)):toEqual { nodeSecond }
		disposeFirst()
		expect(other.isAlive(nodeSecond)):toBe(true)
		disposeSecond()
		expect(world.host.liveNodes()):toBe(1)
		expect(other.liveNodes()):toBe(1)
	end)

	it("updates namespace-built nodes and disposes them once", function()
		local world = Support.world()
		local Host = world.runtime.constructors
		local value = Compose.cell(1)
		local dispose, node = world.runtime.mount(function()
			return Host.Text "Counter" { Value = value }
		end, world.root)
		value:set(2)
		world.settle()
		expect(world.host.propertyOf(node, "Value")):toBe(2)
		expect(Compose.labelOf(node)):toBe "Counter"
		world.host.resetCounts()
		dispose()
		dispose()
		expect(world.host.counts().destroyNode):toBe(1)
		expect(world.host.isAlive(world.root)):toBe(true)
	end)

	it("unwinds a failed namespace-built tree", function()
		local world = Support.world()
		local Host = world.runtime.constructors
		expect(function()
			world.runtime.mount(function()
				return Host.Panel {
					Host.Text "Good" {},
					Host.Text "Bad" { [Compose.event "Activated"] = 3 },
				}
			end, world.root)
		end):toThrow()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("builds the same node the anonymous form does", function()
		local world = Support.world()
		local Part = world.create "Part"

		local dispose, node = world.runtime.mount(function()
			return Part "Ground" { Anchored = true }
		end, world.root)

		expect(world.host.kindOf(node)):toBe "Part"
		expect(world.host.propertyOf(node, "Anchored")):toBe(true)
		dispose()
	end)

	it("records the label on the node", function()
		local world = Support.world()
		local Part = world.create "Part"

		local dispose, node = world.runtime.mount(function()
			return Part "Ground" {}
		end, world.root)

		expect(Compose.labelOf(node)):toBe "Ground"
		dispose()
	end)

	it("leaves an anonymous node with no label", function()
		local world = Support.world()
		local Part = world.create "Part"

		local dispose, node = world.runtime.mount(function()
			return Part {}
		end, world.root)

		expect(Compose.labelOf(node)):toBe(nil)
		dispose()
	end)

	it("projects the label into the host's own name", function()
		local world = Support.world()
		local Part = world.create "Part"

		local dispose, node = world.runtime.mount(function()
			return Part "Ground" {}
		end, world.root)

		expect(world.host.nameOf(node)):toBe "Ground"
		dispose()
	end)

	it("keeps the label on a host that cannot name nodes", function()
		local world = Support.world { namesNodes = false }
		local Part = world.create "Part"

		local dispose, node = world.runtime.mount(function()
			return Part "Ground" { Anchored = true }
		end, world.root)

		expect(Compose.labelOf(node)):toBe "Ground"
		expect(world.host.nameOf(node)):toBe(nil)
		expect(world.host.propertyOf(node, "Anchored")):toBe(true)
		dispose()
	end)

	it("lets an explicit Name property win the host property", function()
		local world = Support.world()
		local Part = world.create "Part"

		local dispose, node = world.runtime.mount(function()
			return Part "Ground" { Name = "Floor" }
		end, world.root)

		expect(Compose.labelOf(node)):toBe "Ground"
		expect(world.host.propertyOf(node, "Name")):toBe "Floor"
		dispose()
	end)

	it("is a label, not a key: duplicates are legal and order is unchanged", function()
		local world = Support.world()
		local Part = world.create "Part"
		local Model = world.create "Model"

		local dispose, root = world.runtime.mount(function()
			return Model {
				Part "Tree" {},
				Part "Tree" {},
				Part "Rock" {},
			}
		end, world.root)

		local children = world.host.childrenOf(root)
		expect(#children):toBe(3)
		expect(Compose.labelOf(children[1])):toBe "Tree"
		expect(Compose.labelOf(children[2])):toBe "Tree"
		expect(Compose.labelOf(children[3])):toBe "Rock"
		expect(children[1] == children[2]):toBe(false)
		dispose()
	end)

	it("reports the label in ownership inspection", function()
		local world = Support.world()
		local Part = world.create "Part"

		local dispose, node = world.runtime.mount(function()
			return Part "Ground" {}
		end, world.root)

		local report = Compose.inspect.node(node)
		expect(report.label):toBe "Ground"
		dispose()
	end)

	it("refuses props that are not a table, after a label", function()
		local world = Support.world()
		local Part = world.create "Part"
		expect(function()
			world.runtime.mount(function()
				return (Part "Ground" :: any)(3)
			end, world.root)
		end):toThrow "props/not-a-table"
	end)

	it("unwinds a failed build without leaving the node or its label behind", function()
		local world = Support.world()
		local Part = world.create "Part"
		local Model = world.create "Model"
		local escaped: any = nil

		local ok = pcall(function()
			world.runtime.mount(function()
				return Model {
					Part "Ground" {},
					Part "Broken" { [Compose.event "Activated"] = 3 },
				}
			end, world.root)
		end)

		expect(ok):toBe(false)
		expect(world.host.liveNodes()):toBe(1)
		expect(escaped):toBe(nil)
	end)

	it("drops the label when the node is destroyed", function()
		local world = Support.world()
		local Part = world.create "Part"

		local dispose, node = world.runtime.mount(function()
			return Part "Ground" {}
		end, world.root)
		dispose()

		expect(Compose.labelOf(node)):toBe(nil)
	end)

	it("refuses a constructor that was never given props", function()
		local world = Support.world()
		local Part = world.create "Part"
		local Model = world.create "Model"
		expect(function()
			world.runtime.mount(function()
				return Model {
					Part "Ground",
				}
			end, world.root)
		end):toThrow "mount/constructor-not-applied"
	end)

	it("leaves nothing behind when the host's naming raises", function()
		local world = Support.world()
		local Part = world.create "Part"

		local before = world.host.liveNodes()
		local escaped: any = nil
		world.host.failNext "setName"

		local ok = pcall(function()
			world.runtime.mount(function()
				local node = Part "Ground" {}
				escaped = node
				return node
			end, world.root)
		end)

		expect(ok):toBe(false)
		expect(world.host.liveNodes()):toBe(before)
		expect(escaped):toBe(nil)
	end)

	it("keeps no custody or label for a node whose naming raised", function()
		local world = Support.world()
		local Part = world.create "Part"
		local tracked = Compose.inspect.snapshot().trackedNodes

		world.host.failNext "setName"
		pcall(function()
			world.runtime.mount(function()
				return Part "Ground" {}
			end, world.root)
		end)

		expect(Compose.inspect.snapshot().trackedNodes):toBe(tracked)
	end)

	it("names a node built through the dynamic form", function()
		local world = Support.world()
		local kind = "Part"

		local dispose, node = world.runtime.mount(function()
			return world.create(kind) "Ground" { Anchored = true }
		end, world.root)

		expect(world.host.kindOf(node)):toBe "Part"
		expect(Compose.labelOf(node)):toBe "Ground"
		dispose()
	end)
end)

return nil
