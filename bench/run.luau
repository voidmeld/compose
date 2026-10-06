--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Gate = require "../.lute/dependencies/verify/src/gate"
local Lute = require "../.lute/dependencies/verify/src/lute"
local Suites = require "./suites"
local Verify = require "../.lute/dependencies/verify/src/core"

local USAGE =
	"usage: lute run bench/run.luau [--suite workloads|screens|entities|all] [--filter text] [--scale name] [--out directory] [--verify] [--baseline stored.json] | --spread stored.json stored.json [...]"
local DEFAULT_OUT = "bench/results/scratch"
local RATIO = 1.5
local FLOOR_MICROSECONDS = 5

type Options = {
	suite: Suites.Suite,
	filter: string?,
	scale: string?,
	out: string,
	verify: boolean,
	baseline: string?,
	spread: { string },
}

local function parse(): Options
	local options: Options = { suite = "workloads", out = DEFAULT_OUT, verify = false, spread = {} }
	local index = 2
	while index <= #process.args do
		local flag = process.args[index]
		if flag == "--verify" then
			options.verify = true
		elseif flag == "--spread" then
			while process.args[index + 1] ~= nil do
				index += 1
				table.insert(options.spread, process.args[index])
			end
		else
			index += 1
			local value = process.args[index]
			if value == nil then
				error(USAGE, 0)
			elseif flag == "--suite" then
				assert(
					value == "workloads" or value == "screens" or value == "entities" or value == "all",
					"bench: unknown suite " .. value
				)
				options.suite = value
			elseif flag == "--filter" then
				options.filter = value
			elseif flag == "--scale" then
				options.scale = value
			elseif flag == "--out" then
				options.out = value
			elseif flag == "--baseline" then
				options.baseline = value
			else
				error(USAGE, 0)
			end
		end
		index += 1
	end
	return options
end

local function read(path: string): Benchmark.Stored
	return Benchmark.decode(Lute.parse(fs.readFileToString(path)))
end

local function spread(paths: { string }): number
	local runs: { Benchmark.Stored } = {}
	for _, path in paths do
		table.insert(runs, read(path))
	end
	local summary = Benchmark.spread(runs)
	table.sort(summary.noise, function(left: Benchmark.Noise, right: Benchmark.Noise): boolean
		return (left.relativeRange or 0) > (right.relativeRange or 0)
	end)
	print(("%d measurement(s) across %d run(s)"):format(#summary.noise, summary.runs))
	for _, noise in summary.noise do
		print(
			("  %-60s median %.4g %s, range %.1f%%"):format(
				noise.name,
				noise.median,
				noise.unit,
				(noise.relativeRange or 0) * 100
			)
		)
	end
	for _, name in summary.incomplete do
		print(("  incomplete: %s"):format(name))
	end
	return 0
end

local function identity(): string
	local head = process.run { "git", "rev-parse", "--short", "HEAD" }
	local status = process.run { "git", "status", "--porcelain" }
	local commit = if head.ok then (string.gsub(head.stdout, "%s+$", "")) else "unversioned"
	return if status.ok and string.match(status.stdout, "%S") ~= nil then commit .. "-dirty" else commit
end

local function main(): number
	local options = parse()
	if #options.spread > 0 then
		return spread(options.spread)
	end

	local entries = Suites.entries { suite = options.suite, filter = options.filter, scale = options.scale }
	if #entries == 0 then
		print "bench: no workload or scenario matches the filter"
		return 1
	end

	local producers: { Gate.ProducerDraft } = {}
	for _, entry in entries do
		Benchmark.checkCollection(entry.collection)
		local parity: Gate.ProducerDraft = {
			id = "parity-" .. entry.id,
			kind = "tests",
			worker = "bench/worker.luau",
			locators = { entry.id },
			tier = "parity",
			why = "every framework builds the same observable tree",
		}
		local timing: Gate.ProducerDraft = {
			id = "timing-" .. entry.id,
			kind = "benchmark",
			collection = entry.collection,
			after = { "parity-" .. entry.id },
			tier = "timing",
			why = "measured only: no framework is judged against another",
		}
		table.insert(producers, parity)
		table.insert(producers, timing)
	end

	local parityOnly: Gate.Selection = { tiers = { "parity" } }
	local outcome = Lute.gate.run(Gate.define { id = "compose-benchmarks", producers = producers }, {
		directory = options.out .. "/gate",
		selection = if options.verify then parityOnly else nil,
	})
	print(Verify.format(outcome.execution.report))

	if not options.verify then
		fs.createDirectory(options.out, { makeParents = true })
		local name = identity()
		local run = Benchmark.storeReport(name, outcome.execution.report)
		fs.writeStringToFile(options.out .. "/stored.json", Lute.encode(run) .. "\n")
		fs.writeStringToFile(options.out .. "/report.json", Lute.encode(outcome.execution.report) .. "\n")
		print(("bench: wrote %s/stored.json and %s/report.json"):format(options.out, options.out))
		local baseline = options.baseline
		if baseline ~= nil then
			local comparison = Benchmark.compare(read(baseline), run, {
				rule = { ratio = RATIO, floor = FLOOR_MICROSECONDS },
			})
			print(Verify.format(comparison))
			if comparison.passed ~= comparison.total then
				return 1
			end
		end
	end
	print(("bench: verdict %s"):format(outcome.acceptance.verdict))
	return if outcome.acceptance.verdict == "failed" then 1 else 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
