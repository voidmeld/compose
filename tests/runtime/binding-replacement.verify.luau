--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("binding replacement", function()
	it("replaces attributes independently from properties with the same name", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local property = Compose.cell(12)
		local attribute = Compose.cell(12)
		local other = Compose.cell(3)
		local replacement = Compose.cell(12)
		local node = Compose.withOwner(owner, function()
			local created = world.create "Frame" {
				X = property,
				Attributes = { X = attribute, Other = other },
			}
			world.runtime.decorate(created, { Attributes = { X = 12 } })
			return created
		end)

		attribute:set(100)
		property:set(20)
		other:set(8)
		world.settle()
		expect(world.host.attributeOf(node, "X")):toBe(12)
		expect(world.host.propertyOf(node, "X")):toBe(20)
		expect(world.host.attributeOf(node, "Other")):toBe(8)
		Compose.withOwner(owner, function()
			world.runtime.decorate(node, { Attributes = { X = replacement } })
		end)
		replacement:set(21)
		attribute:set(200)
		world.settle()
		expect(world.host.attributeOf(node, "X")):toBe(21)
		expect(world.host.propertyOf(node, "X")):toBe(20)
	end)

	it("replaces an equal literal without disturbing other bindings, children, or events", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local x = Compose.cell(12)
		local y = Compose.cell(3)
		local clicks = 0
		local node = Compose.withOwner(owner, function()
			local props: Compose.Props = {
				X = x,
				Y = y,
				[Compose.event "Activated"] = function()
					clicks += 1
				end,
				world.create "Text" { Text = "child" },
			}
			return world.create "Frame"(props)
		end)
		local child = world.host.childrenOf(node)[1]
		Compose.withOwner(owner, function()
			world.runtime.decorate(node, { X = 12 })
		end)

		x:set(100)
		y:set(8)
		world.settle()
		world.host.dispatch(node, "Activated")
		expect(world.host.propertyOf(node, "X")):toBe(12)
		expect(world.host.propertyOf(node, "Y")):toBe(8)
		expect(world.host.childrenOf(node)):toEqual { child }
		expect(world.host.isAlive(child)):toBe(true)
		expect(world.host.handlerCount(node, "Activated")):toBe(1)
		expect(clicks):toBe(1)
	end)

	it("replaces a cell with an equal-valued cell and detaches the old source", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local old = Compose.cell(12)
		local replacement = Compose.cell(12)
		local node = Compose.withOwner(owner, function()
			local created = world.create "Frame" { X = old }
			world.runtime.decorate(created, { X = replacement })
			return created
		end)

		world.host.resetCounts()
		old:set(100)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(12)
		expect(world.host.counts().setProperty):toBe(0)
		replacement:set(21)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(21)
		expect(world.host.counts().setProperty):toBe(1)
	end)

	it("replaces a reactive body and stops evaluating its old dependencies", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local old = Compose.cell(6)
		local replacement = Compose.cell(4)
		local oldRuns = 0
		local node = Compose.withOwner(owner, function()
			local created = world.create "Frame" {
				X = function(use: Compose.Use)
					oldRuns += 1
					return use(old) * 2
				end,
			}
			world.runtime.decorate(created, {
				X = function(use: Compose.Use)
					return use(replacement) * 3
				end,
			})
			return created
		end)
		local runsBefore = oldRuns

		old:set(100)
		world.settle()
		expect(oldRuns):toBe(runsBefore)
		expect(world.host.propertyOf(node, "X")):toBe(12)
		replacement:set(7)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(21)
	end)

	it("preserves the newer borrowed binding when its former owner disposes", function(own)
		local world = Support.world()
		local first = Compose.createOwner(world.runtime.reactor)
		local second = Compose.createOwner(world.runtime.reactor)
		own(first.dispose)
		own(second.dispose)
		local external = world.host.makeNode "External"
		local old = Compose.cell(12)
		local replacement = Compose.cell(12)
		Compose.withOwner(first, function()
			world.runtime.decorate(external, { X = old, FirstOnly = 7 })
		end)
		Compose.withOwner(second, function()
			world.runtime.decorate(external, { X = replacement })
		end)

		first.dispose()
		expect(world.host.isAlive(external)):toBe(true)
		expect(world.host.propertyOf(external, "FirstOnly")):toBeNil()
		expect(world.host.propertyOf(external, "X")):toBe(12)
		old:set(100)
		replacement:set(21)
		world.settle()
		expect(world.host.propertyOf(external, "X")):toBe(21)
		second.dispose()
		expect(world.host.propertyOf(external, "X")):toBeNil()
	end)

	it("does not resurrect a replaced borrowed binding when the newer owner disposes first", function(own)
		local world = Support.world()
		local first = Compose.createOwner(world.runtime.reactor)
		local second = Compose.createOwner(world.runtime.reactor)
		own(first.dispose)
		own(second.dispose)
		local external = world.host.makeNode "External"
		local old = Compose.cell(12)
		Compose.withOwner(first, function()
			world.runtime.decorate(external, { X = old })
		end)
		Compose.withOwner(second, function()
			world.runtime.decorate(external, { X = 12 })
		end)

		second.dispose()
		expect(world.host.propertyOf(external, "X")):toBeNil()
		world.host.resetCounts()
		old:set(100)
		world.settle()
		expect(world.host.propertyOf(external, "X")):toBeNil()
		expect(world.host.counts().setProperty):toBe(0)
		first.dispose()
		expect(world.host.counts().clearProperty):toBe(0)
		expect(world.host.isAlive(external)):toBe(true)
	end)

	it("keeps an unreplaced group member reactive until the last member is replaced", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local source = Compose.cell(12)
		local runs = 0
		local node = Compose.withOwner(owner, function()
			local created = world.create "Frame" {
				[Compose.group { "X", "Y" }] = function(use: Compose.Use)
					runs += 1
					local value = use(source)
					return value, value * 2
				end,
			}
			world.runtime.decorate(created, { X = 12 })
			return created
		end)

		source:set(20)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(12)
		expect(world.host.propertyOf(node, "Y")):toBe(40)
		Compose.withOwner(owner, function()
			world.runtime.decorate(node, { Y = 40 })
		end)
		local runsBefore = runs
		world.host.resetCounts()
		source:set(30)
		world.settle()
		expect(runs):toBe(runsBefore)
		expect(world.host.counts().setProperty):toBe(0)
	end)

	it("replaces overlapping group properties without taking unrelated members", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local old = Compose.cell(2)
		local replacement = Compose.cell(2)
		local node = Compose.withOwner(owner, function()
			local created = world.create "Frame" {
				[Compose.group { "X", "Y" }] = function(use: Compose.Use)
					local value = use(old)
					return value, value * 2
				end,
			}
			world.runtime.decorate(created, {
				[Compose.group { "X", "Z" }] = function(use: Compose.Use)
					local value = use(replacement)
					return value, value * 3
				end,
			})
			return created
		end)

		old:set(5)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(2)
		expect(world.host.propertyOf(node, "Y")):toBe(10)
		expect(world.host.propertyOf(node, "Z")):toBe(6)
		replacement:set(7)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(7)
		expect(world.host.propertyOf(node, "Y")):toBe(10)
		expect(world.host.propertyOf(node, "Z")):toBe(21)
	end)

	it("keeps the old binding usable when the first replacement write refuses", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local external = world.host.makeNode "External"
		local old = Compose.cell(12)
		local replacement = Compose.cell(30)
		Compose.withOwner(owner, function()
			world.runtime.decorate(external, { X = old })
		end)
		world.host.failNext("setProperty", 1)
		local accepted = pcall(function()
			Compose.withOwner(owner, function()
				world.runtime.decorate(external, { X = replacement })
			end)
		end)

		expect(accepted):toBe(false)
		expect(world.host.propertyOf(external, "X")):toBe(12)
		replacement:set(100)
		world.settle()
		expect(world.host.propertyOf(external, "X")):toBe(12)
		old:set(21)
		world.settle()
		expect(world.host.propertyOf(external, "X")):toBe(21)
	end)
	it("keeps a reentrant replacement after the outer first host write returns", function(own)
		local world = Support.world()
		local outer = Compose.createOwner(world.runtime.reactor)
		local inner = Compose.createOwner(world.runtime.reactor)
		own(outer.dispose)
		own(inner.dispose)
		local external = world.host.makeNode "External"
		local source = Compose.cell(1)
		local runs = 0
		local fired = false
		local write = world.host.adapter.render.setProperty
		world.host.adapter.render.setProperty = function(node, key, value)
			write(node, key, value)
			if not fired then
				fired = true
				Compose.withOwner(inner, function()
					world.runtime.decorate(external, { X = 20 })
				end)
			end
		end
		Compose.withOwner(outer, function()
			world.runtime.decorate(external, {
				X = function(use: Compose.Use)
					runs += 1
					return use(source)
				end,
			})
		end)
		source:set(2)
		world.settle()
		expect(runs):toBe(1)
		expect(world.host.propertyOf(external, "X")):toBe(20)
		outer.dispose()
		expect(world.host.propertyOf(external, "X")):toBe(20)
	end)

	it("retires a group replaced reentrantly before its watch registration completes", function(own)
		local world = Support.world()
		local outer = Compose.createOwner(world.runtime.reactor)
		local inner = Compose.createOwner(world.runtime.reactor)
		own(outer.dispose)
		own(inner.dispose)
		local external = world.host.makeNode "External"
		local source = Compose.cell(1)
		local runs = 0
		local fired = false
		local write = world.host.adapter.render.setProperty
		world.host.adapter.render.setProperty = function(node, key, value)
			write(node, key, value)
			if not fired and key == "X" then
				fired = true
				Compose.withOwner(inner, function()
					world.runtime.decorate(external, { X = 20, Y = 30 })
				end)
			end
		end
		Compose.withOwner(outer, function()
			world.runtime.decorate(external, {
				[Compose.group { "X", "Y" }] = function(use: Compose.Use)
					runs += 1
					local value = use(source)
					return value, value * 2
				end,
			})
		end)
		source:set(2)
		world.settle()
		expect(runs):toBe(1)
		expect(world.host.propertyOf(external, "X")):toBe(20)
		expect(world.host.propertyOf(external, "Y")):toBe(30)
		outer.dispose()
		expect(world.host.propertyOf(external, "X")):toBe(20)
		expect(world.host.propertyOf(external, "Y")):toBe(30)
	end)

	it("releases a group when its owner disposes inside its first host write", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local external = world.host.makeNode "External"
		local source = Compose.cell(1)
		local runs = 0
		local write = world.host.adapter.render.setProperty
		world.host.adapter.render.setProperty = function(node, key, value)
			write(node, key, value)
			owner.dispose()
		end
		Compose.withOwner(owner, function()
			world.runtime.decorate(external, {
				[Compose.group { "X", "Y" }] = function(use: Compose.Use)
					runs += 1
					local value = use(source)
					return value, value * 2
				end,
			})
		end)
		source:set(2)
		world.settle()
		expect(runs):toBe(1)
		expect(world.host.propertyOf(external, "X")):toBeNil()
		expect(world.host.propertyOf(external, "Y")):toBeNil()
	end)

	it("detaches failed first-write function and group dependencies", function(own)
		for _, grouped in { false, true } do
			local world = Support.world()
			local owner = Compose.createOwner(world.runtime.reactor)
			own(owner.dispose)
			local external = world.host.makeNode "External"
			local old = Compose.cell(12)
			local replacement = Compose.cell(30)
			local runs = 0
			Compose.withOwner(owner, function()
				world.runtime.decorate(external, { X = old })
			end)
			local props: Compose.Props = {}
			props[if grouped then Compose.group { "X", "Y" } else "X"] = function(use: Compose.Use): (number, number?)
				runs += 1
				local value = use(replacement)
				if grouped then
					return value, value * 2
				end
				return value, nil
			end
			world.host.failNext("setProperty", 1)
			local accepted = pcall(function()
				Compose.withOwner(owner, function()
					world.runtime.decorate(external, props)
				end)
			end)
			expect(accepted):toBe(false)
			replacement:set(100)
			world.settle()
			expect(runs):toBe(1)
			expect(world.host.propertyOf(external, "X")):toBe(12)
			old:set(21)
			world.settle()
			expect(world.host.propertyOf(external, "X")):toBe(21)
		end
	end)
	it("does not overwrite a replacement created while an older source evaluates", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local external = world.host.makeNode "External"
		local source = Compose.cell(1)
		local runs = 0
		Compose.withOwner(owner, function()
			world.runtime.decorate(external, {
				X = function(use: Compose.Use)
					runs += 1
					local value = use(source)
					if value == 2 then
						Compose.withOwner(owner, function()
							world.runtime.decorate(external, { X = 20 })
						end)
					end
					return value
				end,
			})
		end)
		source:set(2)
		world.settle()
		expect(world.host.propertyOf(external, "X")):toBe(20)
		source:set(3)
		world.settle()
		expect(runs):toBe(2)
		expect(world.host.propertyOf(external, "X")):toBe(20)
	end)

	it("keeps the current registry when a host callback replaces an emptied registry", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(owner.dispose)
		local node = Compose.withOwner(owner, function()
			return world.create "Frame" {}
		end)
		local outer = Compose.cell(1)
		local inner = Compose.cell(20)
		local fired = false
		local write = world.host.adapter.render.setProperty
		world.host.adapter.render.setProperty = function(target, key, value)
			write(target, key, value)
			if not fired then
				fired = true
				Compose.withOwner(owner, function()
					world.runtime.decorate(node, { X = 10 })
					world.runtime.decorate(node, { X = inner })
				end)
			end
		end
		Compose.withOwner(owner, function()
			world.runtime.decorate(node, { X = outer })
		end)
		Compose.withOwner(owner, function()
			world.runtime.decorate(node, { X = 30 })
		end)
		inner:set(21)
		outer:set(2)
		world.settle()
		expect(world.host.propertyOf(node, "X")):toBe(30)
	end)
end)

return nil
