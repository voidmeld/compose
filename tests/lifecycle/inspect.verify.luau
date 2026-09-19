--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("inspector activation", function()
	it("is off until started and off again after stopping", function()
		Compose.__resetForTests()
		expect(Compose.inspect.active()):toBe(false)
		Compose.inspect.start()
		expect(Compose.inspect.active()):toBe(true)
		Compose.inspect.stop()
		expect(Compose.inspect.active()):toBe(false)
	end)

	it("reports inactive rather than raising when nothing is running", function()
		Compose.__resetForTests()
		local report = Compose.inspect.snapshot()
		expect(report.active):toBe(false)
		expect(#report.mounts):toBe(0)
		expect(Compose.inspect.format(report)):toBe "compose inspect: not running\n"
		expect(Compose.inspect.owner({} :: any)):toBe(nil)
	end)
end)

describe("inspector attribution", function()
	it("reports a mount, its nodes, its watches and its child owners", function()
		local world = Support.world()
		Compose.inspect.start()

		local title = Compose.cell "a"
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {
				Name = "Root",
				Text = title,
				world.create "Frame" { Name = "Child" },
			}
		end, world.root)

		local report = Compose.inspect.snapshot()
		expect(report.active):toBe(true)
		expect(#report.mounts):toBe(1)

		local mount = report.mounts[1]
		expect(mount.totalOwned >= 2):toBe(true)
		expect(mount.totalWatches >= 1):toBe(true)
		expect(mount.descendants >= 1):toBe(true)
		expect(mount.disposed):toBe(false)
		expect(mount.holding > 0):toBe(true)

		local text = Compose.inspect.format(report)
		expect(string.find(text, "mounts:", 1, true) ~= nil):toBe(true)
		expect(string.find(text, "owned node", 1, true) ~= nil):toBe(true)

		dispose()
		Compose.inspect.stop()
	end)

	it("says why a node is alive, and which owner holds it", function()
		local world = Support.world()
		Compose.inspect.start()

		local made: any = nil
		local dispose = world.runtime.mount(function()
			made = world.create "Frame" { Name = "Panel" }
			return made
		end, world.root)

		local answer = Compose.inspect.node(made)
		expect(answer.custody):toBe "owned"
		expect(answer.ownerId ~= nil):toBe(true)
		expect(string.find(answer.because, "disposed", 1, true) ~= nil):toBe(true)

		local borrowedAnswer = Compose.inspect.node(world.root)
		expect(borrowedAnswer.custody):toBe "borrowed"
		expect(string.find(borrowedAnswer.because, "never destroy", 1, true) ~= nil):toBe(true)

		dispose()
		Compose.inspect.stop()
	end)

	it("admits when it was not running for the thing being asked about", function()
		local world = Support.world()
		local made: any = nil
		local dispose = world.runtime.mount(function()
			made = world.create "Frame" { Name = "Early" }
			return made
		end, world.root)

		Compose.inspect.start()
		local answer = Compose.inspect.node(made)
		expect(answer.custody):toBe "owned"
		expect(answer.ownerId):toBe(nil)
		expect(string.find(answer.because, "not recorded", 1, true) ~= nil):toBe(true)

		local report = Compose.inspect.snapshot()
		expect(#report.mounts):toBe(0)
		expect(report.outstandingMounts):toBe(1)

		dispose()
		Compose.inspect.stop()
	end)

	it("names an owner when the caller labels it", function()
		Compose.__resetForTests()
		Compose.inspect.start()
		local owner = Compose.createOwner()
		Compose.inspect.label(owner, "session")
		Compose.withOwner(owner, function()
			Compose.cleanup(function() end)
		end)

		local report = Compose.inspect.snapshot()
		expect(#report.detached):toBe(1)
		expect(report.detached[1].label):toBe "session"
		expect(report.detached[1].cleanups):toBe(1)

		owner.dispose()
		Compose.inspect.stop()
	end)
end)

describe("inspector bounds", function()
	it("stops recording owners at the cap and says how many it dropped", function()
		Compose.__resetForTests()
		Compose.inspect.start { maxOwners = 4 }
		local owners = {}
		for index = 1, 12 do
			owners[index] = Compose.createOwner()
			Compose.inspect.label(owners[index], ("owner-%d"):format(index))
		end
		local report = Compose.inspect.snapshot()
		expect(#report.detached):toBe(4)
		expect(report.droppedOwners):toBe(8)
		expect(string.find(Compose.inspect.format(report), "capture dropped", 1, true) ~= nil):toBe(true)
		for _, owner in owners do
			owner.dispose()
		end
		Compose.inspect.stop()
	end)

	it("stops attributing nodes at the cap without losing the counts", function()
		local world = Support.world()
		Compose.inspect.start { maxNodes = 3 }
		local dispose = world.runtime.mount(function()
			local children = table.create(20)
			for index = 1, 20 do
				children[index] = world.create "Frame" { Name = ("n%d"):format(index) }
			end
			return world.create "Frame"(children)
		end, world.root)

		local report = Compose.inspect.snapshot()
		expect(report.mounts[1].totalOwned):toBe(21)
		expect(report.droppedNodes > 0):toBe(true)
		dispose()
		Compose.inspect.stop()
	end)
end)

describe("inspector disposal", function()
	it("holds nothing after stopping, and a second session starts from zero", function()
		local world = Support.world()
		Compose.inspect.start()
		local dispose = world.runtime.mount(function()
			return world.create "Frame" { Name = "One" }
		end, world.root)
		expect(#Compose.inspect.snapshot().mounts):toBe(1)
		dispose()
		Compose.inspect.stop()

		expect(Compose.inspect.snapshot().active):toBe(false)
		Compose.inspect.start()
		local report = Compose.inspect.snapshot()
		expect(#report.mounts):toBe(0)
		expect(#report.detached):toBe(0)
		Compose.inspect.stop()
	end)

	it("stops reporting a tree that has been disposed", function()
		local world = Support.world()
		Compose.inspect.start()
		local dispose = world.runtime.mount(function()
			return world.create "Frame" { Name = "Temporary" }
		end, world.root)
		expect(#Compose.inspect.snapshot().mounts):toBe(1)

		dispose()
		local after = Compose.inspect.snapshot()
		expect(after.outstandingMounts):toBe(0)
		expect(after.mounts[1].disposed):toBe(true)
		expect(after.mounts[1].holding):toBe(0)
		Compose.inspect.stop()
	end)

	it("leaves no live instances or connections behind", function()
		local world = Support.world()
		local baselineInstances = world.host.liveNodes()
		local baselineConnections = world.host.liveSubscriptions()

		Compose.inspect.start()
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {
				Name = "Panel",
				Activated = function() end,
			}
		end, world.root)
		Compose.inspect.snapshot()
		dispose()
		Compose.inspect.stop()

		expect(world.host.liveNodes()):toBe(baselineInstances)
		expect(world.host.liveSubscriptions()):toBe(baselineConnections)
		expect(Compose.outstandingMounts()):toBe(0)
	end)

	it("adds no field to any owner or node", function()
		local world = Support.world()
		local function keyCount(subject: any): number
			local count = 0
			for _ in subject :: { [any]: any } do
				count += 1
			end
			return count
		end

		local owner = Compose.createOwner()
		local before = keyCount(owner)
		Compose.inspect.start()
		Compose.inspect.label(owner, "probe")
		Compose.withOwner(owner, function()
			Compose.cleanup(function() end)
		end)
		local during = keyCount(owner)
		Compose.inspect.stop()

		expect(during):toBe(before)
		expect(keyCount(owner)):toBe(before)
		owner.dispose()
		world.settle()
	end)
end)

describe("inspector per-owner counts", function()
	it("stays exact for one owner across churn, with stranded unreachable nodes elsewhere", function()
		local world = Support.world()
		Compose.inspect.start()

		local target = Compose.createOwner()
		Compose.withOwner(target, function()
			world.create "Frame" { Name = "Kept1" }
			world.create "Frame" { Name = "Kept2" }
		end)
		expect(Compose.inspect.owned(target)):toEqual { ownedNodes = 2, borrowedNodes = 0 }

		for index = 1, 200 do
			local strandedOwner = Compose.createOwner()
			Compose.withOwner(strandedOwner, function()
				world.create "Frame" { Name = ("stranded%d"):format(index) }
			end)
		end

		for index = 1, 200 do
			local churned = Compose.createOwner()
			Compose.withOwner(churned, function()
				world.create "Frame" { Name = ("churn%d"):format(index) }
			end)
			churned.dispose()
		end

		expect(Compose.inspect.owned(target)):toEqual { ownedNodes = 2, borrowedNodes = 0 }

		target.dispose()
		expect(Compose.inspect.owned(target)):toEqual { ownedNodes = 0, borrowedNodes = 0 }

		Compose.inspect.stop()
	end)

	it("counts borrowed nodes separately from owned and adopted ones", function()
		local world = Support.world()
		Compose.inspect.start()

		local target = Compose.createOwner()
		local external = world.host.makeNode "External"
		Compose.withOwner(target, function()
			world.create "Frame" { Name = "Owned" }
			world.runtime.borrow(external)
		end)

		expect(Compose.inspect.owned(target)):toEqual { ownedNodes = 1, borrowedNodes = 1 }

		target.dispose()
		Compose.inspect.stop()
	end)

	it("returns nil while the inspector is not running, like inspect.owner", function()
		Compose.__resetForTests()
		local owner = Compose.createOwner()
		expect(Compose.inspect.owned(owner)):toBe(nil)
		owner.dispose()
	end)

	it("reports zero for an owner it never saw", function()
		Compose.__resetForTests()
		Compose.inspect.start()
		expect(Compose.inspect.owned({} :: any)):toEqual { ownedNodes = 0, borrowedNodes = 0 }
		Compose.inspect.stop()
	end)
end)

describe("trackedNodes as a diagnostic", function()
	it("starts a fresh census after the test reset boundary", function()
		Compose.__resetForTests()
		local world = Support.world()
		local priorOwner = Compose.createOwner(world.runtime.reactor)
		local prior: any = nil
		Compose.withOwner(priorOwner, function()
			prior = world.create "Frame" { Name = "Prior" }
		end)
		expect(Compose.inspect.active()):toBe(false)
		expect(Compose.custodyOf(prior)):toBe "owned"

		Compose.__resetForTests()
		Compose.inspect.start()
		expect(Compose.inspect.snapshot().trackedNodes):toBe(0)
		expect(Compose.custodyOf(prior)):toBe "borrowed"

		local currentOwner = Compose.createOwner(world.runtime.reactor)
		Compose.withOwner(currentOwner, function()
			world.create "Frame" { Name = "Current" }
		end)
		expect(Compose.inspect.active()):toBe(true)
		expect(Compose.inspect.snapshot().trackedNodes):toBe(1)

		currentOwner.dispose()
		priorOwner.dispose()
		Compose.inspect.stop()
	end)

	it("is a non-negative integer census, not a value a spec asserts a delta on", function()
		local world = Support.world()
		Compose.inspect.start()

		local dispose = world.runtime.mount(function()
			return world.create "Frame" { Name = "Root" }
		end, world.root)

		local report = Compose.inspect.snapshot()
		expect(math.floor(report.trackedNodes) == report.trackedNodes):toBe(true)
		expect(report.trackedNodes >= 0):toBe(true)

		dispose()
		Compose.inspect.stop()
	end)
end)

describe("inspector failure", function()
	it("cannot break the application", function()
		Compose.__resetForTests()
		Compose.inspect.start()
		local hostile = setmetatable({}, {
			__index = function()
				error "hostile owner"
			end,
		})
		Compose.inspect.label(hostile :: any, "hostile")

		local owner = Compose.createOwner()
		local ran = 0
		Compose.withOwner(owner, function()
			Compose.cleanup(function()
				ran += 1
			end)
		end)
		owner.dispose()
		expect(ran):toBe(1)

		Compose.inspect.stop()
		Compose.inspect.start()
		local fresh = Compose.createOwner()
		Compose.inspect.label(fresh, "fresh")
		expect(#Compose.inspect.snapshot().detached):toBe(1)
		fresh.dispose()
		Compose.inspect.stop()
	end)
end)

describe("inspector output", function()
	it("is deterministic and carries no application value", function()
		local world = Support.world()
		Compose.inspect.start()
		local secret = Compose.cell "a-value-that-must-not-appear"
		local dispose = world.runtime.mount(function()
			return world.create "Frame" { Name = "Panel", Text = secret }
		end, world.root)

		local report = Compose.inspect.snapshot()
		local first = Compose.inspect.format(report)
		expect(Compose.inspect.format(report)):toBe(first)
		expect(string.find(first, "must-not-appear", 1, true) == nil):toBe(true)

		local shaped = Compose.inspect.data(report)
		expect(shaped.schemaVersion):toBe(1)
		expect(#shaped.mounts):toBe(1)
		expect(shaped.mounts[1].totalOwned >= 1):toBe(true)

		dispose()
		Compose.inspect.stop()
	end)
end)

return nil
