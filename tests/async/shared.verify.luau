--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

describe("createSharedResource", function()
	Test.beforeEach(function()
		Compose.__resetForTests()
	end)

	it("builds once for many consumers", function()
		local builds = 0
		local acquire = Compose.createSharedResource(function()
			builds += 1
			return { id = builds }, nil
		end)

		local owner = Compose.createOwner()
		local first, second
		Compose.withOwner(owner, function()
			first = acquire()
			second = acquire()
		end)

		expect(builds):toBe(1)
		expect(first):toBe(second)
		owner.dispose()
	end)

	it("tears down when the last reference goes, and not before", function()
		local torn = 0
		local acquire = Compose.createSharedResource(function()
			return "value", function()
				torn += 1
			end
		end)

		local first = Compose.createOwner()
		local second = Compose.createOwner()
		Compose.withOwner(first, function()
			acquire()
		end)
		Compose.withOwner(second, function()
			acquire()
		end)

		first.dispose()
		expect(torn):toBe(0)
		second.dispose()
		expect(torn):toBe(1)
	end)

	it("releases exactly once however the owner is disposed", function()
		local torn = 0
		local acquire = Compose.createSharedResource(function()
			return "value", function()
				torn += 1
			end
		end)

		local owner = Compose.createOwner()
		Compose.withOwner(owner, function()
			acquire()
		end)
		owner.dispose()
		owner.dispose()
		expect(torn):toBe(1)
	end)

	it("builds a fresh one after the count reaches zero", function()
		local builds = 0
		local acquire = Compose.createSharedResource(function()
			builds += 1
			return { id = builds }, nil
		end)

		local first = Compose.createOwner()
		local firstValue
		Compose.withOwner(first, function()
			firstValue = acquire()
		end)
		first.dispose()

		local second = Compose.createOwner()
		local secondValue
		Compose.withOwner(second, function()
			secondValue = acquire()
		end)

		expect(builds):toBe(2)
		expect(secondValue).never:toBe(firstValue)
		second.dispose()
	end)

	it("does not take a reference when the factory raises", function()
		local attempts = 0
		local acquire = Compose.createSharedResource(function(): (string, (() -> ())?)
			attempts += 1
			if attempts == 1 then
				error "could not build"
			end
			return "second attempt", nil
		end)

		local owner = Compose.createOwner()
		Compose.withOwner(owner, function()
			expect(function()
				acquire()
			end):toThrow "could not build"
		end)

		local value
		Compose.withOwner(owner, function()
			value = acquire()
		end)
		expect(value):toBe "second attempt"
		owner.dispose()
	end)

	it("follows a mounted tree", function()
		local world = Support.world()
		local torn = 0
		local acquire = Compose.createSharedResource(function()
			return "atlas", function()
				torn += 1
			end
		end)

		local function Panel()
			acquire()
			return world.create "Frame" {}
		end

		local dispose = world.runtime.mount(function()
			return world.create "Screen" { Panel(), Panel() }
		end, world.root)

		expect(torn):toBe(0)
		dispose()
		expect(torn):toBe(1)
	end)

	it("refuses outside a mount", function()
		local acquire = Compose.createSharedResource(function()
			return "value", nil
		end)
		expect(function()
			acquire()
		end):toThrow "async/shared-no-owner"
	end)

	it("refuses a factory that is not a function", function()
		expect(function()
			Compose.createSharedResource(42 :: any)
		end):toThrow "async/shared-needs-a-factory"
	end)
end)

