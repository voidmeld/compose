--!strict

local Compose = require "../../src/core"
local Test = require "../harness"
local Support = require "../support"
local TestScene = require "../../src/test-scene"
local fs = require "@std/fs"
local luau = require "@lute/luau"
local process = require "@lute/process"
local TemporaryDirectory = require "../../.lute/dependencies/verify/src/checks/temporary-directory"
local Walk = require "../../.lute/dependencies/verify/src/checks/walk"

local describe, it, expect = Test.describe, Test.it, Test.expect

local OUT = "build/bundle-test.luau"

local function build(strip: boolean): typeof(Compose)
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
	return (Support.erased(chunk())) :: typeof(Compose)
end

describe("bundle", function()
	it("loads the design editor after vendoring packages without their src prefix", function()
		TemporaryDirectory.run(TemporaryDirectory.root(), "compose-design-vendor", function(root)
			fs.writeStringToFile(root .. "/rokit.toml", fs.readFileToString "rokit.toml")
			for _, package in { "core", "design", "design-editor" } do
				for _, source in Walk.paths("src/" .. package, { ".luau" }) do
					local target = root .. "/" .. string.sub(source, 5)
					fs.createDirectory(assert(string.match(target, "^(.*)/[^/]+$")), { makeParents = true })
					fs.writeStringToFile(target, fs.readFileToString(source))
				end
			end
			fs.writeStringToFile(
				root .. "/consumer.luau",
				[[
--!strict
local Compose = require "./core"
local Design = require "./design"
local Editor = require "./design-editor"
assert(type(Compose.createRuntime) == "function")
assert(type(Design.document.new) == "function")
assert(type(Editor.create) == "function")
assert(type(Editor.robloxLibrary) == "function")
assert(type(Editor.roblox3DLibrary) == "function")
]]
			)
			local result = process.run({ "lute", "run", "consumer.luau" }, { cwd = root })
			if not result.ok then
				error(result.stderr, 0)
			end
			expect(result.ok):toBe(true)
			return true
		end)
	end)

	Test.beforeEach(function()
		Compose.__resetForTests()
		if not fs.exists "build" then
			process.run { "mkdir", "-p", "build" }
		end
	end)

	it("exports the same public surface as the module tree", function()
		local bundled = build(false)

		local expected: { string } = {}
		for name in Support.record(Compose) do
			assert(type(name) == "string")
			table.insert(expected, name)
		end
		table.sort(expected)

		local actual: { string } = {}
		for name in Support.record(bundled) do
			assert(type(name) == "string")
			table.insert(actual, name)
		end
		table.sort(actual)

		expect(actual):toEqual(expected)
	end)

	it("mounts, updates, and disposes exactly like the module tree", function()
		local bundled = build(false)

		local host = TestScene.create()
		local runtime = bundled.createRuntime(host.adapter)
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

		local host = TestScene.create()
		local runtime = bundled.createRuntime(host.adapter)
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

		local host = TestScene.create()
		local core = bundled["src/core"]
		local runtime = core.createRuntime(host.adapter)
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
