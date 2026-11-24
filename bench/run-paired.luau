--!strict

local fs = require "@std/fs"
local process = require "@std/process"
local Benchmark = require "@verify/src/benchmark"
local Lute = require "@verify/src/lute"
local Paired = require "./paired"

local base =
	assert(process.args[2], "usage: lute run bench/run-paired.luau BASE CANDIDATE ABSOLUTE_OUTPUT [FILTER] [SHARD]")
local candidate = assert(process.args[3])
local directory = assert(process.args[4])
local filter = process.args[5]
local shard = process.args[6]
fs.createDirectory(directory, { makeParents = true })
local first: { Benchmark.Stored } = {}
local second: { Benchmark.Stored } = {}
local order: { string } = {}
for round = 1, 6 do
	local arms: { string } = if round % 2 == 1 then { "base", "candidate" } else { "candidate", "base" }
	for _, arm in arms do
		local out = `{directory}/{arm}-{round}`
		local argv =
			{ "lute", "run", "bench/run.luau", "--suite", "all", "--paired-round", tostring(round), "--out", out }
		if filter and filter ~= "" then
			table.insert(argv, "--filter")
			table.insert(argv, filter)
		end
		if shard and shard ~= "" then
			table.insert(argv, "--shard")
			table.insert(argv, shard)
		end
		table.insert(order, `{round}:{arm}`)
		fs.writeStringToFile(`{directory}/order.txt`, table.concat(order, "\n") .. "\n")
		print(`paired: round {round}, {arm}`)
		local result = process.run(argv, { cwd = if arm == "base" then base else candidate, stdio = "inherit" })
		if not result.ok then
			process.exit(1)
		end
		local stored = Benchmark.decode(Lute.parse(fs.readFileToString(`{out}/stored.json`)))
		table.insert(if arm == "base" then first else second, stored)
	end
	if round == 3 or round == 6 then
		local result = Paired.compare(first, second)
		fs.writeStringToFile(`{directory}/comparison-{round}.json`, Lute.encode(result) .. "\n")
		print(`paired: {round} complete rounds; {#result.regressed} persistent regression(s)`)
		for _, name in result.regressed do
			print(`  regressed: {name}`)
		end
		if #result.regressed == 0 then
			break
		elseif round == 6 then
			process.exit(1)
		end
	end
end
