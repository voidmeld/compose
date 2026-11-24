--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

local function stringValue(value: unknown): string
	assert(type(value) == "string")
	return value
end

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

	local label = stringValue(test.propertyOf(root, "Label"))
	dispose()
	return label
end

return {
	name = "quickstart",
	what = "building, updating and disposing one component",
	expected = "clicked 3 times",
	run = run,
}
