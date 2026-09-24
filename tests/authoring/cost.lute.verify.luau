--!strict

local fs = require "@std/fs"
local time = require "@lute/time"

local Author = require "../../authoring"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local SAMPLES = 3
local WARMUP = 1
local N = 10000

local function sequence(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(): number
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
end

local SEED = 20260830
local ROLES = { "npc", "prop", "quest", "loot" }
local TAGS = { "common", "rare", "epic" }
local ZONE_COUNT = 24

local function zoneEntries(): { Author.Entry }
	local entries = table.create(ZONE_COUNT) :: { Author.Entry }
	for index = 1, ZONE_COUNT do
		entries[index] = { id = ("zone.%04d"):format(index), name = ("Zone %d"):format(index) }
	end
	return entries
end

local function propEntries(count: number, collideIds: boolean?): { Author.Entry }
	local next = sequence(SEED)
	local entries = table.create(count) :: { Author.Entry }
	for index = 1, count do
		local role = ROLES[(index % #ROLES) + 1]
		local zoneIndex = ((index - 1) % ZONE_COUNT) + 1
		local tag = TAGS[(index % #TAGS) + 1]
		local id = if collideIds == true then "npc.z01.e00001" else ("%s.z%02d.e%05d"):format(role, zoneIndex, index)
		entries[index] = {
			id = id,
			role = role,
			model = ("Model_%04d"):format(math.floor(next() * 9999)),
			zone = ("zone.%04d"):format(zoneIndex),
			tag = tag,
		}
	end
	return entries
end

local ATTRIBUTE_MAPPING: Author.AttributeMapping = {
	{ field = "id", attribute = "Id" },
	{ field = "role", attribute = "Role" },
	{ field = "model", attribute = "Model" },
	{ field = "zone", attribute = "Zone" },
	{ field = "tag", attribute = "Tag" },
}

local function rules(zones: Author.EntrySet): Author.Rules
	local refs: { Author.RefRule } = {
		{ field = "zone", into = zones },
		{ field = "tag", oneOf = TAGS },
	}
	return {
		idPattern = "^%l+%.%l%w*%.%l%w*$",
		unique = true,
		required = { "model", "role" },
		refs = refs,
	}
end

local CALIBRATION_SEED = 20260905
local CALIBRATION_ITERATIONS = 200000

local function calibrationBaseline(): number
	local spin = sequence(CALIBRATION_SEED)
	local accumulator = 0
	local started = time.now()
	for _ = 1, CALIBRATION_ITERATIONS do
		accumulator += spin()
	end
	local elapsed = time.since(started)
	assert(accumulator > 0, "calibration spin produced no output")
	return elapsed
end

local function medianRatio(body: () -> ()): number
	local ratios = {}
	for round = 1, SAMPLES + WARMUP do
		local before = calibrationBaseline()
		local started = time.now()
		body()
		local elapsed = time.since(started)
		local after = calibrationBaseline()
		if round > WARMUP then
			ratios[#ratios + 1] = elapsed / ((before + after) / 2)
		end
	end
	table.sort(ratios)
	return ratios[(#ratios + 1) // 2]
end

local RATIO_CEILING_SET = 0.4
local RATIO_CEILING_VALIDATE = 6
local RATIO_CEILING_DIGEST = 120
local RATIO_CEILING_COVERAGE = 10
local RATIO_CEILING_ATTRIBUTE_PLAN = 5

local RATIO_CEILING_REGISTRY_MODULE = 40

local RATIO_CEILING_VALIDATE_PATHOLOGICAL = 8

describe("authoring bake-time cost", function()
	local zones = Author.set { name = "zones", idKey = "id", entries = zoneEntries() }
	local rawEntries = propEntries(N)
	local propsSet = Author.set { name = "props", idKey = "id", entries = rawEntries }
	local RULES = rules(zones)

	it(("Author.set stays proportionate to a calibrated baseline at %d entries"):format(N), function()
		local ratio = medianRatio(function()
			local set = Author.set { name = "props", idKey = "id", entries = rawEntries }
			assert(#set.entries == N, "set did not retain every entry")
		end)
		expect(ratio):toBeLessThan(RATIO_CEILING_SET)
	end)

	it(("Author.validate stays proportionate to a calibrated baseline at %d entries"):format(N), function()
		local ratio = medianRatio(function()
			local ok, violations = Author.validate(propsSet, RULES)
			assert(ok and #violations == 0, "clean fixture produced violations")
		end)
		expect(ratio):toBeLessThan(RATIO_CEILING_VALIDATE)
	end)

	it(("Author.digest stays proportionate to a calibrated baseline at %d entries"):format(N), function()
		local ratio = medianRatio(function()
			assert(#Author.digest(propsSet) == 16, "digest did not produce 16 hex characters")
		end)
		expect(ratio):toBeLessThan(RATIO_CEILING_DIGEST)
	end)

	it(("Author.coverage stays proportionate to a calibrated baseline at %d entries"):format(N), function()
		local keys = table.create(N) :: { string }
		for _, entry in rawEntries do
			keys[#keys + 1] = propsSet:idOf(entry)
		end
		local ratio = medianRatio(function()
			local report = Author.coverage(propsSet, keys)
			assert(#report.missingIds == 0, "coverage fixture was not clean")
		end)
		expect(ratio):toBeLessThan(RATIO_CEILING_COVERAGE)
	end)

	it(("Author.bake.attributePlan stays proportionate to a calibrated baseline over %d entries"):format(N), function()
		local ratio = medianRatio(function()
			local total = 0
			for _, entry in propsSet.entries do
				total += #Author.bake.attributePlan(entry, ATTRIBUTE_MAPPING)
			end
			assert(total == N * #ATTRIBUTE_MAPPING, "attribute plan did not emit every mapped field")
		end)
		expect(ratio):toBeLessThan(RATIO_CEILING_ATTRIBUTE_PLAN)
	end)

	it("Author.bake.registryModule stays proportionate to a calibrated baseline at 1,000 entries", function()
		local count = 1000
		local smallSet = Author.set { name = "props", idKey = "id", entries = propEntries(count) }
		local scratch = "build/authoring-cost-spec"
		fs.createDirectory(scratch, { makeParents = true })
		local outPath = scratch .. "/registry.luau"

		local ratio = medianRatio(function()
			local source = Author.bake.registryModule({
				name = "PropRegistry",
				set = smallSet,
				mapping = ATTRIBUTE_MAPPING,
			}, outPath)
			assert(#source > 0, "registryModule produced no source")
		end)
		expect(ratio):toBeLessThan(RATIO_CEILING_REGISTRY_MODULE)

		fs.remove(outPath)
	end)

	it(
		"stays proportionate to a calibrated baseline when every id collides against a zero-entry refs target",
		function()
			local emptyZones = Author.set { name = "zones", idKey = "id", entries = {} }
			local pathological = Author.set { name = "props", idKey = "id", entries = propEntries(N, true) }
			local pathologicalRules = rules(emptyZones)

			local ratio = medianRatio(function()
				local ok, violations = Author.validate(pathological, pathologicalRules)
				assert(not ok and #violations > 0, "pathological fixture produced no violations")
			end)
			expect(ratio):toBeLessThan(RATIO_CEILING_VALIDATE_PATHOLOGICAL)
		end
	)
end)

return nil
