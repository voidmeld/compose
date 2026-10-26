--!strict

local Test = require "../harness"
local Benchmark = require "../../.lute/dependencies/verify/src/benchmark"
local process = require "@std/process"
local Suites = require "../../bench/suites"
local Paired = require "../../bench/paired"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function stored(timing: number, memory: number): Benchmark.Stored
	return {
		schemaVersion = 1,
		name = "paired-policy",
		measurements = {
			{ name = "scene/compose", unit = "microseconds", environment = "test", samples = { timing } },
			{ name = "scene/memory/mounted", unit = "KiB", environment = "retained", samples = { 1000 + memory } },
			{ name = "scene/memory/teardown", unit = "KiB", environment = "retained", samples = { memory } },
		},
	}
end

describe("retained performance", function()
	it("counterbalanced rounds preserve the complete sample and calibration budgets", function()
		for _, total in { 12, 16, 20, 25, 30, 31, 32 } do
			local first, second = 0, 0
			for round = 1, 3 do
				first += Paired.budget(total, round)
				second += Paired.budget(total, round + 3)
			end
			expect(first):toBe(total)
			expect(second):toBe(total)
		end
		local original = Suites.entries({ suite = "workloads", filter = "mount-dispose" })[1].collection
		local originalSamples = original.benchmarks[1].samples
		local samples, calibration, warmup = 0, 0, 0
		for round = 1, 3 do
			local part = Paired.collection(original, round)
			samples += part.benchmarks[1].samples
			calibration += part.yardstick.samples
			warmup += part.yardstick.warmup or 0
			expect(part.benchmarks[1].warmup):toBe(original.benchmarks[1].warmup)
		end
		expect(samples):toBe(originalSamples)
		expect(original.benchmarks[1].samples):toBe(originalSamples)
		expect(calibration):toBe(original.yardstick.samples)
		expect(warmup):toBe(original.yardstick.warmup)
	end)

	it("paired policy requires persistent timing and memory growth", function()
		local base = { stored(100, 0), stored(100, 0), stored(100, 0) }
		local unchanged = Paired.compare(base, base)
		expect(#unchanged.regressed):toBe(0)
		local noisy = Paired.compare(base, { stored(200, 200), stored(200, 200), stored(100, 0) })
		expect(noisy.pooled.failed):toBe(3)
		expect(#noisy.regressed):toBe(0)
		local persistent = Paired.compare(base, { stored(200, 200), stored(200, 200), stored(200, 200) })
		expect(#persistent.regressed):toBe(3)
		local sixBase, sixCandidate = {}, {}
		for round = 1, 6 do
			table.insert(sixBase, stored(100, 0))
			table.insert(sixCandidate, if round <= 3 then stored(200, 200) else stored(100, 0))
		end
		expect(#Paired.compare(sixBase, sixCandidate).regressed):toBe(0)
	end)

	it("paired policy rejects incomplete rounds and missing memory endpoints", function()
		local base = { stored(100, 0), stored(100, 0), stored(100, 0) }
		local incomplete = pcall(function()
			Paired.compare({ base[1], base[2] }, { base[1], base[2] })
		end)
		expect(incomplete):toBe(false)
		local missing = stored(100, 0)
		table.remove(missing.measurements)
		local accepted = pcall(function()
			Paired.compare(base, { base[1], missing, base[3] })
		end)
		expect(accepted):toBe(false)
		local missingEverywhere = pcall(function()
			Paired.compare({ missing, missing, missing }, { missing, missing, missing })
		end)
		expect(missingEverywhere):toBe(false)
	end)

	it("fixture priming cleans up without consuming the declared sample budget", function()
		local prepared, ran, cleaned, calibrated = 0, 0, 0, 0
		local member: Benchmark.Spec = {
			name = "prime",
			unit = "seconds",
			environment = { observed = "priming-lifecycle" },
			warmup = 7,
			samples = 31,
			beforeSample = function(): unknown
				prepared += 1
				return nil
			end,
			workload = function(_state: unknown)
				ran += 1
			end,
			afterSample = function(_state: unknown, _sampler: Benchmark.Sampler)
				cleaned += 1
			end,
		}
		Suites.prime {
			name = "priming",
			benchmarks = { member },
			yardstick = {
				samples = 3,
				maxDrift = 0.25,
				maxSpread = 4,
				run = function()
					calibrated += 1
				end,
			},
		}
		expect(prepared):toBe(1)
		expect(ran):toBe(1)
		expect(cleaned):toBe(1)
		expect(calibrated):toBe(0)
		expect(member.warmup):toBe(7)
		expect(member.samples):toBe(31)
	end)

	it("paired memory accepts unchanged scenes and detects retained allocations", function()
		local function readings(bytes: number): ({ number }, { number })
			local result = process.run { "lute", "run", "bench/memory-control.luau", tostring(bytes) }
			assert(result.ok, result.stderr)
			local mounted: { number } = {}
			local teardown: { number } = {}
			local count = 0
			for token in string.gmatch(result.stdout, "%S+") do
				local value = assert(tonumber(token))
				assert(value >= 0 and value < math.huge)
				count += 1
				table.insert(if count % 2 == 1 then mounted else teardown, value)
			end
			assert(count == 6)
			return mounted, teardown
		end
		local baseMounted, baseTeardown = readings(0)
		local sameMounted, sameTeardown = readings(0)
		local keptMounted, keptTeardown = readings(4 * 1024 * 1024)
		local function stored(name: string, mounted: { number }, teardown: { number }): Benchmark.Stored
			return {
				schemaVersion = 1,
				name = name,
				measurements = {
					{ name = "mounted", unit = "KiB", environment = "retained", samples = mounted },
					{ name = "teardown", unit = "KiB", environment = "retained", samples = teardown },
				},
			}
		end
		local base = stored("base", baseMounted, baseTeardown)
		local rule: Benchmark.CompareRule = { ratio = 1.05, floor = 64 }
		local same = Benchmark.compare(base, stored("same", sameMounted, sameTeardown), { rule = rule })
		local kept = Benchmark.compare(base, stored("kept", keptMounted, keptTeardown), { rule = rule })
		expect(same.passed):toBe(2)
		expect(kept.failed):toBe(2)
	end)

	it("collects the prewarmed 10000-node fixture within its bounded memory allowance", function()
		local entries = Suites.entries { suite = "workloads", filter = "cold-mount-10000" }
		expect(#entries):toBe(1)
		entries[1].memory()
		local result = entries[1].memory()
		expect(result.mountedRetainedKb):toBeGreaterThan(64)
		expect(result.teardownRetainedKb):toBeLessThan(1024)
	end)
end)

return nil
