--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function view(x: number, y: number, width: number, height: number): Compose.TileCollectionViewport
	return { x = x, y = y, width = width, height = height }
end

local function nodes(world: Support.World, root: Compose.Node): { [string]: Compose.Node }
	local found: { [string]: Compose.Node } = {}
	for _, node in world.host.childrenOf(root) do
		found[tostring(world.host.propertyOf(node, "Id"))] = node
	end
	return found
end

local function mount(
	world: Support.World,
	viewport: Compose.Cell<Compose.TileCollectionViewport>,
	read: (Compose.Use, number, number) -> string?,
	overscan: number?
)
	return world.runtime.mount(function()
		return world.create "Frame" {
			Compose.TileCollection {
				viewport = viewport,
				tileSize = { width = 10, height = 20 },
				overscan = overscan,
				read = read,
				render = function(value: Compose.Readable<string>, placement: Compose.TileCollectionPlacement)
					return world.create "Tile" {
						Id = placement.column .. ":" .. placement.row,
						X = placement.x,
						Y = placement.y,
						Image = value,
					}
				end,
			},
		}
	end, world.root)
end

describe("TileCollection", function()
	it("queries only intersecting coordinates including negative positions and exact edges", function()
		local world = Support.world()
		local queried: { string } = {}
		local viewport = Compose.cell(view(-10, -20, 20, 40))
		local dispose, root = mount(world, viewport, function(_use, column, row)
			table.insert(queried, column .. ":" .. row)
			return "ground"
		end)
		expect(queried):toEqual { "-1:-1", "0:-1", "-1:0", "0:0" }
		local held = nodes(world, root)
		expect(world.host.propertyOf(held["-1:-1"], "X")):toBe(-10)
		expect(world.host.propertyOf(held["-1:-1"], "Y")):toBe(-20)
		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("includes partially intersecting tiles and expands overscan on both axes", function()
		local world = Support.world()
		local viewport = Compose.cell(view(1, 1, 10, 20))
		local reads = 0
		local dispose, root = mount(world, viewport, function()
			reads += 1
			return "ground"
		end, 1)
		expect(reads):toBe(16)
		expect(#world.host.childrenOf(root)):toBe(16)
		expect(nodes(world, root)["-1:-1"]).never:toBeNil()
		expect(nodes(world, root)["2:2"]).never:toBeNil()
		viewport:set(view(0, 0, 0, 20))
		expect(#world.host.childrenOf(root)):toBe(0)
		expect(reads):toBe(16)
		dispose()
	end)

	it("preserves intersecting nodes and changes only the entering and leaving strip", function()
		local world = Support.world()
		local viewport = Compose.cell(view(0, 0, 30, 40))
		local dispose, root = mount(world, viewport, function()
			return "ground"
		end)
		local before = nodes(world, root)
		world.host.resetCounts()
		viewport:set(view(10, 0, 30, 40))
		local after = nodes(world, root)
		expect(after["1:0"]):toBe(before["1:0"])
		expect(after["2:1"]):toBe(before["2:1"])
		expect(world.host.isAlive(before["0:0"])):toBe(false)
		expect(world.host.counts().createNode):toBe(2)
		expect(world.host.counts().destroyNode):toBe(2)
		expect(#world.host.childrenOf(root)):toBe(6)
		dispose()
	end)

	it("performs no host work while a camera stays within the same covered coordinates", function()
		local world = Support.world()
		local viewport = Compose.cell(view(1, 1, 10, 20))
		local dispose = mount(world, viewport, function()
			return "ground"
		end)
		world.host.resetCounts()
		viewport:set(view(2, 2, 10, 20))
		local counts = world.host.counts()
		expect(
			counts.createNode
				+ counts.destroyNode
				+ counts.setProperty
				+ counts.moveChild
				+ counts.insertChild
				+ counts.removeChild
		):toBe(0)
		dispose()
	end)

	it("edits one tile in place, observes empty cells and ignores offscreen changes", function()
		local world = Support.world()
		local values =
			{ Compose.cell("grass" :: string?), Compose.cell(nil :: string?), Compose.cell("water" :: string?) }
		local reads = 0
		local viewport = Compose.cell(view(0, 0, 20, 20))
		local dispose, root = mount(world, viewport, function(use, column)
			reads += 1
			return use(values[column + 1])
		end)
		local original = nodes(world, root)["0:0"]
		world.host.resetCounts()
		values[1]:set "sand"
		expect(nodes(world, root)["0:0"]):toBe(original)
		expect(world.host.propertyOf(original, "Image")):toBe "sand"
		expect(world.host.counts().setProperty):toBe(1)
		expect(world.host.counts().createNode):toBe(0)
		values[2]:set "stone"
		expect(#world.host.childrenOf(root)):toBe(2)
		values[1]:set(nil)
		expect(world.host.isAlive(original)):toBe(false)
		local before = reads
		values[3]:set "lava"
		expect(reads):toBe(before)
		viewport:set(view(20, 0, 10, 20))
		expect(world.host.propertyOf(nodes(world, root)["2:0"], "Image")):toBe "lava"
		before = reads
		values[2]:set "ice"
		expect(reads):toBe(before)
		dispose()
		before = reads
		values[3]:set "water"
		expect(reads):toBe(before)
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("mounts false as data and leaves nil coordinates empty", function()
		local world = Support.world()
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.TileCollection {
					viewport = Compose.cell(view(0, 0, 20, 10)),
					tileSize = { width = 10, height = 10 },
					read = function(_use: Compose.Use, column: number): boolean?
						return if column == 0 then false else nil
					end,
					render = function(value, placement)
						expect(table.isfrozen(placement)):toBe(true)
						return world.create "Tile" { Flag = value }
					end,
				},
			}
		end, world.root)
		expect(#world.host.childrenOf(root)):toBe(1)
		expect(world.host.propertyOf(world.host.childrenOf(root)[1], "Flag")):toBe(false)
		dispose()
	end)

	it("retains bounded nodes through long two dimensional movement on an unordered host", function()
		local world = Support.world { ordersChildren = false }
		local viewport = Compose.cell(view(0, 0, 30, 40))
		local reads = 0
		local dispose, root = mount(world, viewport, function()
			reads += 1
			return "ground"
		end)
		for step = 1, 100 do
			viewport:set(view(step * 10000, -step * 20000, 30, 40))
			expect(#world.host.childrenOf(root)):toBe(6)
			expect(world.host.liveNodes()):toBe(8)
		end
		expect(reads):toBe(606)
		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("unwinds a failed tile build and releases owned resources exactly once", function()
		local world = Support.world()
		local released = 0
		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.TileCollection {
						viewport = Compose.cell(view(0, 0, 20, 10)),
						tileSize = { width = 10, height = 10 },
						read = function()
							return 1
						end,
						render = function(_value, placement)
							Compose.cleanup(function()
								released += 1
							end)
							local node = world.create "Tile" {}
							if placement.column == 1 then
								error("tile build failed", 0)
							end
							return node
						end,
					},
				}
			end, world.root)
		end):toThrow "tile build failed"
		expect(released):toBe(2)
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("keeps survivors after a failed admission and retries without rebuilding them", function()
		local world = Support.world()
		local viewport = Compose.cell(view(0, 0, 10, 20))
		local dispose, root = mount(world, viewport, function()
			return "ground"
		end)
		local survivor = nodes(world, root)["0:0"]
		world.host.failNext "createNode"
		expect(function()
			viewport:set(view(0, 0, 20, 20))
		end):toThrow()
		world.host.clearFailures()
		expect(nodes(world, root)["0:0"]):toBe(survivor)
		viewport:set(view(0, 0, 20, 20))
		expect(#world.host.childrenOf(root)):toBe(2)
		expect(nodes(world, root)["0:0"]):toBe(survivor)
		dispose()
		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("preserves borrowed tile nodes and clears their owned bindings", function()
		local world = Support.world()
		local borrowed = world.host.makeNode "Tile"
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.TileCollection {
					viewport = Compose.cell(view(0, 0, 10, 10)),
					tileSize = { width = 10, height = 10 },
					read = function()
						return "grass"
					end,
					render = function(value)
						world.runtime.decorate(borrowed, { Image = value })
						return borrowed
					end,
				},
			}
		end, world.root)
		dispose()
		expect(world.host.isAlive(borrowed)):toBe(true)
		expect(world.host.propertyOf(borrowed, "Image")):toBeNil()
		expect(world.host.liveNodes()):toBe(2)
	end)

	it("leaves prior tiles intact when a data read fails and applies the next successful snapshot", function()
		local world = Support.world()
		local viewport = Compose.cell(view(0, 0, 20, 20))
		local revision = Compose.cell(0)
		local failing = false
		local dispose, root = mount(world, viewport, function(use, column)
			use(revision)
			if failing and column == 1 then
				error("tile read failed", 0)
			end
			return if column == 0 then nil else "ground"
		end)
		local original = nodes(world, root)["1:0"]
		failing = true
		expect(function()
			revision:set(1)
		end):toThrow "tile read failed"
		expect(nodes(world, root)["1:0"]):toBe(original)
		failing = false
		revision:set(2)
		expect(nodes(world, root)["1:0"]):toBe(original)
		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("keeps independent layer identities and surrounding siblings through sparse edits", function()
		local world = Support.world()
		local viewport = Compose.cell(view(0, 0, 20, 20))
		local filled = Compose.cell(false)
		local tiles = Compose.TileCollection {
			viewport = viewport,
			tileSize = { width = 10, height = 20 },
			read = function(use: Compose.Use, column: number): string?
				return if use(filled) or column == 1 then "ground" else nil
			end,
			render = function(_value, placement: Compose.TileCollectionPlacement)
				return world.create "Tile" { Id = placement.column }
			end,
		}
		local dispose, root = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "Marker" { Id = "before" },
				tiles,
				world.create "Marker" { Id = "between" },
				tiles,
				world.create "Marker" { Id = "after" },
			}
		end, world.root)
		local original = world.host.childrenOf(root)
		filled:set(true)
		local children = world.host.childrenOf(root)
		local ids: { unknown } = {}
		for _, node in children do
			table.insert(ids, world.host.propertyOf(node, "Id"))
		end
		expect(ids):toEqual({ "before", 0, 1, "between", 0, 1, "after" } :: { unknown })
		expect(children[3]):toBe(original[2])
		expect(children[6]):toBe(original[4])
		expect(children[3]).never:toBe(children[6])
		filled:set(false)
		expect(#world.host.childrenOf(root)):toBe(5)
		dispose()
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("uses the same coordinate identity for positive and negative zero", function()
		local world = Support.world()
		local viewport = Compose.cell(view(0, 0, 10, 20))
		local dispose, root = mount(world, viewport, function()
			return "ground"
		end)
		local original = world.host.childrenOf(root)[1]
		world.host.resetCounts()
		viewport:set(view(-0, -0, 10, 20))
		expect(world.host.childrenOf(root)[1]):toBe(original)
		expect(world.host.counts().createNode + world.host.counts().destroyNode):toBe(0)
		dispose()
	end)

	it("rejects fractional overscan and unsafe coordinate ranges before mounting", function()
		local world = Support.world()
		local reads = 0
		local viewport = Compose.cell(view(0, 0, 10, 20))
		local function read(): string
			reads += 1
			return "ground"
		end
		for _, overscan in { -1, 0.5, math.huge } do
			expect(function()
				mount(world, viewport, read, overscan)
			end):toThrow "tile-collection/invalid-overscan"
		end
		viewport:set(view(1e20, 0, 10, 20))
		expect(function()
			mount(world, viewport, read)
		end):toThrow "tile-collection/invalid-viewport"
		expect(reads):toBe(0)
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("rejects invalid dimensions before reading tiles and recovers from an invalid viewport", function()
		local world = Support.world()
		for _, width in { 0, -1, math.huge, math.sqrt(-1) } do
			expect(function()
				Compose.TileCollection {
					viewport = Compose.cell(view(0, 0, 10, 10)),
					tileSize = { width = width, height = 10 },
					read = function()
						return 1
					end,
					render = function()
						return world.create "Tile" {}
					end,
				}
			end):toThrow "tile-collection/invalid-size"
		end
		local viewport = Compose.cell(view(0, 0, 10, 20))
		local dispose, root = mount(world, viewport, function()
			return "ground"
		end)
		local original = nodes(world, root)["0:0"]
		expect(function()
			viewport:set(view(math.huge, 0, 10, 20))
		end):toThrow "tile-collection/invalid-viewport"
		expect(nodes(world, root)["0:0"]):toBe(original)
		viewport:set(view(0, 0, 10, 20))
		expect(nodes(world, root)["0:0"]):toBe(original)
		dispose()
	end)
end)

return nil
