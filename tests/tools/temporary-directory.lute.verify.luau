--!strict

local fs = require "@std/fs"
local process = require "@lute/process"
local Test = require "../harness"
local TemporaryDirectory = require "../../tools/lib/temporary-directory"

local describe, it, expect = Test.describe, Test.it, Test.expect
local PARENT = string.gsub(process.env["TMPDIR"] or "/tmp", "/+$", "")

describe("temporary directory ownership", function()
	it("isolates overlapping invocations with the same name and retains the live owner", function()
		local outerPath = ""
		local innerPath = ""
		local result = TemporaryDirectory.run(PARENT, "compose-clean-clone", function(outer)
			outerPath = outer
			fs.writeStringToFile(outer .. "/candidate", "outer candidate")
			TemporaryDirectory.run(PARENT .. "/", "compose-clean-clone", function(inner)
				innerPath = inner
				expect(inner == outer):toBe(false)
				fs.writeStringToFile(inner .. "/candidate", "inner candidate")
				expect(fs.readFileToString(outer .. "/candidate")):toBe "outer candidate"
				return 0
			end)
			expect(fs.exists(innerPath)):toBe(false)
			expect(fs.readFileToString(outer .. "/candidate")):toBe "outer candidate"
			return 7
		end)
		expect(result):toBe(7)
		expect(fs.exists(outerPath)):toBe(false)
	end)

	it("cleans a failed candidate without removing another invocation", function()
		local failedPath = ""
		TemporaryDirectory.run(PARENT, "compose-clean-clone", function(outer)
			local ok, failure = pcall(function()
				TemporaryDirectory.run(PARENT, "compose-clean-clone", function(inner)
					failedPath = inner
					error("candidate failed", 0)
				end)
			end)
			expect(ok):toBe(false)
			expect(tostring(failure)):toContain "candidate failed"
			expect(fs.exists(failedPath)):toBe(false)
			expect(fs.exists(outer)):toBe(true)
			return 0
		end)
	end)
end)

return nil
