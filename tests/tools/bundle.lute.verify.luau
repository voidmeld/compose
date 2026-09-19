--!strict

local Compose = require "../../src/core"
local Test = require "../harness"
local TestHost = require "../../src/test-host"
local fs = require "@std/fs"
local luau = require "@lute/luau"
local process = require "@lute/process"

local describe, it, expect = Test.describe, Test.it, Test.expect

local OUT = "build/bundle-test.luau"

local function build(strip: boolean): any
	local argv = {
		"lute",
		"run",
		"tools/bundle.luau",
		"--entry",
		"src/core",
		"--name",
		"Compose",
		"--out",
		OUT,
	}
	if strip then
		table.insert(argv, "--strip-comments")
	end

	local result = process.run(argv)
	if not result.ok then
		error(("bundling failed: %s%s"):format(result.stdout, result.stderr), 0)
	end

	local source = fs.readFileToString(OUT)
	local chunk = luau.load(luau.compile(source), "@" .. OUT)
	return chunk()
end

describe("bundle", function()
	Test.beforeEach(function()
		Compose.__resetForTests()
		if not fs.exists "build" then
			process.run { "mkdir", "-p", "build" }
		end
	end)

	it("exports the same public surface as the module tree", function()
		local bundled = build(false)

		local expected: { string } = {}
		for name in (Compose :: any) :: { [string]: unknown } do
			table.insert(expected, name)
		end
		table.sort(expected)

		local actual: { string } = {}
		for name in (bundled :: any) :: { [string]: unknown } do
			table.insert(actual, name)
		end
		table.sort(actual)

		expect(actual):toEqual(expected)
	end)

	it("mounts, updates, and disposes exactly like the module tree", function()
		local bundled = build(false)

		local host = TestHost.create()
		local runtime = bundled.createRuntime(host.host)
		local count = bundled.cell(0)

		local dispose, root = runtime.mount(function()
			return runtime.create "Frame" {
				Label = function(use)
					return "n=" .. tostring(use(count))
				end,
			}
		end, host.root)

		expect(host.propertyOf(root, "Label")):toBe "n=0"
		count:set(7)
		runtime:settle()
		expect(host.propertyOf(root, "Label")):toBe "n=7"

		dispose()
		expect(host.leaked()):toEqual { "Root#1" }
	end)

	it("keeps its behaviour when comments are stripped", function()
		local bundled = build(true)

		local host = TestHost.create()
		local runtime = bundled.createRuntime(host.host)
		local rows = bundled.cell { "a", "b", "c" }

		local dispose, frame = runtime.mount(function()
			return runtime.create "Frame" {
				bundled.keyed {
					from = rows,
					render = function(value)
						return runtime.create "Row" {
							Id = function(use)
								return use(value)
							end,
						}
					end,
				},
			}
		end, host.root)

		local before = host.childrenOf(frame)
		rows:set { "c", "a", "b" }
		runtime:settle()
		local after = host.childrenOf(frame)

		expect(after[1]):toBe(before[3])
		expect(after[2]):toBe(before[1])

		dispose()
		expect(host.leaked()):toEqual { "Root#1" }
	end)

	it("bundles several entry points against one shared registry", function()
		local result = process.run {
			"lute",
			"run",
			"tools/bundle.luau",
			"--entry",
			"src/core",
			"--entry",
			"src/roblox",
			"--name",
			"Compose",
			"--out",
			OUT,
		}
		expect(result.ok):toBe(true)

		local bundled = luau.load(luau.compile(fs.readFileToString(OUT)), "@" .. OUT)()
		expect(bundled["src/core"]):toBeOk()
		expect(bundled["src/roblox"]):toBeOk()

		local host = TestHost.create()
		local core = bundled["src/core"]
		local runtime = core.createRuntime(host.host)
		local value = core.cell "first"
		local dispose, node = runtime.mount(function()
			return runtime.create "Frame" {
				Text = function(use)
					return use(value)
				end,
			}
		end, host.root)
		value:set "second"
		runtime:settle()
		expect(host.propertyOf(node, "Text")):toBe "second"
		dispose()
	end)
end)

return nil
