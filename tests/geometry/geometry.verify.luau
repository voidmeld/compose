--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local geometry = Compose.geometry

local function rect(left: number, top: number, width: number, height: number): Compose.GeometryFrame
	return { left = left, top = top, right = left + width, bottom = top + height, width = width, height = height }
end

describe("geometry safe area", function()
	it("subtracts insets and a margin on every side", function()
		local area = geometry.safeArea(
			{ width = 1000, height = 600 },
			{ left = 40, top = 30, right = 20, bottom = 10 },
			8
		)
		expect(area):toEqual(rect(48, 38, 1000 - 40 - 20 - 16, 600 - 30 - 10 - 16))
	end)

	it("takes the whole viewport without insets or margin", function()
		expect(geometry.safeArea { width = 320, height = 480 }):toEqual(rect(0, 0, 320, 480))
	end)

	it("clamps an overflowing inset to a zero extent instead of going negative", function()
		local area = geometry.safeArea({ width = 100, height = 100 }, { left = 80, right = 80, top = 120 }, 4)
		expect(area.width):toBe(0)
		expect(area.height):toBe(0)
		expect(area.left):toBe(84)
		expect(area.right):toBe(84)
	end)

	it("refuses unusable viewports, insets and margins", function()
		expect(function()
			geometry.safeArea { width = -1, height = 10 }
		end):toThrow "geometry/invalid-number"
		expect(function()
			geometry.safeArea { width = math.huge - math.huge, height = 10 }
		end):toThrow "geometry/invalid-number"
		expect(function()
			geometry.safeArea({ width = 10, height = 10 }, { left = -1 })
		end):toThrow "geometry/invalid-number"
		expect(function()
			geometry.safeArea({ width = 10, height = 10 }, nil, math.huge)
		end):toThrow "geometry/invalid-number"
		expect(function()
			geometry.safeArea({ width = 10, height = 10 }, (3 :: unknown) :: Compose.GeometryInsets)
		end):toThrow "geometry/invalid-insets"
		expect(function()
			geometry.safeArea((nil :: unknown) :: Compose.GeometrySize)
		end):toThrow "geometry/invalid-size"
	end)
end)

describe("geometry fit", function()
	local available = rect(10, 20, 400, 300)

	it("centers a panel that fits", function()
		expect(geometry.fit(available, { width = 200, height = 100 })):toEqual(rect(110, 120, 200, 100))
	end)

	it("never overflows the available rect", function()
		local frame = geometry.fit(available, { width = 900, height = 900 })
		expect(frame):toEqual(available)
	end)

	it("applies the maximum before the available room", function()
		local frame = geometry.fit(available, { width = 900, height = 900 }, { max = { width = 360, height = 250 } })
		expect(frame):toEqual(rect(30, 45, 360, 250))
	end)

	it("raises a small panel to the minimum but not past the available room", function()
		local raised = geometry.fit(available, { width = 10, height = 10 }, { min = { width = 120, height = 80 } })
		expect(raised.width):toBe(120)
		expect(raised.height):toBe(80)
		local capped = geometry.fit(available, { width = 10, height = 10 }, { min = { width = 500, height = 80 } })
		expect(capped.width):toBe(400)
	end)

	it("anchors inside the available rect", function()
		local desired = { width = 100, height = 50 }
		expect(geometry.fit(available, desired, { anchor = { x = 0, y = 0 } })):toEqual(rect(10, 20, 100, 50))
		expect(geometry.fit(available, desired, { anchor = { x = 1, y = 1 } })):toEqual(rect(310, 270, 100, 50))
		expect(geometry.fit(available, desired, { anchor = { x = 1, y = 0.5 } })):toEqual(rect(310, 145, 100, 50))
	end)

	it("fits into a zero-extent area as a zero-extent frame", function()
		local frame = geometry.fit(rect(5, 6, 0, 0), { width = 50, height = 50 })
		expect(frame):toEqual(rect(5, 6, 0, 0))
	end)

	it("fits a safe area result directly", function()
		local area = geometry.safeArea({ width = 800, height = 400 }, { top = 40 }, 10)
		local frame = geometry.fit(area, { width = 300, height = 1000 }, { max = { width = 600, height = 300 } })
		expect(frame):toEqual(rect(250, 70, 300, 300))
	end)

	it("refuses degenerate rects, sizes, limits and anchors", function()
		expect(function()
			geometry.fit({ left = 0, top = 0, right = -1, bottom = 5 }, { width = 1, height = 1 })
		end):toThrow "geometry/invalid-rect"
		expect(function()
			geometry.fit({ left = 0, top = 0, right = math.huge - math.huge, bottom = 5 }, { width = 1, height = 1 })
		end):toThrow "geometry/invalid-number"
		expect(function()
			geometry.fit(
				({ left = 0, top = 0, right = 5 } :: unknown) :: Compose.GeometryBounds,
				{ width = 1, height = 1 }
			)
		end):toThrow "geometry/invalid-number"
		expect(function()
			geometry.fit((nil :: unknown) :: Compose.GeometryBounds, { width = 1, height = 1 })
		end):toThrow "geometry/invalid-rect"
		expect(function()
			geometry.fit(available, { width = -1, height = 1 })
		end):toThrow "geometry/invalid-number"
		expect(function()
			geometry.fit(available, (nil :: unknown) :: Compose.GeometrySize)
		end):toThrow "geometry/invalid-size"
		expect(function()
			geometry.fit(
				available,
				{ width = 1, height = 1 },
				{ min = { width = 9, height = 1 }, max = { width = 5, height = 1 } }
			)
		end):toThrow "geometry/invalid-limits"
		expect(function()
			geometry.fit(available, { width = 1, height = 1 }, { anchor = { x = 2, y = 0 } })
		end):toThrow "geometry/invalid-anchor"
		expect(function()
			geometry.fit(available, { width = 1, height = 1 }, { anchor = { x = math.huge - math.huge, y = 0 } })
		end):toThrow "geometry/invalid-anchor"
	end)
end)

