--!strict

local Lute = require "../.lute/dependencies/verify/src/lute"
local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Suites = require "./suites"
local Verify = require "../.lute/dependencies/verify/src/core"

Lute.worker {
	load = function(locator: string): unknown
		local timing = locator:sub(1, 7) == "timing:"
		local memory = locator:sub(1, 7) == "memory:"
		local id = if timing or memory then locator:sub(8) else locator
		for _, entry in Suites.entries { suite = "all" } do
			if entry.id == id then
				return function(harness: Verify.Harness)
					harness:suite(entry.id, function()
						if memory then
							harness:case("retained Luau heap", function(context)
								entry.memory()
								local mounted, teardown = {}, {}
								for round = 1, 3 do
									local result = entry.memory()
									context:attach(`round-{round}.json`, "application/json", Lute.encode(result))
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
									}, { unit = "KiB", minimumSamples = 3, measureOnly = true })
								end
							end)
							return
						end
						if timing then
							local definition = Benchmark.collection(entry.collection)
							local run = assert(definition.run)
							definition.run = function(context)
								Suites.prime(entry.collection)
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
