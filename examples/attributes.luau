--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

local function run(): string
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors
	local cell = Compose.cell

	local tier = cell(1)
	local faction = cell "north"

	local dispose, node = runtime.mount(function()
		return Host.Prop {

			Name = "Banner",

			Attributes = {
				Faction = faction,
				Tier = tier,
				Label = function(use: Compose.Use)
					return ("%s tier %d"):format(use(faction), use(tier))
				end,

				Optional = nil,
			},
		}
	end, test.root)

	tier:set(2)
	faction:set "south"
	runtime:settle()

	test.resetCounts()
	tier:set(2)
	runtime:settle()
	assert(test.counts().setAttribute == 0, "an equal value must not reach the host")

	local ok, err: any = pcall(function()
		runtime.mount(function()
			return Host.Prop { Attributes = { Tier = { deep = true } } }
		end, test.root)
	end)
	assert(not ok, "a table is not an attribute value")
	local report = Compose.parseDiagnostic(tostring(err))
	assert(report ~= nil and report.code == "props/attribute-value", "the refusal names the contract")

	local label = tostring(test.attributeOf(node, "Label"))

	dispose()
	assert(test.liveNodes() == 1, "everything but the borrowed root should be gone")

	return label
end

return {
	name = "attributes",
	what = "declarative attributes: reactive, deduped, cleared by nil, and refused by name",
	expected = "south tier 2",
	run = run,
}
