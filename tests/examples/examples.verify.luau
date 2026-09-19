--!strict
local Compose = require "../../src/core"
local Examples = require "../../examples"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("examples", function()
	Test.beforeEach(function()
		Compose.__resetForTests()
	end)

	for _, example in Examples.all do
		it(("%s: %s"):format(example.name, example.what), function()
			expect(example.run()):toBe(example.expected)
		end)
	end
end)

return nil
