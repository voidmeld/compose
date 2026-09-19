--!strict

local Compose = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type Item = { id: string, disabled: boolean, x: number?, y: number? }

describe("focus scope", function()
	it("navigates stable enabled keys and wraps only when requested", function()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local items = Compose.cell({
			{ id = "one", disabled = false },
			{ id = "two", disabled = true },
			{ id = "three", disabled = false },
		} :: { Item })
		local scope = Compose.withOwner(owner, function()
			return Compose.createFocusScope {
				from = items,
				key = function(item: Item)
					return item.id
				end,
				disabled = function(item: Item)
					return item.disabled
				end,
				wrap = true,
			}
		end)
		reactor:settle()
		expect(scope.next()):toBe "one"
		expect(scope.next()):toBe "three"
		expect(scope.next()):toBe "one"
		expect(scope.focus "two"):toBe(false)
		expect(scope.isFocused("one"):peek()):toBe(true)
		owner.dispose()
	end)

	it("clears a removed key and makes disposed controls inert", function()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local items = Compose.cell({ { id = "one", disabled = false } } :: { Item })
		local scope = Compose.withOwner(owner, function()
			return Compose.createFocusScope {
				from = items,
				key = function(item: Item)
					return item.id
				end,
			}
		end)
		reactor:settle()
		scope.focus "one"
		items:set {}
		reactor:settle()
		expect(scope.current:peek()):toBeNil()
		owner.dispose()
		expect(scope.next()):toBeNil()
	end)

	it("moves directionally by geometry without coupling to a host", function()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local items = Compose.cell({
			{ id = "center", disabled = false, x = 0, y = 0 },
			{ id = "right", disabled = false, x = 10, y = 0 },
			{ id = "down", disabled = false, x = 0, y = 10 },
		} :: { Item })
		local scope = Compose.withOwner(owner, function()
			return Compose.createFocusScope {
				from = items,
				key = function(item: Item)
					return item.id
				end,
				position = function(item: Item)
					return item.x or 0, item.y or 0
				end,
			}
		end)
		reactor:settle()
		scope.focus "center"
		expect(scope.move "right"):toBe "right"
		scope.focus "center"
		expect(scope.move "down"):toBe "down"
		owner.dispose()
	end)

	it("rejects non-finite geometry and unwinds its owner", function()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local items = Compose.cell({ { id = "bad", disabled = false } } :: { Item })
		expect(function()
			Compose.withOwner(owner, function()
				Compose.createFocusScope {
					from = items,
					key = function(item: Item)
						return item.id
					end,
					position = function()
						return math.huge, 0
					end,
				}
			end)
		end):toThrow "finite numbers"
		owner.dispose()
	end)
end)

return nil
