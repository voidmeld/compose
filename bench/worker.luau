--!strict

local Lute = require "../.lute/dependencies/verify/src/lute"
local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Suites = require "./suites"
local Verify = require "../.lute/dependencies/verify/src/core"

Lute.worker {
	load = function(locator: string): unknown
		local timing = locator:sub(1, 7) == "timing:"
		local id = if timing then locator:sub(8) else locator
		for _, entry in Suites.entries { suite = "all" } do
			if entry.id == id then
				return function(harness: Verify.Harness)
					harness:suite(entry.id, function()
						if timing then
							harness:case("timing", Benchmark.collection(entry.collection))
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
