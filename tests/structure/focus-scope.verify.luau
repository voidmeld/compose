--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Item = { id: string, disabled: boolean, x: number?, y: number? }

describe("focus scope", function()
	it("navigates stable enabled keys and wraps only when requested", function()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local items = Compose.cell({
			{ id = "one", disabled = false },
			{ id = "two", disabled = true },
			{ id = "three", disabled = false },
		} :: { Item })
		local scope = Compose.withOwner(owner, function()
			return Compose.createFocusScope {
				from = items,
				key = function(item: Item)
					return item.id
				end,
				disabled = function(item: Item)
					return item.disabled
				end,
				wrap = true,
			}
		end)
		reactor:settle()
		expect(scope.next()):toBe "one"
		expect(scope.next()):toBe "three"
		expect(scope.next()):toBe "one"
		expect(scope.focus "two"):toBe(false)
		expect(scope.isFocused("one"):peek()):toBe(true)
		owner.dispose()
	end)

	it("clears a removed key and makes disposed controls inert", function()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local items = Compose.cell({ { id = "one", disabled = false } } :: { Item })
		local scope = Compose.withOwner(owner, function()
			return Compose.createFocusScope {
				from = items,
				key = function(item: Item)
					return item.id
				end,
			}
		end)
		reactor:settle()
		scope.focus "one"
		items:set {}
		reactor:settle()
		expect(scope.current:peek()):toBeNil()
		owner.dispose()
		expect(scope.next()):toBeNil()
	end)

	it("moves directionally by geometry without coupling to a host", function()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local items = Compose.cell({
			{ id = "center", disabled = false, x = 0, y = 0 },
			{ id = "right", disabled = false, x = 10, y = 0 },
			{ id = "down", disabled = false, x = 0, y = 10 },
		} :: { Item })
		local scope = Compose.withOwner(owner, function()
			return Compose.createFocusScope {
				from = items,
				key = function(item: Item)
					return item.id
				end,
				position = function(item: Item)
					return item.x or 0, item.y or 0
				end,
			}
		end)
		reactor:settle()
		scope.focus "center"
		expect(scope.move "right"):toBe "right"
		scope.focus "center"
		expect(scope.move "down"):toBe "down"
		owner.dispose()
	end)

	it("rejects non-finite geometry and unwinds its owner", function()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local items = Compose.cell({ { id = "bad", disabled = false } } :: { Item })
		expect(function()
			Compose.withOwner(owner, function()
				Compose.createFocusScope {
					from = items,
					key = function(item: Item)
						return item.id
					end,
					position = function()
						return math.huge, 0
					end,
				}
			end)
		end):toThrow "finite numbers"
		owner.dispose()
	end)
end)

describe("focus neighbour", function()
	local function r(x: number, y: number, width: number, height: number): Compose.FocusRect
		return { x = x, y = y, width = width, height = height }
	end

	it("prefers an in-beam candidate by gap over a nearer out-of-beam one", function()
		expect(Compose.focusNeighbor(r(300, 600, 600, 44), { r(100, 520, 44, 44), r(500, 200, 300, 44) }, "up")):toBe(2)
	end)

	it("ranks in-beam candidates by leading-edge gap before centre offset", function()
		expect(
			Compose.focusNeighbor(
				r(17, 700, 687, 44),
				{ r(71, 272, 633, 44), r(164, 402, 392, 44), r(17, 480, 44, 190) },
				"up"
			)
		):toBe(3)
	end)

	it("falls back to the half-plane and ignores candidates behind or overlapping", function()
		expect(Compose.focusNeighbor(r(100, 100, 100, 44), { r(400, 400, 50, 50) }, "down")):toBe(1)
		expect(Compose.focusNeighbor(r(100, 100, 100, 44), { r(100, 0, 100, 44) }, "down")):toBeNil()
		expect(Compose.focusNeighbor(r(100, 100, 100, 44), { r(120, 110, 20, 20) }, "down")):toBeNil()
	end)

	it("counts a candidate as ahead when it starts past the centre and ends past the edge", function()
		local tab = r(850.5, 59, 68.5, 44)
		expect(Compose.focusNeighbor(tab, { r(886.5, 108, 71, 44) }, "right")):toBe(1)
		expect(Compose.focusNeighbor(tab, { r(883, 108, 71, 44) }, "right")):toBeNil()
		local row = r(16, 809, 741, 44)
		expect(Compose.focusNeighbor(row, { r(511.67, 605, 242.33, 44) }, "right")):toBeNil()
	end)

	it("out of the beam, a candidate within 45 degrees ranks by cross offset, even when much farther", function()
		expect(Compose.focusNeighbor(r(100, 500, 100, 44), { r(430, 250, 40, 44), r(1030, 200, 40, 44) }, "right")):toBe(
			2
		)
		local from = r(100, 400, 100, 44)
		expect(Compose.focusNeighbor(from, { r(520, 100, 40, 40), r(1030, 85, 40, 40) }, "right")):toBe(1)
		expect(Compose.focusNeighbor(from, { r(460, 100, 40, 40), r(1030, 85, 40, 40) }, "right")):toBe(2)
	end)

	it("out of the beam, the nearer of two equally offset candidates wins", function()
		expect(Compose.focusNeighbor(r(161.5, 8, 101.5, 44), { r(623, 56, 296, 50), r(629, 59, 68, 44) }, "right")):toBe(
			2
		)
	end)

	it("works on every axis", function()
		local from = r(100, 100, 100, 100)
		local candidates = { r(300, 120, 50, 50), r(-100, 120, 50, 50), r(120, 300, 50, 50), r(120, -100, 50, 50) }
		expect(Compose.focusNeighbor(from, candidates, "right")):toBe(1)
		expect(Compose.focusNeighbor(from, candidates, "left")):toBe(2)
		expect(Compose.focusNeighbor(from, candidates, "down")):toBe(3)
		expect(Compose.focusNeighbor(from, candidates, "up")):toBe(4)
	end)

	it("breaks equal gaps by centre offset and exact ties by array order", function()
		local from = r(0, 0, 100, 100)
		expect(Compose.focusNeighbor(from, { r(120, 80, 20, 20), r(120, 40, 20, 20) }, "right")):toBe(2)
		expect(Compose.focusNeighbor(from, { r(120, 40, 20, 20), r(120, 40, 20, 20) }, "right")):toBe(1)
	end)

	it("excludes self, empty populations and the exact centre boundary", function()
		local from = r(0, 0, 100, 100)
		expect(Compose.focusNeighbor(from, {}, "right")):toBeNil()
		expect(Compose.focusNeighbor(from, { from }, "right")):toBeNil()
		expect(Compose.focusNeighbor(from, { r(50, 0, 100, 100) }, "right")):toBeNil()
		expect(Compose.focusNeighbor(from, { r(51, 0, 100, 100) }, "right")):toBe(1)
	end)

	it("rejects an unknown direction instead of selecting to the left", function()
		expect(function()
			Compose.focusNeighbor(r(0, 0, 100, 100), {}, ("diagonal" :: unknown) :: Compose.FocusDirection)
		end):toThrow "focus-neighbor/unknown-direction"
	end)
end)

return nil
