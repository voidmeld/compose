--!strict

local Compose = require "../src/core"
local TestHost = require "../src/test-host"

type Connection = { name: string }

local function run(): string
	local host = TestHost.create()
	local runtime = Compose.createRuntime(host.host)
	local Frame = runtime.create "Frame"

	local opened = 0
	local closed = 0

	local connect = Compose.createSharedResource(function(): (Connection, () -> ())
		opened += 1
		return { name = "connection" }, function()
			closed += 1
		end
	end)

	local refused, failure: any = pcall(connect)
	assert(not refused, "an ownerless acquire should have been refused")
	local diagnostic = Compose.parseDiagnostic(tostring(failure))
	assert(diagnostic ~= nil, "the refusal should be a Compose diagnostic")
	local refusedCode = (diagnostic :: Compose.Diagnostic).code

	local ticks = Compose.cell(0)
	local seen: Compose.Readable<number>
	local scope = Compose.createRootOwner(function()
		local connection = connect()
		assert(connection.name == "connection", "the shared resource should have been built")

		seen = Compose.accumulator {
			from = ticks,
			reduce = function(previous: number, value: number): number
				return previous + value
			end,
			initial = 0,
		}

		runtime.mount(function()
			return Frame "Hud" {
				Text = function(use: Compose.Use): string
					return ("seen %d"):format(use(seen))
				end,
			}
		end, host.root)
	end, runtime.reactor)

	ticks:set(2)
	ticks:set(3)
	runtime:settle()

	local hud = host.childrenOf(host.root)[1]
	local text = host.propertyOf(hud, "Text")

	local pooled = Compose.withRootOwner(function(): number
		local pool = Compose.createPool {
			create = function(): { id: number }
				return { id = 0 }
			end,
			destroy = function()
				closed += 1
			end,
			maxRetained = 2,
		}
		local first = pool.acquire()
		local second = pool.acquire()
		first.release()
		second.release()
		return pool.idle()
	end, runtime.reactor)

	local afterJob = closed

	scope.dispose()

	assert(Compose.outstandingMounts() == 0, "the mount inside the root scope was left outstanding")
	assert(host.liveNodes() == 1, "shutting the root scope down left nodes behind")
	assert(host.isAlive(host.root), "shutting the root scope down destroyed the borrowed target")
	assert(opened == 1, "the shared connection should have been built exactly once")

	return ("refused %s | %s | pooled=%d | releasedByJob=%d | closed=%d"):format(
		refusedCode,
		tostring(text),
		pooled,
		afterJob,
		closed
	)
end

return {
	name = "root-scope",
	what = "an entry point with no ambient owner: one long-lived root for the process, one scoped root for a boot job",
	expected = "refused async/shared-no-owner | seen 5 | pooled=2 | releasedByJob=2 | closed=3",
	run = run,
}
