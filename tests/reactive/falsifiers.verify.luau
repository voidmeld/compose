--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function domain()
	local reactor = Compose.reactor()
	return reactor, Compose.createOwner(reactor)
end

local function cellAsReadable<T>(value: Compose.Cell<T>): Compose.Readable<T>
	return value
end

describe("falsifiers", function()
	it("accepts cells through the generic readable contract", function()
		local source: Compose.Cell<number> = Compose.cell(2)
		local readable = cellAsReadable(source)
		local derived: Compose.Formula<number> = Compose.formula(function(use)
			return use(readable) * 2
		end)
		expect(derived:peek()):toBe(4)
		source:set(3)
		source:update(function(previous)
			return previous + 1
		end)
		expect(readable:peek()):toBe(4)
		expect(derived:peek()):toBe(8)
		derived:dispose()
	end)

	describe("released dependencies", function()
		it("stops the remaining direct listeners when their owner is disposed during delivery", function()
			local _, owner = domain()
			local source = Compose.cell(0)
			local laterRuns = 0
			owner.watchStatic(source, function(value)
				if value == 1 then
					owner.dispose()
				end
			end)
			owner.watchStatic(source, function()
				laterRuns += 1
			end)
			source:set(1)
			expect(laterRuns):toBe(1)
			expect((source :: any).subscribers):toBe(nil)
		end)

		it("disposes an unevaluated formula without running its body", function()
			local calls = 0
			local derived = Compose.formula(function()
				calls += 1
				return 1
			end)
			derived:dispose()
			expect(calls):toBe(0)
			expect(function()
				derived:peek()
			end):toThrow "disposed"
		end)

		it("unregisters explicitly disposed owned formulas", function()
			local _, owner = domain()
			local derived = Compose.withOwner(owner, function()
				return Compose.formula(function()
					return 1
				end)
			end)
			expect(owner.size()):toBe(1)
			derived:dispose()
			expect(owner.size()):toBe(0)
			owner.dispose()
		end)

		it("preserves a borrowed formula after the consuming owner is disposed", function()
			local _, owner = domain()
			local source = Compose.cell(1)
			local derived = Compose.formula(function(use)
				return use(source) * 2
			end)
			owner.watch(function(use)
				use(derived)
			end)
			owner.dispose()
			source:set(3)
			expect(derived:peek()):toBe(6)
			derived:dispose()
			expect((source :: any).subscribers):toBe(nil)
		end)

		it("unwinds formula dependencies when a mount fails", function()
			local world = Support.world()
			local source = Compose.cell(1)
			expect(function()
				world.runtime.mount(function()
					local derived = Compose.formula(function(use)
						return use(source)
					end)
					derived:peek()
					error "failed build"
				end, world.root)
			end):toThrow "failed build"
			expect((source :: any).subscribers):toBe(nil)
		end)

		it("keeps fused watch self-disposal from reconnecting or skipping peers", function()
			local _, owner = domain()
			local source = Compose.cell(0)
			local later = Compose.cell(1)
			local stops: { () -> () } = {}
			local runs = table.create(20, 0)
			for index = 1, 20 do
				stops[index] = owner.watchTerminal(function(use)
					runs[index] += 1
					if use(source) == 1 and index == 9 then
						stops[index]()
						use(later)
					end
				end)
			end
			source:set(1)
			for index = 1, 20 do
				expect(runs[index]):toBe(2)
			end
			expect((later :: any).subscribers):toBe(nil)
			owner.dispose()
			expect((source :: any).subscribers):toBe(nil)
		end)

		it("releases owned formulas with their owner", function()
			local _, owner = domain()
			local source = Compose.cell(1)
			local derived = Compose.withOwner(owner, function()
				return Compose.formula(function(use)
					return use(source) * 2
				end)
			end)
			owner.watch(function(use)
				use(derived)
			end)
			owner.dispose()
			expect((source :: any).subscribers):toBe(nil)
			expect(function()
				derived:peek()
			end):toThrow "disposed"
		end)

		it("supports explicit formula disposal and rejects subsequent reads", function()
			local source = Compose.cell(3)
			local derived = Compose.formula(function(use)
				return use(source) * 2
			end)
			local readable: Compose.Readable<number> = derived
			expect(readable:peek()):toBe(6)
			derived:dispose()
			derived:dispose()
			expect((source :: any).subscribers):toBe(nil)
			expect(function()
				derived:peek()
			end):toThrow "disposed"
			local _, owner = domain()
			expect(function()
				owner.watch(function(use)
					use(derived)
				end)
			end):toThrow "disposed"
			expect((derived :: any).subscribers):toBe(nil)
			owner.dispose()
		end)

		it("detaches every fused binding when its tree is disposed", function()
			local world = Support.world()
			local source = Compose.cell(0)
			local Host = world.runtime.constructors
			local dispose = world.runtime.mount(function()
				local children = {}
				for index = 1, 20 do
					children[index] = Host.Label {
						Text = function(use)
							return tostring(use(source))
						end,
					}
				end
				return Host.Frame(children)
			end, world.root)
			dispose()
			expect((source :: any).subscribers):toBe(nil)
			expect((source :: any).lastSubscriber):toBe(nil)
			source:set(1)
			expect(world.pending()):toBe(0)
		end)

		it("detaches the last direct listener and supports a fresh subscription", function()
			local reactor, owner = domain()
			local source = Compose.cell(0)
			local calls = 0
			local stop = owner.watchStatic(source, function()
				calls += 1
			end)
			stop()
			stop()
			expect((source :: any).subscribers):toBe(nil)
			expect((source :: any).lastSubscriber):toBe(nil)
			source:set(1)
			expect(calls):toBe(1)
			expect(reactor:pending()):toBe(0)
			owner.watchStatic(source, function()
				calls += 1
			end)
			source:set(2)
			expect(calls):toBe(3)
			owner.dispose()
			expect((source :: any).subscribers):toBe(nil)
		end)

		it("keeps reads after self-disposal untracked", function()
			local reactor, owner = domain()
			local trigger = Compose.cell(false)
			local later = Compose.cell(7)
			local seen = 0
			local calls = 0
			local stop: () -> () = function() end
			stop = owner.watch(function(use)
				calls += 1
				if use(trigger) then
					stop()
					seen = use(later)
					use(trigger)
				end
			end)
			trigger:set(true)
			expect(seen):toBe(7)
			expect((trigger :: any).subscribers):toBe(nil)
			expect((later :: any).subscribers):toBe(nil)
			later:set(8)
			expect(calls):toBe(2)
			expect(reactor:pending()):toBe(0)
			owner.dispose()
		end)
	end)
	describe("formulas that raise", function()
		local function checked(source: Compose.Cell<number>)
			return Compose.formula(function(use)
				local value = use(source)
				if value < 0 then
					error "negative input"
				end
				return value
			end)
		end

		it("raises again on the next read and recovers after a valid write", function()
			local source = Compose.cell(1)
			local derived = checked(source)
			expect(derived:peek()):toBe(1)
			source:set(-1)
			expect(function()
				derived:peek()
			end):toThrow "negative input"
			expect(function()
				derived:peek()
			end):toThrow "negative input"
			source:set(4)
			expect(derived:peek()):toBe(4)
		end)

		it("recovers a dependent formula and watch after the inner formula raised", function()
			local reactor, owner = domain()
			local source = Compose.cell(1)
			local inner = checked(source)
			local outer = Compose.formula(function(use)
				return use(inner) * 2
			end)
			local seen: { number } = {}
			owner.watch(function(use)
				local ok, value = pcall(use, outer)
				if ok then
					table.insert(seen, value)
				end
			end)
			reactor:settle()
			pcall(function()
				source:set(-1)
				reactor:settle()
			end)
			expect(function()
				outer:peek()
			end):toThrow "negative input"
			source:set(3)
			reactor:settle()
			expect(outer:peek()):toBe(6)
			expect(seen[#seen]):toBe(6)
		end)
	end)

	describe("a raising formula bound to a host property", function()
		it("writes the recovered value after a rejected input", function()
			local world = Support.world()
			local label = Compose.cell "New"
			local text = Compose.formula(function(use)
				local value = use(label)
				if value == "" then
					error "empty label"
				end
				return value
			end)
			local dispose, node = world.runtime.mount(function()
				return world.create "Frame" { Text = text }
			end, world.root)
			expect(world.host.propertyOf(node, "Text")):toBe "New"

			pcall(function()
				label:set ""
				world.settle()
			end)
			label:set "Ready"
			world.settle()
			expect(world.host.propertyOf(node, "Text")):toBe "Ready"
			dispose()
		end)

		it("writes the recovered value through a derived formula binding", function()
			local world = Support.world()
			local label = Compose.cell "New"
			local checked = Compose.formula(function(use)
				local value = use(label)
				if value == "" then
					error "empty label"
				end
				return value
			end)
			local shown = Compose.formula(function(use)
				return "[" .. use(checked) .. "]"
			end)
			local dispose, node = world.runtime.mount(function()
				return world.create "Frame" {
					Text = shown,
					Title = function(use)
						return use(checked)
					end,
				}
			end, world.root)

			pcall(function()
				label:set ""
				world.settle()
			end)
			label:set "Ready"
			world.settle()
			expect(world.host.propertyOf(node, "Text")):toBe "[Ready]"
			expect(world.host.propertyOf(node, "Title")):toBe "Ready"
			dispose()
		end)
	end)

	describe("cleanup inside an owner watch", function()
		it("releases each run's cleanup before the next run and on disposal", function()
			local _, owner = domain()
			local source = Compose.cell(0)
			local released: { number } = {}
			owner.watch(function(use)
				local value = use(source)
				Compose.cleanup(function()
					table.insert(released, value)
				end)
			end)
			source:set(1)
			source:set(2)
			expect(released):toEqual { 0, 1 }
			owner.dispose()
			expect(released):toEqual { 0, 1, 2 }
		end)
	end)

	describe("cleanup inside a watch", function()
		it("releases each run's cleanup before the next run and on disposal", function()
			local _, owner = domain()
			local source = Compose.cell(0)
			local released: { number } = {}
			Compose.withOwner(owner, function()
				Compose.watch(function(use)
					local value = use(source)
					Compose.cleanup(function()
						table.insert(released, value)
					end)
				end)
			end)
			source:set(1)
			source:set(2)
			expect(released):toEqual { 0, 1 }
			owner.dispose()
			expect(released):toEqual { 0, 1, 2 }
		end)
	end)

	describe("a boundary around a raising property formula", function()
		it("renders the fallback when a bound formula raises after mount", function()
			local world = Support.world()
			local label = Compose.cell "New"
			local text = Compose.formula(function(use)
				local value = use(label)
				if value == "" then
					error "empty label"
				end
				return value
			end)
			local reported: unknown = nil
			local dispose, root = world.runtime.mount(function()
				return world.create "Frame" {
					Compose.boundary(function()
						return world.create "TextLabel" { Text = text }
					end, function(failure)
						reported = failure
						return world.create "Frame" { Name = "Fallback" }
					end),
				}
			end, world.root)

			label:set ""
			world.settle()
			expect(tostring(reported)):toContain "empty label"
			local children = world.host.childrenOf(root)
			expect(#children):toBe(1)
			expect(world.host.kindOf(children[1])):toBe "Frame"
			dispose()
		end)
	end)

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
		it("wakes the abandoned watch after its feedback stops", function()
			local reactor, owner = domain()
			local source = Compose.cell(0)
			local looping = false
			local runs = 0
			owner.watch(function(use)
				local value = use(source)
				runs += 1
				if looping then
					source:set(value + 1)
				end
			end)
			looping = true
			expect(function()
				source:set(1)
			end):toThrow "did not settle"
			looping = false
			local before = runs
			expect(reactor:pending()):toBe(0)
			source:set(source:peek() + 1)
			expect(runs):toBe(before + 1)
			owner.dispose()
		end)

		it("wakes an abandoned watch through a stale formula chain", function()
			local reactor, owner = domain()
			local source = Compose.cell(0)
			local first = Compose.formula(function(use)
				return use(source) + 1
			end)
			local second = Compose.formula(function(use)
				return use(first) + 1
			end)
			local looping = false
			local seen = 0
			owner.watch(function(use)
				seen = use(second)
				if looping then
					source:set(seen)
				end
			end)
			looping = true
			expect(function()
				source:set(1)
			end):toThrow "did not settle"
			looping = false
			local nextValue = source:peek() + 1
			source:set(nextValue)
			expect(seen):toBe(nextValue + 2)
			expect(reactor:pending()):toBe(0)
			owner.dispose()
		end)

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
