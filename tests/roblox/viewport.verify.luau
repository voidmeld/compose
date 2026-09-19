--!strict

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Emulator = require "../../src/test-scene/roblox"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function emulatorWithCamera(): (Emulator.Emulator, any)
	Compose.__resetForTests()
	ComposeRoblox.__resetForTests()
	local emulator = Emulator.create()
	emulator.defineClass("Camera", {
		super = "Instance",
		properties = { ViewportSize = { X = 1280, Y = 720 } },
	})
	local camera = emulator.createInstance "Camera"
	return emulator, camera
end

describe("ComposeRoblox.usableViewportSize", function()
	it("accepts a pair of finite numbers at or above the threshold", function()
		expect(ComposeRoblox.usableViewportSize { X = 100, Y = 100 }):toBe(true)
		expect(ComposeRoblox.usableViewportSize { X = 1280, Y = 720 }):toBe(true)
	end)

	it("refuses a size below the threshold on either axis", function()
		expect(ComposeRoblox.usableViewportSize { X = 1, Y = 1 }):toBe(false)
		expect(ComposeRoblox.usableViewportSize { X = 1280, Y = 99 }):toBe(false)
		expect(ComposeRoblox.usableViewportSize { X = 99, Y = 720 }):toBe(false)
	end)

	it("refuses nothing, and a size that is not a finite pair of numbers", function()
		expect(ComposeRoblox.usableViewportSize(nil)):toBe(false)
		expect(ComposeRoblox.usableViewportSize { X = math.huge - math.huge, Y = 720 }):toBe(false)
		expect(ComposeRoblox.usableViewportSize { X = math.huge, Y = 720 }):toBe(false)
		expect(ComposeRoblox.usableViewportSize { X = "1280" :: any, Y = 720 }):toBe(false)
	end)

	it("takes the threshold from its second argument", function()
		expect(ComposeRoblox.usableViewportSize({ X = 64, Y = 64 }, 32)):toBe(true)
		expect(ComposeRoblox.usableViewportSize({ X = 64, Y = 64 }, 128)):toBe(false)
	end)
end)

describe("ComposeRoblox.createViewport", function()
	it("reads the camera's ViewportSize as { width, height }", function()
		local emulator, camera = emulatorWithCamera()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local viewport = Compose.withOwner(owner, function()
			return ComposeRoblox.createViewport(camera, emulator.engine)
		end)
		expect(viewport:peek()):toEqual { width = 1280, height = 720 }
		owner.dispose()
	end)

	it("updates reactively when ViewportSize changes", function()
		local emulator, camera = emulatorWithCamera()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local viewport = Compose.withOwner(owner, function()
			return ComposeRoblox.createViewport(camera, emulator.engine)
		end)
		local seen: { { width: number, height: number } } = {}
		Compose.withOwner(owner, function()
			Compose.watch(function(use)
				table.insert(seen, use(viewport))
			end)
		end)
		reactor:settle()
		camera.ViewportSize = { X = 390, Y = 844 }
		reactor:settle()
		expect(seen):toEqual {
			{ width = 1280, height = 720 },
			{ width = 390, height = 844 },
		}
		owner.dispose()
	end)

	it("disconnects on owner disposal and stops updating", function()
		local emulator, camera = emulatorWithCamera()
		local before = emulator.liveConnections()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local viewport = Compose.withOwner(owner, function()
			return ComposeRoblox.createViewport(camera, emulator.engine)
		end)
		expect(emulator.liveConnections()):toBe(before + 1)
		owner.dispose()
		expect(emulator.liveConnections()):toBe(before)
		camera.ViewportSize = { X = 1, Y = 1 }
		expect(viewport:peek()):toEqual { width = 1280, height = 720 }
	end)

	it("holds the last known size when the camera reports one below the threshold", function()
		local emulator, camera = emulatorWithCamera()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local viewport, ready = Compose.withOwner(owner, function()
			return ComposeRoblox.createViewport(camera, emulator.engine)
		end)
		expect(ready:peek()):toBe(true)
		camera.ViewportSize = { X = 1, Y = 1 }
		expect(viewport:peek()):toEqual { width = 1280, height = 720 }
		expect(ready:peek()):toBe(true)
		camera.ViewportSize = { X = 390, Y = 844 }
		expect(viewport:peek()):toEqual { width = 390, height = 844 }
		owner.dispose()
	end)

	it("reports an unknown first size as not ready and stands on the fallback", function()
		local emulator, camera = emulatorWithCamera()
		camera.ViewportSize = { X = 1, Y = 1 }
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local viewport, ready = Compose.withOwner(owner, function()
			return ComposeRoblox.createViewport(camera, emulator.engine)
		end)
		expect(ready:peek()):toBe(false)
		expect(viewport:peek()):toEqual { width = 1280, height = 720 }
		camera.ViewportSize = { X = 390, Y = 844 }
		expect(ready:peek()):toBe(true)
		expect(viewport:peek()):toEqual { width = 390, height = 844 }
		owner.dispose()
	end)

	it("takes the threshold and the fallback from options", function()
		local emulator, camera = emulatorWithCamera()
		camera.ViewportSize = { X = 64, Y = 64 }
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local viewport, ready = Compose.withOwner(owner, function()
			return ComposeRoblox.createViewport(camera, emulator.engine, {
				minimumSide = 32,
				fallback = { width = 800, height = 600 },
			})
		end)
		expect(ready:peek()):toBe(true)
		expect(viewport:peek()):toEqual { width = 64, height = 64 }

		local other, otherReady = Compose.withOwner(owner, function()
			return ComposeRoblox.createViewport(camera, emulator.engine, { minimumSide = 128 })
		end)
		expect(otherReady:peek()):toBe(false)
		expect(other:peek()):toEqual { width = 1280, height = 720 }

		local third, thirdReady = Compose.withOwner(owner, function()
			return ComposeRoblox.createViewport(camera, emulator.engine, {
				minimumSide = 128,
				fallback = { width = 800, height = 600 },
			})
		end)
		expect(thirdReady:peek()):toBe(false)
		expect(third:peek()):toEqual { width = 800, height = 600 }
		owner.dispose()
	end)

	it("does not accept a size that is not a finite pair of numbers", function()
		local emulator, camera = emulatorWithCamera()
		local reactor = Compose.reactor()
		local owner = Compose.createOwner(reactor)
		local viewport = Compose.withOwner(owner, function()
			return ComposeRoblox.createViewport(camera, emulator.engine)
		end)
		camera.ViewportSize = { X = math.huge - math.huge, Y = 844 }
		expect(viewport:peek()):toEqual { width = 1280, height = 720 }
		camera.ViewportSize = { X = math.huge, Y = 844 }
		expect(viewport:peek()):toEqual { width = 1280, height = 720 }
		owner.dispose()
	end)
end)

return nil
