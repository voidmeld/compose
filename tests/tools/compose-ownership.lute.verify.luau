--!strict

local Check = require "../../tools/check-compose-ownership"
local fs = require "@std/fs"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function rules(source: string, options: Check.Options?): { string }
	local result: { string } = {}
	for _, finding in Check.scan("source.luau", source, options or {}) do
		table.insert(result, finding.rule)
	end
	return result
end

local names: Check.Options = {
	ownership = false,
	naming = {
		hosts = { "Host", "UI", "constructors" },
		forbidName = true,
		namedMounts = true,
		namedRender = true,
		namedReturns = true,
		rootLabel = true,
		component = { typeName = "Identity.Named", field = "label", definitionPath = "shared/Identity.luau" },
	},
}

describe("configurable Compose ownership and naming check", function()
	it("rejects native lifecycle operations and mount entry points with source locations", function()
		for _, sample in
			{
				{ "Instance.new('Part')", "instance-new" },
				{ "Instance['new']('Part')", "instance-new" },
				{ "part:Clone()", "clone" },
				{ "part:Destroy()", "destroy" },
				{ "part.Parent = parent", "parent-assignment" },
				{ "part['Parent'] = parent", "parent-assignment" },
				{ "Instance.fromExisting(part)", "from-existing" },
				{ "Instance['fromExisting'](part)", "from-existing" },
				{ "Roblox.createRuntime()", "runtime-create" },
				{ "createRuntime()", "runtime-create" },
				{ "rt.mount(App, parent)", "mount" },
				{ "rt.mountFragment(App, parent)", "mount" },
				{ "Scene.app(App)", "mount" },
			}
		do
			local hits = Check.scan("src/view.luau", "\n" .. sample[1], {})
			expect(#hits):toBe(1)
			expect(hits[1].rule):toBe(sample[2])
			expect(hits[1].path):toBe "src/view.luau"
			expect(hits[1].line):toBe(2)
		end
	end)

	it("ignores literals comments and comparisons but checks interpolation expressions", function()
		expect(rules [====[
local a = "Instance.new('Part')"
local b = [==[part:Destroy()]==]
local c = `part.Parent = parent`
-- part:Clone()
--[=[ Instance.fromExisting(part) ]=]
if part.Parent == parent then return part end
]====]):toEqual {}
		expect(rules "local label = `created {Instance.new('Part')}`"):toEqual { "instance-new" }
	end)

	it("configures every naming rule without a fixed host or label convention", function()
		for _, source in
			{
				'Host.Frame { Name = "Bad" }',
				'Host.Frame { ["Name"] = "Bad" }',
				'frame.Name = "Bad"',
				'frame["Name"] = "Bad"',
				"rt.mount(\nfunction() return Host.Frame {} end, parent)",
				"UI.Grid { render = function() return UI.Text {} end }",
				"return function() return UI.Screen {} end",
				"return Host.Frame {}",
				"return runtime.constructors.Frame {}",
				"local function View(props: { value: string }) return Host.Frame 'Fixed' {} end",
				"local function View(props: Identity.Named) return Host.Frame 'Fixed' {} end",
				"type Named = { label: string }",
			}
		do
			expect(#Check.scan("source.luau", source, names) > 0):toBe(true)
		end
		expect(Check.scan(
			"source.luau",
			[[
type Props = Identity.Named & { value: string }
local function View(props: Props) return Host.Frame(props.label) {} end
local function Tile(current: Readable) return UI.Button "Tile" {} end
UI.Grid { render = Tile }
rt.mount(View, parent)
return View
]],
			names
		)):toEqual {}
		expect(rules('return Host.Frame({}, "Label")', names)):toEqual {}
		expect(rules('return Host.Frame "Label" {}', names)):toEqual {}
		expect(rules('local note = "Name = text"', names)):toEqual {}
		expect(rules("local function View(props: Identity.Named?) return Host.Frame(props.label) {} end", names)):toContain "component-type"
	end)

	it("lets a consumer enable naming rules by source path", function()
		local config: Check.Config = {
			roots = {},
			options = {
				ownership = false,
				naming = { hosts = { "Native" }, namedReturns = true, rootLabel = true },
				enabled = function(path: string, _rule: string): boolean
					return string.sub(path, 1, 4) == "app/"
				end,
			},
		}
		local result = Check.evaluate({
			["shared/utility.luau"] = "return function() end",
			["app/view.luau"] = "return Native.Part {}",
		}, config)
		expect(#result.findings):toBe(1)
		expect(result.findings[1].rule):toBe "unnamed-root"
	end)

	it("supports exact scoped exemptions and reports invalid and stale entries", function()
		local files = { ["source.luau"] = "part:Destroy()\nInstance.new('Part')" }
		local config: Check.Config = {
			roots = {},
			options = {},
			exemptions = {
				{
					path = "source.luau",
					rule = "destroy",
					snippet = "part:Destroy()",
					reason = "External resource boundary",
				},
			},
		}
		local result = Check.evaluate(files, config)
		expect(#result.findings):toBe(1)
		expect(result.findings[1].rule):toBe "instance-new"
		config.exemptions = { { path = "missing.luau", reason = " " } }
		result = Check.evaluate(files, config)
		expect(result.findings[1].rule):toBe "configuration"
		expect(#result.notes):toBe(1)
		config.exemptions = { { path = "source.luau", reason = "External factory owns its instances" } }
		expect(Check.evaluate(files, config).findings):toEqual {}
	end)

	it("checks configured required files counts patterns and nested mount boundaries", function()
		local config: Check.Config = {
			roots = {},
			options = {
				patterns = { { rule = "callback-prop", pattern = "On%a*Invoke%s*=" } },
				counts = {
					{ path = "entry.luau", rule = "root-mount-count", pattern = "Runtime%.mount%s*%(", count = 1 },
				},
				nestedCalls = { "^Root%.add$", "^Root%.addFragment$" },
				enabled = function(path: string, rule: string): boolean
					return not (path == "entry.luau" and rule == "mount")
				end,
			},
		}
		expect(Check.evaluate({ ["entry.luau"] = "Runtime.mount(App, parent)" }, config).findings):toEqual {}
		expect(#Check.evaluate({}, config).findings):toBe(1)
		local result = Check.evaluate({
			["entry.luau"] = "Root.add(function() Root.addFragment(Children) end)\nlocal props = { OnServerInvoke = handler }",
		}, config)
		expect(#result.findings):toBe(3)
	end)

	it("ratchets per-rule baselines and reports reductions without changing files", function()
		local config: Check.Config = {
			roots = {},
			options = {},
			baseline = { ["source.luau"] = { clone = 1 } },
		}
		expect(Check.evaluate({ ["source.luau"] = "part:Clone()" }, config).findings):toEqual {}
		local grown = Check.evaluate({ ["source.luau"] = "part:Clone()\npart:Clone()" }, config)
		expect(#grown.findings):toBe(1)
		expect(grown.findings[1].line):toBe(2)
		expect(#Check.evaluate({ ["source.luau"] = "return {}" }, config).notes):toBe(1)
	end)

	it("reads caller source roots once and applies caller selection", function()
		local root = "build/ownership-check-spec"
		fs.createDirectory(root, { makeParents = true })
		fs.writeStringToFile(root .. "/view.luau", "Instance.new('Part')")
		fs.writeStringToFile(root .. "/ignored.luau", "part:Destroy()")
		local result = Check.check {
			roots = { root, root .. "/view.luau" },
			options = {},
			include = function(path: string): boolean
				return string.find(path, "ignored", 1, true) == nil
			end,
		}
		expect(#result.findings):toBe(1)
		expect(fs.readFileToString(root .. "/view.luau")):toBe "Instance.new('Part')"
		fs.remove(root .. "/view.luau")
		fs.remove(root .. "/ignored.luau")
		fs.removeDirectory(root)
	end)

	it("applies source selection to in-memory manifests and rejects invalid source", function()
		local result = Check.evaluate({ ["selected.luau"] = "return {}", ["ignored.luau"] = "invalid +" }, {
			roots = {},
			options = {},
			include = function(path: string): boolean
				return path == "selected.luau"
			end,
		})
		expect(result.findings):toEqual {}
		expect(function()
			Check.scan("invalid.luau", "local =", {})
		end):toThrow()
	end)
end)

return nil
