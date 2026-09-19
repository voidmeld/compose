--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("root scope", function()
	describe("withRootOwner", function()
		it("makes an owner active for the body and returns the body's results", function()
			Compose.__resetForTests()
			expect(Compose.currentOwner()):toBe(nil)

			local seen: Compose.Owner? = nil
			local a, b = Compose.withRootOwner(function(owner): (string, number)
				seen = Compose.currentOwner()
				expect(Compose.currentOwner()):toBe(owner)
				return "ready", 2
			end)

			expect(a):toBe "ready"
			expect(b):toBe(2)
			expect(seen ~= nil):toBe(true)
			expect(Compose.currentOwner()):toBe(nil)
		end)

		it("disposes everything the body registered, newest first, when the body returns", function()
			Compose.__resetForTests()
			local order: { string } = {}

			Compose.withRootOwner(function()
				Compose.cleanup(function()
					table.insert(order, "first")
				end)
				Compose.cleanup(function()
					table.insert(order, "second")
				end)
				Compose.cleanup(function()
					table.insert(order, "third")
				end)
			end)

			expect(order):toEqual { "third", "second", "first" }
		end)

		it("disposes newest first when the body raises, and re-raises the body's failure", function()
			Compose.__resetForTests()
			local order: { string } = {}

			local ok, err: any = pcall(function()
				Compose.withRootOwner(function()
					Compose.cleanup(function()
						table.insert(order, "first")
					end)
					Compose.cleanup(function()
						table.insert(order, "second")
					end)
					error("boot step failed", 0)
				end)
			end)

			expect(ok):toBe(false)
			expect(tostring(err)):toContain "boot step failed"
			expect(order):toEqual { "second", "first" }
			expect(Compose.currentOwner()):toBe(nil)
		end)

		it("reports a disposer that raises while unwinding without losing the body's failure", function()
			Compose.__resetForTests()

			local ok, err: any = pcall(function()
				Compose.withRootOwner(function()
					Compose.cleanup(function()
						error("teardown blew up", 0)
					end)
					error("boot step failed", 0)
				end)
			end)

			expect(ok):toBe(false)
			expect(tostring(err)):toContain "boot step failed"
			expect(tostring(err)):toContain "teardown blew up"
		end)

		it("leaves the owner disposed once the body has returned", function()
			Compose.__resetForTests()
			local captured = Compose.withRootOwner(function(owner): Compose.Owner
				return owner
			end)
			expect(captured.isDisposed()):toBe(true)
		end)

		it("puts the root owner in the reactor it was given", function()
			Compose.__resetForTests()
			local reactor = Compose.reactor()
			Compose.withRootOwner(function(owner)
				expect(owner.reactor):toBe(reactor)
			end, reactor)
		end)

		it("nests: an inner root does not adopt the outer owner's resources", function()
			Compose.__resetForTests()
			local order: { string } = {}
			local outer = Compose.withRootOwner(function(owner): Compose.Owner
				Compose.cleanup(function()
					table.insert(order, "outer")
				end)
				Compose.withRootOwner(function()
					Compose.cleanup(function()
						table.insert(order, "inner")
					end)
				end)
				expect(order):toEqual { "inner" }
				expect(Compose.currentOwner()):toBe(owner)
				return owner
			end)
			expect(order):toEqual { "inner", "outer" }
			expect(outer.isDisposed()):toBe(true)
		end)

		it("refuses a body that is not a function", function()
			Compose.__resetForTests()
			expect(function()
				(Compose.withRootOwner :: any)(nil)
			end):toThrow "owner/root-body-not-a-function"
		end)
	end)

	describe("createRootOwner", function()
		it("keeps the scope open after the body returns and closes it on dispose", function()
			Compose.__resetForTests()
			local released = false
			local scope = Compose.createRootOwner(function()
				Compose.cleanup(function()
					released = true
				end)
			end)

			expect(scope.owner.isDisposed()):toBe(false)
			expect(released):toBe(false)
			expect(Compose.currentOwner()):toBe(nil)

			scope.dispose()
			expect(released):toBe(true)
			expect(scope.owner.isDisposed()):toBe(true)
		end)

		it("hands back a scope that later work can re-enter with withOwner", function()
			Compose.__resetForTests()
			local scope = Compose.createRootOwner(function() end)
			local ticks = 0
			local source = Compose.cell(0)

			Compose.withOwner(scope.owner, function()
				Compose.watch(function(use)
					local _ = use(source)
					ticks += 1
				end)
			end)

			expect(ticks):toBe(1)
			source:set(1)
			expect(ticks):toBe(2)

			scope.dispose()
			source:set(2)
			expect(ticks):toBe(2)
		end)

		it("unwinds a partly built root, newest first, when the body raises", function()
			Compose.__resetForTests()
			local order: { string } = {}

			local ok, err: any = pcall(function()
				Compose.createRootOwner(function()
					Compose.cleanup(function()
						table.insert(order, "first")
					end)
					Compose.cleanup(function()
						table.insert(order, "second")
					end)
					error("service failed to start", 0)
				end)
			end)

			expect(ok):toBe(false)
			expect(tostring(err)):toContain "service failed to start"
			expect(order):toEqual { "second", "first" }
			expect(Compose.currentOwner()):toBe(nil)
		end)

		it("refuses a body that is not a function", function()
			Compose.__resetForTests()
			expect(function()
				(Compose.createRootOwner :: any)(42)
			end):toThrow "owner/root-body-not-a-function"
		end)
	end)

	describe("the primitives that refuse an ownerless caller", function()
		it("accepts all four inside a root scope with no other owner", function()
			Compose.__resetForTests()
			expect(Compose.currentOwner()):toBe(nil)

			local destroyed = 0
			local sharedTornDown = false

			local scope = Compose.createRootOwner(function()
				local acquire = Compose.createSharedResource(function(): (string, () -> ())
					return "connection", function()
						sharedTornDown = true
					end
				end)
				expect(acquire()):toBe "connection"

				local events = Compose.cell(0)
				local total = Compose.accumulator {
					from = events,
					reduce = function(previous: number, value: number): number
						return previous + value
					end,
					initial = 0,
				}
				events:set(3)
				expect(total:peek()):toBe(3)

				local pool = Compose.createPool {
					create = function(): { n: number }
						return { n = 0 }
					end,
					destroy = function()
						destroyed += 1
					end,
					maxRetained = 2,
				}
				local lease = pool.acquire()
				lease.release()
				expect(pool.idle()):toBe(1)

				local rows = Compose.cell { "a", "b", "c" }
				local focus = Compose.createFocusScope {
					from = rows,
					key = function(value: string): string
						return value
					end,
				}
				expect(focus.first()):toBe "a"
				expect(focus.next()):toBe "b"
			end)

			scope.dispose()
			expect(sharedTornDown):toBe(true)
			expect(destroyed):toBe(1)
		end)

		it("still refuses each of them outside any root scope", function()
			Compose.__resetForTests()

			expect(function()
				Compose.createSharedResource(function(): (string, nil)
					return "x", nil
				end)()
			end):toThrow "async/shared-no-owner"

			expect(function()
				local _ = Compose.accumulator {
					from = Compose.cell(0),
					reduce = function(previous: number): number
						return previous
					end,
					initial = 0,
				}
			end):toThrow "accumulator/no-active-owner"

			expect(function()
				local _ = Compose.createPool {
					create = function(): boolean
						return true
					end,
					destroy = function() end,
					maxRetained = 1,
				}
			end):toThrow "pool/no-active-owner"

			expect(function()
				local _ = Compose.createFocusScope {
					from = Compose.cell { "a" },
				}
			end):toThrow "focus-scope/no-active-owner"

			expect(function()
				Compose.watch(function() end)
			end):toThrow "owner/no-active-owner"
		end)

		it("disposes the four in newest-first order, and does so when the body raises", function()
			Compose.__resetForTests()
			local order: { string } = {}

			local ok = pcall(function()
				Compose.withRootOwner(function()
					local acquire = Compose.createSharedResource(function(): (string, () -> ())
						return "connection", function()
							table.insert(order, "shared")
						end
					end)
					acquire()

					Compose.cleanup(function()
						table.insert(order, "accumulator-marker")
					end)
					local _ = Compose.accumulator {
						from = Compose.cell(0),
						reduce = function(previous: number): number
							return previous
						end,
						initial = 0,
					}

					local _pool = Compose.createPool {
						create = function(): boolean
							return true
						end,
						destroy = function() end,
						maxRetained = 1,
					}
					Compose.cleanup(function()
						table.insert(order, "pool-marker")
					end)

					local _focus = Compose.createFocusScope {
						from = Compose.cell { "a" },
					}
					Compose.cleanup(function()
						table.insert(order, "focus-marker")
					end)

					error("startup aborted", 0)
				end)
			end)

			expect(ok):toBe(false)
			expect(order):toEqual { "focus-marker", "pool-marker", "accumulator-marker", "shared" }
		end)
	end)
end)

return nil
