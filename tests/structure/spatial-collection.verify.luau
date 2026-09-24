--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect, beforeEach = Test.describe, Test.it, Test.expect, Test.beforeEach

type Unit = { id: string, x: number, y: number, z: number }

local TIERS: { Compose.SpatialCollectionTier } = {
	{ name = "full", radius = 80 },
	{ name = "simplified", radius = 180 },
	{ name = "marker", radius = 300 },
}

local function line(count: number, spacing: number): { Unit }
	local units = table.create(count) :: { Unit }
	for index = 1, count do
		units[index] = { id = "u" .. index, x = (index - 1) * spacing, y = 0, z = 0 }
	end
	return units
end

local function idOf(unit: Unit): string
	return unit.id
end

local function positionOf(unit: Unit): (number, number, number)
	return unit.x, unit.y, unit.z
end

local world: Support.World

describe("SpatialCollection", function()
	beforeEach(function()
		world = Support.world()
	end)

	local function mount(options: {
		units: { Unit },
		origin: Compose.Cell<Compose.SpatialCollectionPoint>,
		hysteresis: number?,
		cellSize: number?,
		budget: Compose.SpatialCollectionBudget?,
		pinned: Compose.Cell<{ [string]: boolean }>?,
		importance: ((unit: Unit) -> number)?,
		status: Compose.Cell<Compose.SpatialCollectionStatus>?,
	})
		local units = Compose.cell(options.units)
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.SpatialCollection {
					from = units,
					key = idOf,
					position = positionOf,
					origin = options.origin,
					tiers = TIERS,
					hysteresis = options.hysteresis,
					cellSize = options.cellSize,
					budget = options.budget,
					pinned = options.pinned,
					importance = options.importance,
					status = options.status,
					render = function(value, representation)
						return world.create "Unit" {
							Id = function(use)
								return use(value).id
							end,
							Tier = function(use)
								return use(representation).name
							end,
						}
					end,
				},
			}
		end, world.root)
		return dispose, root, units
	end

	local function idsOf(root: Compose.Node): { string }
		local names: { string } = {}
		for _, child in world.host.childrenOf(root) do
			table.insert(names, tostring(world.host.propertyOf(child, "Id")))
		end
		return names
	end

	local function tierOf(root: Compose.Node, id: string): string?
		for _, child in world.host.childrenOf(root) do
			if world.host.propertyOf(child, "Id") == id then
				return tostring(world.host.propertyOf(child, "Tier"))
			end
		end
		return nil
	end

	describe("retention", function()
		it("retains only what is inside the outermost radius", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose, root = mount { units = line(20, 50), origin = origin }
			expect(idsOf(root)):toEqual { "u1", "u2", "u3", "u4", "u5", "u6", "u7" }
			dispose()
		end)

		it("gives each retained entity the tier its distance earns", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose, root = mount { units = line(20, 50), origin = origin }
			expect(tierOf(root, "u1")):toBe "full"
			expect(tierOf(root, "u3")):toBe "simplified"
			expect(tierOf(root, "u6")):toBe "marker"
			dispose()
		end)

		it("follows the origin, keeping what stays relevant", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose, root = mount { units = line(20, 50), origin = origin }
			world.host.resetCounts()

			origin:set { x = 50, y = 0, z = 0 }
			world.settle()

			expect(idsOf(root)):toEqual { "u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8" }
			expect(world.host.counts().createNode):toBe(1)
			dispose()
		end)

		it("re-tiers a retained entity without rebuilding it", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose, root = mount { units = line(20, 50), origin = origin }
			expect(tierOf(root, "u3")):toBe "simplified"
			world.host.resetCounts()

			origin:set { x = 100, y = 0, z = 0 }
			world.settle()

			expect(tierOf(root, "u3")):toBe "full"
			expect(world.host.counts().destroyNode):toBe(0)
			dispose()
		end)

		it("keeps source order, so following the origin is not a reorder", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose = mount { units = line(20, 50), origin = origin }
			world.host.resetCounts()
			origin:set { x = 50, y = 0, z = 0 }
			world.settle()
			expect(world.host.counts().moveChild):toBe(0)
			dispose()
		end)
	end)

	describe("hysteresis", function()
		it("builds an entity oscillating on a boundary exactly once", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local units: { Unit } = { { id = "edge", x = 299, y = 0, z = 0 } }
			local dispose, root = mount { units = units, origin = origin, hysteresis = 24 }
			expect(idsOf(root)):toEqual { "edge" }

			world.host.resetCounts()
			for _ = 1, 10 do
				origin:set { x = -5, y = 0, z = 0 }
				world.settle()
				origin:set { x = 5, y = 0, z = 0 }
				world.settle()
			end

			expect(idsOf(root)):toEqual { "edge" }
			expect(world.host.counts().createNode):toBe(0)
			expect(world.host.counts().destroyNode):toBe(0)
			dispose()
		end)

		it("thrashes without a band, which is what the band is for", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local units: { Unit } = { { id = "edge", x = 299, y = 0, z = 0 } }
			local dispose = mount { units = units, origin = origin, hysteresis = 0 }

			world.host.resetCounts()
			for _ = 1, 5 do
				origin:set { x = -5, y = 0, z = 0 }
				world.settle()
				origin:set { x = 5, y = 0, z = 0 }
				world.settle()
			end
			expect(world.host.counts().createNode):toBeGreaterThan(0)
			dispose()
		end)

		it("still releases an entity that genuinely leaves", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local units: { Unit } = { { id = "edge", x = 299, y = 0, z = 0 } }
			local dispose, root = mount { units = units, origin = origin, hysteresis = 24 }
			origin:set { x = -100, y = 0, z = 0 }
			world.settle()
			expect(idsOf(root)):toEqual {}
			dispose()
		end)
	end)

	describe("pinning", function()
		it("retains a pinned entity the radius would have dropped", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local pinned = Compose.cell({} :: { [string]: boolean })
			local dispose, root = mount { units = line(20, 50), origin = origin, pinned = pinned }
			expect(tierOf(root, "u15")):toBeNil()

			pinned:set { u15 = true }
			world.settle()

			expect(tierOf(root, "u15")):toBe "marker"
			dispose()
		end)

		it("releases it when it is unpinned", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local pinned = Compose.cell({ u15 = true } :: { [string]: boolean })
			local dispose, root = mount { units = line(20, 50), origin = origin, pinned = pinned }
			expect(tierOf(root, "u15")):toBe "marker"
			pinned:set {}
			world.settle()
			expect(tierOf(root, "u15")):toBeNil()
			dispose()
		end)
	end)

	describe("importance", function()
		it("keeps an important entity relevant further out", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose, root = mount {
				units = line(20, 50),
				origin = origin,
				importance = function(unit: Unit): number
					return if unit.id == "u10" then 3 else 1
				end,
			}

			expect(tierOf(root, "u9")):toBeNil()
			expect(tierOf(root, "u10")):toBe "simplified"
			dispose()
		end)
	end)

	describe("admission budget", function()
		it("admits a bounded number of entities per frame", function()
			local origin = Compose.cell({ x = 10000, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local status = Compose.cell({} :: Compose.SpatialCollectionStatus)
			local dispose, root = mount {
				units = line(20, 10),
				origin = origin,
				budget = { mountsPerFrame = 3 },
				status = status,
			}
			expect(#idsOf(root)):toBe(0)

			origin:set { x = 0, y = 0, z = 0 }
			world.settle()
			expect(#idsOf(root)):toBe(3)
			expect(status:peek().pending):toBe(17)

			world.host.step(1 / 60)
			world.settle()
			expect(#idsOf(root)):toBe(6)

			world.host.step(1 / 60)
			world.settle()
			expect(#idsOf(root)):toBe(9)
			dispose()
		end)

		it("drains, and then stops taking frames at all", function()
			local origin = Compose.cell({ x = 10000, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local status = Compose.cell({} :: Compose.SpatialCollectionStatus)
			local dispose, root = mount {
				units = line(9, 10),
				origin = origin,
				budget = { mountsPerFrame = 3 },
				status = status,
			}
			origin:set { x = 0, y = 0, z = 0 }
			world.settle()
			for _ = 1, 5 do
				world.host.step(1 / 60)
				world.settle()
			end
			expect(#idsOf(root)):toBe(9)
			expect(status:peek().pending):toBe(0)
			expect(world.host.counts().frameListeners):toBe(0)
			dispose()
		end)

		it("admits the nearest entities first", function()
			local origin = Compose.cell({ x = 10000, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose, root = mount {
				units = line(20, 10),
				origin = origin,
				budget = { mountsPerFrame = 2 },
			}
			origin:set { x = 0, y = 0, z = 0 }
			world.settle()
			expect(idsOf(root)):toEqual { "u1", "u2" }
			dispose()
		end)

		it("never budgets a departure", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose, root = mount {
				units = line(20, 10),
				origin = origin,
				budget = { mountsPerFrame = 2 },
			}
			for _ = 1, 20 do
				world.host.step(1 / 60)
				world.settle()
			end
			expect(#idsOf(root)):toBe(20)

			origin:set { x = 10000, y = 0, z = 0 }
			world.settle()
			expect(#idsOf(root)):toBe(0)
			dispose()
		end)
	end)

	describe("cost", function()
		it("looks at its own neighbourhood rather than the whole world", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local status = Compose.cell({} :: Compose.SpatialCollectionStatus)
			local dispose = mount {
				units = line(4000, 10),
				origin = origin,
				cellSize = 100,
				status = status,
			}
			local published = status:peek()
			expect(published.total):toBe(4000)
			expect(published.queried):toBeLessThan(200)
			expect(published.retained):toBe(31)
			expect(published.cells):toBe(4)
			dispose()
		end)

		it("scans a fresh moving snapshot instead of building a one-use grid", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local status = Compose.cell({} :: Compose.SpatialCollectionStatus)
			local dispose, _, units = mount { units = line(200, 10), origin = origin, status = status }
			local moved = line(200, 10)
			for _, unit in moved do
				unit.x += 1
			end

			units:set(moved)
			world.settle()

			expect(status:peek().queried):toBe(200)
			expect(status:peek().cells):toBe(0)
			dispose()
		end)

		it("reports how many entities are at each tier", function()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local status = Compose.cell({} :: Compose.SpatialCollectionStatus)
			local dispose = mount { units = line(20, 50), origin = origin, status = status }
			local perTier = status:peek().perTier
			expect(perTier[1]):toBe(2)
			expect(perTier[2]):toBe(2)
			expect(perTier[3]):toBe(3)
			dispose()
		end)
	end)

	describe("lifetime", function()
		it("returns every node when the collection goes", function()
			local before = world.host.liveNodes()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose = mount { units = line(500, 10), origin = origin }
			dispose()
			expect(world.host.liveNodes()):toBe(before)
		end)

		it("returns every node after a long traversal", function()
			local before = world.host.liveNodes()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			local dispose = mount { units = line(500, 10), origin = origin }
			for step = 1, 60 do
				origin:set { x = step * 50, y = 0, z = 0 }
				world.settle()
			end
			dispose()
			expect(world.host.liveNodes()):toBe(before)
		end)

		it("unwinds completely when an entity fails to build", function()
			local before = world.host.liveNodes()
			local origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint)
			world.host.failNext("createNode", 1)
			expect(function()
				mount { units = line(50, 10), origin = origin }
			end):toThrow()
			world.host.clearFailures()
			expect(world.host.liveNodes()):toBe(before)
		end)
	end)

	describe("arguments", function()
		it("refuses an unordered tier list where it was written", function()
			expect(function()
				world.runtime.mount(function()
					return world.create "Frame" {
						Compose.SpatialCollection {
							from = Compose.cell(line(2, 10)),
							key = idOf,
							position = positionOf,
							origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint),
							tiers = {
								{ name = "far", radius = 300 },
								{ name = "near", radius = 80 },
							},
							render = function()
								return world.create "Unit" {}
							end,
						},
					}
				end, world.root)
			end):toThrow "collection/tiers%-unordered"
		end)

		it("names an option it does not have", function()
			expect(function()
				world.runtime.mount(function()
					return world.create "Frame" {
						Compose.SpatialCollection {
							from = Compose.cell(line(2, 10)),
							position = positionOf,
							origin = Compose.cell({ x = 0, y = 0, z = 0 } :: Compose.SpatialCollectionPoint),
							tiers = TIERS,
							radius = 100,
							render = function()
								return world.create "Unit" {}
							end,
						} :: any,
					}
				end, world.root)
			end):toThrow "structure/unknown%-option"
		end)
	end)
end)

return nil
