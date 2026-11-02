--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function domain()
	local reactor = Compose.reactor.create()
	return reactor, Compose.createOwner(reactor)
end

local function cellAsReadable<T>(value: Compose.ReadOnlyValue<T>): Compose.ReadOnlyValue<T>
	return value
end

describe("falsifiers", function()
	it("keeps mixed subscribers when the leading reactive subscriber detaches", function()
		Support.world()
		local _, owner = domain()
		local source = Compose.cell(0)
		local direct, reactive = 0, 0
		local release = Compose.owner.watch(owner, function(use)
			use(source)
		end)
		Compose.owner.watchStatic(owner, source, function(value)
			direct = value
		end)
		Compose.owner.watchTerminal(owner, function(use)
			reactive = use(source)
		end)
		release()
		source:set(1)
		expect(direct):toBe(1)
		expect(reactive):toBe(1)
		Compose.owner.dispose(owner)
	end)

	it("keeps dependencies after a watch normalizes its own source during its first run", function()
		Support.world()
		local _, owner = domain()
		local revision, size = Compose.cell(0), Compose.cell(48)
		local measured = Compose.formula(function(use)
			return use(size)
		end)
		local seen = 0
		Compose.owner.watch(owner, function(use)
			if use(revision) == 0 then
				revision:set(1)
			end
			seen = use(measured)
		end)
		expect(seen):toBe(48)
		size:set(66)
		expect(seen):toBe(66)
		Compose.owner.dispose(owner)
		measured:dispose()
	end)

	it("shares consecutive reads and trims the next dependency after a branch changes", function()
		Support.world()
		local _, owner = domain()
		local source, other, repeated = Compose.cell(1), Compose.cell(10), Compose.cell(true)
		local value, runs = 0, 0
		Compose.owner.watch(owner, function(use)
			local twice = use(repeated)
			value = use(source)
			value += if twice then use(source) else use(other)
			runs += 1
		end)
		Compose.setWorkCounters(true)
		Compose.resetWorkCounters()
		source:set(2)
		expect(Compose.readWorkCounters().notifications):toBe(1)
		expect(value):toBe(4)
		repeated:set(false)
		other:set(20)
		expect(value):toBe(22)
		repeated:set(true)
		local before = runs
		other:set(30)
		expect(runs):toBe(before)
		Compose.owner.dispose(owner)
		Compose.resetWorkCounters()
		source:set(3)
		expect(Compose.readWorkCounters().notifications):toBe(0)
		Compose.setWorkCounters(false)
	end)

	describe("coroutine evaluation isolation", function()
		it("refuses independent reads and cleanup while another unchecked reactive body is suspended", function()
			Support.world()
			local _, owner = domain()
			local source = Compose.cell(0)
			local read: ((Compose.ReadOnlyValue<number>) -> number)? = nil
			local watching = coroutine.create(function()
				Compose.owner.watch(owner, function(use)
					read = use
					use(source)
					coroutine.yield()
				end)
			end)
			local ok, failure = coroutine.resume(watching)
			assert(ok, tostring(failure))
			assert(read ~= nil)
			local readOk, readFailure = pcall(read, source)
			local cleanupOk, cleanupFailure = pcall(Compose.cleanup, function() end)
			ok, failure = coroutine.resume(watching)
			assert(ok, tostring(failure))
			Compose.owner.dispose(owner)
			expect(readOk):toBe(false)
			expect(tostring(readFailure)):toContain "reactive/no-evaluation"
			expect(cleanupOk):toBe(false)
			expect(tostring(cleanupFailure)):toContain "owner/no-active-owner"
		end)

		it("restores each suspended evaluation when another coroutine fails", function()
			Support.world()
			local _, first = domain()
			local _, second = domain()
			local source = Compose.cell(0)
			local seen, runs = -1, 0
			local failed = coroutine.create(function()
				Compose.owner.watch(first, function()
					coroutine.yield()
					error("independent_body_failure", 0)
				end)
			end)
			local surviving = coroutine.create(function()
				Compose.owner.watch(second, function(use)
					runs += 1
					if runs == 1 then
						coroutine.yield()
					end
					seen = use(source)
				end)
			end)
			local ok, failure = coroutine.resume(failed)
			assert(ok, tostring(failure))
			ok, failure = coroutine.resume(surviving)
			assert(ok, tostring(failure))
			local failedOk, failedCause = coroutine.resume(failed)
			local survived, survivorFailure = coroutine.resume(surviving)
			source:set(7)
			Compose.owner.dispose(first)
			Compose.owner.dispose(second)
			expect(failedOk):toBe(false)
			expect(tostring(failedCause)):toContain "independent_body_failure"
			expect(survived):toBe(true)
			expect(survivorFailure):toBe(nil)
			expect(seen):toBe(7)
			expect(runs):toBe(2)
		end)
	end)

	it("accepts cells through the generic readable contract", function()
		local source: Compose.Value<number> = Compose.cell(2)
		local readable = cellAsReadable(source)
		local derived: Compose.Value<number> = Compose.formula(function(use)
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
			Compose.owner.watchStatic(owner, source, function(value)
				if value == 1 then
					Compose.owner.dispose(owner)
				end
			end)
			Compose.owner.watchStatic(owner, source, function()
				laterRuns += 1
			end)
			source:set(1)
			expect(laterRuns):toBe(1)
			expect((Support.record(source)).first):toBe(nil)
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
			expect(Compose.owner.size(owner)):toBe(1)
			derived:dispose()
			expect(Compose.owner.size(owner)):toBe(0)
			Compose.owner.dispose(owner)
		end)

		it("preserves a borrowed formula after the consuming owner is disposed", function()
			local _, owner = domain()
			local source = Compose.cell(1)
			local derived = Compose.formula(function(use)
				return use(source) * 2
			end)
			Compose.owner.watch(owner, function(use)
				use(derived)
			end)
			Compose.owner.dispose(owner)
			source:set(3)
			expect(derived:peek()):toBe(6)
			derived:dispose()
			expect((Support.record(source)).first):toBe(nil)
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
			expect((Support.record(source)).first):toBe(nil)
		end)

		it("keeps fused watch self-disposal from reconnecting or skipping peers", function()
			local _, owner = domain()
			local source = Compose.cell(0)
			local later = Compose.cell(1)
			local stops: { () -> () } = {}
			local runs = table.create(20, 0)
			for index = 1, 20 do
				stops[index] = Compose.owner.watchTerminal(owner, function(use)
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
			expect((Support.record(later)).first):toBe(nil)
			Compose.owner.dispose(owner)
			expect((Support.record(source)).first):toBe(nil)
		end)

		it("releases owned formulas with their owner", function()
			local _, owner = domain()
			local source = Compose.cell(1)
			local derived = Compose.withOwner(owner, function()
				return Compose.formula(function(use)
					return use(source) * 2
				end)
			end)
			Compose.owner.watch(owner, function(use)
				use(derived)
			end)
			Compose.owner.dispose(owner)
			expect((Support.record(source)).first):toBe(nil)
			expect(function()
				derived:peek()
			end):toThrow "disposed"
		end)

		it("supports explicit formula disposal and rejects subsequent reads", function()
			local source = Compose.cell(3)
			local derived = Compose.formula(function(use)
				return use(source) * 2
			end)
			local readable: Compose.ReadOnlyValue<number> = derived
			expect(readable:peek()):toBe(6)
			derived:dispose()
			derived:dispose()
			expect((Support.record(source)).first):toBe(nil)
			expect(function()
				derived:peek()
			end):toThrow "disposed"
			local _, owner = domain()
			expect(function()
				Compose.owner.watch(owner, function(use)
					use(derived)
				end)
			end):toThrow "disposed"
			expect((Support.record(derived)).first):toBe(nil)
			Compose.owner.dispose(owner)
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
			expect((Support.record(source)).first):toBe(nil)
			expect((Support.record(source)).lastSubscriber):toBe(nil)
			source:set(1)
			expect(world.pending()):toBe(0)
		end)

		it("detaches the last direct listener and supports a fresh subscription", function()
			local reactor, owner = domain()
			local source = Compose.cell(0)
			local calls = 0
			local stop = Compose.owner.watchStatic(owner, source, function()
				calls += 1
			end)
			stop()
			stop()
			expect((Support.record(source)).first):toBe(nil)
			expect((Support.record(source)).lastSubscriber):toBe(nil)
			source:set(1)
			expect(calls):toBe(1)
			expect(Compose.reactor.pending(reactor)):toBe(0)
			Compose.owner.watchStatic(owner, source, function()
				calls += 1
			end)
			source:set(2)
			expect(calls):toBe(3)
			Compose.owner.dispose(owner)
			expect((Support.record(source)).first):toBe(nil)
		end)

		it("keeps reads after self-disposal untracked", function()
			local reactor, owner = domain()
			local trigger = Compose.cell(false)
			local later = Compose.cell(7)
			local seen = 0
			local calls = 0
			local stop: () -> () = function() end
			stop = Compose.owner.watch(owner, function(use)
				calls += 1
				if use(trigger) then
					stop()
					seen = use(later)
					use(trigger)
				end
			end)
			trigger:set(true)
			expect(seen):toBe(7)
			expect((Support.record(trigger)).first):toBe(nil)
			expect((Support.record(later)).first):toBe(nil)
			later:set(8)
			expect(calls):toBe(2)
			expect(Compose.reactor.pending(reactor)):toBe(0)
			Compose.owner.dispose(owner)
		end)
	end)
	describe("formulas that raise", function()
		local function checked(source: Compose.Value<number>)
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
			Compose.owner.watch(owner, function(use)
				local ok, value = pcall(use, outer)
				if ok then
					table.insert(seen, value)
				end
			end)
			Compose.reactor.settle(reactor)
			pcall(function()
				source:set(-1)
				Compose.reactor.settle(reactor)
			end)
			expect(function()
				outer:peek()
			end):toThrow "negative input"
			source:set(3)
			Compose.reactor.settle(reactor)
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
			Compose.owner.watch(owner, function(use)
				local value = use(source)
				Compose.cleanup(function()
					table.insert(released, value)
				end)
			end)
			source:set(1)
			source:set(2)
			expect(released):toEqual { 0, 1 }
			Compose.owner.dispose(owner)
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
			Compose.owner.dispose(owner)
			expect(released):toEqual { 0, 1, 2 }
		end)
	end)

	describe("a boundary around a raising property formula", function()
		it("owns directive branches and fallbacks without retaining guard scopes on retry", function()
			for _, directives in { false, true } do
				local world = Support.world()
				Compose.inspect.start()
				local label = Compose.cell "New"
				local retry: () -> () = function() end
				local dispose, root = world.runtime.mount(function()
					return world.create "Frame" {
						Compose.boundary(function()
							local function build()
								return world.create "TextLabel" {
									Text = function(use)
										local text = use(label)
										if text == "" then
											error "empty label"
										end
										return text
									end,
								}
							end
							return if directives
								then Compose.show(function()
									return true
								end, build)
								else build()
						end, function(_, again)
							retry = again
							if not directives then
								return world.create "Frame" {}
							end
							return Compose.fragment(function()
								return { world.create "Frame" {}, world.create "Frame" {} }
							end)
						end),
					}
				end, world.root)
				local baseline = Compose.inspect.snapshot().mounts[1].totalHolding
				for _ = 1, 4 do
					label:set ""
					world.settle()
					expect(#world.host.childrenOf(root)):toBe(if directives then 2 else 1)
					label:set "Restored"
					retry()
					world.settle()
					local children = world.host.childrenOf(root)
					expect(#children):toBe(1)
					expect(world.host.kindOf(children[1])):toBe "TextLabel"
					expect(Compose.inspect.snapshot().mounts[1].totalHolding):toBe(baseline)
				end
				dispose()
				expect(world.host.leaked()):toEqual { "Root#1" }
				Compose.inspect.stop()
			end
		end)

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

			Compose.owner.watch(owner, function(use)
				if use(useLeft) then
					table.insert(seen, use(left))
				else
					table.insert(seen, use(right))
				end
			end)
			expect(seen):toEqual { "L" }

			useLeft:set(false)
			Compose.reactor.settle(reactor)
			expect(seen):toEqual { "L", "R" }

			left:set "L2"
			Compose.reactor.settle(reactor)
			expect(seen):toEqual { "L", "R" }

			right:set "R2"
			Compose.reactor.settle(reactor)
			expect(seen):toEqual { "L", "R", "R2" }
			Compose.owner.dispose(owner)
		end)

		it("survives a dependency list that grows, shrinks, and reorders", function()
			local reactor, owner = domain()
			local cells = {}
			for index = 1, 6 do
				cells[index] = Compose.cell(index)
			end
			local shape = Compose.cell { 1, 2, 3 }
			local seen: { number } = {}

			Compose.owner.watch(owner, function(use)
				local total = 0
				for _, index in use(shape) do
					total += use(cells[index])
				end
				table.insert(seen, total)
			end)
			expect(seen):toEqual { 6 }

			shape:set { 1, 2, 3, 4, 5 }
			Compose.reactor.settle(reactor)
			expect(seen[#seen]):toBe(15)

			shape:set { 5, 1 }
			Compose.reactor.settle(reactor)
			expect(seen[#seen]):toBe(6)

			local before = #seen
			cells[3]:set(300)
			Compose.reactor.settle(reactor)
			expect(#seen):toBe(before)

			cells[5]:set(50)
			Compose.reactor.settle(reactor)
			expect(seen[#seen]):toBe(51)
			Compose.owner.dispose(owner)
		end)
	end)

	describe("lifetime is deterministic, and needs no retained handle", function()
		it("keeps running with the dispose thrown away", function()
			local reactor, owner = domain()
			local count = Compose.cell(0)
			local runs = 0
			Compose.owner.watch(owner, function(use)
				use(count)
				runs += 1
			end)

			for _ = 1, 200 do
				local allocateJunk: (number, { number }?) -> { { number } } = table.create
				local junk: { { number } }? = allocateJunk(200)
				for index = 1, 200 do
					assert(junk ~= nil)
					junk[index] = { index }
				end
				junk = nil
			end

			count:set(1)
			Compose.reactor.settle(reactor)
			expect(runs):toBe(2)
			Compose.owner.dispose(owner)
		end)

		it("stops exactly when the owner is disposed, not before or after", function()
			local reactor, root = domain()
			local count = Compose.cell(0)
			local outer, inner = 0, 0
			local child = Compose.owner.createChild(root)

			Compose.owner.watch(root, function(use)
				use(count)
				outer += 1
			end)
			Compose.owner.watch(child, function(use)
				use(count)
				inner += 1
			end)

			count:set(1)
			Compose.reactor.settle(reactor)
			expect({ outer, inner }):toEqual { 2, 2 }

			Compose.owner.dispose(child)
			count:set(2)
			Compose.reactor.settle(reactor)
			expect({ outer, inner }):toEqual { 3, 2 }

			Compose.owner.dispose(root)
			count:set(3)
			Compose.reactor.settle(reactor)
			expect({ outer, inner }):toEqual { 3, 2 }
		end)

		it("leaves no edge behind on the producer after disposal", function()
			Compose.setWorkCounters(true)
			local reactor, owner = domain()
			local count = Compose.cell(0)
			Compose.owner.watch(owner, function(use)
				use(count)
			end)

			Compose.owner.dispose(owner)
			Compose.resetWorkCounters()
			count:set(1)
			Compose.reactor.settle(reactor)
			expect(Compose.readWorkCounters().notifications):toBe(0)
			Compose.setWorkCounters(false)
		end)
	end)

	describe("independent runtimes", function()
		it("preserves outer readers when a nested write settles several other reactors", function()
			local source, nested = Compose.cell(0), Compose.cell(0)
			local owners: { Compose.Owner } = {}
			local outerSeen, nestedSeen = { 0, 0, 0 }, { 0, 0, 0 }
			for index = 1, 3 do
				local _, owner = domain()
				table.insert(owners, owner)
				Compose.owner.watch(owner, function(use)
					local value = use(source)
					outerSeen[index] = value
					if index == 1 then
						nested:set(value)
					end
				end)
			end
			for index = 1, 3 do
				local _, owner = domain()
				table.insert(owners, owner)
				Compose.owner.watch(owner, function(use)
					nestedSeen[index] = use(nested)
				end)
			end
			for value = 1, 2 do
				source:set(value)
				expect(outerSeen):toEqual { value, value, value }
				expect(nestedSeen):toEqual { value, value, value }
			end
			for index = 1, #owners do
				Compose.owner.dispose(owners[index])
			end
		end)
		it("do not share a queue, a batch, or an error", function()
			local first = Compose.reactor.create()
			local second = Compose.reactor.create()
			local ownerOne = Compose.createOwner(first)
			local ownerTwo = Compose.createOwner(second)
			local shared = Compose.cell(0)
			local one, two = 0, 0

			Compose.owner.watch(ownerOne, function(use)
				use(shared)
				one += 1
			end)
			Compose.owner.watch(ownerTwo, function(use)
				use(shared)
				two += 1
			end)

			Compose.reactor.batch(first, function()
				shared:set(1)
				expect(one):toBe(1)
				expect(two):toBe(2)
			end)
			expect(one):toBe(2)

			Compose.owner.dispose(ownerOne)
			Compose.owner.dispose(ownerTwo)
		end)

		it("keep working after the other one's watch raises", function()
			local first = Compose.reactor.create()
			local second = Compose.reactor.create()
			local ownerOne = Compose.createOwner(first)
			local ownerTwo = Compose.createOwner(second)
			local trigger = Compose.cell(false)
			local survived = 0

			Compose.owner.watch(ownerOne, function(use)
				if use(trigger) then
					error "first domain failed"
				end
			end)
			Compose.owner.watch(ownerTwo, function(use)
				use(trigger)
				survived += 1
			end)

			expect(function()
				trigger:set(true)
			end):toThrow "first domain failed"
			expect(survived):toBe(2)

			trigger:set(false)
			Compose.reactor.settle(first)
			Compose.reactor.settle(second)
			expect(survived):toBe(3)
			Compose.owner.dispose(ownerOne)
			Compose.owner.dispose(ownerTwo)
		end)
	end)

	describe("writes from inside a drain", function()
		it("re-runs a watch that wrote to something it reads", function()
			local reactor, owner = domain()
			local input = Compose.cell(1)
			local mirror = Compose.cell(0)
			local seen: { number } = {}

			Compose.owner.watch(owner, function(use)
				mirror:set(use(input) * 10)
			end)
			Compose.owner.watch(owner, function(use)
				table.insert(seen, use(mirror))
			end)
			expect(seen):toEqual { 10 }

			input:set(2)
			Compose.reactor.settle(reactor)
			expect(seen):toEqual { 10, 20 }
			expect(Compose.reactor.pending(reactor)):toBe(0)
			Compose.owner.dispose(owner)
		end)

		it("lets a watch mark itself from inside its own first run", function()
			local reactor, owner = domain()
			local ticks = Compose.cell(0)
			local runs = 0

			Compose.owner.watch(owner, function(use)
				local value = use(ticks)
				runs += 1
				if value < 3 then
					ticks:set(value + 1)
				end
			end)
			Compose.reactor.settle(reactor)
			expect(ticks:peek()):toBe(3)
			expect(runs):toBe(4)
			Compose.owner.dispose(owner)
		end)

		it("disposes a watch mid-drain without running it", function()
			local reactor, owner = domain()
			local count = Compose.cell(0)
			local firstRuns, secondRuns = 0, 0
			local second: Compose.Dispose

			Compose.owner.watch(owner, function(use)
				use(count)
				firstRuns += 1
				if firstRuns == 2 then
					second()
				end
			end)
			second = Compose.owner.watch(owner, function(use)
				use(count)
				secondRuns += 1
			end)
			expect({ firstRuns, secondRuns }):toEqual { 1, 1 }

			count:set(1)
			Compose.reactor.settle(reactor)
			expect(firstRuns):toBe(2)
			expect(secondRuns):toBe(1)
			Compose.owner.dispose(owner)
		end)
	end)

	describe("bounded cascades", function()
		it("raises rather than hanging when a cascade will not settle", function()
			local _reactor, owner = domain()
			local count = Compose.cell(0)
			expect(function()
				Compose.owner.watch(owner, function(use)
					count:set(use(count) + 1)
				end)
			end):toThrow "did not settle"
			Compose.owner.dispose(owner)
		end)
	end)

	describe("recovery after an abandoned drain", function()
		it("wakes the abandoned watch after its feedback stops", function()
			local reactor, owner = domain()
			local source = Compose.cell(0)
			local looping = false
			local runs = 0
			Compose.owner.watch(owner, function(use)
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
			expect(Compose.reactor.pending(reactor)):toBe(0)
			source:set(source:peek() + 1)
			expect(runs):toBe(before + 1)
			Compose.owner.dispose(owner)
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
			Compose.owner.watch(owner, function(use)
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
			expect(Compose.reactor.pending(reactor)):toBe(0)
			Compose.owner.dispose(owner)
		end)

		it("keeps marking a watch whose drain gave up", function()
			local reactor, owner = domain()
			local runaway = Compose.cell(0)
			local quiet = Compose.cell(0)
			local quietRuns = 0

			Compose.owner.watch(owner, function(use)
				use(quiet)
				quietRuns += 1
			end)
			expect(quietRuns):toBe(1)

			expect(function()
				Compose.owner.watch(owner, function(use)
					runaway:set(use(runaway) + 1)
				end)
			end):toThrow "did not settle"

			quiet:set(1)
			Compose.reactor.settle(reactor)
			expect(quietRuns):toBe(2)
			quiet:set(2)
			Compose.reactor.settle(reactor)
			expect(quietRuns):toBe(3)
			Compose.owner.dispose(owner)
		end)
	end)

	describe("errors", function()
		it("reports every failing watch in a drain and still runs the rest", function()
			local _reactor, owner = domain()
			local trigger = Compose.cell(0)
			local survivors = 0

			Compose.owner.watch(owner, function(use)
				if use(trigger) > 0 then
					error "first failed"
				end
			end)
			Compose.owner.watch(owner, function(use)
				use(trigger)
				survivors += 1
			end)
			Compose.owner.watch(owner, function(use)
				if use(trigger) > 0 then
					error "third failed"
				end
			end)

			local ok, err: unknown = pcall(function()
				trigger:set(1)
			end)
			expect(ok):toBe(false)
			expect(tostring(err)):toContain "first failed"
			expect(tostring(err)):toContain "third failed"
			expect(survivors):toBe(2)
			Compose.owner.dispose(owner)
		end)

		it("keeps the reactor usable after a batch body raises", function()
			local reactor, owner = domain()
			local count = Compose.cell(0)
			local runs = 0
			Compose.owner.watch(owner, function(use)
				use(count)
				runs += 1
			end)

			expect(function()
				Compose.reactor.batch(reactor, function()
					count:set(1)
					error "halfway"
				end)
			end):toThrow "halfway"

			expect(count:peek()):toBe(1)
			expect(runs):toBe(2)
			expect(Compose.reactor.pending(reactor)):toBe(0)

			count:set(2)
			Compose.reactor.settle(reactor)
			expect(runs):toBe(3)
			Compose.owner.dispose(owner)
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
				local edge = (Support.record(count)).first
				while edge ~= nil do
					total += 1
					edge = (Support.record(edge))[4]
				end
				return total
			end

			expect(edges()):toBe(0)
			local owners = {}
			for index = 1, 50 do
				local child = Compose.owner.createChild(root)
				owners[index] = child
				Compose.owner.watch(child, function(use)
					use(count)
				end)
			end
			expect(edges()):toBe(50)

			for index = 1, 25 do
				Compose.owner.dispose(owners[index])
			end
			expect(edges()):toBe(25)

			Compose.owner.dispose(root)
			expect(edges()):toBe(0)

			count:set(1)
			Compose.reactor.settle(reactor)
			expect(edges()):toBe(0)
		end)

		it("does not grow edges when a body re-reads the same shape", function()
			local reactor, owner = domain()
			local a = Compose.cell(1)
			local b = Compose.cell(2)
			Compose.owner.watch(owner, function(use)
				use(a)
				use(b)
			end)

			local function edgesOf(cell: unknown): number
				local total = 0
				local edge = (Support.record(cell)).first
				while edge ~= nil do
					total += 1
					edge = (Support.record(edge))[4]
				end
				return total
			end

			for step = 1, 40 do
				a:set(step)
				Compose.reactor.settle(reactor)
			end
			expect(edgesOf(a)):toBe(1)
			expect(edgesOf(b)):toBe(1)
			Compose.owner.dispose(owner)
		end)
	end)
end)

return nil
