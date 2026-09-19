--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect, beforeEach = Test.describe, Test.it, Test.expect, Test.beforeEach

local world: Support.World

local function idsOf(root: Compose.Node): { string }
	local names: { string } = {}
	for _, child in world.host.childrenOf(root) do
		table.insert(names, tostring(world.host.propertyOf(child, "Id")))
	end
	return names
end

local function nodesByKey(root: Compose.Node): { [string]: Compose.Node }
	local map: { [string]: Compose.Node } = {}
	for _, child in world.host.childrenOf(root) do
		map[tostring(world.host.propertyOf(child, "Id"))] = child
	end
	return map
end

describe("crowd tier under churn", function()
	beforeEach(function()
		world = Support.world()
	end)

	describe("SpatialCollection membership churn", function()
		type Unit = { id: string, x: number, y: number, z: number }

		local function idOf(unit: Unit): string
			return unit.id
		end

		local function positionOf(unit: Unit): (number, number, number)
			return unit.x, unit.y, unit.z
		end

		local function mountSpatial(units: Compose.Cell<{ Unit }>, origin: Compose.Cell<Compose.SpatialCollectionPoint>)
			return world.runtime.mount(function()
				return world.create "Frame" {
					Compose.SpatialCollection {
						from = units,
						key = idOf,
						position = positionOf,
						origin = origin,
						tiers = { { name = "near", radius = 100 }, { name = "far", radius = 200 } },
						render = function(value)
							return world.create "Unit" {
								Id = function(use)
									return use(value).id
								end,
							}
						end,
					},
				}
			end, world.root)
		end

		it("does not leak membership under rapid enter and leave", function()
			local before = world.host.liveNodes()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local units = Compose.cell({} :: { Unit })
			local dispose, root = mountSpatial(units, origin)

			local inside: { Unit } = {}
			local outside: { Unit } = {}
			for index = 1, 5 do
				inside[index] = { id = "s" .. index, x = index * 10, y = 0, z = 0 }
				outside[index] = { id = "s" .. index, x = 10000 + index, y = 0, z = 0 }
			end
			for _ = 1, 20 do
				units:set(inside)
				world.settle()
				expect(#idsOf(root)):toBe(5)
				units:set(outside)
				world.settle()
				expect(#idsOf(root)):toBe(0)
			end

			units:set(inside)
			world.settle()
			expect(world.host.liveNodes()):toBe(before + 1 + 5)

			dispose()
			expect(world.host.liveNodes()):toBe(before)
		end)

		it("follows a source permutation with identity intact and no rebuilds", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local ordered: { Unit } = {}
			for index = 1, 6 do
				ordered[index] = { id = "p" .. index, x = index * 10, y = 0, z = 0 }
			end
			local units = Compose.cell(ordered)
			local dispose, root = mountSpatial(units, origin)
			expect(idsOf(root)):toEqual { "p1", "p2", "p3", "p4", "p5", "p6" }

			local before = nodesByKey(root)
			world.host.resetCounts()

			units:set { ordered[4], ordered[1], ordered[6], ordered[2], ordered[5], ordered[3] }
			world.settle()

			expect(idsOf(root)):toEqual { "p4", "p1", "p6", "p2", "p5", "p3" }
			expect(world.host.counts().createNode):toBe(0)
			expect(world.host.counts().destroyNode):toBe(0)
			local after = nodesByKey(root)
			for key, node in before do
				expect(after[key]):toBe(node)
			end
			dispose()
		end)

		it("hosts a keyed sublist inside each retained entity and tears it all down", function()
			local before = world.host.liveNodes()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local parts = Compose.cell { { id = "arm" }, { id = "leg" } }
			local units = Compose.cell({
				{ id = "w1", x = 10, y = 0, z = 0 },
				{ id = "w2", x = 20, y = 0, z = 0 },
			} :: { Unit })
			local dispose, root = world.runtime.mount(function()
				return world.create "Frame" {
					Compose.SpatialCollection {
						from = units,
						key = idOf,
						position = positionOf,
						origin = origin,
						tiers = { { name = "near", radius = 100 } },
						render = function(value)
							return world.create "Unit" {
								Id = function(use)
									return use(value).id
								end,
								Compose.keyed {
									from = function(use)
										return use(parts)
									end,
									key = function(part: { id: string })
										return part.id
									end,
									render = function(part)
										return world.create "Part" {
											Id = function(use)
												return use(part).id
											end,
										}
									end,
								},
							}
						end,
					},
				}
			end, world.root)

			local unit = world.host.childrenOf(root)[1]
			expect(#world.host.childrenOf(unit)):toBe(2)

			parts:set { { id = "leg" }, { id = "arm" }, { id = "tail" } }
			world.settle()
			expect(#world.host.childrenOf(unit)):toBe(3)

			origin:set { x = 10000, y = 0, z = 0 }
			world.settle()
			expect(#idsOf(root)):toBe(0)
			origin:set { x = 0, y = 0, z = 0 }
			world.settle()
			expect(#idsOf(root)):toBe(2)

			dispose()
			expect(world.host.liveNodes()):toBe(before)
		end)
	end)

	describe("LayerStack push and pop churn", function()
		type Layer = { id: string }

		local function mountStack(layers: Compose.Cell<{ Layer }>)
			return world.runtime.mount(function()
				return world.create "Root" {
					Compose.LayerStack {
						from = layers,
						key = function(layer: Layer)
							return layer.id
						end,
						render = function(
							layer: Compose.Readable<Layer>,
							state: Compose.Readable<Compose.LayerStackState>
						)
							return world.create "Layer" {
								Id = function(use)
									return use(layer).id
								end,
								Top = function(use)
									return use(state).top
								end,
								Covered = function(use)
									return use(state).covered
								end,
								DepthFromTop = function(use)
									return use(state).depthFromTop
								end,
							}
						end,
					},
				}
			end, world.root)
		end

		it("keeps the world layer's node through twenty modal cycles", function()
			local layers = Compose.cell({ { id = "world" } } :: { Layer })
			local dispose, root = mountStack(layers)
			local worldNode = world.host.childrenOf(root)[1]

			for cycle = 1, 20 do
				layers:set { { id = "world" }, { id = "modal" .. cycle } }
				world.settle()
				expect(world.host.childrenOf(root)[1]):toBe(worldNode)
				expect(world.host.propertyOf(worldNode, "Covered")):toBe(true)
				expect(world.host.propertyOf(worldNode, "Top")):toBe(false)

				layers:set { { id = "world" } }
				world.settle()
				expect(world.host.childrenOf(root)[1]):toBe(worldNode)
				expect(world.host.propertyOf(worldNode, "Covered")):toBe(false)
				expect(world.host.propertyOf(worldNode, "Top")):toBe(true)
			end

			dispose()
			expect(world.host.liveNodes()):toBe(1)
		end)

		it("gives every layer of a deep stack its depth from the top", function()
			local layers = Compose.cell({ { id = "a" }, { id = "b" }, { id = "c" } } :: { Layer })
			local dispose, root = mountStack(layers)
			local children = world.host.childrenOf(root)
			expect(world.host.propertyOf(children[1], "DepthFromTop")):toBe(2)
			expect(world.host.propertyOf(children[2], "DepthFromTop")):toBe(1)
			expect(world.host.propertyOf(children[3], "DepthFromTop")):toBe(0)
			expect(world.host.propertyOf(children[3], "Top")):toBe(true)
			expect(world.host.propertyOf(children[3], "Covered")):toBe(false)
			dispose()
		end)
	end)

	describe("OrderedCollection adversarial updates", function()
		type Row = { id: string }

		it("absorbs a reorder and a viewport move landing in one batch", function()
			local items: { Row } = {}
			for index = 1, 40 do
				items[index] = { id = "r" .. index }
			end
			local list = Compose.cell(items)
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
			local dispose, root = world.runtime.mount(function()
				return world.create "Frame" {
					Compose.OrderedCollection {
						from = list,
						key = function(row: Row)
							return row.id
						end,
						mode = "windowed",
						viewport = viewport,
						layout = { itemSize = 10 },
						render = function(value)
							return world.create "Row" {
								Id = function(use)
									return use(value).id
								end,
							}
						end,
					},
				}
			end, world.root)
			expect(idsOf(root)):toEqual { "r1", "r2", "r3" }

			world.batch(function()
				local reversed: { Row } = table.create(40)
				for index = 40, 1, -1 do
					table.insert(reversed, items[index])
				end
				list:set(reversed)
				viewport:set { offset = 100, size = 30 }
			end)
			world.settle()

			expect(idsOf(root)):toEqual { "r30", "r29", "r28" }

			dispose()
			expect(world.host.liveNodes()):toBe(1)
		end)

		it("comes back to baseline after a churn-and-scroll marathon", function()
			local population = 0
			local function fresh(count: number): { Row }
				local rows: { Row } = table.create(count)
				for index = 1, count do
					population += 1
					rows[index] = { id = "gen" .. population }
				end
				return rows
			end
			local list = Compose.cell(fresh(50))
			local viewport = Compose.cell({ offset = 0, size = 30 } :: Compose.OrderedCollectionViewport)
			local dispose = world.runtime.mount(function()
				return world.create "Frame" {
					Compose.OrderedCollection {
						from = list,
						key = function(row: Row)
							return row.id
						end,
						mode = "windowed",
						viewport = viewport,
						layout = { itemSize = 10 },
						render = function()
							return world.create "Row" {}
						end,
					},
				}
			end, world.root)

			for round = 1, 10 do
				viewport:set { offset = round * 40, size = 30 }
				world.settle()
				list:set(fresh(50))
				world.settle()
			end

			dispose()
			expect(world.host.liveNodes()):toBe(1)
		end)
	end)
end)

return nil
