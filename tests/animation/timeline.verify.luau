--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local FRAME = 1 / 60

local function step(world: any, seconds: number)
	local frames = math.round(seconds / FRAME)
	for _ = 1, frames do
		world.host.step(FRAME)
	end
	world.settle()
end

describe("timeline", function()
	it("advances progress from zero to one over its duration", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 0.5 }
			expect(timeline.progress:peek()):toBe(0)
			expect(timeline.moving:peek()):toBe(true)

			step(world, 0.25)
			expect(timeline.progress:peek()):toBeCloseTo(0.5, 0.05)

			step(world, 0.3)
			expect(timeline.progress:peek()):toBe(1)
			expect(timeline.completed:peek()):toBe(true)
			expect(timeline.moving:peek()):toBe(false)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("holds no frame subscription once it has finished", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local before = world.host.counts().frameListeners
			local timeline = world.runtime.timeline { duration = 0.1 }
			expect(world.host.counts().frameListeners > before):toBe(true)
			step(world, 0.2)
			expect(timeline.completed:peek()):toBe(true)
			expect(world.host.counts().frameListeners):toBe(before)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("waits out its delay before any progress", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 0.2, delay = 0.2 }
			step(world, 0.15)
			expect(timeline.progress:peek()):toBe(0)
			step(world, 0.15)
			expect(timeline.progress:peek() > 0):toBe(true)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("repeats, and alternates when asked", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local normal = world.runtime.timeline { duration = 0.1, repeats = 2 }
			step(world, 0.15)
			expect(normal.progress:peek()):toBeCloseTo(0.5, 0.1)
			expect(normal.completed:peek()):toBe(false)

			local alternating = world.runtime.timeline { duration = 0.1, repeats = 2, direction = "alternate" }
			step(world, 0.15)
			expect(alternating.progress:peek()):toBeCloseTo(0.5, 0.1)
			step(world, 0.1)
			expect(alternating.completed:peek()):toBe(true)
			expect(alternating.progress:peek()):toBe(0)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("pauses and resumes without losing its place", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 1 }
			step(world, 0.3)
			local held = timeline.progress:peek()
			timeline:pause()
			expect(timeline.moving:peek()):toBe(false)

			step(world, 0.3)
			expect(timeline.progress:peek()):toBe(held)

			timeline:play()
			step(world, 0.2)
			expect(timeline.progress:peek() > held):toBe(true)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("seeks to an exact time", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 2, autoplay = false }
			expect(timeline.moving:peek()):toBe(false)
			timeline:seek(0.5)
			expect(timeline.progress:peek()):toBe(0.25)
			timeline:seek(2)
			expect(timeline.completed:peek()):toBe(true)
			expect(timeline.progress:peek()):toBe(1)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("scales time", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local fast = world.runtime.timeline { duration = 1, scale = 2 }
			step(world, 0.25)
			expect(fast.progress:peek()):toBeCloseTo(0.5, 0.05)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("costs one frame subscription however many properties read it", function()
		local world = Support.world()
		local Label = world.create "Label"
		local before = world.host.counts().frameListeners

		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 1 }
			local children = table.create(50)
			for index = 1, 50 do
				children[index] = Label {
					Alpha = function(use: Compose.Use)
						return math.clamp(use(timeline.progress) - index * 0.01, 0, 1)
					end,
				}
			end
			return (world.create "Frame")(children)
		end, world.root)

		expect(world.host.counts().frameListeners):toBe(before + 1)
		dispose()
		expect(world.host.counts().frameListeners):toBe(before)
	end)

	it("releases its frame subscription when its owner goes", function()
		local world = Support.world()
		local before = world.host.counts().frameListeners
		local dispose = world.runtime.mount(function()
			world.runtime.timeline { duration = 100 }
			return world.create "Frame" {}
		end, world.root)
		expect(world.host.counts().frameListeners > before):toBe(true)
		dispose()
		expect(world.host.counts().frameListeners):toBe(before)
	end)

	it("publishes one coherent state per frame", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 0.1 }
			local seen: { { progress: number, completed: boolean } } = {}
			world.runtime:watch(function(use: Compose.Use)
				table.insert(seen, {
					progress = use(timeline.progress),
					completed = use(timeline.completed),
				})
			end)

			step(world, 0.2)
			expect(timeline.completed:peek()):toBe(true)

			for _, state in seen do
				if state.progress == 1 then
					expect(state.completed):toBe(true)
				end
			end
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("wakes the graph once a frame however many read it", function()
		local world = Support.world()
		local Label = world.create "Label"
		local runs = 0

		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 1 }
			local children = table.create(30)
			for index = 1, 30 do
				children[index] = Label {
					Alpha = function(use: Compose.Use)
						runs += 1
						return math.clamp(use(timeline.progress) - index * 0.01, 0, 1)
					end,
				}
			end
			return (world.create "Frame")(children)
		end, world.root)

		runs = 0
		world.host.step(1 / 60)
		world.settle()
		expect(runs):toBe(30)
		dispose()
	end)

	it("distinguishes pause, play and restart", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 0.1 }
			step(world, 0.2)
			expect(timeline.completed:peek()):toBe(true)

			timeline:play()
			expect(timeline.moving:peek()):toBe(false)
			expect(timeline.progress:peek()):toBe(1)

			timeline:restart()
			expect(timeline.moving:peek()):toBe(true)
			expect(timeline.completed:peek()):toBe(false)
			expect(timeline.progress:peek()):toBe(0)

			step(world, 0.05)
			local held = timeline.progress:peek()
			timeline:pause()
			expect(timeline.moving:peek()):toBe(false)
			expect(timeline.progress:peek()):toBe(held)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("un-completes when seeking back from the end", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 1, autoplay = false }
			timeline:seek(2)
			expect(timeline.completed:peek()):toBe(true)
			timeline:seek(0.5)
			expect(timeline.completed:peek()):toBe(false)
			expect(timeline.progress:peek()):toBe(0.5)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("seeks before the delay, across runs, and past the end", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 1, delay = 0.5, repeats = 3, autoplay = false }
			timeline:seek(-1)
			expect(timeline.progress:peek()):toBe(0)
			timeline:seek(1.5)
			expect(timeline.progress:peek()):toBe(0.5)
			timeline:seek(2)
			expect(timeline.progress:peek()):toBe(0)
			timeline:seek(100)
			expect(timeline.completed:peek()):toBe(true)
			expect(timeline.progress:peek()):toBe(1)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("ends a fractional run part way through its curve", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local half = world.runtime.timeline { duration = 1, repeats = 1.5, autoplay = false }
			half:seek(100)
			expect(half.completed:peek()):toBe(true)
			expect(half.progress:peek()):toBeCloseTo(0.5, 1e-9)

			local quarter = world.runtime.timeline { duration = 1, repeats = 2.25, autoplay = false }
			quarter:seek(100)
			expect(quarter.progress:peek()):toBeCloseTo(0.25, 1e-9)

			local alternating =
				world.runtime.timeline { duration = 1, repeats = 2.25, direction = "alternate", autoplay = false }
			alternating:seek(100)
			expect(alternating.progress:peek()):toBeCloseTo(0.25, 1e-9)

			local reversing =
				world.runtime.timeline { duration = 1, repeats = 1.5, direction = "alternate", autoplay = false }
			reversing:seek(100)
			expect(reversing.progress:peek()):toBeCloseTo(0.5, 1e-9)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("advances through a hitch rather than clamping or snapping", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 0.1, repeats = 3 }
			world.host.step(0.25)
			world.settle()
			expect(timeline.completed:peek()):toBe(false)
			expect(timeline.progress:peek()):toBeCloseTo(0.5, 0.01)

			world.host.step(10)
			world.settle()
			expect(timeline.completed:peek()):toBe(true)
			expect(timeline.progress:peek()):toBe(1)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("changes its scale in place, without rebuilding anything", function()
		local world = Support.world()
		local dispose = world.runtime.mount(function()
			local timeline = world.runtime.timeline { duration = 1 }
			step(world, 0.1)
			local slow = timeline.progress:peek()

			timeline:setScale(10)
			step(world, 0.1)
			expect(timeline.progress:peek() - slow > 0.5):toBe(true)
			return world.create "Frame" {}
		end, world.root)
		dispose()
	end)

	it("refuses a scale that is not a scale", function()
		local world = Support.world()
		for _, bad in { 0, -1, 0 / 0, math.huge } do
			expect(function()
				world.runtime.mount(function()
					world.runtime.timeline { scale = bad }
					return world.create "Frame" {}
				end, world.root)
			end):toThrow "animation/timeline-option"
		end
	end)

	it("refuses a duration that is not a duration", function()
		local world = Support.world()
		expect(function()
			world.runtime.mount(function()
				world.runtime.timeline { duration = 0 }
				return world.create "Frame" {}
			end, world.root)
		end):toThrow "animation/timeline-option"
	end)
end)

return nil
