--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("fused terminal bindings", function()
	it("stops adding queue entries once a source is wide enough to fuse", function()
		local world = Support.world()
		local tint = Compose.cell(0)
		local Label = world.create "Label"

		local function mountMany(count: number)
			return world.runtime.mount(function()
				local children = table.create(count)
				for index = 1, count do
					children[index] = Label {
						Text = function(use)
							return tostring(use(tint)) .. index
						end,
					}
				end
				return (world.create "Frame")(children)
			end, world.root)
		end

		local narrow = mountMany(20)
		local narrowEntries = 0
		world.batch(function()
			tint:set(1)
			narrowEntries = world.pending()
		end)
		world.settle()
		narrow()

		local wide = mountMany(200)
		local wideEntries = 0
		world.batch(function()
			tint:set(2)
			wideEntries = world.pending()
		end)
		world.settle()
		wide()

		expect(wideEntries <= narrowEntries):toBe(true)
		expect(wideEntries < 20):toBe(true)
		expect(narrowEntries < 20):toBe(true)
	end)

	it("writes every fused binding", function()
		local world = Support.world()
		local tint = Compose.cell(0)
		local Label = world.create "Label"

		local dispose, root = world.runtime.mount(function()
			local children = table.create(10)
			for index = 1, 10 do
				children[index] = Label {
					Text = function(use)
						return ("%d-%d"):format(use(tint), index)
					end,
				}
			end
			return (world.create "Frame")(children)
		end, world.root)

		tint:set(7)
		world.settle()
		local children = world.host.childrenOf(root)
		for index = 1, 10 do
			expect(world.host.propertyOf(children[index], "Text")):toBe(("7-%d"):format(index))
		end
		dispose()
	end)

	it("keeps batch atomicity: nothing runs until the batch closes", function()
		local world = Support.world()
		local tint = Compose.cell(0)
		local runs = 0
		local Label = world.create "Label"

		local dispose = world.runtime.mount(function()
			local children = table.create(5)
			for index = 1, 5 do
				children[index] = Label {
					Text = function(use)
						runs += 1
						return tostring(use(tint)) .. index
					end,
				}
			end
			return (world.create "Frame")(children)
		end, world.root)

		runs = 0
		world.batch(function()
			tint:set(1)
			tint:set(2)
			tint:set(3)
			expect(runs):toBe(0)
		end)
		world.settle()
		expect(runs):toBe(5)
		dispose()
	end)

	it("suppresses an equal write, as it always did", function()
		local world = Support.world()
		local tint = Compose.cell(1)
		local runs = 0
		local Label = world.create "Label"

		local dispose = world.runtime.mount(function()
			local children = table.create(5)
			for index = 1, 5 do
				children[index] = Label {
					Text = function(use)
						runs += 1
						return tostring(use(tint))
					end,
				}
			end
			return (world.create "Frame")(children)
		end, world.root)

		runs = 0
		tint:set(1)
		world.settle()
		expect(runs):toBe(0)
		dispose()
	end)

	it("contains one member's failure: its siblings still run", function()
		local world = Support.world()
		local tint = Compose.cell(0)
		local ran = 0
		local Label = world.create "Label"

		local dispose = world.runtime.mount(function()
			return (world.create "Frame") {
				Label {
					Text = function(use)
						ran += 1
						return tostring(use(tint))
					end,
				},
				Label {
					Text = function(use)
						local value = use(tint)
						if value > 0 then
							error "this member is broken"
						end
						return "0"
					end,
				},
				Label {
					Text = function(use)
						ran += 1
						return tostring(use(tint))
					end,
				},
			}
		end, world.root)

		ran = 0
		pcall(function()
			tint:set(1)
			world.settle()
		end)
		expect(ran):toBe(2)
		dispose()
	end)

	it("evicts a member whose dependency set grows, and keeps it working", function()
		local world = Support.world()
		local first = Compose.cell(1)
		local second = Compose.cell(10)
		local widen = Compose.cell(false)
		local Label = world.create "Label"

		local dispose, root = world.runtime.mount(function()
			return (world.create "Frame") {
				Label {
					Text = function(use: Compose.Use)
						if use(widen) then
							return ("%d+%d"):format(use(first), use(second))
						end
						return tostring(use(first))
					end,
				},
			}
		end, world.root)
		local node = world.host.childrenOf(root)[1]

		widen:set(true)
		world.settle()
		expect(world.host.propertyOf(node, "Text")):toBe "1+10"

		second:set(20)
		world.settle()
		expect(world.host.propertyOf(node, "Text")):toBe "1+20"
		first:set(2)
		world.settle()
		expect(world.host.propertyOf(node, "Text")):toBe "2+20"

		dispose()
	end)

	it("releases exactly what a disposed binding held", function()
		local world = Support.world()
		local tint = Compose.cell(0)
		local runs = 0
		local Label = world.create "Label"

		local outer = world.runtime.mount(function()
			return Label {
				Text = function(use)
					runs += 1
					return tostring(use(tint))
				end,
			}
		end, world.root)
		local inner = world.runtime.mount(function()
			return Label {
				Text = function(use)
					runs += 1
					return tostring(use(tint))
				end,
			}
		end, world.root)

		outer()
		runs = 0
		tint:set(1)
		world.settle()
		expect(runs):toBe(1)

		inner()
		runs = 0
		tint:set(2)
		world.settle()
		expect(runs):toBe(0)
		expect(world.host.liveNodes()):toBe(1)
	end)

	it("does not fuse across two runtimes", function()
		local first = Support.world()
		local second = Support.world()
		local shared = Compose.cell(0)

		local disposeFirst = first.runtime.mount(function()
			return (first.create "Label") {
				Text = function(use)
					return tostring(use(shared))
				end,
			}
		end, first.root)
		local disposeSecond = second.runtime.mount(function()
			return (second.create "Label") {
				Text = function(use)
					return tostring(use(shared))
				end,
			}
		end, second.root)

		first.batch(function()
			shared:set(1)
			expect(first.pending()):toBe(1)
		end)
		first.settle()
		second.settle()

		disposeFirst()
		disposeSecond()
	end)

	it("keeps the profiler counting every member's run", function()
		local world = Support.world()
		local tint = Compose.cell(0)
		local Label = world.create "Label"

		local dispose = world.runtime.mount(function()
			local children = table.create(6)
			for index = 1, 6 do
				children[index] = Label {
					Text = function(use)
						return tostring(use(tint)) .. index
					end,
				}
			end
			return (world.create "Frame")(children)
		end, world.root)

		local session = Compose.profile
		local clock = 0
		session.start(function(): number
			clock += 1
			return clock
		end)
		tint:set(1)
		world.settle()
		local snapshot = session.data(session.stop())
		expect(snapshot.totals.runs >= 6):toBe(true)
		dispose()
	end)
end)

