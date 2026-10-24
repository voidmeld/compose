--!strict

local fs = require "@std/fs"
local process = require "@lute/process"
local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Lute = require "../.lute/dependencies/verify/src/lute"
local Suites = require "./suites"

local directory = process.args[2] or "build/performance/calibration"
assert(process.args[3] == nil or process.args[3] == "--prime")
local primed = process.args[3] == "--prime"
fs.createDirectory(directory, { makeParents = true })
for round = 1, 3 do
	for _, name in { "mount-dispose", "keyed-shuffle" } do
		local entries = Suites.entries { suite = "workloads", filter = name }
		assert(#entries == 1)
		local collection = entries[1].collection
		if primed then
			Suites.prime(collection)
		end
		local result = Benchmark.collect(collection)
		local evidence = {
			name = name,
			round = round,
			unit = collection.benchmarks[1].unit,
			environment = Suites.identity(),
			primed = primed,
			iterations = collection.yardstick.iterations,
			warmup = collection.yardstick.warmup,
			before = result.yardstickBefore,
			after = result.yardstickAfter,
			invalid = result.invalid,
			failure = result.failure,
		}
		local encoded = Lute.encode(evidence)
		fs.writeStringToFile(`{directory}/{name}-{round}.json`, encoded .. "\n")
		print(encoded)
	end
end
return nil
