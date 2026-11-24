--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local function required<T>(value: T?): T
	assert(value ~= nil)
	return value
end

local describe, it, expect = Test.describe, Test.it, Test.expect

local function fixture(): (Compose.Slot, Compose.Owner)
	local owner = Compose.createOwner()
	return Compose.createSlot(owner), owner
end

describe("replacement slot", function()
	it("attaches under a fresh owner and keeps it until replaced", function()
		local slot, owner = fixture()
		local log: { string } = {}
		local first, second = {}, {}
		expect(slot.bind(first, function(attached)
			Compose.owner.own(attached, function()
				table.insert(log, "first released")
			end)
			table.insert(log, "first attached")
		end)):toBe(true)
		expect(slot.current()):toBe(first)
		expect(slot.bind(second, function(attached)
			Compose.owner.own(attached, function()
				table.insert(log, "second released")
			end)
			table.insert(log, "second attached")
		end)):toBe(true)
		expect(slot.current()):toBe(second)
		expect(log):toEqual { "first attached", "second attached", "first released" }
		Compose.owner.dispose(owner)
		expect(log[#log]):toBe "second released"
		expect(slot.current()):toBeNil()
	end)

	it("treats a rebind of the current key as a no-op", function()
		local slot, owner = fixture()
		local key = {}
		local attaches = 0
		local function attach()
			attaches += 1
		end
		expect(slot.bind(key, attach)):toBe(true)
		expect(slot.bind(key, attach)):toBe(false)
		expect(attaches):toBe(1)
		Compose.owner.dispose(owner)
	end)

	it("keeps the current attachment and releases the staged one when attach throws", function()
		local slot, owner = fixture()
		local released: { string } = {}
		slot.bind("old", function(attached)
			Compose.owner.own(attached, function()
				table.insert(released, "old")
			end)
		end)
		local ok, message = pcall(function()
			return slot.bind("new", function(attached)
				Compose.owner.own(attached, function()
					table.insert(released, "staged")
				end)
				error("attach failed", 0)
			end)
		end)
		expect(ok):toBe(false)
		expect(message):toBe "attach failed"
		expect(slot.current()):toBe "old"
		expect(released):toEqual { "staged" }
		Compose.owner.dispose(owner)
		expect(released):toEqual { "staged", "old" }
	end)

	it("activates the staged owner while attaching", function()
		local slot, owner = fixture()
		local seen: Compose.Owner? = nil
		local given: Compose.Owner? = nil
		slot.bind("key", function(attached)
			given = attached
			seen = Compose.currentOwner()
		end)
		expect(seen == given):toBe(true)
		Compose.owner.dispose(owner)
	end)

	it("releases only the current key, from outside or from the attachment's own callback", function()
		local slot, owner = fixture()
		local released = 0
		local callback: (() -> ())? = nil
		slot.bind("a", function(attached, release)
			callback = release
			Compose.owner.own(attached, function()
				released += 1
			end)
		end)
		expect(slot.release "other"):toBe(false)
		expect((required(callback))()):toBeNil()
		expect(slot.current()):toBeNil()
		expect(released):toBe(1)
		expect(slot.release "a"):toBe(false)
		slot.bind("b", function() end);
		(required(callback))()
		expect(slot.current()):toBe "b"
		Compose.owner.dispose(owner)
	end)

	it("ignores a release raised while attaching, before the key is current", function()
		local slot, owner = fixture()
		slot.bind("a", function(_, release)
			release()
		end)
		expect(slot.current()):toBe "a"
		Compose.owner.dispose(owner)
	end)

	it("lets the last bind win when attach binds another key", function()
		local slot, owner = fixture()
		local released: { string } = {}
		slot.bind("outer", function(attached)
			Compose.owner.own(attached, function()
				table.insert(released, "outer")
			end)
			slot.bind("inner", function(innerOwner)
				Compose.owner.own(innerOwner, function()
					table.insert(released, "inner")
				end)
			end)
		end)
		expect(slot.current()):toBe "outer"
		expect(released):toEqual { "inner" }
		Compose.owner.dispose(owner)
		expect(released):toEqual { "inner", "outer" }
	end)

	it("refuses binds after the owner is disposed without running attach", function()
		local slot, owner = fixture()
		Compose.owner.dispose(owner)
		local attached = false
		expect(slot.bind("a", function()
			attached = true
		end)):toBe(false)
		expect(attached):toBe(false)
	end)

	it("releases the staged attachment when the slot is disposed during attach", function()
		local slot, owner = fixture()
		local released = 0
		expect(slot.bind("a", function(attached)
			Compose.owner.own(attached, function()
				released += 1
			end)
			slot.dispose()
		end)):toBe(false)
		expect(released):toBe(1)
		expect(slot.current()):toBeNil()
		Compose.owner.dispose(owner)
	end)

	it("disposes the current attachment with dispose and leaves the parent alive", function()
		local slot, owner = fixture()
		local released = 0
		slot.bind("a", function(attached)
			Compose.owner.own(attached, function()
				released += 1
			end)
		end)
		slot.dispose()
		slot.dispose()
		expect(released):toBe(1)
		expect(Compose.owner.isDisposed(owner)):toBe(false)
		Compose.owner.dispose(owner)
		expect(released):toBe(1)
	end)

	it("reports every failure when the replaced attachment fails to release", function()
		local slot, owner = fixture()
		slot.bind("a", function(attached)
			Compose.owner.own(attached, function()
				error("release failed", 0)
			end)
		end)
		local ok, message = pcall(function()
			return slot.bind("b", function() end)
		end)
		expect(ok):toBe(false)
		expect(message):toBe "release failed"
		expect(slot.current()):toBe "b"
		Compose.owner.dispose(owner)
	end)

	it("uses the active owner and refuses to exist without one", function()
		local owner = Compose.createOwner()
		local slot = Compose.withOwner(owner, function()
			return Compose.createSlot()
		end)
		local released = 0
		slot.bind("a", function(attached)
			Compose.owner.own(attached, function()
				released += 1
			end)
		end)
		Compose.owner.dispose(owner)
		expect(released):toBe(1)
		expect(function()
			Compose.createSlot()
		end):toThrow "slot/no-active-owner"
		expect(function()
			Support.invoke(Compose.createSlot, {})
		end):toThrow "slot/invalid-owner"
	end)

	it("refuses a nil key and a missing attach function", function()
		local slot, owner = fixture()
		expect(function()
			slot.bind(nil, function() end)
		end):toThrow "slot/invalid-key"
		expect(function()
			Support.invoke(slot.bind, "a", nil)
		end):toThrow "slot/invalid-attach"
		Compose.owner.dispose(owner)
	end)
end)

return nil
