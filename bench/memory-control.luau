--!strict

local process = require "@lute/process"
local Suites = require "./suites"

local bytes = assert(tonumber(process.args[2]))
local released = process.args[3] == "released"
assert(bytes == 0 or bytes == 4 * 1024 * 1024)
local entry = Suites.entries({ suite = "workloads", filter = "cold-mount-100" })[1]
assert(entry.id == "cold-mount-100")
entry.memory()
for _ = 1, 3 do
	local result = entry.memory(bytes, released)
	print(result.mountedRetainedKb, result.teardownRetainedKb)
end
