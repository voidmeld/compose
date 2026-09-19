--!strict

local Author = require "../../authoring"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function props()
	return Author.set {
		name = "props",
		idKey = "id",
		roleKey = "role",
		entries = {
			{ id = "torch", role = "light" },
			{ id = "lantern", role = "light" },
			{ id = "crate", role = "clutter" },
		},
	}
end

describe("Author.coverage", function()
	it("answers full coverage when every id is in the key list", function()
		local report = Author.coverage(props(), { "torch", "lantern", "crate" })
		expect(report.missingIds):toHaveLength(0)
		expect(report.missingRoles):toHaveLength(0)
		expect(report.unknownKeys):toHaveLength(0)
	end)

	it("surfaces an authored id that fell through the key list", function()
		local report = Author.coverage(props(), { "torch", "crate" })
		expect(report.missingIds):toEqual { "lantern" }
		expect(report.missingRoles):toEqual { "light" }
	end)

	it("surfaces a registry key that names no authored entry", function()
		local report = Author.coverage(props(), { "torch", "lantern", "crate", "throne" })
		expect(report.missingIds):toHaveLength(0)
		expect(report.unknownKeys):toEqual { "throne" }
	end)

	it("reports missing ids and roles sorted, regardless of authored order", function()
		local set = Author.set {
			name = "props",
			idKey = "id",
			roleKey = "role",
			entries = {
				{ id = "zeppelin", role = "vehicle" },
				{ id = "anvil", role = "clutter" },
			},
		}
		local report = Author.coverage(set, {})
		expect(report.missingIds):toEqual { "anvil", "zeppelin" }
		expect(report.missingRoles):toEqual { "clutter", "vehicle" }
	end)

	it("reports a role as soon as any one of its entries falls through", function()
		local report = Author.coverage(props(), { "torch", "crate" })
		expect(report.missingRoles):toEqual { "light" }
		local covered = Author.coverage(props(), { "torch", "lantern" })
		expect(covered.missingIds):toEqual { "crate" }
		expect(covered.missingRoles):toEqual { "clutter" }
	end)
end)

return nil
