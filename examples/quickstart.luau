--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

local function run(): string
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors

	local count = Compose.cell(0)

	local dispose, root = runtime.mount(function()
		return Host.Panel {
			Title = "Clicks",
			Label = function(use): string
				return ("clicked %d times"):format(use(count))
			end,
		}
	end, test.root)

	count:set(3)
	runtime:settle()

	local label = test.propertyOf(root, "Label") :: string
	dispose()
	return label
end

return {
	name = "quickstart",
	what = "building, updating and disposing one component",
	expected = "clicked 3 times",
	run = run,
}
