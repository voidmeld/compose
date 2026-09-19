--!strict

local Relevance = require "../../src/core/collection/relevance"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local TIERS: { Relevance.Tier } = {
	{ name = "full", radius = 80 },
	{ name = "simplified", radius = 180 },
	{ name = "marker", radius = 300 },
}

describe("relevance", function()
	describe("tier selection", function()
		it("picks the nearest tier that contains the entity", function()
			expect(Relevance.tierFor(10, nil, TIERS, 0, 1)):toBe(1)
			expect(Relevance.tierFor(120, nil, TIERS, 0, 1)):toBe(2)
			expect(Relevance.tierFor(250, nil, TIERS, 0, 1)):toBe(3)
		end)

		it("retains nothing past the outermost radius", function()
			expect(Relevance.tierFor(301, nil, TIERS, 0, 1)):toBeNil()
		end)

		it("includes an entity exactly on a radius", function()
			expect(Relevance.tierFor(80, nil, TIERS, 0, 1)):toBe(1)
		end)
	end)

	describe("hysteresis", function()
		it("holds an entity at its current tier through the band", function()
			expect(Relevance.tierFor(90, 1, TIERS, 24, 1)):toBe(1)
		end)

		it("lets it go once the band is passed", function()
			expect(Relevance.tierFor(105, 1, TIERS, 24, 1)):toBe(2)
		end)

		it("does not delay a promotion", function()
			expect(Relevance.tierFor(80, 2, TIERS, 24, 1)):toBe(1)
			expect(Relevance.tierFor(81, 2, TIERS, 24, 1)):toBe(2)
		end)

		it("stops an entity oscillating on a boundary from changing tier at all", function()
			local current: number? = Relevance.tierFor(79, nil, TIERS, 24, 1)
			expect(current):toBe(1)
			for _ = 1, 8 do
				current = Relevance.tierFor(81, current, TIERS, 24, 1)
				expect(current):toBe(1)
				current = Relevance.tierFor(79, current, TIERS, 24, 1)
				expect(current):toBe(1)
			end
		end)

		it("keeps a retained entity retained through the outer band", function()
			expect(Relevance.tierFor(310, 3, TIERS, 24, 1)):toBe(3)
			expect(Relevance.tierFor(330, 3, TIERS, 24, 1)):toBeNil()
		end)
	end)

	describe("importance", function()
		it("scales every radius for one entity", function()
			expect(Relevance.tierFor(160, nil, TIERS, 0, 1)):toBe(2)
			expect(Relevance.tierFor(160, nil, TIERS, 0, 2)):toBe(1)
		end)

		it("keeps an important entity relevant past the outermost radius", function()
			expect(Relevance.tierFor(400, nil, TIERS, 0, 1)):toBeNil()
			expect(Relevance.tierFor(400, nil, TIERS, 0, 2)):toBe(3)
		end)
	end)

	describe("pinning", function()
		it("retains an entity distance would have dropped", function()
			expect(Relevance.pinnedTier(5000, nil, TIERS, 0, 1)):toBe(3)
		end)

		it("still gives it the tier its distance earns", function()
			expect(Relevance.pinnedTier(10, nil, TIERS, 0, 1)):toBe(1)
			expect(Relevance.pinnedTier(200, nil, TIERS, 0, 1)):toBe(3)
		end)
	end)

	describe("declaration errors", function()
		it("rejects an empty tier list", function()
			expect(function()
				Relevance.checkTiers({}, "SpatialCollection")
			end):toThrow "collection/no%-tiers"
		end)

		it("rejects tiers that are not ordered outwards", function()
			expect(function()
				Relevance.checkTiers({
					{ name = "far", radius = 300 },
					{ name = "near", radius = 80 },
				}, "SpatialCollection")
			end):toThrow "collection/tiers%-unordered"
		end)

		it("rejects a tier with no name", function()
			expect(function()
				Relevance.checkTiers({ { name = 4, radius = 10 } :: any }, "SpatialCollection")
			end):toThrow "collection/tier%-unnamed"
		end)

		it("rejects a tier with no usable radius", function()
			expect(function()
				Relevance.checkTiers({ { name = "full", radius = "near" } :: any }, "SpatialCollection")
			end):toThrow "collection/tier%-radius"
		end)
	end)
end)

return nil
