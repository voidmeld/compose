--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("owner context", function()
	it("reads the default without a provider or active owner", function()
		Compose.__resetForTests()
		local context: Compose.Context<string> = Compose.createContext "default"
		expect(context.read()):toBe "default"
		Compose.withRootOwner(function(owner)
			expect(context.read()):toBe "default"
			Compose.withOwner(Compose.owner.createChild(owner), function()
				expect(context.read()):toBe "default"
			end)
		end)
	end)

	it("reads the nearest nested override and restores the outer value", function()
		local context = Compose.createContext "default"
		Compose.withRootOwner(function()
			local result = context.provide("outer", function(): number
				expect(context.read()):toBe "outer"
				context.provide("inner", function()
					expect(context.read()):toBe "inner"
					local child = Compose.createOwner()
					Compose.withOwner(child, function()
						expect(context.read()):toBe "inner"
					end)
					Compose.owner.dispose(child)
				end)
				expect(context.read()):toBe "outer"
				return 42
			end)
			expect(result):toBe(42)
			expect(context.read()):toBe "default"
		end)
	end)

	it("isolates sibling providers after their bodies return", function()
		local context = Compose.createContext "default"
		Compose.withRootOwner(function()
			local function capture(): Compose.Owner
				return Compose.createOwner()
			end
			local left = context.provide("left", capture)
			local right = context.provide("right", capture)
			Compose.withOwner(left, function()
				expect(context.read()):toBe "left"
			end)
			Compose.withOwner(right, function()
				expect(context.read()):toBe "right"
			end)
			expect(context.read()):toBe "default"
			Compose.owner.dispose(left)
			Compose.owner.dispose(right)
		end)
	end)

	it("inherits in children created later by a watch", function()
		local context = Compose.createContext "default"
		local source = Compose.cell(0)
		local seen: { string } = {}
		local scope = Compose.createRootOwner(function()
			context.provide("inherited", function()
				Compose.watch(function(use)
					local _ = use(source)
					local owner = Compose.currentOwner()
					assert(owner ~= nil)
					Compose.withOwner(Compose.owner.createChild(owner), function()
						table.insert(seen, context.read())
					end)
				end)
			end)
		end)
		source:set(1)
		source:set(2)
		expect(seen):toEqual { "inherited", "inherited", "inherited" }
		scope.dispose()
		source:set(3)
		expect(#seen):toBe(3)
	end)

	it("stops resolving values through a disposed owner", function()
		local context = Compose.createContext "default"
		Compose.withRootOwner(function()
			context.provide("outer", function()
				context.provide("inner", function()
					local owner = Compose.currentOwner()
					assert(owner ~= nil)
					local independent = Compose.createOwner()
					Compose.owner.dispose(owner)
					expect(context.read()):toBe "default"
					Compose.withOwner(independent, function()
						expect(context.read()):toBe "default"
					end)
					Compose.owner.dispose(independent)
				end)
				expect(context.read()):toBe "outer"
			end)
		end)
	end)

	it("reads in a watch without allocating its lazy owner", function()
		local context = Compose.createContext "default"
		local source = Compose.cell(0)
		Compose.withRootOwner(function()
			context.provide("inherited", function()
				local owner = Compose.currentOwner()
				assert(owner ~= nil)
				Compose.watch(function(use)
					local _ = use(source)
					local before = Compose.owner.size(owner)
					expect(context.read()):toBe "inherited"
					expect(Compose.owner.size(owner)):toBe(before)
				end)
				source:set(1)
			end)
		end)
	end)

	it("inherits across runtime mount roots inside provide", function()
		local first = Support.world()
		local second = Support.world()
		local context = Compose.createContext "default"
		local seen: { string } = {}
		local dispose = context.provide("mounted", function(): Compose.Dispose
			local release = first.runtime.mount(function()
				table.insert(seen, context.read())
				second.runtime.mount(function()
					table.insert(seen, context.read())
					return second.create "Panel" {}
				end, second.root)
				return first.create "Panel" {}
			end, first.root)
			return release
		end)
		expect(seen):toEqual { "mounted", "mounted" }
		expect(context.read()):toBe "default"
		dispose()
		expect(#first.host.childrenOf(first.root)):toBe(0)
		expect(#second.host.childrenOf(second.root)):toBe(0)
	end)

	it("keeps readable values unchanged and adds no reactive dependency", function()
		local fallback = Compose.cell(0)
		local provided = Compose.cell(1)
		local context: Compose.Context<Compose.Value<number>> = Compose.createContext(fallback)
		local runs = 0
		Compose.withRootOwner(function()
			context.provide(provided, function()
				Compose.watch(function()
					runs += 1
					expect(context.read()):toBe(provided)
				end)
				provided:set(2)
				expect(context.read():peek()):toBe(2)
				expect(runs):toBe(1)
			end)
		end)
	end)

	it("preserves nil and false as provided values", function()
		local function fallback(): boolean?
			return true
		end
		local context = Compose.createContext(fallback())
		Compose.withRootOwner(function()
			context.provide(nil, function()
				expect(context.read()):toBeNil()
				context.provide(false, function()
					expect(context.read()):toBe(false)
				end)
				expect(context.read()):toBeNil()
			end)
		end)
	end)

	it("unwinds a failed provider and restores the previous owner", function()
		local context = Compose.createContext "default"
		local failure = {}
		local released = 0
		Compose.withRootOwner(function(owner)
			local ok, result = pcall(function()
				context.provide("failed", function()
					Compose.cleanup(function()
						released += 1
					end)
					error(failure, 0)
				end)
			end)
			expect(ok):toBe(false)
			expect(result):toBe(failure)
			expect(released):toBe(1)
			expect(Compose.currentOwner()):toBe(owner)
			expect(context.read()):toBe "default"
		end)
	end)

	it("inherits in slot attachments created after provide returns", function()
		local context = Compose.createContext "default"
		Compose.withRootOwner(function()
			local slot = context.provide("slot", function(): Compose.Slot
				return Compose.createSlot()
			end)
			local seen: { string } = {}
			for _, key in { "first", "second" } do
				slot.bind(key, function()
					table.insert(seen, context.read())
				end)
			end
			expect(seen):toEqual { "slot", "slot" }
		end)
	end)

	it("inherits in keyed children added after provide returns", function()
		local world = Support.world()
		local context = Compose.createContext "default"
		local items = Compose.cell { "first" }
		local seen: { string } = {}
		local dispose = context.provide("keyed", function(): Compose.Dispose
			local release = world.runtime.mount(function()
				return world.create "Panel" {
					Compose.keyed {
						from = items,
						key = function(value: string): string
							return value
						end,
						render = function()
							table.insert(seen, context.read())
							return world.create "Row" {}
						end,
					},
				}
			end, world.root)
			return release
		end)
		items:set { "first", "second" }
		world.settle()
		expect(seen):toEqual { "keyed", "keyed" }
		dispose()
	end)

	it("inherits in OrderedCollection children rebuilt after provide returns", function()
		local world = Support.world()
		local context = Compose.createContext "default"
		local items = Compose.cell { "first", "second" }
		local initial: Compose.OrderedCollectionViewport = { offset = 0, size = 10 }
		local viewport = Compose.cell(initial)
		local layout: Compose.OrderedCollectionLayout = { itemSize = 10 }
		local seen: { string } = {}
		local dispose = context.provide("ordered", function(): Compose.Dispose
			local release = world.runtime.mount(function()
				return world.create "Panel" {
					Compose.OrderedCollection {
						from = items,
						key = function(value: string): string
							return value
						end,
						mode = "windowed",
						viewport = viewport,
						layout = layout,
						overscan = 0,
						render = function()
							table.insert(seen, context.read())
							return world.create "Row" {}
						end,
					},
				}
			end, world.root)
			return release
		end)
		viewport:set { offset = 10, size = 10 }
		world.settle()
		expect(seen):toEqual { "ordered", "ordered" }
		dispose()
	end)
end)

return nil
