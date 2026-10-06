--!strict

local Author = require "../../authoring"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("Author.digest", function()
	it("is deterministic for the same set", function()
		local set = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch", model = "TorchA", tier = 2 } },
		}
		expect(Author.digest(set)):toBe(Author.digest(set))
	end)

	it("is stable across entry key order", function()
		local first = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch", model = "TorchA", tier = 2, lit = true } },
		}
		local second = Author.set {
			name = "props",
			idKey = "id",
			entries = { { lit = true, tier = 2, model = "TorchA", id = "torch" } },
		}
		expect(Author.digest(first)):toBe(Author.digest(second))
	end)

	it("is stable across entry array order", function()
		local first = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch" }, { id = "crate" } },
		}
		local second = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "crate" }, { id = "torch" } },
		}
		expect(Author.digest(first)):toBe(Author.digest(second))
	end)

	it("changes when a field value changes", function()
		local first = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch", tier = 2 } },
		}
		local second = Author.set {
			name = "props",
			idKey = "id",
			entries = { { id = "torch", tier = 3 } },
		}
		expect(Author.digest(first) ~= Author.digest(second)):toBe(true)
	end)

	it("changes when the set name changes", function()
		local first = Author.set { name = "props", idKey = "id", entries = { { id = "torch" } } }
		local second = Author.set { name = "clutter", idKey = "id", entries = { { id = "torch" } } }
		expect(Author.digest(first) ~= Author.digest(second)):toBe(true)
	end)

	it("distinguishes the string 2 from the number 2", function()
		local first = Author.set { name = "props", idKey = "id", entries = { { id = "torch", tier = 2 } } }
		local second = Author.set { name = "props", idKey = "id", entries = { { id = "torch", tier = "2" } } }
		expect(Author.digest(first) ~= Author.digest(second)):toBe(true)
	end)

	it("renders as fixed-width lowercase hex", function()
		local set = Author.set { name = "props", idKey = "id", entries = {} }
		local digest = Author.digest(set)
		expect(string.match(digest, "^%x+$")):toBeOk()
		expect(#digest):toBe(16)
		expect(digest):toBe(string.lower(digest))
	end)
end)

return nil