describe("direct binding sinks", function()
	it("queues one sink for a wide direct fan-out", function()
		local world = Support.world()
		local tint = Compose.cell "0"
		local Label = world.create "Label"
		local dispose, root = world.runtime.mount(function()
			local children = table.create(200)
			for index = 1, 200 do
				children[index] = Label { Text = tint }
			end
			return (world.create "Frame")(children)
		end, world.root)

		world.batch(function()
			tint:set "1"
			expect(world.pending()):toBe(1)
		end)
		for _, node in world.host.childrenOf(root) do
			expect(world.host.propertyOf(node, "Text")):toBe "1"
		end
		dispose()
		expect(world.host.leaked()):toEqual { "Root#1" }
	end)

	it("lets an unchanged formula stop before its direct bindings", function()
		local world = Support.world()
		local source = Compose.cell(0)
		local parity = Compose.formula(function(use)
			return use(source) % 2
		end)
		local dispose = world.runtime.mount(function()
			return (world.create "Label") { Text = parity }
		end, world.root)

		world.host.resetCounts()
		source:set(2)
		world.settle()
		expect(world.host.counts().setProperty):toBe(0)
		source:set(3)
		world.settle()
		expect(world.host.counts().setProperty):toBe(1)
		dispose()
	end)
end)

return nil
