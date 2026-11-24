--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect, beforeEach = Test.describe, Test.it, Test.expect, Test.beforeEach

type Layer = { id: string }
local world: Support.World

local function ids(root: Compose.Node): { string }
	local result: { string } = {}
	for _, node in world.host.childrenOf(root) do
		result[#result + 1] = tostring(world.host.propertyOf(node, "Id"))
	end
	return result
end

describe("LayerStack", function()
	beforeEach(function()
		world = Support.world()
	end)

	it("retains covered layers and updates top state without rebuilding", function()
		local initialLayers: { Layer } = { { id = "world" }, { id = "menu" } }
		local layers = Compose.cell(initialLayers)
		local dispose, root = world.runtime.mount(function()
			return world.create "Root" {
				Compose.LayerStack {
					from = layers,
					key = function(layer: Layer)
						return layer.id
					end,
					render = function(
						layer: Compose.ReadOnlyValue<Layer>,
						state: Compose.ReadOnlyValue<Compose.LayerStackState>
					)
						return world.create "Layer" {
							Id = function(use)
								return use(layer).id
							end,
							Top = function(use)
								return use(state).top
							end,
						}
					end,
				},
			}
		end, world.root)
		expect(ids(root)):toEqual { "world", "menu" }
		local worldNode = world.host.childrenOf(root)[1]
		world.host.resetCounts()
		layers:set { { id = "world" } }
		world.settle()
		expect(world.host.childrenOf(root)[1]):toBe(worldNode)
		expect(world.host.propertyOf(worldNode, "Top")):toBe(true)
		expect(world.host.counts().createNode):toBe(0)
		dispose()
	end)

	it("can retain only the top layer", function()
		local dispose, root = world.runtime.mount(function()
			return world.create "Root" {
				Compose.LayerStack {
					from = Compose.cell((function(value: { Layer }): { Layer }
						return value
					end) { { id = "world" }, { id = "dialog" } }),
					key = function(layer: Layer)
						return layer.id
					end,
					retention = "top",
					render = function(layer: Compose.ReadOnlyValue<Layer>)
						return world.create "Layer" {
							Id = function(use)
								return use(layer).id
							end,
						}
					end,
				},
			}
		end, world.root)
		expect(ids(root)):toEqual { "dialog" }
		dispose()
	end)

	it("unwinds the whole stack when a layer fails to build", function()
		expect(function()
			world.runtime.mount(function()
				return world.create "Root" {
					Compose.LayerStack {
						from = Compose.cell((function(value: { Layer }): { Layer }
							return value
						end) { { id = "one" }, { id = "two" } }),
						key = function(layer: Layer)
							return layer.id
						end,
						render = function(layer: Compose.ReadOnlyValue<Layer>)
							if layer:peek().id == "two" then
								error "layer failed"
							end
							return world.create "Layer" {}
						end,
					},
				}
			end, world.root)
		end):toThrow "layer failed"
		expect(world.host.liveNodes()):toBe(1)
	end)
end)

return nil
