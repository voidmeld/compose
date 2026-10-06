--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function kinds(world: Support.World, parent: Compose.Node): { string }
	local names: { string } = {}
	for _, child in world.host.childrenOf(parent) do
		table.insert(names, tostring(world.host.kindOf(child)))
	end
	return names
end

describe("show", function()
	it("mounts and unmounts as the condition changes", function()
		local world = Support.world()
		local open = Compose.cell(false)
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.show(function(use: Compose.Use)
					return use(open)
				end, function()
					return world.create "Panel" {}
				end),
			}
		end, world.root)

		expect(kinds(world, root)):toEqual {}
		open:set(true)
		world.settle()
		expect(kinds(world, root)):toEqual { "Panel" }
		open:set(false)
		world.settle()
		expect(kinds(world, root)):toEqual {}
		dispose()
	end)

	it("mounts the fallback when the condition is falsy", function()
		local world = Support.world()
		local open = Compose.cell(true)
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.show(function(use: Compose.Use)
					return use(open)
				end, function()
					return world.create "Panel" {}
				end, function()
					return world.create "Empty" {}
				end),
			}
		end, world.root)

		expect(kinds(world, root)):toEqual { "Panel" }
		open:set(false)
		world.settle()
		expect(kinds(world, root)):toEqual { "Empty" }
		dispose()
	end)

	it("does not rebuild when truthiness is unchanged", function()
		local world = Support.world()
		local count = Compose.cell(1)
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.show(function(use)
					return use(count) > 0
				end, function()
					return world.create "Panel" {}
				end),
			}
		end, world.root)

		local panel = world.host.childrenOf(root)[1]
		world.host.resetCounts()
		count:set(2)
		count:set(3)
		world.settle()
		expect(world.host.childrenOf(root)[1]):toBe(panel)
		expect(world.host.counts().createNode):toBe(0)
		expect(world.host.counts().destroyNode):toBe(0)
		dispose()
	end)

	it("keeps its position between static siblings", function()
		local world = Support.world()
		local open = Compose.cell(false)
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "Header" {},
				Compose.show(function(use: Compose.Use)
					return use(open)
				end, function()
					return world.create "Panel" {}
				end),
				world.create "Footer" {},
			}
		end, world.root)

		expect(kinds(world, root)):toEqual { "Header", "Footer" }
		open:set(true)
		world.settle()
		expect(kinds(world, root)):toEqual { "Header", "Panel", "Footer" }
		dispose()
	end)

	it("directly composes another structural directive", function()
		local world = Support.world()
		local open = Compose.cell(false)
		local rows = Compose.cell { "A", "B" }
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "Header" {},
				Compose.show(open, function()
					return Compose.keyed {
						from = rows,
						render = function(_row, _index, key)
							return world.create(key) {}
						end,
					}
				end),
				world.create "Footer" {},
			}
		end, world.root)

		expect(kinds(world, root)):toEqual { "Header", "Footer" }
		open:set(true)
		world.settle()
		expect(kinds(world, root)):toEqual { "Header", "A", "B", "Footer" }
		open:set(false)
		world.settle()
		expect(kinds(world, root)):toEqual { "Header", "Footer" }
		dispose()
	end)

	it("destroys the branch's whole subtree on unmount", function()
		local world = Support.world()
		local open = Compose.cell(true)
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.show(function(use: Compose.Use)
					return use(open)
				end, function()
					return world.create "Panel" {
						world.create "Text" {},
						world.create "Text" {},
					}
				end),
			}
		end, world.root)

		expect(world.host.liveNodes()):toBe(5)
		open:set(false)
		world.settle()
		expect(world.host.liveNodes()):toBe(2)
		dispose()
	end)
end)

describe("switch", function()
	it("mounts the branch for the current key", function()
		local world = Support.world()
		local screen = Compose.cell "menu"
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.switch(function(use: Compose.Use)
					return use(screen)
				end, {
					menu = function()
						return world.create "Menu" {}
					end,
					playing = function()
						return world.create "Hud" {}
					end,
				}),
			}
		end, world.root)

		expect(kinds(world, root)):toEqual { "Menu" }
		screen:set "playing"
		world.settle()
		expect(kinds(world, root)):toEqual { "Hud" }
		dispose()
	end)

	it("mounts nothing for an unknown key, and the fallback when there is one", function()
		local world = Support.world()
		local screen = Compose.cell "menu"
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.switch(function(use: Compose.Use)
					return use(screen)
				end, {
					menu = function()
						return world.create "Menu" {}
					end,
				}, function()
					return world.create "Unknown" {}
				end),
			}
		end, world.root)

		screen:set "something-the-server-invented"
		world.settle()
		expect(kinds(world, root)):toEqual { "Unknown" }
		dispose()
	end)

	it("does not rebuild when the key is unchanged", function()
		local world = Support.world()
		local screen = Compose.cell "menu"
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.switch(function(use: Compose.Use)
					return use(screen)
				end, {
					menu = function()
						return world.create "Menu" {}
					end,
				}),
			}
		end, world.root)

		local menu = world.host.childrenOf(root)[1]
		world.host.resetCounts()
		screen:set "menu"
		world.settle()
		expect(world.host.childrenOf(root)[1]):toBe(menu)
		expect(world.host.counts().createNode):toBe(0)
		dispose()
	end)
end)

describe("fragment", function()
	it("contributes several siblings in one slot", function()
		local world = Support.world()
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "Header" {},
				Compose.fragment(function()
					return { world.create "A" {}, world.create "B" {} }
				end),
				world.create "Footer" {},
			}
		end, world.root)

		expect(kinds(world, root)):toEqual { "Header", "A", "B", "Footer" }
		dispose()
	end)
end)

describe("portal", function()
	it("mounts elsewhere while staying owned here", function()
		local world = Support.world()
		local layer = world.host.makeNode "Layer"
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "Body" {},
				Compose.portal(layer, function()
					return { world.create "Tooltip" {} }
				end),
			}
		end, world.root)

		expect(kinds(world, root)):toEqual { "Body" }
		expect(kinds(world, layer)):toEqual { "Tooltip" }

		dispose()
		expect(kinds(world, layer)):toEqual {}
		expect(world.host.isAlive(layer)):toBe(true)
	end)
end)

describe("indexes", function()
	it("reuses rows by position and updates their values", function()
		local world = Support.world()
		local lines = Compose.cell { "one", "two" }
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.indexes(function(use: Compose.Use)
					return use(lines)
				end, function(value, index)
					return world.create "Line" {
						Text = function(use)
							return use(value)
						end,
						Index = index,
					}
				end),
			}
		end, world.root)

		local first = world.host.childrenOf(root)[1]
		world.host.resetCounts()

		lines:set { "changed", "two" }
		world.settle()

		expect(world.host.childrenOf(root)[1]):toBe(first)
		expect(world.host.propertyOf(first, "Text")):toBe "changed"
		expect(world.host.counts().createNode):toBe(0)
		expect(world.host.counts().setProperty):toBe(1)
		dispose()
	end)

	it("grows and shrinks from the end", function()
		local world = Support.world()
		local lines = Compose.cell { "a" }
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.indexes(function(use: Compose.Use)
					return use(lines)
				end, function()
					return world.create "Line" {}
				end),
			}
		end, world.root)

		lines:set { "a", "b", "c" }
		world.settle()
		expect(world.host.childrenOf(root)):toHaveLength(3)

		lines:set { "a" }
		world.settle()
		expect(world.host.childrenOf(root)):toHaveLength(1)
		dispose()
	end)
end)

return nil