describe("runtime.connect", function()
	it("subscribes to an existing node and releases with the owner", function()
		local world = Support.world()
		world.host.declareEvent("External", "Poked")
		local external = world.host.makeNode "External"
		local pokes = 0

		local dispose = world.runtime.mount(function()
			world.runtime.connect(external, "Poked", function()
				pokes += 1
			end)
			return world.create "Frame" {}
		end, world.root)

		world.host.dispatch(external, "Poked")
		expect(pokes):toBe(1)

		dispose()
		world.host.dispatch(external, "Poked")
		expect(pokes):toBe(1)
		expect(world.host.liveSubscriptions()):toBe(0)
		expect(world.host.isAlive(external)):toBe(true)
	end)

	it("returns an unsubscribe that is safe to call twice", function()
		local world = Support.world()
		local external = world.host.makeNode "External"
		local pokes = 0

		local dispose = world.runtime.mount(function()
			local off = world.runtime.connect(external, "Poked", function()
				pokes += 1
			end)
			off()
			off()
			return world.create "Frame" {}
		end, world.root)

		world.host.dispatch(external, "Poked")
		expect(pokes):toBe(0)
		expect(world.host.liveSubscriptions()):toBe(0)
		dispose()
	end)

	it("refuses outside a mount, and refuses a non-node", function()
		local world = Support.world()
		local external = world.host.makeNode "External"
		expect(function()
			world.runtime.connect(external, "Poked", function() end)
		end):toThrow "owner/no-active-owner"

		expect(function()
			world.runtime.mount(function()
				world.runtime.connect(42 :: any, "Poked", function() end)
				return world.create "Frame" {}
			end, world.root)
		end):toThrow "mount/not-a-node"
	end)
end)

describe("mount point misuse", function()
	it("raises when a child function is written against the parent node", function()
		local world = Support.world()
		local ok, err: any = pcall(function()
			world.runtime.mount(function()
				return world.create "Frame" {
					function(parent: any)
						parent.Parent = nil
					end,
				}
			end, world.root)
		end)
		expect(ok):toBe(false)
		expect(tostring(err)):toContain "structure/not-a-mount-point"
		expect(tostring(err)):toContain "receives a mount point"
	end)

	it("leaves a correctly written directive alone", function()
		local world = Support.world()
		local dispose, frame = world.runtime.mount(function()
			return world.create "Frame" {
				Compose.show(function()
					return true
				end, function()
					return world.create "Panel" {}
				end),
			}
		end, world.root)
		expect(world.host.childrenOf(frame)):toHaveLength(1)
		dispose()
	end)
end)

