--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function ticking(step: number)
	local at = 0
	return function(): number
		at += step
		return at
	end
end

local function rowNamed(report: Compose.ProfileReport, name: string): Compose.ProfileNode?
	for _, row in report.nodes do
		if row.label == name then
			return row
		end
	end
	return nil
end

describe("profiler activation", function()
	it("is off until started and off again after stopping", function()
		Compose.__resetForTests()
		expect(Compose.profile.active()):toBe(false)
		Compose.profile.start(ticking(0.001))
		expect(Compose.profile.active()):toBe(true)
		Compose.profile.stop()
		expect(Compose.profile.active()):toBe(false)
	end)

	it("reports inactive rather than raising when stopped twice", function()
		Compose.__resetForTests()
		local report = Compose.profile.stop()
		expect(report.active):toBe(false)
		expect(#report.nodes):toBe(0)
		expect(Compose.profile.format(report)):toBe "compose profile: not running\n"
	end)

	it("restores the work counters to whatever they were", function()
		Compose.__resetForTests()
		Compose.setWorkCounters(false)
		Compose.profile.start(ticking(0.001))
		Compose.profile.stop()
		local before = Compose.readWorkCounters().cellWrites
		Compose.cell(0):set(1)
		expect(Compose.readWorkCounters().cellWrites):toBe(before)

		Compose.setWorkCounters(true)
		Compose.profile.start(ticking(0.001))
		Compose.profile.stop()
		Compose.resetWorkCounters()
		Compose.cell(0):set(1)
		expect(Compose.readWorkCounters().cellWrites):toBe(1)
		Compose.setWorkCounters(false)
	end)

	it("ignores a label when it is not running", function()
		Compose.__resetForTests()
		local health = Compose.cell(100)
		Compose.profile.label(health, "player.health")

		Compose.profile.start(ticking(0.001))
		health:set(90)
		local report = Compose.profile.stop()
		expect(rowNamed(report, "player.health")):toBe(nil)
		expect(#report.nodes):toBe(1)
		expect(report.nodes[1].kind):toBe "cell"
	end)
end)

describe("profiler attribution", function()
	it("names explicit watches at every public ownership entry point", function()
		local world = Support.world()
		local owner = Compose.createOwner()
		Compose.profile.start(ticking(0.001))

		owner.watch(function() end, "owner.projection")
		world.runtime:watch(function() end, "runtime.projection")
		Compose.withOwner(owner, function()
			Compose.watch(function() end, "ambient.projection")
		end)

		local report = Compose.profile.stop()
		owner.dispose()
		world.runtime:dispose()

		expect((rowNamed(report, "owner.projection") :: Compose.ProfileNode).kind):toBe "watch"
		expect((rowNamed(report, "runtime.projection") :: Compose.ProfileNode).kind):toBe "watch"
		expect((rowNamed(report, "ambient.projection") :: Compose.ProfileNode).kind):toBe "watch"
		Compose.setWorkCounters(false)
	end)

	it("records the chain from a write to a host property", function()
		local world = Support.world()
		Compose.setWorkCounters(false)
		Compose.profile.start(ticking(0.0005))

		local health = Compose.cell(100)
		Compose.profile.label(health, "player.health")
		local percent = Compose.formula(function(use)
			return use(health) // 10
		end)
		Compose.profile.label(percent, "healthPercent")

		local dispose = world.runtime.mount(function()
			return world.create "Frame" { Size = percent }
		end, world.root)

		for value = 99, 90, -1 do
			health:set(value)
			world.settle()
		end

		local report = Compose.profile.stop()
		dispose()

		local cellRow = rowNamed(report, "player.health") :: Compose.ProfileNode
		local formulaRow = rowNamed(report, "healthPercent") :: Compose.ProfileNode
		expect(cellRow.kind):toBe "cell"
		expect(cellRow.writes):toBe(10)
		expect(formulaRow.kind):toBe "formula"
		expect(formulaRow.recomputations):toBe(11)
		expect(formulaRow.recomputations - formulaRow.recomputationsSuppressed):toBe(2)

		expect(cellRow.wakes[formulaRow.id] ~= nil):toBe(true)
		expect(cellRow.peakFanOut >= 1):toBe(true)

		local binding: Compose.ProfileNode? = nil
		for _, row in report.nodes do
			if row.kind == "watch" and row.hostWrites > 0 then
				binding = row
			end
		end
		expect(binding ~= nil):toBe(true)
		expect(string.find((binding :: Compose.ProfileNode).label or "", "Size", 1, true) ~= nil):toBe(true)
		Compose.setWorkCounters(false)
	end)

	it("separates a suppressed write from one that propagates", function()
		Compose.__resetForTests()
		Compose.profile.start(ticking(0.001))
		local score = Compose.cell(0)
		Compose.profile.label(score, "score")
		score:set(1)
		score:set(1)
		score:set(2)
		local report = Compose.profile.stop()

		local row = rowNamed(report, "score") :: Compose.ProfileNode
		expect(row.writes):toBe(2)
		expect(row.writesSuppressed):toBe(1)
		Compose.setWorkCounters(false)
	end)

	it("shows a batch of writes collapsing into one run", function()
		Compose.__resetForTests()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		Compose.profile.start(ticking(0.001))

		local left, right = Compose.cell(0), Compose.cell(0)
		Compose.profile.label(left, "left")
		Compose.profile.label(right, "right")
		local ran = 0
		owner.watch(function(use)
			use(left)
			use(right)
			ran += 1
		end)

		reactor:batch(function()
			left:set(1)
			left:set(2)
			right:set(1)
		end)

		local report = Compose.profile.stop()
		owner.dispose()
		expect(ran):toBe(2)

		local watchRow: Compose.ProfileNode? = nil
		for _, row in report.nodes do
			if row.kind == "watch" then
				watchRow = row
			end
		end
		local found = watchRow :: Compose.ProfileNode
		expect(found.runs):toBe(2)
		expect(found.schedules):toBe(1)
		expect(found.schedulesCoalesced):toBe(0)

		local leftRow = rowNamed(report, "left") :: Compose.ProfileNode
		local rightRow = rowNamed(report, "right") :: Compose.ProfileNode
		expect(leftRow.writes):toBe(2)
		expect(rightRow.writes):toBe(1)
		expect(report.totals.writes):toBe(3)
		expect(report.totals.schedules):toBe(1)
		Compose.setWorkCounters(false)
	end)

	it("times a drain and names the write that opened it", function()
		Compose.__resetForTests()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		Compose.profile.start(ticking(0.25))

		local trigger = Compose.cell(0)
		Compose.profile.label(trigger, "trigger")
		owner.watch(function(use)
			use(trigger)
		end)
		trigger:set(1)

		local report = Compose.profile.stop()
		owner.dispose()

		expect(#report.drains >= 1):toBe(true)
		local last = report.drains[#report.drains]
		expect(last.runs >= 1):toBe(true)
		expect(last.seconds > 0):toBe(true)
		expect(last.cause):toBe "trigger"
		Compose.setWorkCounters(false)
	end)
end)

describe("profiler bounds", function()
	it("does not grow with the number of writes", function()
		Compose.__resetForTests()
		Compose.profile.start(ticking(0.001))
		local value = Compose.cell(0)
		for index = 1, 5_000 do
			value:set(index)
		end
		local report = Compose.profile.stop()
		expect(#report.nodes):toBe(1)
		expect(report.nodes[1].writes):toBe(5_000)
		Compose.setWorkCounters(false)
	end)

	it("stops adding rows at the node cap and says how many it dropped", function()
		Compose.__resetForTests()
		Compose.profile.start(ticking(0.001), { maxNodes = 8 })
		local cells = {}
		for index = 1, 20 do
			cells[index] = Compose.cell(0)
			cells[index]:set(index)
		end
		local report = Compose.profile.stop()
		expect(#report.nodes):toBe(8)
		expect(report.droppedRecords >= 12):toBe(true)
		expect(string.find(Compose.profile.format(report), "capture dropped", 1, true) ~= nil):toBe(true)
		Compose.setWorkCounters(false)
	end)

	it("keeps only the most recent drains", function()
		Compose.__resetForTests()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		Compose.profile.start(ticking(0.001), { maxDrains = 4 })
		local trigger = Compose.cell(0)
		owner.watch(function(use)
			use(trigger)
		end)
		for index = 1, 30 do
			trigger:set(index)
		end
		local report = Compose.profile.stop()
		owner.dispose()
		expect(#report.drains):toBe(4)
		Compose.setWorkCounters(false)
	end)
end)

describe("profiler disposal", function()
	it("holds nothing after stopping, and a second session starts from zero", function()
		Compose.__resetForTests()
		Compose.profile.start(ticking(0.001))
		local first = Compose.cell(0)
		Compose.profile.label(first, "first")
		first:set(1)
		local one = Compose.profile.stop()
		expect(#one.nodes):toBe(1)

		Compose.profile.start(ticking(0.001))
		first:set(2)
		local two = Compose.profile.stop()
		expect(#two.nodes):toBe(1)
		expect(two.nodes[1].label):toBe(nil)
		expect(two.nodes[1].id):toBe(1)
		Compose.setWorkCounters(false)
	end)

	it("leaves no live instances, connections or owners behind", function()
		local world = Support.world()
		Compose.setWorkCounters(false)
		local baselineInstances = world.host.liveNodes()
		local baselineConnections = world.host.liveSubscriptions()

		Compose.profile.start(ticking(0.001))
		local label = Compose.cell "a"
		Compose.profile.label(label, "label")
		local dispose = world.runtime.mount(function()
			return world.create "Frame" {
				Text = label,
				Activated = function() end,
			}
		end, world.root)
		label:set "b"
		world.settle()
		dispose()
		local report = Compose.profile.stop()

		expect(#report.nodes > 0):toBe(true)
		expect(world.host.liveNodes()):toBe(baselineInstances)
		expect(world.host.liveSubscriptions()):toBe(baselineConnections)
		expect(Compose.outstandingMounts()):toBe(0)
		Compose.setWorkCounters(false)
	end)

	it("adds no field to any node, profiled or not", function()
		Compose.__resetForTests()
		local function keyCount(subject: any): number
			local count = 0
			for _ in subject :: { [any]: any } do
				count += 1
			end
			return count
		end

		local value = Compose.cell(0)
		value:set(1)
		local before = keyCount(value)

		Compose.profile.start(ticking(0.001))
		Compose.profile.label(value, "value")
		value:set(2)
		local during = keyCount(value)
		Compose.profile.stop()
		value:set(3)

		expect(during):toBe(before)
		expect(keyCount(value)):toBe(before)
		Compose.setWorkCounters(false)
	end)

	it("hands back a report that outlives the recorder", function()
		Compose.__resetForTests()
		Compose.profile.start(ticking(0.001))
		local temporary = Compose.cell(0)
		temporary:set(1)
		local report = Compose.profile.stop()
		expect(#report.nodes):toBe(1)
		expect(Compose.profile.active()):toBe(false)

		for _, row in report.nodes do
			expect(type(row.id)):toBe "number"
			expect(type(row.kind)):toBe "string"
		end
		Compose.setWorkCounters(false)
	end)
end)

describe("profiler failure", function()
	it("cannot break the application, and says so in the report", function()
		Compose.__resetForTests()
		Compose.profile.start(ticking(0.001))

		local value = Compose.cell(0)
		value:set(1)
		local hostile = setmetatable({}, {
			__index = function()
				error "hostile node"
			end,
		})
		Compose.profile.label(hostile :: any, "hostile")

		local seen = 0
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		owner.watch(function(use)
			seen = use(value) :: number
		end)
		value:set(7)
		expect(seen):toBe(7)

		local report = Compose.profile.stop()
		owner.dispose()
		expect(report.totals.broken):toBe(1)
		expect(string.find(Compose.profile.format(report), "recorder failed", 1, true) ~= nil):toBe(true)

		Compose.profile.start(ticking(0.001))
		value:set(8)
		local after = Compose.profile.stop()
		expect(after.totals.broken):toBe(0)
		expect(after.totals.writes):toBe(1)
		Compose.setWorkCounters(false)
	end)
end)

describe("profiler output", function()
	it("is deterministic for the same session", function()
		Compose.__resetForTests()
		Compose.profile.start(ticking(0.001))
		local a, b = Compose.cell(0), Compose.cell(0)
		Compose.profile.label(a, "a")
		Compose.profile.label(b, "b")
		for index = 1, 5 do
			a:set(index)
			b:set(index)
		end
		local report = Compose.profile.stop()
		expect(Compose.profile.format(report)):toBe(Compose.profile.format(report))
		Compose.setWorkCounters(false)
	end)

	it("produces JSON-ready data with no application value in it", function()
		Compose.__resetForTests()
		Compose.profile.start(ticking(0.001))
		local secret = Compose.cell "a-value-that-must-not-appear"
		Compose.profile.label(secret, "secret")
		secret:set "another-value-that-must-not-appear"
		local report = Compose.profile.stop()

		local shaped = Compose.profile.data(report)
		expect(shaped.schemaVersion):toBe(1)
		expect(#shaped.nodes):toBe(1)
		expect(shaped.nodes[1].name):toBe "secret"
		expect(shaped.nodes[1].writes):toBe(1)

		local text = Compose.profile.format(report)
		expect(string.find(text, "must-not-appear", 1, true) == nil):toBe(true)
		Compose.setWorkCounters(false)
	end)
end)

return nil
