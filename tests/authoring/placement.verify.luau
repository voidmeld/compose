--!strict

local Author = require "../../authoring"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect
local Placement = Author.placement

describe("Author.placement measurements", function()
	it("measures plan distance and optionally height", function()
		expect(Placement.distance({ x = 0, y = 0, z = 0 }, { x = 3, y = 12, z = 4 })):toBe(5)
		expect(Placement.distance({ x = 0, y = 0, z = 0 }, { x = 3, y = 12, z = 4 }, "xyz")):toBe(13)
		expect(Placement.distance({ x = 1, y = 0, z = 1 }, { x = 1, y = 0, z = 4 }, "xyz")):toBe(3)
	end)

	it("measures the distance to the nearest segment of a path", function()
		local path = { { x = 0, y = 0, z = 0 }, { x = 10, y = 0, z = 0 }, { x = 10, y = 0, z = 10 } }
		expect(Placement.distanceToPath({ x = 5, y = 9, z = 3 }, path)):toBe(3)
		expect(Placement.distanceToPath({ x = 13, y = 0, z = 5 }, path)):toBe(3)
		expect(Placement.distanceToPath({ x = -4, y = 0, z = 3 }, path)):toBe(5)
		expect(function()
			Placement.distanceToPath({ x = 0, y = 0, z = 0 }, { { x = 0, y = 0, z = 0 } })
		end):toThrow "two points"
	end)

	it("splits a point into along and lateral components of a segment", function()
		local along, lateral, length = Placement.alongLateral(
			{ x = 4, y = 0, z = 3 },
			{ x = 0, y = 0, z = 0 },
			{ x = 10, y = 0, z = 0 }
		)
		expect(along):toBe(4)
		expect(lateral):toBe(3)
		expect(length):toBe(10)
		local _, other = Placement.alongLateral(
			{ x = 4, y = 0, z = -3 },
			{ x = 0, y = 0, z = 0 },
			{ x = 10, y = 0, z = 0 }
		)
		expect(other):toBe(-3)
		expect(function()
			Placement.alongLateral({ x = 1, y = 0, z = 1 }, { x = 2, y = 0, z = 2 }, { x = 2, y = 0, z = 2 })
		end):toThrow "distinct"
	end)

	it("finds the nearest item and keeps the first of equal distances", function()
		local items = {
			{ id = "far", at = { x = 9, y = 0, z = 0 } },
			{ id = "first", at = { x = 0, y = 0, z = 4 } },
			{ id = "second", at = { x = 4, y = 0, z = 0 } },
		}
		local function at(item: { id: string, at: Author.PlacementPosition }): Author.PlacementPosition
			return item.at
		end
		local item, found = Placement.nearest({ x = 0, y = 0, z = 0 }, items, at)
		expect(if item ~= nil then item.id else nil):toBe "first"
		expect(found):toBe(4)
		local none, infinite = Placement.nearest({ x = 0, y = 0, z = 0 }, {}, at)
		expect(none):toBe(nil)
		expect(infinite):toBe(math.huge)
	end)

	it("spaces a ring evenly from the first offset", function()
		local offsets = Placement.ring(4, 2)
		expect(#offsets):toBe(4)
		expect(offsets[1].x):toBe(2)
		expect(offsets[1].z):toBe(0)
		expect(math.abs(offsets[2].x) < 1e-9):toBe(true)
		expect(offsets[2].z):toBe(2)
		expect(function()
			Placement.ring(0, 2)
		end):toThrow "count"
		expect(function()
			Placement.ring(3, math.huge)
		end):toThrow "radius"
	end)
end)

describe("Author.placement.check", function()
	local points: { [string]: Author.PlacementPosition } = {
		hub = { x = 0, y = 0, z = 0 },
		near = { x = 6, y = 8, z = 0 },
		mid = { x = 30, y = 0, z = 0 },
		far = { x = 90, y = 0, z = 0 },
	}

	it("reports every pair closer than a separation, in id order", function()
		local violations = Placement.check(points, {
			{ kind = "separation", ids = { "hub", "near", "mid" }, minimum = 40 },
		})
		expect(#violations):toBe(3)
		expect(violations[1].subject):toBe "hub"
		expect(violations[1].other):toBe "near"
		expect(violations[1].actual):toBe(6)
		expect(violations[1].required):toBe(40)
		expect(violations[2].other):toBe "mid"
		expect(violations[3].subject):toBe "near"
	end)

	it("measures height only when asked and honors tolerance", function()
		local ids = { "hub", "near" }
		expect(#Placement.check(points, { { kind = "separation", ids = ids, minimum = 10 } })):toBe(1)
		expect(#Placement.check(points, { { kind = "separation", ids = ids, minimum = 10, space = "xyz" } })):toBe(0)
		expect(#Placement.check(points, { { kind = "separation", ids = ids, minimum = 6.001 } })):toBe(1)
		expect(#Placement.check(points, { { kind = "separation", ids = ids, minimum = 6.001, tolerance = 0.01 } })):toBe(
			0
		)
	end)

	it("names the nearest offender of a clearance and its edge", function()
		local violations = Placement.check(points, {
			{ kind = "clearance", subject = "hub", from = { "far", "mid", "near" }, minimum = 40 },
		})
		expect(#violations):toBe(1)
		expect(violations[1].other):toBe "near"
		expect(violations[1].actual):toBe(6)
		expect(#Placement.check(points, { { kind = "clearance", subject = "hub", from = { "mid" }, minimum = 30 } })):toBe(
			0
		)
		local strict = Placement.check(
			points,
			{ { kind = "clearance", subject = "hub", from = { "mid" }, minimum = 30, strict = true } }
		)
		expect(#strict):toBe(1)
	end)

	it("keeps a point within a radius of its anchor", function()
		expect(#Placement.check(points, { { kind = "within", subject = "near", anchor = "hub", radius = 6 } })):toBe(0)
		local violations =
			Placement.check(points, { { kind = "within", subject = "mid", anchor = "hub", radius = 25 } })
		expect(violations[1].actual):toBe(30)
		expect(violations[1].required):toBe(25)
		expect(violations[1].other):toBe "hub"
	end)

	it("keeps a point on a path corridor", function()
		local path = { { x = 0, y = 0, z = -5 }, { x = 100, y = 0, z = -5 } }
		expect(#Placement.check(points, { { kind = "path", subject = "hub", path = path, halfWidth = 5 } })):toBe(0)
		local violations = Placement.check(points, { { kind = "path", subject = "hub", path = path, halfWidth = 4 } })
		expect(violations[1].actual):toBe(5)
		expect(violations[1].other):toBe(nil)
	end)

	it("tags each violation with its constraint index", function()
		local violations = Placement.check(points, {
			{ kind = "within", subject = "near", anchor = "hub", radius = 6 },
			{ kind = "within", subject = "mid", anchor = "hub", radius = 1 },
			{ kind = "within", subject = "far", anchor = "hub", radius = 1 },
		})
		expect(#violations):toBe(2)
		expect(violations[1].index):toBe(2)
		expect(violations[2].index):toBe(3)
	end)

	it("refuses undeclared points, missing numbers and unknown kinds", function()
		expect(function()
			Placement.check(points, { { kind = "within", subject = "ghost", anchor = "hub", radius = 1 } })
		end):toThrow "not declared"
		expect(function()
			Placement.check(points, { { kind = "clearance", subject = "hub", from = { "mid" } } })
		end):toThrow "minimum"
		expect(function()
			Placement.check(points, { { kind = "within", subject = "hub", anchor = "mid", radius = math.huge } })
		end):toThrow "radius"
		expect(function()
			Placement.check(points, { { kind = "bogus" } })
		end):toThrow "unknown kind"
	end)

	it("is deterministic across repeated runs", function()
		local constraints: { Author.PlacementConstraint } = {
			{ kind = "separation", ids = { "hub", "near", "mid", "far" }, minimum = 50 },
		}
		expect(Placement.check(points, constraints)):toEqual(Placement.check(points, constraints))
	end)
end)

describe("Author.placement numeric and space refusals", function()
	local origin = { x = 0, y = 0, z = 0 }
	local nan = math.huge - math.huge

	it("refuses non-finite coordinates in a constraint's points", function()
		expect(function()
			Placement.check(
				{ a = { x = nan, y = 0, z = 0 }, b = origin },
				{ { kind = "within", subject = "a", anchor = "b", radius = 5 } }
			)
		end):toThrow "placement/non-finite-number"
		expect(function()
			Placement.check(
				{ a = origin, b = { x = 0, y = math.huge, z = 0 } },
				{ { kind = "clearance", subject = "a", from = { "b" }, minimum = 5 } }
			)
		end):toThrow "placement/non-finite-number"
		expect(function()
			Placement.check(
				{ a = origin },
				{ { kind = "path", subject = "a", path = { origin, { x = 1, y = 0, z = -math.huge } }, halfWidth = 1 } }
			)
		end):toThrow "placement/non-finite-number"
	end)

	it("refuses a non-finite or negative tolerance and threshold", function()
		local points = { a = origin, b = origin }
		for _, tolerance in { nan, math.huge } do
			expect(function()
				Placement.check(
					points,
					{ { kind = "separation", ids = { "a", "b" }, minimum = 100, tolerance = tolerance } }
				)
			end):toThrow "placement/non-finite-number"
		end
		expect(function()
			Placement.check(points, { { kind = "separation", ids = { "a", "b" }, minimum = 1, tolerance = -1 } })
		end):toThrow "placement/negative-number"
		expect(function()
			Placement.check(points, { { kind = "within", subject = "a", anchor = "b", radius = -1 } })
		end):toThrow "placement/negative-number"
		expect(function()
			Placement.check(points, { { kind = "clearance", subject = "a", from = { "b" }, minimum = -1 } })
		end):toThrow "placement/negative-number"
		expect(function()
			Placement.check(
				points,
				{ { kind = "path", subject = "a", path = { origin, { x = 1, y = 0, z = 0 } }, halfWidth = -1 } }
			)
		end):toThrow "placement/negative-number"
	end)

	it("refuses non-finite arguments to every measurement", function()
		local bad = { x = nan, y = 0, z = 0 }
		expect(function()
			Placement.distance(bad, origin)
		end):toThrow "placement/non-finite-number"
		expect(function()
			Placement.distanceToPath(bad, { origin, { x = 1, y = 0, z = 0 } })
		end):toThrow "placement/non-finite-number"
		expect(function()
			Placement.alongLateral(origin, origin, { x = math.huge, y = 0, z = 0 })
		end):toThrow "placement/non-finite-number"
		expect(function()
			Placement.nearest(origin, { bad }, function(item)
				return item
			end)
		end):toThrow "placement/non-finite-number"
		expect(function()
			Placement.ring(nan, 1)
		end):toThrow "placement/bad-ring"
		expect(function()
			Placement.ring(3, nan)
		end):toThrow "placement/non-finite-number"
		expect(function()
			Placement.ring(3, -1)
		end):toThrow "placement/negative-number"
	end)

	it("refuses a path constraint that asks for three-dimensional distance", function()
		local path = { origin, { x = 10, y = 0, z = 0 } }
		expect(function()
			Placement.check(
				{ a = { x = 5, y = 100, z = 0 } },
				{ { kind = "path", subject = "a", path = path, halfWidth = 1, space = "xyz" } }
			)
		end):toThrow "placement/unsupported-space"
		expect(function()
			Placement.distanceToPath({ x = 5, y = 100, z = 0 }, path, ("xyz" :: unknown) :: "xz")
		end):toThrow "placement/unsupported-space"
		expect(function()
			Placement.alongLateral({ x = 5, y = 100, z = 0 }, origin, path[2], ("xyz" :: unknown) :: "xz")
		end):toThrow "placement/unsupported-space"
	end)

	it("refuses an unknown space everywhere it is accepted", function()
		expect(function()
			Placement.distance(origin, origin, ("xy" :: unknown) :: Author.PlacementSpace)
		end):toThrow "placement/unknown-space"
		expect(function()
			Placement.check({ a = origin, b = origin }, {
				{
					kind = "within",
					subject = "a",
					anchor = "b",
					radius = 1,
					space = ("plane" :: unknown) :: Author.PlacementSpace,
				},
			})
		end):toThrow "placement/unknown-space"
		expect(function()
			Placement.check({ a = origin }, {
				{
					kind = "path",
					subject = "a",
					path = { origin, { x = 1, y = 0, z = 0 } },
					halfWidth = 1,
					space = ("plane" :: unknown) :: Author.PlacementSpace,
				},
			})
		end):toThrow "placement/unknown-space"
		expect(
			#Placement.check(
				{ a = origin, b = origin },
				{ { kind = "within", subject = "a", anchor = "b", radius = 1, space = "xz" } }
			)
		):toBe(0)
	end)
end)

describe("Author.placement.spread and pathPoint", function()
	it("starts a spread on its anchor and walks outward deterministically", function()
		local dx, dz = Placement.spread(1, 3.5)
		expect(dx):toBe(0)
		expect(dz):toBe(0)
		local x2, z2 = Placement.spread(2, 3.5)
		expect(math.abs(math.sqrt(x2 * x2 + z2 * z2) - 3.5) < 1e-9):toBe(true)
		local x5, z5 = Placement.spread(5, 2)
		expect(math.abs(math.sqrt(x5 * x5 + z5 * z5) - 4) < 1e-9):toBe(true)
		local again, againZ = Placement.spread(5, 2)
		expect(again):toBe(x5)
		expect(againZ):toBe(z5)
	end)

	it("refuses a bad ordinal or step", function()
		expect(function()
			Placement.spread(0, 3.5)
		end):toThrow "placement/bad-ordinal"
		expect(function()
			Placement.spread(1.5, 3.5)
		end):toThrow "placement/bad-ordinal"
		expect(function()
			Placement.spread(2, -1)
		end):toThrow "placement/negative-number"
	end)

	it("places a point along and beside a straight path, extending past its ends", function()
		local path = { { x = 10, y = 0, z = 10 }, { x = 10, y = 0, z = 30 } }
		local point = Placement.pathPoint(path, 5, 2, 7)
		expect(point):toEqual { x = 8, y = 7, z = 15 }
		expect(Placement.pathPoint(path, 25, 0, 0).z):toBe(35)
		expect(Placement.pathPoint(path, -5, 0, 0).z):toBe(5)
	end)

	it("follows the segment that holds the distance along a bent path", function()
		local path = { { x = 0, y = 0, z = 0 }, { x = 10, y = 0, z = 0 }, { x = 10, y = 0, z = 10 } }
		expect(Placement.pathPoint(path, 4, 0, 0).x):toBe(4)
		local bent = Placement.pathPoint(path, 14, 0, 0)
		expect(bent.x):toBe(10)
		expect(bent.z):toBe(4)
	end)

	it("refuses a short path and a doubled vertex", function()
		expect(function()
			Placement.pathPoint({ { x = 0, y = 0, z = 0 } }, 1, 0, 0)
		end):toThrow "placement/short-path"
		expect(function()
			Placement.pathPoint({ { x = 0, y = 0, z = 0 }, { x = 0, y = 5, z = 0 } }, 1, 0, 0)
		end):toThrow "placement/degenerate-segment"
	end)
end)

describe("Author.placement.resolve", function()
	local anchors = {
		hub = { x = 100, y = 4, z = 200 },
		gate = { x = 140, y = 6, z = 200 },
	}
	local routes = { main = { { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 100 } } }

	local function entries(): { Author.PlacementRule }
		return {
			{ id = "camp", kind = "offset", from = "hub", dx = 5, dz = -3 },
			{ id = "well", kind = "offset", from = "camp", dx = 1, dy = 2, dz = 1 },
			{ id = "fixed", kind = "absolute", x = 7, z = 9 },
			{ id = "road", kind = "route", route = "main", along = 40, lateral = 3 },
			{ id = "crowd", kind = "spread", from = "gate", ordinal = 3 },
		}
	end

	it("resolves absolute, offset, route and spread rules against anchors", function()
		local placed =
			Placement.resolve { anchors = anchors, routes = routes, spreadDistance = 3.5, entries = entries() }
		expect(placed.camp):toEqual { x = 105, y = 4, z = 197 }
		expect(placed.well):toEqual { x = 106, y = 6, z = 198 }
		expect(placed.fixed):toEqual { x = 7, y = 0, z = 9 }
		expect(placed.road):toEqual { x = -3, y = 0, z = 40 }
		local dx, dz = Placement.spread(3, 3.5)
		expect(placed.crowd):toEqual { x = 140 + dx, y = 6, z = 200 + dz }
	end)

	it("gives the same positions for any rule order and any repeat", function()
		local forward =
			Placement.resolve { anchors = anchors, routes = routes, spreadDistance = 3.5, entries = entries() }
		local reversed = entries()
		local count = #reversed
		for index = 1, count // 2 do
			reversed[index], reversed[count - index + 1] = reversed[count - index + 1], reversed[index]
		end
		local backward =
			Placement.resolve { anchors = anchors, routes = routes, spreadDistance = 3.5, entries = reversed }
		expect(backward):toEqual(forward)
		expect(Placement.resolve { anchors = anchors, routes = routes, spreadDistance = 3.5, entries = entries() }):toEqual(
			forward
		)
	end)

	it("does not touch its inputs", function()
		local input = entries()
		Placement.resolve { anchors = anchors, routes = routes, spreadDistance = 3.5, entries = input }
		expect(input):toEqual(entries())
		expect(anchors.hub):toEqual { x = 100, y = 4, z = 200 }
	end)

	it("refuses an unknown anchor, route and rule kind", function()
		expect(function()
			Placement.resolve {
				anchors = anchors,
				entries = { { id = "a", kind = "offset", from = "nowhere", dx = 0, dz = 0 } },
			}
		end):toThrow "placement/unknown-anchor"
		expect(function()
			Placement.resolve { entries = { { id = "a", kind = "route", route = "none", along = 1, lateral = 0 } } }
		end):toThrow "placement/unknown-route"
		expect(function()
			Placement.resolve { entries = { { id = "a", kind = "bogus" } } }
		end):toThrow "placement/unknown-rule"
	end)

	it("refuses a cycle and names it", function()
		expect(function()
			Placement.resolve {
				entries = {
					{ id = "a", kind = "offset", from = "b", dx = 1, dz = 0 },
					{ id = "b", kind = "offset", from = "c", dx = 1, dz = 0 },
					{ id = "c", kind = "offset", from = "a", dx = 1, dz = 0 },
				},
			}
		end):toThrow "a -> b -> c -> a"
		expect(function()
			Placement.resolve { entries = { { id = "a", kind = "offset", from = "a", dx = 1, dz = 0 } } }
		end):toThrow "placement/cyclic-reference"
	end)

	it("refuses duplicate ids, shadowed anchors and non-finite numbers", function()
		expect(function()
			Placement.resolve {
				entries = {
					{ id = "a", kind = "absolute", x = 0, z = 0 },
					{ id = "a", kind = "absolute", x = 1, z = 1 },
				},
			}
		end):toThrow "placement/duplicate-id"
		expect(function()
			Placement.resolve { anchors = anchors, entries = { { id = "hub", kind = "absolute", x = 0, z = 0 } } }
		end):toThrow "placement/duplicate-id"
		expect(function()
			Placement.resolve { entries = { { id = "a", kind = "absolute", x = math.huge, z = 0 } } }
		end):toThrow "placement/non-finite-number"
		expect(function()
			Placement.resolve {
				anchors = { hub = { x = 0, y = 0, z = math.huge - math.huge } },
				entries = { { id = "a", kind = "offset", from = "hub", dx = 0, dz = 0 } },
			}
		end):toThrow "placement/non-finite-number"
		expect(function()
			Placement.resolve {
				anchors = anchors,
				entries = { { id = "a", kind = "spread", from = "hub", ordinal = 0 } },
				spreadDistance = 3,
			}
		end):toThrow "placement/bad-ordinal"
		expect(function()
			Placement.resolve {
				anchors = anchors,
				entries = { { id = "a", kind = "spread", from = "hub", ordinal = 1 } },
			}
		end):toThrow "placement/non-finite-number"
	end)
end)

describe("Author.placement authoring errors", function()
	local origin = { x = 0, y = 0, z = 0 }
	local points = { a = origin, b = { x = 1, y = 0, z = 0 } }

	it("refuses constraints that cannot constrain anything", function()
		local function refused(constraint: unknown, field: string)
			local ok, message = pcall(Placement.check, points, { constraint :: Author.PlacementConstraint })
			expect(ok):toBe(false)
			expect(tostring(message)):toContain "placement/bad-constraint"
			expect(tostring(message)):toContain "constraint 1"
			expect(tostring(message)):toContain(field)
		end
		refused({ kind = "separation", minimum = 1 }, "ids")
		refused({ kind = "separation", ids = { "a" }, minimum = 1 }, "ids")
		refused({ kind = "clearance", subject = "a", minimum = 1 }, "from")
		refused({ kind = "clearance", subject = "a", from = {}, minimum = 1 }, "from")
		refused({ kind = "clearance", minimum = 1, from = { "a" } }, "subject")
		refused({ kind = "within", subject = "a", radius = 1 }, "anchor")
		refused({ kind = "within", anchor = "a", radius = 1 }, "subject")
		refused({ kind = "path", subject = "a", halfWidth = 1 }, "path")
		refused({ kind = "path", subject = "a", halfWidth = 1, path = "road" }, "path")
	end)

	it("refuses non-table points and constraints", function()
		expect(function()
			Placement.check(points, ("none" :: unknown) :: { Author.PlacementConstraint })
		end):toThrow "placement/bad-constraint"
		expect(function()
			Placement.check((nil :: unknown) :: { [string]: Author.PlacementPosition }, {})
		end):toThrow "placement/bad-constraint"
		expect(function()
			Placement.check(points, { ("x" :: unknown) :: Author.PlacementConstraint })
		end):toThrow "placement/bad-constraint"
	end)

	it("refuses a degenerate segment however short the walk", function()
		local path = { origin, { x = 10, y = 0, z = 0 }, { x = 10, y = 5, z = 0 } }
		expect(function()
			Placement.pathPoint(path, 1, 0, 0)
		end):toThrow "placement/degenerate-segment"
		expect(function()
			Placement.pathPoint(path, 50, 0, 0)
		end):toThrow "placement/degenerate-segment"
	end)

	it("refuses a malformed resolve spec and names spreadDistance", function()
		expect(function()
			Placement.resolve((nil :: unknown) :: Author.PlacementResolveSpec)
		end):toThrow "placement/bad-rule"
		expect(function()
			Placement.resolve(({ entries = "x" } :: unknown) :: Author.PlacementResolveSpec)
		end):toThrow "placement/bad-rule"
		expect(function()
			Placement.resolve {
				anchors = { hub = origin },
				entries = { { id = "a", kind = "spread", from = "hub", ordinal = 1 } },
			}
		end):toThrow "spreadDistance"
	end)

	it("returns entries only and defaults rule heights to zero", function()
		local placed = Placement.resolve {
			anchors = { hub = { x = 1, y = 9, z = 1 } },
			entries = { { id = "a", kind = "absolute", x = 2, z = 2 } },
		}
		expect(placed):toEqual { a = { x = 2, y = 0, z = 2 } }
	end)
end)

return nil
