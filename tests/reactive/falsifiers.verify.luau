--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function domain()
	local reactor = Compose.reactor()
	return reactor, Compose.createOwner(reactor)
end

describe("falsifiers", function()
	describe("dynamic dependency churn", function()
		it("forgets a source a rerun no longer reads", function()
			local reactor, owner = domain()
			local useLeft = Compose.cell(true)
			local left = Compose.cell "L"
			local right = Compose.cell "R"
			local seen: { string } = {}

			owner.watch(function(use)
				if use(useLeft) then
					table.insert(seen, use(left))
				else
					table.insert(seen, use(right))
				end
			end)
			expect(seen):toEqual { "L" }

			useLeft:set(false)
			reactor:settle()
			expect(seen):toEqual { "L", "R" }

			left:set "L2"
			reactor:settle()
			expect(seen):toEqual { "L", "R" }

			right:set "R2"
			reactor:settle()
			expect(seen):toEqual { "L", "R", "R2" }
			owner.dispose()
		end)

		it("survives a dependency list that grows, shrinks, and reorders", function()
			local reactor, owner = domain()
			local cells = {}
			for index = 1, 6 do
				cells[index] = Compose.cell(index)
			end
			local shape = Compose.cell { 1, 2, 3 }
			local seen: { number } = {}

			owner.watch(function(use)
				local total = 0
				for _, index in use(shape) do
					total += use(cells[index])
				end
				table.insert(seen, total)
			end)
			expect(seen):toEqual { 6 }

			shape:set { 1, 2, 3, 4, 5 }
			reactor:settle()
			expect(seen[#seen]):toBe(15)

			shape:set { 5, 1 }
			reactor:settle()
			expect(seen[#seen]):toBe(6)

			local before = #seen
			cells[3]:set(300)
			reactor:settle()
			expect(#seen):toBe(before)

			cells[5]:set(50)
			reactor:settle()
			expect(seen[#seen]):toBe(51)
			owner.dispose()
		end)
	end)

	describe("lifetime is deterministic, and needs no retained handle", function()
		it("keeps running with the dispose thrown away", function()
			local reactor, owner = domain()
			local count = Compose.cell(0)
			local runs = 0
			owner.watch(function(use)
				use(count)
				runs += 1
			end)

			for _ = 1, 200 do
				local junk = table.create(200)
				for index = 1, 200 do
					junk[index] = { index }
				end
				junk = nil :: any
			end

			count:set(1)
			reactor:settle()
			expect(runs):toBe(2)
			owner.dispose()
		end)

		it("stops exactly when the owner is disposed, not before or after", function()
			local reactor, root = domain()
			local count = Compose.cell(0)
			local outer, inner = 0, 0
			local child = root.createChild()

			root.watch(function(use)
				use(count)
				outer += 1
			end)
			child.watch(function(use)
				use(count)
				inner += 1
			end)

			count:set(1)
			reactor:settle()
			expect({ outer, inner }):toEqual { 2, 2 }

			child.dispose()
			count:set(2)
			reactor:settle()
			expect({ outer, inner }):toEqual { 3, 2 }

			root.dispose()
			count:set(3)
			reactor:settle()
			expect({ outer, inner }):toEqual { 3, 2 }
		end)

		it("leaves no edge behind on the producer after disposal", function()
			Compose.setWorkCounters(true)
			local reactor, owner = domain()
			local count = Compose.cell(0)
			owner.watch(function(use)
				use(count)
			end)

			owner.dispose()
			Compose.resetWorkCounters()
			count:set(1)
			reactor:settle()
			expect(Compose.readWorkCounters().notifications):toBe(0)
			Compose.setWorkCounters(false)
		end)
	end)

	describe("independent runtimes", function()
		it("do not share a queue, a batch, or an error", function()
			local first = Compose.reactor()
			local second = Compose.reactor()
			local ownerOne = Compose.createOwner(first)
			local ownerTwo = Compose.createOwner(second)
			local shared = Compose.cell(0)
			local one, two = 0, 0

			ownerOne.watch(function(use)
				use(shared)
				one += 1
			end)
			ownerTwo.watch(function(use)
				use(shared)
				two += 1
			end)

			first:batch(function()
				shared:set(1)
				expect(one):toBe(1)
				expect(two):toBe(2)
			end)
			expect(one):toBe(2)

			ownerOne.dispose()
			ownerTwo.dispose()
		end)

		it("keep working after the other one's watch raises", function()
			local first = Compose.reactor()
			local second = Compose.reactor()
			local ownerOne = Compose.createOwner(first)
			local ownerTwo = Compose.createOwner(second)
			local trigger = Compose.cell(false)
			local survived = 0

			ownerOne.watch(function(use)
				if use(trigger) then
					error "first domain failed"
				end
			end)
			ownerTwo.watch(function(use)
				use(trigger)
				survived += 1
			end)

			expect(function()
				trigger:set(true)
			end):toThrow "first domain failed"
			expect(survived):toBe(2)

			trigger:set(false)
			first:settle()
			second:settle()
			expect(survived):toBe(3)
			ownerOne.dispose()
			ownerTwo.dispose()
		end)
	end)

	describe("writes from inside a drain", function()
		it("re-runs a watch that wrote to something it reads", function()
			local reactor, owner = domain()
			local input = Compose.cell(1)
			local mirror = Compose.cell(0)
			local seen: { number } = {}

			owner.watch(function(use)
				mirror:set(use(input) * 10)
			end)
			owner.watch(function(use)
				table.insert(seen, use(mirror))
			end)
			expect(seen):toEqual { 10 }

			input:set(2)
			reactor:settle()
			expect(seen):toEqual { 10, 20 }
			expect(reactor:pending()):toBe(0)
			owner.dispose()
		end)

		it("lets a watch mark itself from inside its own first run", function()
			local reactor, owner = domain()
			local ticks = Compose.cell(0)
			local runs = 0

			owner.watch(function(use)
				local value = use(ticks)
				runs += 1
				if value < 3 then
					ticks:set(value + 1)
				end
			end)
			reactor:settle()
			expect(ticks:peek()):toBe(3)
			expect(runs):toBe(4)
			owner.dispose()
		end)

		it("disposes a watch mid-drain without running it", function()
			local reactor, owner = domain()
			local count = Compose.cell(0)
			local firstRuns, secondRuns = 0, 0
			local second: Compose.Dispose

			owner.watch(function(use)
				use(count)
				firstRuns += 1
				if firstRuns == 2 then
					second()
				end
			end)
			second = owner.watch(function(use)
				use(count)
				secondRuns += 1
			end)
			expect({ firstRuns, secondRuns }):toEqual { 1, 1 }

			count:set(1)
			reactor:settle()
			expect(firstRuns):toBe(2)
			expect(secondRuns):toBe(1)
			owner.dispose()
		end)
	end)

	describe("bounded cascades", function()
		it("raises rather than hanging when a cascade will not settle", function()
			local _reactor, owner = domain()
			local count = Compose.cell(0)
			expect(function()
				owner.watch(function(use)
					count:set(use(count) + 1)
				end)
			end):toThrow "did not settle"
			owner.dispose()
		end)
	end)

	describe("recovery after an abandoned drain", function()
		it("keeps marking a watch whose drain gave up", function()
			local reactor, owner = domain()
			local runaway = Compose.cell(0)
			local quiet = Compose.cell(0)
			local quietRuns = 0

			owner.watch(function(use)
				use(quiet)
				quietRuns += 1
			end)
			expect(quietRuns):toBe(1)

			expect(function()
				owner.watch(function(use)
					runaway:set(use(runaway) + 1)
				end)
			end):toThrow "did not settle"

			quiet:set(1)
			reactor:settle()
			expect(quietRuns):toBe(2)
			quiet:set(2)
			reactor:settle()
			expect(quietRuns):toBe(3)
			owner.dispose()
		end)
	end)

	describe("errors", function()
		it("reports every failing watch in a drain and still runs the rest", function()
			local _reactor, owner = domain()
			local trigger = Compose.cell(0)
			local survivors = 0

			owner.watch(function(use)
				if use(trigger) > 0 then
					error "first failed"
				end
			end)
			owner.watch(function(use)
				use(trigger)
				survivors += 1
			end)
			owner.watch(function(use)
				if use(trigger) > 0 then
					error "third failed"
				end
			end)

			local ok, err: any = pcall(function()
				trigger:set(1)
			end)
			expect(ok):toBe(false)
			expect(tostring(err)):toContain "first failed"
			expect(tostring(err)):toContain "third failed"
			expect(survivors):toBe(2)
			owner.dispose()
		end)

		it("keeps the reactor usable after a batch body raises", function()
			local reactor, owner = domain()
			local count = Compose.cell(0)
			local runs = 0
			owner.watch(function(use)
				use(count)
				runs += 1
			end)

			expect(function()
				reactor:batch(function()
					count:set(1)
					error "halfway"
				end)
			end):toThrow "halfway"

			expect(count:peek()):toBe(1)
			expect(runs):toBe(2)
			expect(reactor:pending()):toBe(0)

			count:set(2)
			reactor:settle()
			expect(runs):toBe(3)
			owner.dispose()
		end)

		it("unwinds a failed build through the owner, leaving nothing behind", function()
			local world = Support.world()
			local fail = Compose.cell(false)
			local ok = pcall(function()
				world.runtime.mount(function()
					local children = {}
					for index = 1, 5 do
						children[index] = world.create "Row" { Order = index }
					end
					if not fail:peek() then
						error "build failed"
					end
					return world.create "Frame"(children)
				end, world.root)
			end)
			expect(ok):toBe(false)
			expect(#world.host.childrenOf(world.root)):toBe(0)
			expect(world.host.liveNodes()):toBe(1)
		end)
	end)

	describe("standing graph memory", function()
		it("returns every edge when a subtree is released", function()
			local reactor, root = domain()
			local count = Compose.cell(0)

			local function edges(): number
				local total = 0
				local edge = (count :: any).subscribers
				while edge ~= nil do
					total += 1
					edge = edge[5]
				end
				return total
			end

			expect(edges()):toBe(0)
			local owners = {}
			for index = 1, 50 do
				local child = root.createChild()
				owners[index] = child
				child.watch(function(use)
					use(count)
				end)
			end
			expect(edges()):toBe(50)

			for index = 1, 25 do
				owners[index].dispose()
			end
			expect(edges()):toBe(25)

			root.dispose()
			expect(edges()):toBe(0)

			count:set(1)
			reactor:settle()
			expect(edges()):toBe(0)
		end)

		it("does not grow edges when a body re-reads the same shape", function()
			local reactor, owner = domain()
			local a = Compose.cell(1)
			local b = Compose.cell(2)
			owner.watch(function(use)
				use(a)
				use(b)
			end)

			local function edgesOf(cell: any): number
				local total = 0
				local edge = cell.subscribers
				while edge ~= nil do
					total += 1
					edge = edge[5]
				end
				return total
			end

			for step = 1, 40 do
				a:set(step)
				reactor:settle()
			end
			expect(edgesOf(a)):toBe(1)
			expect(edgesOf(b)):toBe(1)
			owner.dispose()
		end)
	end)
end)

return nil