describe("nested shared resources", function()
	local function pair()
		local log: { string } = {}
		local inner = Compose.createSharedResource(function()
			table.insert(log, "build B")
			return "B", function()
				table.insert(log, "tear B")
			end
		end)
		local outer = Compose.createSharedResource(function()
			local b = inner()
			table.insert(log, "build A")
			return "A+" .. b, function()
				table.insert(log, "tear A")
			end
		end)
		return outer, inner, log
	end

	it("keeps the nested resource while the outer one is still held", function()
		local world = Support.world()
		local outer, _inner, log = pair()

		local first = world.runtime.mount(function()
			outer()
			return world.create "Frame" {}
		end, world.root)
		local second = world.runtime.mount(function()
			outer()
			return world.create "Frame" {}
		end, world.root)

		expect(table.concat(log, ",")):toBe "build B,build A"

		first()
		expect(table.concat(log, ",")):toBe "build B,build A"

		second()
		expect(table.concat(log, ",")):toBe "build B,build A,tear A,tear B"
	end)

	it("tears each level down exactly once", function()
		local world = Support.world()
		local outer, _inner, log = pair()
		local dispose = world.runtime.mount(function()
			outer()
			return world.create "Frame" {}
		end, world.root)

		dispose()
		dispose()
		local teardowns = 0
		for _, entry in log do
			if entry == "tear A" or entry == "tear B" then
				teardowns += 1
			end
		end
		expect(teardowns):toBe(2)
	end)

	it("builds both again after the last reference goes", function()
		local world = Support.world()
		local outer, _inner, log = pair()

		local first = world.runtime.mount(function()
			outer()
			return world.create "Frame" {}
		end, world.root)
		first()

		local second = world.runtime.mount(function()
			outer()
			return world.create "Frame" {}
		end, world.root)
		expect(table.concat(log, ",")):toBe "build B,build A,tear A,tear B,build B,build A"
		second()
	end)

	it("releases the nested lifetime when the outer teardown raises", function()
		local innerBuilds = 0
		local innerTeardowns = 0
		local inner = Compose.createSharedResource(function()
			innerBuilds += 1
			return { id = innerBuilds }, function()
				innerTeardowns += 1
			end
		end)
		local outer = Compose.createSharedResource(function()
			return inner(), function(): ()
				error "outer cleanup failed"
			end
		end)

		local first, releaseFirst = outer.detached()
		expect(function()
			releaseFirst()
		end):toThrow "outer cleanup failed"
		releaseFirst()
		expect(innerTeardowns):toBe(1)

		local second, releaseSecond = outer.detached()
		expect(second).never:toBe(first)
		expect(second.id):toBe(2)
		expect(function()
			releaseSecond()
		end):toThrow "outer cleanup failed"
		releaseSecond()
		expect(innerTeardowns):toBe(2)
	end)

	it("runs and reports outer and nested cleanup failures", function()
		local builds = 0
		local log: { string } = {}
		local inner = Compose.createSharedResource(function()
			builds += 1
			local generation = builds
			return generation,
				function()
					table.insert(log, "inner " .. generation)
					if generation == 1 then
						error "inner cleanup failed"
					end
				end
		end)
		local outer = Compose.createSharedResource(function()
			local generation = inner()
			return generation,
				function()
					table.insert(log, "outer " .. generation)
					if generation == 1 then
						error "outer cleanup failed"
					end
				end
		end)

		local first, releaseFirst = outer.detached()
		expect(first):toBe(1)
		local ok, err: any = pcall(releaseFirst)
		expect(ok):toBe(false)
		expect(log):toEqual { "outer 1", "inner 1" }
		expect(tostring(err)):toContain "2 errors while disposing an owner"
		expect(tostring(err)):toContain "outer cleanup failed"
		expect(tostring(err)):toContain "inner cleanup failed"
		releaseFirst()
		expect(log):toEqual { "outer 1", "inner 1" }

		local second, releaseSecond = outer.detached()
		expect(second):toBe(2)
		releaseSecond()
		releaseSecond()
		expect(log):toEqual { "outer 1", "inner 1", "outer 2", "inner 2" }
	end)

	it("unwinds both levels when the nested acquisition fails", function()
		local world = Support.world()
		local log: { string } = {}
		local inner = Compose.createSharedResource(function()
			table.insert(log, "build B")
			return "B", function()
				table.insert(log, "tear B")
			end
		end)
		local outer = Compose.createSharedResource(function(): (string, (() -> ())?)
			inner()
			table.insert(log, "reached")
			error "the outer factory failed"
		end)

		local ok = pcall(function()
			world.runtime.mount(function()
				outer()
				return world.create "Frame" {}
			end, world.root)
		end)
		expect(ok):toBe(false)

		expect(table.concat(log, ",")):toBe "build B,reached,tear B"
	end)

	it("does not poison the cache when a build fails", function()
		local world = Support.world()
		local attempts = 0
		local resource = Compose.createSharedResource(function()
			attempts += 1
			if attempts == 1 then
				error "first build fails"
			end
			return "value", nil
		end)

		pcall(function()
			world.runtime.mount(function()
				resource()
				return world.create "Frame" {}
			end, world.root)
		end)

		local dispose, node = world.runtime.mount(function()
			local value = resource()
			return world.create "Frame" { Text = value }
		end, world.root)
		expect(world.host.propertyOf(node, "Text")):toBe "value"
		expect(attempts):toBe(2)
		dispose()
	end)

	it("hands a detached caller the release, and takes it twice safely", function()
		local log: { string } = {}
		local resource = Compose.createSharedResource(function()
			table.insert(log, "build")
			return "value", function()
				table.insert(log, "tear")
			end
		end)

		local value, release = resource.detached()
		expect(value):toBe "value"
		release()
		release()
		expect(table.concat(log, ",")):toBe "build,tear"
	end)
end)

return nil
