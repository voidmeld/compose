--!strict

local time = require "@lute/time"
local system = require "@lute/system"
local fs = require "@std/fs"
local process = require "@lute/process"
local Lute = require "../.lute/dependencies/verify/src/lute"
local Benchmark = require "../.lute/dependencies/verify/src/benchmark"
local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

type Work = { step: () -> (), dispose: () -> () }
local origin = time.now()
local cpus = system.cpus()
local identity = ("%s-%s-%s-%dthreads"):format(
	system.os,
	system.arch,
	if #cpus > 0 then cpus[1].model else "unknown",
	system.threadCount()
)
local results: { Benchmark.Result } = {}
local setups: { { name: string, build: (Compose.Runtime, TestScene.TestScene, Compose.Owner) -> () -> () } } = {
	{
		name = "observe/100-holders",
		build = function(runtime, test)
			local node = test.makeNode "Panel"
			for _ = 1, 100 do
				runtime.observe(node, "Size")
			end
			local n = 0
			return function()
				n += 1
				test.poke(node, "Size", n)
			end
		end,
	},
	{
		name = "settled/changing",
		build = function(runtime, test)
			local n = 0
			runtime.settled {
				sample = function()
					n += 1
					return n
				end,
			}
			return function()
				test.step(1 / 60)
			end
		end,
	},
	{
		name = "clock/one-second",
		build = function(runtime, test, owner)
			local value = runtime.clock { interval = 1 }
			owner.watch(function(use)
				use(value)
			end)
			return function()
				test.step(1 / 60)
			end
		end,
	},
	{
		name = "sequence/one-track",
		build = function(runtime, test)
			runtime.sequence { steps = {
				{ tween = { seconds = 1e6 }, sample = function() end },
			} }
			return function()
				test.step(1 / 60)
			end
		end,
	},
}

for _, setup in setups do
	local spec: Benchmark.Spec = {
		name = setup.name,
		unit = "microseconds",
		warmup = 10,
		warmupScope = "sample",
		samples = 40,
		iterations = 200,
		environment = { observed = identity },
		clock = function()
			return time.since(origin)
		end,
		beforeSample = function(): Work
			local test = TestScene.create()
			local runtime = Compose.createRuntime(test.adapter)
			local owner = Compose.createOwner(runtime.reactor)
			local step = Compose.withOwner(owner, function()
				return setup.build(runtime, test, owner)
			end)
			return {
				step = step,
				dispose = function()
					owner.dispose()
					runtime:dispose()
				end,
			}
		end,
		workload = function(state)
			(state :: Work).step()
		end,
		afterSample = function(state)
			(state :: Work).dispose()
		end,
	}
	local result = Benchmark.run(spec)
	assert(result.failure == nil, result.failure)
	assert(#result.invalid == 0, "invalid runtime primitive measurement")
	table.insert(results, result)
	print(("%s: p50 %.3f us; p95 %.3f us"):format(spec.name, result.summary.p50 or 0, result.summary.p95 or 0))
end

local directory = process.args[2] or "bench/results/primitives"
fs.createDirectory(directory, { makeParents = true })
fs.writeStringToFile(directory .. "/stored.json", Lute.encode(Benchmark.store(identity, results)) .. "\n")
fs.writeStringToFile(directory .. "/context.json", Lute.encode {
	head = process.run({ "git", "rev-parse", "HEAD" }).stdout,
	tree = process.run({ "git", "rev-parse", "HEAD^{tree}" }).stdout,
	dirty = process.run({ "git", "status", "--porcelain" }).stdout,
	environment = identity,
	runtime = "lute",
	command = "lute run bench/primitives.luau",
	concurrency = 1,
} .. "\n")

return nil
