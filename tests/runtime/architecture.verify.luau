--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local function required<T>(value: T?): T
	assert(value ~= nil)
	return value
end

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("component architecture", function()
	it("gives each instance of a component its own state", function()
		local world = Support.world()
		local create, cell = world.create, Compose.cell
		local Frame = create "Frame"
		local Model = create "Model"

		local bumps: { () -> () } = {}

		local function Counter()
			local count = cell(0)
			local function bump()
				count:set(count:peek() + 1)
			end
			table.insert(bumps, bump)
			return Frame {
				Value = function(use)
					return use(count)
				end,
				OnBump = Compose.static(bump),
			}
		end

		local dispose, root = world.runtime.mount(function()
			return Model { Counter(), Counter() }
		end, world.root)

		local children = world.host.childrenOf(root)
		expect(world.host.propertyOf(children[1], "OnBump")):toBe(bumps[1])
		bumps[1]()
		world.settle()

		expect(world.host.propertyOf(children[1], "Value")):toBe(1)
		expect(world.host.propertyOf(children[2], "Value")):toBe(0)

		dispose()
	end)

	it("builds a constructor once and reuses it across invocations", function()
		local world = Support.world()
		local create = world.create
		local Frame = create "Frame"

		local seen: { unknown } = {}
		local function Leaf()
			table.insert(seen, Frame)
			return Frame {}
		end

		local dispose = world.runtime.mount(function()
			return (world.create "Model") { Leaf(), Leaf(), Leaf() }
		end, world.root)

		expect(#seen):toBe(3)
		expect(seen[1] == seen[2] and seen[2] == seen[3]):toBe(true)
		dispose()
	end)

	it("gives a component's nodes to the owner it was built under", function()
		local world = Support.world()
		local create = world.create
		local Frame = create "Frame"
		local Model = create "Model"

		local function Leaf()
			return Frame {}
		end

		local before = world.host.liveNodes()
		local dispose = world.runtime.mount(function()
			return Model { Leaf(), Leaf() }
		end, world.root)

		expect(world.host.liveNodes()):toBe(before + 3)
		dispose()
		expect(world.host.liveNodes()):toBe(before)
	end)

	it("does not give a self-mounted subtree to the tree that contains it", function()
		local world = Support.world()
		local create = world.create
		local Frame = create "Frame"
		local Model = create "Model"

		local nested: (() -> ())? = nil
		local dispose = world.runtime.mount(function()
			local shell = Model {}
			nested = world.runtime.mount(function()
				return Frame {}
			end, shell)
			return shell
		end, world.root)

		local before = world.host.liveNodes()
		expect(nested ~= nil):toBe(true)
		dispose()
		expect(world.host.liveNodes() < before):toBe(true);
		(required(nested))()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("releases every subscription a component made through the runtime", function()
		local world = Support.world()
		local create = world.create
		local Frame = create "Frame"

		world.host.declareEvent("Frame", "Activated")
		local function Listener()
			return Frame { [Compose.event "Activated"] = function() end }
		end

		local dispose, root = world.runtime.mount(Listener, world.root)
		expect(world.host.handlerCount(root, "Activated")):toBe(1)
		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)
end)

return nil
