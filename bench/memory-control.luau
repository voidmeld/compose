--!strict

local process = require "@lute/process"
local Suites = require "./suites"

local bytes = assert(tonumber(process.args[2]))
assert(bytes == 0 or bytes == 4 * 1024 * 1024)
local entry = Suites.entries({ suite = "workloads", filter = "mount-dispose" })[1]
entry.memory()
for _ = 1, 3 do
	local result = entry.memory(bytes)
	print(result.mountedRetainedKb, result.teardownRetainedKb)
end
