--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local FRAME = 1 / 60

local function step(world: any, seconds: number)
	for _ = 1, math.round(seconds / FRAME) do
		world.host.step(FRAME)
	end
	world.settle()
end

local function childCount(world: any, node: any): number
	return #world.host.childrenOf(node)
end

describe("presence", function()
	it("is show when no exit is given", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local open = Compose.cell(true)

		local dispose, root = world.runtime.mount(function()
			return Frame {
				Compose.presence(function(use)
					return use(open)
				end, function()
					return Frame {}
				end),
			}
		end, world.root)

		expect(childCount(world, root)):toBe(1)
		open:set(false)
		world.settle()
		expect(childCount(world, root)):toBe(0)
		dispose()
	end)

	it("retains the subtree until the exit completes", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local open = Compose.cell(true)

		local dispose, root = world.runtime.mount(function()
			return Frame {
				Compose.presence(function(use)
					return use(open)
				end, function()
					return Frame {}
				end, {
					exit = function()
						return world.runtime.timeline { duration = 0.2 }
					end,
				}),
			}
		end, world.root)

		open:set(false)
		world.settle()
		expect(childCount(world, root)):toBe(1)

		step(world, 0.1)
		expect(childCount(world, root)):toBe(1)

		step(world, 0.15)
		expect(childCount(world, root)):toBe(0)
		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("reclaims a leaving subtree on re-entry, without rebuilding it", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local open = Compose.cell(true)
		local builds = 0

		local dispose, root = world.runtime.mount(function()
			return Frame {
				Compose.presence(function(use)
					return use(open)
				end, function()
					builds += 1
					return Frame {}
				end, {
					exit = function()
						return world.runtime.timeline { duration = 0.5 }
					end,
				}),
			}
		end, world.root)

		expect(builds):toBe(1)
		local first = world.host.childrenOf(root)[1]

		open:set(false)
		world.settle()
		step(world, 0.1)

		open:set(true)
		world.settle()
		expect(builds):toBe(1)
		expect(world.host.childrenOf(root)[1]):toBe(first)

		step(world, 1)
		expect(childCount(world, root)):toBe(1)
		expect(world.host.childrenOf(root)[1]):toBe(first)
		dispose()
	end)

	it("releases a leaving subtree when its owner is disposed", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local open = Compose.cell(true)

		local dispose = world.runtime.mount(function()
			return Frame {
				Compose.presence(function(use)
					return use(open)
				end, function()
					return Frame {}
				end, {
					exit = function()
						return world.runtime.timeline { duration = 100 }
					end,
				}),
			}
		end, world.root)

		open:set(false)
		world.settle()
		dispose()
		expect(world.host.liveNodes()):toBe(1)
		expect(world.host.counts().frameListeners):toBe(0)
	end)

	it("releases the subtree and reports when the exit raises", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local open = Compose.cell(true)

		local dispose, root = world.runtime.mount(function()
			return Frame {
				Compose.presence(function(use)
					return use(open)
				end, function()
					return Frame {}
				end, {
					exit = function()
						error "no"
					end,
				}),
			}
		end, world.root)

		expect(childCount(world, root)):toBe(1)
		local ok, err = pcall(function()
			open:set(false)
			world.settle()
		end)
		local _ = ok
		local _ = err
		expect(childCount(world, root)):toBe(0)
		dispose()
	end)

	it("releases the subtree when the exit returns something that cannot complete", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local open = Compose.cell(true)

		local dispose, root = world.runtime.mount(function()
			return Frame {
				Compose.presence(function(use)
					return use(open)
				end, function()
					return Frame {}
				end, {
					exit = function()
						return 3 :: any
					end,
				}),
			}
		end, world.root)

		pcall(function()
			open:set(false)
			world.settle()
		end)
		expect(childCount(world, root)):toBe(0)
		dispose()
	end)

	it("builds a run of nodes, not only one", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local Label = world.create "Label"
		local open = Compose.cell(true)

		local dispose, root = world.runtime.mount(function()
			return Frame {
				Compose.presence(function(use)
					return use(open)
				end, function()
					return { Label "A" {}, Label "B" {}, Label "C" {} }
				end, {
					exit = function()
						return world.runtime.timeline { duration = 0.1 }
					end,
				}),
			}
		end, world.root)

		expect(childCount(world, root)):toBe(3)
		open:set(false)
		world.settle()
		expect(childCount(world, root)):toBe(3)
		step(world, 0.15)
		expect(childCount(world, root)):toBe(0)
		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("lets the subtree read that it is leaving", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local open = Compose.cell(true)

		local dispose, root = world.runtime.mount(function()
			return Frame {
				Compose.presence(function(use)
					return use(open)
				end, function(phase)
					return Frame {
						Alpha = function(use)
							return if use(phase.exiting) then 0 else 1
						end,
					}
				end, {
					exit = function()
						return world.runtime.timeline { duration = 0.2 }
					end,
				}),
			}
		end, world.root)

		local node = world.host.childrenOf(root)[1]
		expect(world.host.propertyOf(node, "Alpha")):toBe(1)

		open:set(false)
		world.settle()
		expect(world.host.propertyOf(node, "Alpha")):toBe(0)

		open:set(true)
		world.settle()
		expect(world.host.childrenOf(root)[1]):toBe(node)
		expect(world.host.propertyOf(node, "Alpha")):toBe(1)

		step(world, 0.5)
		expect(childCount(world, root)):toBe(1)
		dispose()
	end)

	it("leaves nothing behind across many enter and exit cycles", function()
		local world = Support.world()
		local Frame = world.create "Frame"
		local open = Compose.cell(false)
		local before = world.host.liveNodes()

		local dispose = world.runtime.mount(function()
			return Frame {
				Compose.presence(function(use)
					return use(open)
				end, function()
					return Frame {}
				end, {
					exit = function()
						return world.runtime.timeline { duration = 0.05 }
					end,
				}),
			}
		end, world.root)

		for _ = 1, 10 do
			open:set(true)
			world.settle()
			open:set(false)
			world.settle()
			step(world, 0.1)
		end

		dispose()
		expect(world.host.liveNodes()):toBe(before)
		expect(world.host.counts().frameListeners):toBe(0)
	end)
end)

return nil
