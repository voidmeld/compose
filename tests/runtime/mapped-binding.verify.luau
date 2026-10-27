--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("mapped bindings", function()
	it("writes the transformed source on mount and on each change", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(function()
			Compose.owner.dispose(owner)
		end)
		local index = Compose.cell(3)
		local runs = 0
		local node = Compose.withOwner(owner, function()
			return world.create "Frame" {
				X = Compose.map(index, function(at: number): number
					runs += 1
					return at * 10
				end),
			}
		end)
		expect(world.host.propertyOf(node, "X")):toBe(30)
		index:set(4)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(40)
		index:set(4)
		world.settle()
		expect(runs):toBe(2)
	end)

	it("follows a formula source and stops writing after disposal", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(function()
			Compose.owner.dispose(owner)
		end)
		local base = Compose.cell(1)
		local doubled = Compose.formula(function(use: Compose.Use): number
			return use(base) * 2
		end)
		local calls = 0
		local node = Compose.withOwner(owner, function()
			return world.create "Frame" {
				X = Compose.map(doubled, function(value: number): number
					calls += 1
					return value + 1
				end),
			}
		end)
		expect(world.host.propertyOf(node, "X")):toBe(3)
		base:set(5)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(11)
		Compose.owner.dispose(owner)
		base:set(9)
		world.settle()
		expect(calls):toBe(2)
	end)

	it("is an ordinary reactive body wherever a function is accepted", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(function()
			Compose.owner.dispose(owner)
		end)
		local count = Compose.cell(2)
		local label = Compose.map(count, function(value: number): string
			return `{value} items`
		end)
		local text = Compose.formula(label)
		expect(text:peek()):toBe "2 items"
		local node = Compose.withOwner(owner, function()
			local created = world.create "Frame" {}
			world.runtime.decorate(created, { Name = label })
			return created
		end)
		count:set(5)
		world.settle()
		expect(text:peek()):toBe "5 items"
		expect(world.host.propertyOf(node, "Name")):toBe "5 items"
	end)
end)

return nil
