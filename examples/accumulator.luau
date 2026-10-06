--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

local presses = Compose.sharedCell(0)

local function run(): string
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors

	local signalFired = Compose.cell(nil :: { name: string, at: number }?)

	local dispose, root = runtime.mount(function()
		local timings = Compose.accumulator {
			from = signalFired,
			reduce = function(previous: { [string]: number }, event: { name: string, at: number }?)
				if event == nil then
					return previous
				end
				local merged = table.clone(previous)
				merged[event.name] = event.at
				return merged
			end,
			initial = {} :: { [string]: number },
		}

		return Host.Panel {
			Summary = function(use: Compose.Use)
				local byName = use(timings)
				local names: { string } = {}
				for name in byName do
					table.insert(names, name)
				end
				table.sort(names)
				return ("%d signals seen, %d presses"):format(#names, use(presses))
			end,
		}
	end, test.root)

	presses:set(presses:peek() + 1)
	signalFired:set { name = "alpha", at = 1 }
	presses:set(presses:peek() + 1)
	signalFired:set { name = "beta", at = 2 }
	presses:set(presses:peek() + 1)
	runtime:settle()

	local summary = tostring(test.propertyOf(root, "Summary"))

	dispose()
	assert(test.liveNodes() == 1, "everything but the borrowed root should be gone")

	presses:set(presses:peek() + 1)
	assert(presses:peek() == 4, "the shared cell outlives the screen by design")

	return summary
end

return {
	name = "accumulator",
	what = "a stated singleton, and discrete events merged into running state",
	expected = "2 signals seen, 3 presses",
	run = run,
}
