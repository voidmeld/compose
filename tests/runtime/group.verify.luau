--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("grouped bindings", function()
	it("writes every declared property from one body", function()
		local world = Support.world()
		local pose = Compose.cell { x = 1, alpha = 0.5 }

		local dispose, node = world.runtime.mount(function()
			return world.create "Part" {
				[Compose.group { "Position", "Transparency" }] = function(use)
					local p = use(pose)
					return p.x, p.alpha
				end,
			}
		end, world.root)

		expect(world.host.propertyOf(node, "Position")):toBe(1)
		expect(world.host.propertyOf(node, "Transparency")):toBe(0.5)

		pose:set { x = 7, alpha = 0.25 }
		world.settle()
		expect(world.host.propertyOf(node, "Position")):toBe(7)
		expect(world.host.propertyOf(node, "Transparency")):toBe(0.25)

		dispose()
	end)

	it("runs one body however many properties it writes", function()
		local world = Support.world()
		local pose = Compose.cell(1)

		local groupedRuns = 0
		local grouped = world.runtime.mount(function()
			return world.create "Part" {
				[Compose.group { "A", "B", "C", "D" }] = function(use)
					groupedRuns += 1
					local value = use(pose)
					return value, value, value, value
				end,
			}
		end, world.root)
		groupedRuns = 0
		pose:set(2)
		world.settle()
		expect(groupedRuns):toBe(1)
		grouped()

		local separateRuns = 0
		local function count(use: Compose.Use): number
			separateRuns += 1
			return use(pose)
		end
		local separate = world.runtime.mount(function()
			return world.create "Part" { A = count, B = count, C = count, D = count }
		end, world.root)
		separateRuns = 0
		pose:set(3)
		world.settle()
		expect(separateRuns):toBe(4)
		separate()
	end)

	it("writes a property only when its own value changed", function()
		local world = Support.world()
		local pose = Compose.cell { x = 1, alpha = 0.5 }

		local dispose, node = world.runtime.mount(function()
			return world.create "Part" {
				[Compose.group { "Position", "Transparency" }] = function(use)
					local p = use(pose)
					return p.x, p.alpha
				end,
			}
		end, world.root)

		world.host.resetCounts()
		pose:set { x = 9, alpha = 0.5 }
		world.settle()

		expect(world.host.propertyOf(node, "Position")):toBe(9)
		expect(world.host.counts().setProperty):toBe(1)

		dispose()
	end)

	it("leaves the node untouched when the body raises", function()
		local world = Support.world()
		local pose = Compose.cell(1)

		local ok = pcall(function()
			local dispose = world.runtime.mount(function()
				return world.create "Part" {
					[Compose.group { "Position", "Transparency" }] = function(use)
						local value = use(pose)
						if value > 1 then
							error "no"
						end
						return value, 0
					end,
				}
			end, world.root)
			return dispose
		end)
		expect(ok):toBe(true)
	end)

	it("refuses a body that returns the wrong number of values", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				return world.create "Part" {
					[Compose.group { "Position", "Transparency" }] = function()
						return 1
					end,
				}
			end, world.root)
		end):toThrow "props/group-arity"
	end)

	it("refuses something that is not a body", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				return world.create "Part" {
					[Compose.group { "Position" }] = 3,
				}
			end, world.root)
		end):toThrow "props/group-needs-a-body"
	end)

	it("refuses an empty name list", function()
		expect(function()
			Compose.group {}
		end):toThrow "at least one property name"
	end)

	it("clears exactly its declared names from a borrowed node", function()
		local world = Support.world()
		local external = world.host.makeNode "External"
		local pose = Compose.cell(4)

		local dispose = world.runtime.mount(function()
			local frame = world.create "Frame" {}
			world.runtime.decorate(external, {
				[Compose.group { "Position", "Transparency" }] = function(use)
					return use(pose), 0.5
				end,
			})
			return frame
		end, world.root)

		expect(world.host.propertyOf(external, "Position")):toBe(4)
		dispose()
		expect(world.host.isAlive(external)):toBe(true)
		expect(world.host.propertyOf(external, "Position")):toBe(nil)
		expect(world.host.propertyOf(external, "Transparency")):toBe(nil)
	end)

	it("writes an initial nil, exactly as a fine-grained binding does", function()
		local world = Support.world()
		local pose = Compose.cell { a = nil :: any, b = 1 }

		local grouped, groupedNode = world.runtime.mount(function()
			return world.create "Part" {
				[Compose.group { "A", "B" }] = function(use)
					local p = use(pose)
					return p.a, p.b
				end,
			}
		end, world.root)
		local separate, separateNode = world.runtime.mount(function()
			return world.create "Part" {
				A = function(use)
					return use(pose).a
				end,
				B = function(use)
					return use(pose).b
				end,
			}
		end, world.root)

		expect(world.host.propertyOf(groupedNode, "A")):toBe(world.host.propertyOf(separateNode, "A"))
		expect(world.host.propertyOf(groupedNode, "B")):toBe(1)

		grouped()
		separate()
	end)

	it("reaches the host on the first run even when the value is nil", function()
		local world = Support.world()
		local pose = Compose.cell { a = nil :: any, b = 1 }

		world.host.resetCounts()
		local grouped = world.runtime.mount(function()
			return world.create "Part" {
				[Compose.group { "A", "B" }] = function(use)
					local p = use(pose)
					return p.a, p.b
				end,
			}
		end, world.root)
		local groupedWrites = world.host.counts().setProperty
		grouped()

		world.host.resetCounts()
		local separate = world.runtime.mount(function()
			return world.create "Part" {
				A = function(use)
					return use(pose).a
				end,
				B = function(use)
					return use(pose).b
				end,
			}
		end, world.root)
		local separateWrites = world.host.counts().setProperty
		separate()

		expect(groupedWrites):toBe(separateWrites)
	end)

	it("writes a change from a value to nil", function()
		local world = Support.world()
		local pose = Compose.cell { a = 5 :: any }

		local dispose, node = world.runtime.mount(function()
			return world.create "Part" {
				[Compose.group { "A", "B" }] = function(use)
					return use(pose).a, 0
				end,
			}
		end, world.root)
		expect(world.host.propertyOf(node, "A")):toBe(5)

		pose:set { a = nil :: any }
		world.settle()
		expect(world.host.propertyOf(node, "A")):toBe(nil)

		pose:set { a = 7 :: any }
		world.settle()
		expect(world.host.propertyOf(node, "A")):toBe(7)

		dispose()
	end)

	it("handles several nil positions at once", function()
		local world = Support.world()
		local source = Compose.cell(false)

		local dispose, node = world.runtime.mount(function()
			return world.create "Part" {
				[Compose.group { "A", "B", "C" }] = function(use)
					if use(source) then
						return 1 :: number?, 2 :: number?, 3 :: number?
					end
					return nil :: number?, nil :: number?, nil :: number?
				end,
			}
		end, world.root)

		expect(world.host.propertyOf(node, "A")):toBe(nil)
		expect(world.host.propertyOf(node, "C")):toBe(nil)

		source:set(true)
		world.settle()
		expect(world.host.propertyOf(node, "A")):toBe(1)
		expect(world.host.propertyOf(node, "C")):toBe(3)

		source:set(false)
		world.settle()
		expect(world.host.propertyOf(node, "B")):toBe(nil)

		dispose()
	end)

	it("unwinds without leaving the node behind when a host write raises", function()
		local world = Support.world()
		local pose = Compose.cell(1)
		local before = world.host.liveNodes()

		world.host.failNext("setProperty", 1)
		local ok = pcall(function()
			world.runtime.mount(function()
				return world.create "Part" {
					[Compose.group { "A", "B" }] = function(use)
						return use(pose), 0
					end,
				}
			end, world.root)
		end)

		expect(ok):toBe(false)
		expect(world.host.liveNodes()):toBe(before)
	end)

	it("releases its watch exactly once with its owner", function()
		local world = Support.world()
		local pose = Compose.cell(1)

		local dispose = world.runtime.mount(function()
			return world.create "Part" {
				[Compose.group { "Position" }] = function(use)
					return use(pose)
				end,
			}
		end, world.root)

		dispose()
		pose:set(2)
		world.settle()
		expect(world.pending()):toBe(0)
	end)
end)

return nil
