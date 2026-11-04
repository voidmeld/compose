--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local function required<T>(value: T?): T
	assert(value ~= nil)
	return value
end

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("attribute writer lifetime", function()
	it("uses the current host writer for new bindings while preserving earlier bindings", function(own)
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		own(function()
			Compose.owner.dispose(owner)
		end)
		local render = world.host.adapter.render
		local original = assert(render.setAttribute)
		local replacementWrites = 0
		local source = Compose.cell(1)
		local first = Compose.withOwner(owner, function()
			return world.create "Frame" { Attributes = { Value = source } }
		end)
		render.setAttribute = function(node, name, value)
			replacementWrites += 1
			return original(node, name, value)
		end
		local second = Compose.withOwner(owner, function()
			return world.create "Frame" { Attributes = { Value = source } }
		end)
		expect(replacementWrites):toBe(1)
		source:set(2)
		world.settle()
		expect(replacementWrites):toBe(2)
		expect(world.host.attributeOf(first, "Value")):toBe(2)
		expect(world.host.attributeOf(second, "Value")):toBe(2)
		render.setAttribute = original
		local third = Compose.withOwner(owner, function()
			return world.create "Frame" { Attributes = { Value = source } }
		end)
		source:set(3)
		world.settle()
		expect(replacementWrites):toBe(3)
		expect(world.host.attributeOf(third, "Value")):toBe(3)
	end)
end)

local function parse(body: () -> ()): Compose.Diagnostic
	local ok, err: unknown = pcall(body)
	expect(ok):toBe(false)
	local parsed = Compose.parseDiagnostic(tostring(err))
	expect(parsed ~= nil):toBe(true)
	return required(parsed)
end

