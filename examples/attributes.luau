--!strict

local Compose = require "../src/core"
local TestHost = require "../src/test-host"

local function run(): string
	local host = TestHost.create()
	local runtime = Compose.createRuntime(host.host)
	local create = runtime.create
	local cell = Compose.cell

	local Prop = create "Prop"

	local tier = cell(1)
	local faction = cell "north"

	local dispose, node = runtime.mount(function()
		return Prop {

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
	end, host.root)

	tier:set(2)
	faction:set "south"
	runtime:settle()

	host.resetCounts()
	tier:set(2)
	runtime:settle()
	assert(host.counts().setAttribute == 0, "an equal value must not reach the host")

	local ok, err: any = pcall(function()
		runtime.mount(function()
			return Prop { Attributes = { Tier = { deep = true } } }
		end, host.root)
	end)
	assert(not ok, "a table is not an attribute value")
	local report = Compose.parseDiagnostic(tostring(err))
	assert(report ~= nil and report.code == "props/attribute-value", "the refusal names the contract")

	local label = tostring(host.attributeOf(node, "Label"))

	dispose()
	assert(host.liveNodes() == 1, "everything but the borrowed root should be gone")

	return label
end

return {
	name = "attributes",
	what = "declarative attributes: reactive, deduped, cleared by nil, and refused by name",
	expected = "south tier 2",
	run = run,
}
