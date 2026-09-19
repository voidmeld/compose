--!strict

local fs = require "@std/fs"
local process = require "@lute/process"
local Test = require "../harness"
local TemporaryDirectory = require "../../tools/lib/temporary-directory"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function fixture(body: (string) -> number): number
	return TemporaryDirectory.run(process.env["TMPDIR"] or "/tmp", "compose-required-surface", function(root)
		fs.writeStringToFile(root .. "/rokit.toml", fs.readFileToString "rokit.toml")
		for _, directory in { "tools", "docs", "src/core", "src/test-host", "src/roblox", "authoring" } do
			fs.createDirectory(root .. "/" .. directory, { makeParents = true })
		end
		for _, tool in { "check-public-surface", "gate" } do
			fs.writeStringToFile(root .. "/tools/" .. tool .. ".luau", fs.readFileToString("tools/" .. tool .. ".luau"))
		end
		for _, path in
			{ "src/core/init", "src/test-host/init", "src/roblox/init", "src/test-host/roblox", "authoring/init" }
		do
			fs.writeStringToFile(root .. "/" .. path .. ".luau", "return { sample = true }")
		end
		local docs: { string } = {}
		for _, prefix in { "Compose", "TestHost", "ComposeRoblox", "RobloxEmulator", "Author" } do
			table.insert(docs, "### `" .. prefix .. ".sample`")
		end
		fs.writeStringToFile(root .. "/docs/api.md", table.concat(docs, "\n"))
		return body(root)
	end)
end

local function check(root: string): (boolean, string)
	local result = process.run({ "lute", "run", "tools/check-public-surface.luau" }, { cwd = root })
	return result.ok, result.stdout .. result.stderr
end

describe("required repository surface", function()
	it("accepts complete public packages matching the documentation", function()
		fixture(function(root)
			local ok, output = check(root)
			if not ok then
				error(output, 0)
			end
			expect(ok):toBe(true)
			expect(output):toContain "5 exports"
			return 0
		end)
	end)

	it("refuses missing API documentation", function()
		fixture(function(root)
			fs.remove(root .. "/docs/api.md")
			local ok, output = check(root)
			expect(ok):toBe(false)
			expect(output):toContain "required docs/api.md is absent"
			return 0
		end)
	end)

	it("refuses a missing package even when its documentation is also removed", function()
		fixture(function(root)
			fs.remove(root .. "/src/core/init.luau")
			local docs = fs.readFileToString(root .. "/docs/api.md")
			fs.writeStringToFile(root .. "/docs/api.md", (string.gsub(docs, "### `Compose%.sample`\n", "")))
			local ok, output = check(root)
			expect(ok):toBe(false)
			expect(output):toContain "src/core/init.luau is required but absent"
			return 0
		end)
	end)

	it("refuses incomplete gate inputs before running child checks", function()
		fixture(function(root)
			local result = process.run({ "lute", "run", "tools/gate.luau", "--fast" }, { cwd = root })
			expect(result.ok):toBe(false)
			expect(result.stdout):toContain "requires missing target dependencies.lock.luau"
			return 0
		end)
	end)
end)

return nil
