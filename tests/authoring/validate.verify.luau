--!strict

local Author = require "../../authoring"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function models()
	return Author.set {
		name = "models",
		idKey = "id",
		entries = {
			{ id = "torch-a" },
			{ id = "crate-a" },
		},
	}
end

describe("Author.validate", function()
	it("answers ok with no violations for a clean set", function()
		local set = models()
		local ok, violations = Author.validate(set, { idPattern = "^%l+%-%l$", unique = true })
		expect(ok):toBe(true)
		expect(violations):toHaveLength(0)
	end)

	it("reports an id that does not match idPattern, as a structured record", function()
		local set = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "Torch" } },
		}
		local ok, violations = Author.validate(set, { idPattern = "^%l[%l%d%-]*$" })
		expect(ok):toBe(false)
		expect(violations):toEqual {
			{
				setName = "props",
				entryId = "Torch",
				rule = "idPattern",
				detail = 'id "Torch" does not match pattern "^%l[%l%d%-]*$"',
			},
		}
	end)

	it("reports a duplicated id once per extra occurrence", function()
		local set = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch" }, { id = "torch" } },
		}
		local ok, violations = Author.validate(set, { unique = true })
		expect(ok):toBe(false)
		expect(violations):toEqual {
			{
				setName = "props",
				entryId = "torch",
				rule = "unique",
				detail = 'id "torch" appears more than once (first at entry 1, again at entry 2)',
			},
		}
	end)

	it("reports a missing required field", function()
		local set = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch", model = "TorchA" }, { id = "crate" } },
		}
		local ok, violations = Author.validate(set, { required = { "model" } })
		expect(ok):toBe(false)
		expect(violations):toEqual {
			{
				setName = "props",
				entryId = "crate",
				rule = "required",
				detail = 'required field "model" is missing',
			},
		}
	end)

	it("reports a reference whose target id is not in the other set", function()
		local set = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch", model = "torch-a" }, { id = "ghost", model = "phantom-x" } },
		}
		local ok, violations = Author.validate(set, {
			refs = { { field = "model", into = models() } },
		})
		expect(ok):toBe(false)
		expect(violations):toEqual {
			{
				setName = "props",
				entryId = "ghost",
				rule = "refs",
				detail = 'field "model" = "phantom-x" is not an id in set "models"',
			},
		}
	end)

	it("reports a field value outside a declared oneOf list", function()
		local set = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch", tier = "near" }, { id = "crate", tier = "cosmic" } },
		}
		local ok, violations = Author.validate(set, {
			refs = { { field = "tier", oneOf = { "near", "mid", "far" } } },
		})
		expect(ok):toBe(false)
		expect(violations):toEqual {
			{
				setName = "props",
				entryId = "crate",
				rule = "refs",
				detail = 'field "tier" = "cosmic" is not one of: "near", "mid", "far"',
			},
		}
	end)

	it("collects every violation in entry order rather than stopping at the first", function()
		local set = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "Bad One" }, { id = "torch" }, { id = "Bad One" } },
		}
		local ok, violations = Author.validate(set, { idPattern = "^%l+$", unique = true })
		expect(ok):toBe(false)
		expect(#violations):toBe(3)
		expect((violations[1] :: any).rule):toBe "idPattern"
		expect((violations[1] :: any).entryId):toBe "Bad One"
		expect((violations[2] :: any).rule):toBe "idPattern"
		expect((violations[3] :: any).rule):toBe "unique"
	end)

	it("refuses a refs rule that names neither into nor oneOf", function()
		local set = models()
		expect(function()
			Author.validate(set, { refs = { { field = "model" } } })
		end):toThrow "refs"
	end)
end)

return nil
