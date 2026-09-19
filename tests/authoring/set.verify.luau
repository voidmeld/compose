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
			{ id = "torch", role = "light", model = "TorchA" },
			{ id = "lantern", role = "light", model = "LanternA" },
			{ id = "crate", role = "clutter", model = "CrateA" },
		},
	}
end

describe("Author.set", function()
	it("wraps authored entries and reports its name", function()
		local set = props()
		expect(set.name):toBe "props"
		expect(#set.entries):toBe(3)
	end)

	it("refuses a declaration without a name", function()
		expect(function()
			Author.set({ idKey = "id", entries = {} } :: any)
		end):toThrow "name"
	end)

	it("refuses a declaration without an idKey", function()
		expect(function()
			Author.set({ name = "props", entries = {} } :: any)
		end):toThrow "idKey"
	end)

	it("refuses an entry that is not a table", function()
		expect(function()
			Author.set { name = "props", idKey = "id", entries = { "torch" } :: any }
		end):toThrow "entry"
	end)

	it("refuses an entry whose id field is missing or not a string", function()
		expect(function()
			Author.set { name = "props", idKey = "id", entries = { { role = "light" } } }
		end):toThrow "id"
		expect(function()
			Author.set { name = "props", idKey = "id", entries = { { id = 7 } } }
		end):toThrow "id"
	end)

	it("refuses declaring both a fixed role and a roleKey", function()
		expect(function()
			Author.set {
				name = "props",
				idKey = "id",
				role = "light",
				roleKey = "role",
				entries = {},
			}
		end):toThrow "role"
	end)

	it("finds an entry by id, and answers nil for an unknown id", function()
		local set = props()
		local torch = set:byId "torch"
		expect(torch):toBeOk()
		expect((torch :: any).model):toBe "TorchA"
		expect(set:byId "throne"):toBeNil()
	end)

	it("answers byRole in authored order, deterministically", function()
		local set = props()
		local lights = set:byRole "light"
		expect(#lights):toBe(2)
		expect((lights[1] :: any).id):toBe "torch"
		expect((lights[2] :: any).id):toBe "lantern"
		expect(#set:byRole "throne"):toBe(0)
	end)

	it("applies a fixed role to every entry when role is declared", function()
		local set = Author.set {
			name = "doors",
			idKey = "id",
			role = "portal",
			entries = { { id = "gate" }, { id = "hatch" } },
		}
		local portals = set:byRole "portal"
		expect(#portals):toBe(2)
		expect(#set:byRole "light"):toBe(0)
	end)
end)

return nil