describe("geometry overlap and clear placement", function()
	it("treats touching edges as clear and shared area as overlap", function()
		expect(geometry.overlaps(rect(0, 0, 10, 10), rect(10, 0, 10, 10))):toBe(false)
		expect(geometry.overlaps(rect(0, 0, 10, 10), rect(9, 9, 10, 10))):toBe(true)
		expect(geometry.overlaps(rect(0, 0, 10, 10), rect(2, 2, 2, 2))):toBe(true)
		expect(geometry.overlaps(rect(0, 0, 0, 0), rect(0, 0, 10, 10))):toBe(false)
	end)

	it("reports containment including shared edges", function()
		expect(geometry.contains(rect(0, 0, 10, 10), rect(0, 0, 10, 10))):toBe(true)
		expect(geometry.contains(rect(0, 0, 10, 10), rect(1, 1, 9, 9))):toBe(true)
		expect(geometry.contains(rect(0, 0, 10, 10), rect(1, 1, 10, 9))):toBe(false)
	end)

	it("returns the first candidate inside bounds and clear of every reserved region", function()
		local within = rect(0, 0, 100, 100)
		local reserved = { rect(0, 0, 50, 50), rect(60, 60, 40, 40) }
		local candidates = {
			rect(10, 10, 20, 20),
			rect(-5, 70, 20, 20),
			rect(55, 55, 10, 10),
			rect(55, 5, 20, 20),
			rect(70, 5, 20, 20),
		}
		local chosen, index = geometry.firstClear(candidates, { within = within, reserved = reserved })
		expect(index):toBe(4)
		expect(chosen == candidates[4]):toBe(true)
	end)

	it("keeps preference order rather than choosing the nearest", function()
		local candidates = { rect(0, 0, 10, 10), rect(20, 0, 10, 10) }
		local _, index = geometry.firstClear(candidates, { reserved = { rect(100, 100, 10, 10) } })
		expect(index):toBe(1)
	end)

	it("returns nothing when every candidate is blocked, so the caller decides the fallback", function()
		local candidates = { rect(0, 0, 10, 10), rect(20, 0, 10, 10) }
		local chosen, index = geometry.firstClear(candidates, { reserved = { rect(0, 0, 100, 100) } })
		expect(chosen):toBeNil()
		expect(index):toBeNil()
		local empty = geometry.firstClear({}, nil)
		expect(empty):toBeNil()
	end)

	it("accepts everything when no bounds or reserved regions are given", function()
		local candidates = { rect(-50, -50, 10, 10) }
		local _, index = geometry.firstClear(candidates)
		expect(index):toBe(1)
	end)

	it("refuses malformed candidates, bounds and reserved regions", function()
		expect(function()
			geometry.firstClear((nil :: unknown) :: { Compose.GeometryBounds })
		end):toThrow "geometry/invalid-candidates"
		expect(function()
			geometry.firstClear { { left = 0, top = 0, right = 1 } }
		end):toThrow "geometry/invalid-number"
		expect(function()
			geometry.firstClear({ rect(0, 0, 1, 1) }, { reserved = { { left = 0, top = 0, right = -3, bottom = 1 } } })
		end):toThrow "geometry/invalid-rect"
		expect(function()
			geometry.firstClear({ rect(0, 0, 1, 1) }, { within = 5 })
		end):toThrow "geometry/invalid-rect"
		expect(function()
			geometry.overlaps(rect(0, 0, 1, 1), (nil :: unknown) :: Compose.GeometryBounds)
		end):toThrow "geometry/invalid-rect"
	end)
end)

return nil
