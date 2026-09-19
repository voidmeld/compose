--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("a node under a string key", function()
	it("refuses a node given as a property value", function()
		local world = Support.world()

		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Corner = world.create "UICorner" {},
				}
			end, world.root)
		end):toThrow "props/child-under-string-key"
	end)

	it("names the key and the fix", function()
		local world = Support.world()

		local ok, err: any = pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Corner = world.create "UICorner" {},
				}
			end, world.root)
		end)
		expect(ok):toBe(false)

		local parsed = Compose.parseDiagnostic(tostring(err))
		expect(parsed ~= nil):toBe(true)
		local report = parsed :: any
		expect(report.code):toBe "props/child-under-string-key"
		expect(report.fields.key):toBe "Corner"
		expect(string.find(report.fields.fix, "positional child", 1, true) ~= nil):toBe(true)
	end)

	it("raises before any write reaches the host", function()
		local world = Support.world()
		world.host.resetCounts()

		pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Corner = world.create "UICorner" {},
				}
			end, world.root)
		end)

		expect(world.host.counts().setProperty):toBe(0)
	end)

	it("refuses a node under a wrapped property key", function()
		local world = Support.world()

		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					[Compose.property "Corner"] = world.create "UICorner" {},
				}
			end, world.root)
		end):toThrow "props/child-under-string-key"
	end)

	it("refuses a node under a string key on decorate", function()
		local world = Support.world()
		local external = world.host.makeNode "External"

		expect(function()
			world.runtime.mount(function()
				world.runtime.decorate(external, {
					Corner = world.create "UICorner" {},
				})
				return world.create "Frame" {}
			end, world.root)
		end):toThrow "props/child-under-string-key"
	end)

	it("refuses a node this runtime adopted", function()
		local world = Support.world()
		local external = world.host.makeNode "Adopted"

		expect(function()
			world.runtime.mount(function()
				world.runtime.adopt(external)
				return world.create "Frame" { Value = external }
			end, world.root)
		end):toThrow "props/child-under-string-key"
	end)

	it("leaves the positional child shape alone", function()
		local world = Support.world()

		local dispose, node = world.runtime.mount(function()
			return world.create "Frame" {
				world.create "UICorner" {},
			}
		end, world.root)

		expect(#world.host.childrenOf(node)):toBe(1)
		expect(world.host.kindOf(world.host.childrenOf(node)[1])):toBe "UICorner"
		dispose()
	end)

	it("still writes an ordinary table value", function()
		local world = Support.world()
		local size = { width = 3, height = 4 }

		local dispose, node = world.runtime.mount(function()
			return world.create "Frame" { Size = size }
		end, world.root)

		expect(world.host.propertyOf(node, "Size")):toBe(size)
		dispose()
	end)

	it("still writes a host node Compose never took custody of", function()
		local world = Support.world()
		local external = world.host.makeNode "Camera"

		local dispose, node = world.runtime.mount(function()
			return world.create "Frame" { CurrentCamera = external }
		end, world.root)

		expect(world.host.propertyOf(node, "CurrentCamera")):toBe(external)
		dispose()
	end)

	it("still writes a node this runtime borrowed", function()
		local world = Support.world()
		local external = world.host.makeNode "Camera"

		local dispose, node = world.runtime.mount(function()
			return world.create "Frame" { CurrentCamera = world.runtime.borrow(external) }
		end, world.root)

		expect(world.host.propertyOf(node, "CurrentCamera")):toBe(external)
		dispose()
	end)

	it("writes an owned node under static", function()
		local world = Support.world()

		local dispose, node = world.runtime.mount(function()
			local corner = world.create "UICorner" {}
			return world.create "Frame" { Corner = Compose.static(corner) }
		end, world.root)

		expect(world.host.kindOf(world.host.propertyOf(node, "Corner") :: any)):toBe "UICorner"
		dispose()
	end)

	it("does not check a node that arrives through a binding", function()
		local world = Support.world()

		local dispose, node = world.runtime.mount(function()
			local corner = world.create "UICorner" {}
			return world.create "Frame" {
				Corner = function()
					return corner
				end,
			}
		end, world.root)

		expect(world.host.kindOf(world.host.propertyOf(node, "Corner") :: any)):toBe "UICorner"
		dispose()
	end)
end)

return nil
