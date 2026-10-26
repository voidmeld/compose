--!strict

local Lute = require "../.lute/dependencies/verify/src/lute"
local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Suites = require "./suites"
local Verify = require "../.lute/dependencies/verify/src/core"
local Paired = require "./paired"

Lute.worker {
	load = function(locator: string): unknown
		local timingRound, timingId = locator:match "^timing(%d*):(.+)$"
		local memoryRound, memoryId = locator:match "^memory(%d*):(.+)$"
		local timing = timingId ~= nil
		local memory = memoryId ~= nil
		local round = tonumber(timingRound or memoryRound or "")
		local id = timingId or memoryId or locator
		for _, entry in Suites.entries { suite = "all" } do
			if entry.id == id then
				return function(harness: Verify.Harness)
					harness:suite(entry.id, function()
						if memory then
							harness:case("retained Luau heap", function(context)
								local settled = entry.memory().teardownRetainedKb
								for _ = 1, 3 do
									local next = entry.memory().teardownRetainedKb
									if math.abs(next - settled) <= 1 then
										break
									end
									settled = next
								end
								local mounted, teardown = {}, {}
								local count = if round then 1 else 3
								for sample = 1, count do
									local result = entry.memory()
									context:attach(
										`round-{round or sample}.json`,
										"application/json",
										Lute.encode(result)
									)
									table.insert(mounted, result.mountedRetainedKb)
									table.insert(teardown, result.teardownRetainedKb)
								end
								for _, metric in
									{
										{ name = "mounted", samples = mounted },
										{ name = "teardown", samples = teardown },
									}
								do
									context:measure("compose", entry.id .. "/memory/" .. metric.name, {
										samples = metric.samples,
										unit = "KiB",
										context = {
											environment = Lute.memory.METHOD,
											signal = metric.name,
											timing = "observed",
										},
									}, { unit = "KiB", minimumSamples = count, measureOnly = true })
								end
							end)
							return
						end
						if timing then
							local collection = if round
								then Paired.collection(entry.collection, round)
								else entry.collection
							collection.calibrationAttempts = 3
							local definition = Benchmark.collection(collection)
							local run = assert(definition.run)
							definition.run = function(context)
								Suites.prime(collection)
								run(context)
							end
							harness:case("timing", definition)
							return
						end
						harness:case("every framework builds the same observable tree", function()
							local detail = entry.parity()
							if detail ~= nil then
								error(detail, 0)
							end
						end)
					end)
				end
			end
		end
		error(("no benchmark entry named %s"):format(locator), 0)
	end,
}
