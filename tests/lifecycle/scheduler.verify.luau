--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local FRAME = 1 / 60

local function step(world: Support.World, seconds: number)
	for _ = 1, math.round(seconds / FRAME) do
		world.host.step(FRAME)
	end
	world.settle()
end

local function owned(world: Support.World): (Compose.Scheduler, Compose.Owner)
	local owner = Compose.createOwner(world.runtime.reactor)
	local scheduler = Compose.withOwner(owner, function()
		return world.runtime.scheduler()
	end)
	return scheduler, owner
end

describe("owner scheduler", function()
	it("runs a task once after its delay and holds no frame listener while idle", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran = 0
		expect(world.host.counts().frameListeners):toBe(0)
		scheduler.after(0.2, function()
			ran += 1
		end)
		expect(scheduler.pending()):toBe(1)
		expect(world.host.counts().frameListeners):toBe(1)
		step(world, 0.1)
		expect(ran):toBe(0)
		step(world, 0.2)
		expect(ran):toBe(1)
		step(world, 0.5)
		expect(ran):toBe(1)
		expect(scheduler.pending()):toBe(0)
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
	end)

	it("runs a zero delay on the next frame, not inside the call", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran = false
		scheduler.after(0, function()
			ran = true
		end)
		expect(ran):toBe(false)
		step(world, FRAME)
		expect(ran):toBe(true)
		owner.dispose()
	end)

	it("runs due tasks in delay order, then scheduling order", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local order: { string } = {}
		scheduler.after(0.1, function()
			table.insert(order, "late")
		end)
		scheduler.after(0.05, function()
			table.insert(order, "first")
		end)
		scheduler.after(0.05, function()
			table.insert(order, "second")
		end)
		step(world, 0.2)
		expect(order):toEqual { "first", "second", "late" }
		owner.dispose()
	end)

	it("cancels one task and reports whether it was still pending", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran = 0
		local cancel = scheduler.after(0.1, function()
			ran += 1
		end)
		expect(cancel()):toBe(true)
		expect(cancel()):toBe(false)
		expect(scheduler.pending()):toBe(0)
		expect(world.host.counts().frameListeners):toBe(0)
		step(world, 0.3)
		expect(ran):toBe(0)
		local fired = scheduler.after(0.01, function() end)
		step(world, 0.1)
		expect(fired()):toBe(false)
		owner.dispose()
	end)

	it("replaces earlier work scheduled under the same key", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran: { string } = {}
		scheduler.replace("appearance", 0.1, function()
			table.insert(ran, "old")
		end)
		step(world, 0.05)
		scheduler.replace("appearance", 0.1, function()
			table.insert(ran, "new")
		end)
		scheduler.replace("other", 0.1, function()
			table.insert(ran, "other")
		end)
		expect(scheduler.pending()):toBe(2)
		step(world, 0.2)
		expect(ran):toEqual { "new", "other" }
		owner.dispose()
	end)

	it("cancels by key and refuses a nil key", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran = 0
		scheduler.replace("a", 0.1, function()
			ran += 1
		end)
		expect(scheduler.cancel "a"):toBe(true)
		expect(scheduler.cancel "a"):toBe(false)
		expect(scheduler.cancel "missing"):toBe(false)
		step(world, 0.3)
		expect(ran):toBe(0)
		expect(function()
			scheduler.replace(nil, 0.1, function() end)
		end):toThrow "scheduler/invalid-key"
		owner.dispose()
	end)

	it("clears every pending task without ending the scheduler", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran = 0
		scheduler.after(0.1, function()
			ran += 1
		end)
		scheduler.replace("k", 0.1, function()
			ran += 1
		end)
		scheduler.clear()
		expect(scheduler.pending()):toBe(0)
		step(world, 0.3)
		expect(ran):toBe(0)
		scheduler.after(0.05, function()
			ran += 1
		end)
		step(world, 0.2)
		expect(ran):toBe(1)
		owner.dispose()
	end)

	it("releases every task and the frame listener when the owner is disposed", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran = 0
		scheduler.after(0.1, function()
			ran += 1
		end)
		scheduler.replace("k", 0.1, function()
			ran += 1
		end)
		owner.dispose()
		expect(scheduler.pending()):toBe(0)
		expect(world.host.counts().frameListeners):toBe(0)
		step(world, 0.3)
		expect(ran):toBe(0)
		local late = scheduler.after(0.1, function()
			ran += 1
		end)
		expect(late()):toBe(false)
		expect(scheduler.pending()):toBe(0)
		step(world, 0.3)
		expect(ran):toBe(0)
	end)

	it("disposes only its own scope and leaves the parent usable", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran = 0
		scheduler.after(0.1, function()
			ran += 1
		end)
		scheduler.dispose()
		scheduler.dispose()
		step(world, 0.3)
		expect(ran):toBe(0)
		expect(owner.isDisposed()):toBe(false)
		owner.dispose()
	end)

	it("takes an explicit owner and refuses a missing one", function()
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		local scheduler = world.runtime.scheduler(owner)
		local ran = 0
		scheduler.after(0.05, function()
			ran += 1
		end)
		step(world, 0.1)
		expect(ran):toBe(1)
		owner.dispose()
		expect(function()
			world.runtime.scheduler()
		end):toThrow "owner/no-active-owner"
		expect(function()
			world.runtime.scheduler(({} :: unknown) :: Compose.Owner)
		end):toThrow "scheduler/invalid-owner"
	end)

	it("refuses bad delays and bodies without scheduling", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		for _, bad in { -1, math.huge - math.huge, math.huge, ("1" :: unknown) :: number } do
			expect(function()
				scheduler.after(bad, function() end)
			end):toThrow "scheduler/invalid-delay"
		end
		expect(function()
			scheduler.after(0.1, (nil :: unknown) :: () -> ())
		end):toThrow "scheduler/invalid-body"
		expect(scheduler.pending()):toBe(0)
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
	end)

	it("runs a body with the scheduler's scope active so its resources end with the owner", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local released = 0
		scheduler.after(0.05, function()
			Compose.cleanup(function()
				released += 1
			end)
		end)
		step(world, 0.1)
		expect(released):toBe(0)
		owner.dispose()
		expect(released):toBe(1)
	end)

	it("lets a body schedule more work, including a zero delay, without spinning", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ticks = 0
		local function again()
			ticks += 1
			if ticks < 5 then
				scheduler.after(0, again)
			end
		end
		scheduler.after(0, again)
		step(world, FRAME)
		expect(ticks):toBe(1)
		step(world, FRAME * 4)
		expect(ticks):toBe(5)
		step(world, FRAME * 4)
		expect(ticks):toBe(5)
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
	end)

	it("lets a body replace its own key and keeps only the replacement", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local runs = 0
		local function body()
			runs += 1
			if runs < 3 then
				scheduler.replace("loop", 0.05, body)
			end
		end
		scheduler.replace("loop", 0.05, body)
		step(world, 0.5)
		expect(runs):toBe(3)
		expect(scheduler.pending()):toBe(0)
		owner.dispose()
	end)

	it("skips a due sibling cancelled by an earlier task in the same frame", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran: { string } = {}
		local cancelSecond: (() -> boolean)? = nil
		scheduler.after(0.05, function()
			table.insert(ran, "first")
			if cancelSecond ~= nil then
				(cancelSecond :: () -> boolean)()
			end
		end)
		cancelSecond = scheduler.after(0.05, function()
			table.insert(ran, "second")
		end)
		step(world, 0.1)
		expect(ran):toEqual { "first" }
		owner.dispose()
	end)

	it("stops remaining due tasks when a body disposes the scheduler during the run", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran: { string } = {}
		scheduler.after(0.05, function()
			table.insert(ran, "first")
			scheduler.dispose()
		end)
		scheduler.after(0.05, function()
			table.insert(ran, "second")
		end)
		step(world, 0.1)
		expect(ran):toEqual { "first" }
		expect(scheduler.pending()):toBe(0)
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
	end)

	it("runs sibling tasks and releases its state when a task throws", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran: { string } = {}
		scheduler.after(0.05, function()
			table.insert(ran, "before")
		end)
		scheduler.after(0.05, function()
			error("task failed", 0)
		end)
		scheduler.after(0.05, function()
			table.insert(ran, "after")
		end)
		scheduler.after(0.5, function()
			table.insert(ran, "later")
		end)
		expect(function()
			step(world, 0.1)
		end):toThrow "task failed"
		expect(ran):toEqual { "before", "after" }
		expect(scheduler.pending()):toBe(1)
		step(world, 0.5)
		expect(ran):toEqual { "before", "after", "later" }
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
	end)

	it("summarises several failing tasks and still runs the rest", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		local ran = 0
		scheduler.after(0.05, function()
			error("one", 0)
		end)
		scheduler.after(0.05, function()
			error("two", 0)
		end)
		scheduler.after(0.05, function()
			ran += 1
		end)
		local ok, message = pcall(function()
			step(world, 0.1)
			return nil
		end)
		expect(ok):toBe(false)
		expect(tostring(message)):toContain "2 errors"
		expect(ran):toBe(1)
		expect(scheduler.pending()):toBe(0)
		owner.dispose()
	end)

	it("keeps working after a failed task", function()
		local world = Support.world()
		local scheduler, owner = owned(world)
		scheduler.after(0.05, function()
			error("boom", 0)
		end)
		pcall(step, world, 0.1)
		local ran = false
		scheduler.after(0.05, function()
			ran = true
		end)
		step(world, 0.1)
		expect(ran):toBe(true)
		owner.dispose()
	end)

	it("refuses a host without frames", function()
		local world = Support.world()
		local owner = Compose.createOwner(world.runtime.reactor)
		local frames = world.host.adapter.frames
		world.host.adapter.frames = nil
		local ok = pcall(function()
			Compose.withOwner(owner, function()
				world.runtime.scheduler()
			end)
		end)
		world.host.adapter.frames = frames
		expect(ok):toBe(false)
		expect(owner.size()):toBe(0)
		owner.dispose()
	end)
end)

return nil
