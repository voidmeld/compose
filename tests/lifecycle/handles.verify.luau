--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("lifetime handles", function()
	it("hands back a function from every path that returns a handle", function()
		local world = Support.world()
		world.host.declareEvent("Frame", "Activated")

		local stopWatch: () -> (), disconnect: () -> ()
		local dispose = world.runtime.mount(function()
			local frame = world.create "Frame" {}
			stopWatch = world.runtime:watch(function() end)
			disconnect = world.runtime.connect(frame, "Activated", function() end)
			return frame
		end, world.root)

		expect(typeof(dispose)):toBe "function"
		expect(typeof(stopWatch)):toBe "function"
		expect(typeof(disconnect)):toBe "function"

		local resource = Compose.createSharedResource(function()
			return 1, nil
		end)
		local _value, release = resource.detached()
		expect(typeof(release)):toBe "function"

		release()
		disconnect()
		stopWatch()
		dispose()
	end)

	it("is safe to call twice, every one of them", function()
		local world = Support.world()
		world.host.declareEvent("Frame", "Activated")
		local torn = 0

		local disconnect: () -> (), stopWatch: () -> ()
		local dispose = world.runtime.mount(function()
			Compose.cleanup(function()
				torn += 1
			end)
			local frame = world.create "Frame" {}
			disconnect = world.runtime.connect(frame, "Activated", function() end)
			stopWatch = world.runtime:watch(function() end)
			return frame
		end, world.root)
		local resource = Compose.createSharedResource(function()
			return 1, function()
				torn += 1
			end
		end)
		local _value, release = resource.detached()

		for _ = 1, 3 do
			disconnect()
			stopWatch()
			release()
		end
		dispose()
		dispose()

		expect(torn):toBe(2)
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("does nothing when called after its owner already released it", function()
		local world = Support.world()
		world.host.declareEvent("Frame", "Activated")
		local fired = 0

		local disconnect: () -> ()
		local dispose = world.runtime.mount(function()
			local frame = world.create "Frame" {}
			disconnect = world.runtime.connect(frame, "Activated", function()
				fired += 1
			end)
			return frame
		end, world.root)

		dispose()
		local ok = pcall(disconnect)
		expect(ok):toBe(true)
		expect(fired):toBe(0)
	end)

	it("releases what a partially constructed subtree already took", function()
		local world = Support.world()
		local torn = 0
		local before = world.host.liveNodes()

		local resource = Compose.createSharedResource(function()
			return 1, function()
				torn += 1
			end
		end)

		local ok = pcall(function()
			world.runtime.mount(function()
				resource()
				Compose.cleanup(function()
					torn += 1
				end)
				local Frame = world.create "Frame"
				local node = Frame {}
				local _ = node
				error "the component failed after taking things"
			end, world.root)
		end)

		expect(ok):toBe(false)
		expect(torn):toBe(2)
		expect(world.host.liveNodes()):toBe(before)
	end)

	it("releases a connection exactly once when the subtree goes", function()
		local world = Support.world()
		world.host.declareEvent("Frame", "Activated")
		local fired = 0

		local dispose, node = world.runtime.mount(function()
			local frame = world.create "Frame" {}
			world.runtime.connect(frame, "Activated", function()
				fired += 1
			end)
			return frame
		end, world.root)

		world.host.dispatch(node, "Activated")
		expect(fired):toBe(1)

		dispose()
		expect(world.host.isAlive(node)):toBe(false)
		expect(world.host.liveNodes()):toBe(1)
	end)
end)

return nil