describe("the Attributes key", function()
	it("writes a static attribute", function()
		local world = Support.world()

		local dispose, node = world.runtime.mount(function()
			return world.create "Frame" {
				Attributes = { Tier = 3, Label = "elite", Hidden = false },
			}
		end, world.root)

		expect(world.host.attributeOf(node, "Tier")):toBe(3)
		expect(world.host.attributeOf(node, "Label")):toBe "elite"
		expect(world.host.attributeOf(node, "Hidden")):toBe(false)
		expect(world.host.propertyOf(node, "Attributes")):toBe(nil)
		dispose()
	end)

	it("still writes a real property under a wrapped key", function()
		local world = Support.world()
		local literal = { Tier = 3 }

		local dispose, node = world.runtime.mount(function()
			return world.create "Frame" { [Compose.property "Attributes"] = literal }
		end, world.root)

		expect(world.host.propertyOf(node, "Attributes")):toBe(literal)
		expect(world.host.attributeOf(node, "Tier")):toBe(nil)
		dispose()
	end)

	it("updates a reactive attribute when its source changes", function()
		local world = Support.world()
		local tier = Compose.cell<<number?>>(1)
		local dispose, node = world.runtime.mount(function()
			return world.create "Frame" {
				Attributes = {
					Tier = tier,
					Rank = function(use)
						return ("rank-%d"):format(use(tier) or 0)
					end,
				},
			}
		end, world.root)
		expect(world.host.attributeOf(node, "Tier")):toBe(1)
		expect(world.host.attributeOf(node, "Rank")):toBe "rank-1"
		tier:set(7)
		world.settle()
		expect(world.host.attributeOf(node, "Tier")):toBe(7)
		expect(world.host.attributeOf(node, "Rank")):toBe "rank-7"
		tier:set(nil)
		world.settle()
		expect(world.host.attributeOf(node, "Tier")):toBe(nil)
		dispose()
		world.host.resetCounts()
		tier:set(9)
		world.settle()
		expect(world.host.counts().setAttribute):toBe(0)
	end)

	it("writes a function value under static rather than calling it", function()
		local world = Support.world()

		local dispose, node = world.runtime.mount(function()
			return world.create "Frame" { Attributes = { Tier = Compose.static "literal" } }
		end, world.root)

		expect(world.host.attributeOf(node, "Tier")):toBe "literal"
		dispose()
	end)

	it("does not write again when the value is unchanged", function()
		local world = Support.world()
		local revision = Compose.cell(1)

		local dispose, node = world.runtime.mount(function()
			return world.create "Frame" {
				Attributes = {
					Tier = function(use)
						use(revision)
						return 3
					end,
				},
			}
		end, world.root)

		expect(world.host.attributeOf(node, "Tier")):toBe(3)
		world.host.resetCounts()
		revision:set(2)
		world.settle()
		expect(world.host.counts().setAttribute):toBe(0)
		dispose()
	end)

	it("clears its attributes off a borrowed node on disposal", function()
		local world = Support.world()
		local external = world.host.makeNode "External"

		local dispose = world.runtime.mount(function()
			world.runtime.decorate(external, { Attributes = { Tier = 3 } })
			return world.create "Frame" {}
		end, world.root)

		expect(world.host.attributeOf(external, "Tier")):toBe(3)
		dispose()
		expect(world.host.attributeOf(external, "Tier")):toBe(nil)
	end)

	it("refuses a non-string attribute name", function()
		for _, key in { 1, "" } do
			local world = Support.world()
			local report = parse(function()
				world.runtime.mount(function()
					return world.create "Frame" { Attributes = { Tier = 3, [key] = "invalid" } }
				end, world.root)
			end)
			expect(report.code):toBe "props/attribute-name"
			expect(report.fields.key):toBe "Attributes"
			expect(world.host.counts().setAttribute):toBe(0)
		end
	end)

	it("refuses something that is not a table", function()
		local world = Support.world()

		expect(function()
			world.runtime.mount(function()
				return world.create "Frame" { Attributes = 3 }
			end, world.root)
		end):toThrow "props/attributes-not-a-table"
	end)

	it("refuses a node given as an attribute value", function()
		local world = Support.world()

		local report = parse(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					Attributes = { Corner = world.create "UICorner" {} },
				}
			end, world.root)
		end)
		expect(report.code):toBe "props/child-under-attribute"
		expect(report.fields.key):toBe "Attributes.Corner"
		expect(string.find(report.fields.fix, "positional child", 1, true) ~= nil):toBe(true)
	end)

	it("refuses a value the host will not store, and says why", function()
		local world = Support.world()

		local report = parse(function()
			world.runtime.mount(function()
				return world.create "Frame" { Attributes = { Tier = { deep = true } } }
			end, world.root)
		end)
		expect(report.code):toBe "props/attribute-value"
		expect(report.fields.key):toBe "Attributes.Tier"
		expect(string.find(report.fields.detail, "TestScene", 1, true) ~= nil):toBe(true)
	end)

	it("surfaces an injected host refusal", function()
		local world = Support.world()
		world.host.failNext "setAttribute"

		local report = parse(function()
			world.runtime.mount(function()
				return world.create "Frame" { Attributes = { Tier = 3 } }
			end, world.root)
		end)
		expect(report.code):toBe "props/attribute-value"
		expect(string.find(report.fields.detail, "injected refusal", 1, true) ~= nil):toBe(true)
	end)

	it("unwinds the node when an attribute is refused", function()
		local world = Support.world()
		world.host.failNext "setAttribute"

		pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" { Attributes = { Tier = 3 } }
			end, world.root)
		end)

		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("refuses on a host with no attribute store", function()
		local world = Support.world()
		local bare = table.clone(world.host.adapter.render)
		bare.setAttribute = nil
		local runtime = Compose.createRuntime {
			name = "no-attributes",
			render = bare,
		}

		expect(function()
			runtime.mount(function()
				return runtime.create "Frame" { Attributes = { Tier = 3 } }
			end, world.root)
		end):toThrow "host/no-attributes"
	end)
end)

return nil
