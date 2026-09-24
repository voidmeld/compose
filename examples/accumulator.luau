--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

local presses = Compose.sharedCell(0)

local function run(): string
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors

	local castFired = Compose.cell(nil :: { ability: string, at: number }?)

	local dispose, root = runtime.mount(function()
		local timings = Compose.accumulator {
			from = castFired,
			reduce = function(previous: { [string]: number }, event: { ability: string, at: number }?)
				if event == nil then
					return previous
				end
				local merged = table.clone(previous)
				merged[event.ability] = event.at
				return merged
			end,
			initial = {} :: { [string]: number },
		}

		return Host.Panel {
			Summary = function(use: Compose.Use)
				local byAbility = use(timings)
				local names: { string } = {}
				for ability in byAbility do
					table.insert(names, ability)
				end
				table.sort(names)
				return ("%d abilities cast, %d presses"):format(#names, use(presses))
			end,
		}
	end, test.root)

	presses:set(presses:peek() + 1)
	castFired:set { ability = "smite", at = 1 }
	presses:set(presses:peek() + 1)
	castFired:set { ability = "mend", at = 2 }
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
	expected = "2 abilities cast, 3 presses",
	run = run,
}
