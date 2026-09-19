--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("structural arguments", function()
	it("takes a cell directly, not only a body", function()
		local world = Support.world()
		local rows = Compose.cell { { id = 1 }, { id = 2 } }
		local Label = world.create "Label"

		local dispose, root = world.runtime.mount(function()
			return (world.create "Frame") {
				Compose.keyed {
					from = rows,
					key = function(row: { id: number })
						return row.id
					end,
					render = function()
						return Label {}
					end,
				},
			}
		end, world.root)

		expect(#world.host.childrenOf(root)):toBe(2)
		dispose()
	end)

	it("names a source it cannot read", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				return (world.create "Frame") {
					(Compose.keyed :: any) { from = 3, render = function() end },
				}
			end, world.root)
		end):toThrow "structure/source-not-readable"
	end)

	it("names a render it cannot call", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				return (world.create "Frame") {
					(Compose.keyed :: any) { from = Compose.cell {}, render = "not a function" },
				}
			end, world.root)
		end):toThrow "structure/builder-not-a-function"
	end)

	it("names the positional call it no longer takes", function()
		local world = Support.world()
		local rows = Compose.cell {}
		expect(function()
			world.runtime.mount(function()
				return (world.create "Frame") {
					(Compose.keyed :: any)(rows, function() end),
				}
			end, world.root)
		end):toThrow "structure/options-not-a-table"
	end)

	it("names an option it does not have", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				return (world.create "Frame") {
					(Compose.keyed :: any) {
						from = Compose.cell {},
						render = function() end,
						keyOf = function() end,
					},
				}
			end, world.root)
		end):toThrow "structure/unknown-option"
	end)

	it("names a condition it cannot read", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				return (world.create "Frame") {
					Compose.show(3 :: any, function()
						return world.create "Frame" {}
					end),
				}
			end, world.root)
		end):toThrow "structure/source-not-readable"
	end)

	it("names a builder that is not a function, rather than failing inside debug.info", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				return (world.create "Frame") {
					Compose.show(Compose.cell(true), {} :: any),
				}
			end, world.root)
		end):toThrow "structure/builder-not-a-function"
	end)

	it("takes a cell as a condition", function()
		local world = Support.world()
		local open = Compose.cell(true)
		local Frame = world.create "Frame"

		local dispose, root = world.runtime.mount(function()
			return Frame {
				Compose.show(open, function()
					return Frame {}
				end),
			}
		end, world.root)

		expect(#world.host.childrenOf(root)):toBe(1)
		open:set(false)
		world.settle()
		expect(#world.host.childrenOf(root)):toBe(0)
		dispose()
	end)
end)

return nil
