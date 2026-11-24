--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("mapped bindings", function()
	it("retains mapped attribute failure recovery, replacement and borrowed cleanup", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(function()
			Compose.owner.dispose(owner)
		end)
		local source = Compose.cell(1)
		local replacement = Compose.cell(10)
		local borrowed = world.host.makeNode "Frame"
		Compose.withOwner(owner, function()
			world.runtime.borrow(borrowed)
			world.runtime.decorate(borrowed, {
				Attributes = {
					Value = Compose.map(source, function(value: number): number
						if value == 2 then
							error("mapped attribute rejected", 0)
						end
						return value * 2
					end),
				},
			})
		end)
		expect(world.host.attributeOf(borrowed, "Value")):toBe(2)
		local ok, failure = pcall(function()
			source:set(2)
			world.settle()
		end)
		expect(ok):toBe(false)
		expect(tostring(failure)):toContain "mapped attribute rejected"
		expect(world.host.attributeOf(borrowed, "Value")):toBe(2)
		source:set(3)
		world.settle()
		expect(world.host.attributeOf(borrowed, "Value")):toBe(6)
		Compose.withOwner(owner, function()
			world.runtime.decorate(borrowed, { Attributes = { Value = Compose.map(replacement, tostring) } })
		end)
		source:set(4)
		replacement:set(11)
		world.settle()
		expect(world.host.attributeOf(borrowed, "Value")):toBe "11"
		Compose.owner.dispose(owner)
		expect(world.host.attributeOf(borrowed, "Value")):toBe(nil)
	end)

	it("retires each fast property replaced by a group under guarded and ordinary owners", function(own)
		for _, guarded in { false, true } do
			local world = Support.world()
			local owner = Compose.createOwner(world.runtime.reactor)
			own(function()
				Compose.owner.dispose(owner)
			end)
			if guarded then
				Compose.owner.guardWith(owner, {
					report = function(failure)
						error(failure, 0)
					end,
				})
			end
			local old = Compose.cell(1)
			local replacement = Compose.cell(10)
			local node = Compose.withOwner(owner, function()
				local created = world.create "Frame" {
					X = old,
					Y = function(use: Compose.Use)
						return use(old) * 2
					end,
					Z = old,
				}
				world.runtime.decorate(created, {
					[Compose.group { "X", "Y" }] = function(use: Compose.Use)
						local current = use(replacement)
						return current, current * 3
					end,
				})
				return created
			end)
			old:set(2)
			world.settle()
			expect(world.host.propertyOf(node, "X")):toBe(10)
			expect(world.host.propertyOf(node, "Y")):toBe(30)
			expect(world.host.propertyOf(node, "Z")):toBe(2)
			replacement:set(11)
			world.settle()
			expect(world.host.propertyOf(node, "X")):toBe(11)
			expect(world.host.propertyOf(node, "Y")):toBe(33)
			Compose.owner.dispose(owner)
			world.host.resetCounts()
			old:set(3)
			replacement:set(12)
			world.settle()
			expect(world.host.counts().setProperty):toBe(0)
		end
	end)

	it("retires guarded bindings when a property is decorated again", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(function()
			Compose.owner.dispose(owner)
		end)
		local reports = 0
		Compose.owner.guardWith(owner, {
			report = function()
				reports += 1
			end,
		})
		local old = Compose.cell(1)
		local replacement = Compose.cell(10)
		local node = Compose.withOwner(owner, function()
			local created = world.create "Frame" { X = old }
			world.runtime.decorate(created, { X = replacement })
			return created
		end)
		world.host.resetCounts()
		old:set(2)
		world.settle()
		expect(world.host.counts().setProperty):toBe(0)
		replacement:set(11)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(11)
		world.host.failNext("setProperty", 1)
		replacement:set(12)
		world.settle()
		expect(reports):toBe(1)
		Compose.owner.dispose(owner)
		replacement:set(13)
		world.settle()
		expect(reports):toBe(1)
	end)

	it("unwinds guarded property failures and retries every binding form", function(own)
		for _, form in { "cell", "formula", "map", "function" } do
			local world = Support.world()
			local value = Compose.cell(1)
			local function read(use: Compose.Use): number
				local current = use(value)
				if current == 2 then
					error "guarded property failure"
				end
				return current
			end
			local source: unknown = value
			if form == "formula" then
				source = Compose.formula(read)
			elseif form == "map" then
				source = Compose.map(value, function(current: number): number
					if current == 2 then
						error "guarded property failure"
					end
					return current
				end)
			elseif form == "function" then
				source = read
			end
			local retry: () -> () = function() end
			local reports = 0
			local dispose, root = world.runtime.mount(function()
				return world.create "Frame" {
					Compose.boundary(function()
						return world.create "TextLabel" { X = source }
					end, function(_, again)
						reports += 1
						retry = again
						return world.create "Fallback" {}
					end),
				}
			end, world.root)
			own(dispose)
			for attempt = 1, 3 do
				if form == "cell" then
					world.host.failNext("setProperty", 1)
				end
				value:set(2)
				world.settle()
				expect(reports):toBe(attempt)
				expect(world.host.kindOf(world.host.childrenOf(root)[1])):toBe "Fallback"
				value:set(3)
				retry()
				world.settle()
				local node = world.host.childrenOf(root)[1]
				expect(world.host.kindOf(node)):toBe "TextLabel"
				expect(world.host.propertyOf(node, "X")):toBe(3)
			end
			dispose()
			value:set(4)
			world.settle()
			expect(world.host.leaked()):toEqual { "Root#1" }
		end
	end)

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
