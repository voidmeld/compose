--!strict

local Lute = require "../.lute/dependencies/verify/src/lute"
local Suites = require "./suites"
local Verify = require "../.lute/dependencies/verify/src/core"

Lute.worker {
	load = function(locator: string): unknown
		for _, entry in Suites.entries { suite = "all" } do
			if entry.id == locator then
				return function(harness: Verify.Harness)
					harness:suite(entry.id, function()
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
