--!strict

local Test = require "../harness"
local resources = require "../../tools/lib/gate-resources"

Test.it("test workers fit cores, available memory and the source count", function()
	Test.expect(resources(4, 16384, 100)):toBe(4)
	Test.expect(resources(12, 32768, 100)):toBe(8)
	Test.expect(resources(8, 8192, 100)):toBe(3)
	Test.expect(resources(4, 1024, 100)):toBe(1)
	Test.expect(resources(4, 16384, 2)):toBe(2)
end)

return nil
