--!strict

local Test = require "../harness"
local Benchmark = require "../../.lute/dependencies/verify/src/benchmark"
local process = require "@std/process"
local Suites = require "../../bench/suites"

Test.it("fixture priming cleans up without consuming the declared sample budget", function()
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
			maxDrift = 0.15,
			maxSpread = 4,
			run = function()
				calibrated += 1
			end,
		},
	}
	Test.expect(prepared):toBe(1)
	Test.expect(ran):toBe(1)
	Test.expect(cleaned):toBe(1)
	Test.expect(calibrated):toBe(0)
	Test.expect(member.warmup):toBe(7)
	Test.expect(member.samples):toBe(31)
end)

Test.it("paired memory accepts unchanged scenes and detects retained allocations", function()
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
	Test.expect(same.passed):toBe(2)
	Test.expect(kept.failed):toBe(2)
end)

Test.it("collects the prewarmed 10000-node fixture within its bounded memory allowance", function()
	local entries = Suites.entries { suite = "workloads", filter = "cold-mount-10000" }
	Test.expect(#entries):toBe(1)
	entries[1].memory()
	local result = entries[1].memory()
	Test.expect(result.mountedRetainedKb):toBeGreaterThan(64)
	Test.expect(result.teardownRetainedKb):toBeLessThan(1024)
end)

return nil
