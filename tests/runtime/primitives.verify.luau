--!strict

local Compose = require "../../src/core"
local Support = require "../support"
local Test = require "../harness"
local describe, it, expect = Test.describe, Test.it, Test.expect

describe("runtime primitives", function()
	it("samples frame observations before publishing one coherent change", function()
		local world = Support.world()
		local node = world.host.makeNode "Frame"
		world.host.poke(node, "Width", 0)
		world.host.poke(node, "Height", 0)
		local seen: { string } = {}
		local owner = Compose.createOwner(world.runtime.reactor)
		local pair = Compose.withOwner(owner, function()
			local width = world.runtime.observe(node, "Width", { frame = true })
			local height = world.runtime.observe(node, "Height", { frame = true })
			expect(world.runtime.observe(node, "Width", { frame = true })):toBe(width)
			Compose.watch(function(use)
				table.insert(seen, `{use(width)}:{use(height)}`)
			end)
			return { width, height }
		end)
		table.clear(seen)
		world.host.poke(node, "Width", 10)
		world.host.poke(node, "Width", 20)
		world.host.poke(node, "Height", 30)
		expect(pair[1]:peek()):toBe(0)
		expect(world.host.counts().frameListeners):toBe(1)
		world.host.step(1 / 60)
		expect(seen):toEqual { "20:30" }
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
		expect(world.host.liveSubscriptions()):toBe(0)
	end)

	it("does not enter a property reader again when its read emits a notification", function()
		local world = Support.world()
		local node = world.host.makeNode "Frame"
		world.host.poke(node, "AbsolutePosition", 10)
		local value, owner = Support.owned(function()
			return world.runtime.observe(node, "AbsolutePosition", { frame = true })
		end)
		local observation = assert(world.host.adapter.observation)
		local read = observation.readProperty
		local reads = 0
		observation.readProperty = function(target, property)
			reads += 1
			expect(reads):toBe(1)
			local current = read(target, property)
			world.host.poke(node, property, current)
			return current
		end
		world.host.poke(node, "AbsolutePosition", 20)
		expect(reads):toBe(0)
		world.host.step(1 / 60)
		expect(value:peek()):toBe(20)
		reads = 0
		world.host.step(1 / 60)
		expect(value:peek()):toBe(20)
		owner.dispose()
		expect(world.host.counts().frameListeners):toBe(0)
		expect(world.host.liveSubscriptions()):toBe(0)
	end)

	it("polls silent property changes once per frame until the last holder releases", function()
		local world = Support.world()
		local node = world.host.makeNode "Text"
		local displayed: unknown = 10
		assert(world.host.adapter.observation).readProperty = function()
			return displayed
		end
		local first, a = Support.owned(function()
			return world.runtime.observe(node, "Bounds", { frame = true, poll = true })
		end)
		local second, b = Support.owned(function()
			return world.runtime.observe(node, "Bounds", { frame = true, poll = true })
		end)
		expect(first):toBe(second)
		expect(world.host.liveSubscriptions()):toBe(1)
		displayed = 20
		world.host.step(1 / 60)
		expect(first:peek()):toBe(20)
		a.dispose()
		displayed = nil
		world.host.step(1 / 60)
		expect(second:peek()):toBe(nil)
		b.dispose()
		expect(world.host.counts().frameListeners):toBe(0)
		expect(world.host.liveSubscriptions()):toBe(0)
	end)

	it("does not restart settled sampling for an equal restart key", function()
		local world = Support.world()
		local revision = Compose.cell(0)
		local value, owner = Support.owned(function()
			return world.runtime.settled {
				sample = function()
					return 1
				end,
				restart = function(use: Compose.Use)
					return math.floor(use(revision) / 2)
				end,
			}
		end)
		world.host.step(0)
		world.host.step(0)
		revision:set(1)
		expect(value:peek()):toBe(true)
		expect(world.host.counts().frameListeners):toBe(0)
		revision:set(2)
		expect(value:peek()):toBe(false)
		owner.dispose()
	end)
	it("unwinds failed acquisitions and starts no work without host capabilities", function()
		local world = Support.world()
		local node = world.host.makeNode "Panel"
		local observation = assert(world.host.adapter.observation)
		local subscribe = observation.observeProperty
		observation.observeProperty = function(): () -> ()
			error "subscription refused"
		end
		Compose.withRootOwner(function(owner)
			expect(function()
				world.runtime.observe(node, "Size")
			end):toThrow "subscription refused"
			expect(owner.size()):toBe(0)
			observation.observeProperty = subscribe
			world.runtime.observe(node, "Size")
		end)
		expect(world.host.liveSubscriptions()):toBe(0)
		world.host.adapter.frames = nil
		Compose.withRootOwner(function(owner)
			local attempts: { () -> () } = {
				function()
					world.runtime.clock()
				end,
				function()
					world.runtime.settled {
						sample = function()
							return 0
						end,
					}
				end,
				function()
					world.runtime.sequence { steps = {} }
				end,
			}
			for _, attempt in attempts do
				expect(attempt):toThrow()
				expect(owner.size()):toBe(0)
			end
		end)
	end)

	it("uses ready time for optional settlement timeout", function()
		local world = Support.world()
		local ready, n = true, 0
		local result, owner = Support.owned(function()
			return world.runtime.settled {
				sample = function()
					n += 1
					return n
				end,
				ready = function()
					return ready
				end,
				timeout = 1,
			}
		end)
		world.host.step(0.5)
		ready = false
		world.host.step(10)
		ready = true
		world.host.step(0.5)
		expect(result:peek()):toBe(false)
		world.host.step(0.5)
		expect(result:peek()):toBe(true)
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
	end)

	it(
		"orders nested parallel events, completes zero tweens, cancels callback failure and unwinds bad builds",
		function()
			local world = Support.world()
			local calls: { number } = {}
			Compose.withRootOwner(function(owner)
				world.runtime.sequence {
					steps = {
						{
							parallel = {
								{
									wait = 2,
									onComplete = function()
										table.insert(calls, 2)
									end,
								},
								{
									steps = {
										{ wait = 1 },
										{
											run = function()
												table.insert(calls, 1)
											end,
										},
									} :: { Compose.SequenceStep },
								},
							} :: { Compose.SequenceStep },
						},
						{
							tween = { seconds = 0 },
							sample = function(value)
								table.insert(calls, value + 2)
							end,
						},
					},
				}
				world.host.step(3)
				expect(calls):toEqual { 1, 2, 3 }
				local bad = world.runtime.sequence {
					autoplay = false,
					steps = { {
						run = function()
							error "callback failed"
						end,
					} },
				}
				expect(bad.play):toThrow "callback failed"
				expect(bad.running:peek()):toBe(false)
				expect(world.host.counts().frameListeners):toBe(0)
				local before = owner.size()
				expect(function()
					world.runtime.sequence { steps = { { wait = -1 } } }
				end):toThrow "finite nonnegative"
				expect(owner.size()):toBe(before)
			end)
		end
	)

	it("catches up absolute deadlines on resubscription and refuses invalid clock options", function()
		local world = Support.world()
		Compose.withRootOwner(function()
			local value = world.runtime.clock { deadline = 1 }
			local elapsed = world.runtime.clock { start = -1 }
			world.host.step(2)
			local reader = Compose.createOwner(world.runtime.reactor)
			reader.watch(function(use)
				use(value)
				use(elapsed)
			end)
			expect(value:peek()):toBe(0)
			expect(elapsed:peek()):toBe(3)
			reader.dispose()
			expect(world.host.counts().frameListeners):toBe(0)
			for _, options in
				{
					{ duration = -1 },
					{ interval = math.huge },
					{ deadline = math.sqrt(-1) },
					{ duration = 1, deadline = 1 },
				} :: { Compose.ClockOptions }
			do
				expect(function()
					world.runtime.clock(options)
				end):toThrow()
			end
		end)
	end)
	it("shares one property signal until the last holder releases it", function()
		local world = Support.world()
		local node = world.host.makeNode "Frame"
		world.host.poke(node, "AbsoluteSize", 10)
		local first, a = Support.owned(function()
			return world.runtime.observe(node, "AbsoluteSize")
		end)
		local second, b = Support.owned(function()
			return world.runtime.observe(node, "AbsoluteSize")
		end)
		expect(first):toBe(second)
		Compose.withOwner(a, function()
			for _ = 1, 98 do
				expect(world.runtime.observe(node, "AbsoluteSize")):toBe(first)
			end
		end)
		expect(world.host.liveSubscriptions()):toBe(1)
		expect(world.host.counts().frameListeners):toBe(0)
		world.host.poke(node, "AbsoluteSize", 20)
		expect(first:peek()):toBe(20)
		a.dispose()
		world.host.poke(node, "AbsoluteSize", nil)
		expect(second:peek()):toBe(nil)
		expect(world.host.liveSubscriptions()):toBe(1)
		b.dispose()
		expect(world.host.liveSubscriptions()):toBe(0)
		expect(world.host.isAlive(node)):toBe(true)
	end)

	it("unwinds observation and keeps different properties independent", function()
		local world = Support.world()
		local node = world.host.makeNode "Frame"
		expect(function()
			Compose.withRootOwner(function()
				world.runtime.observe(node, "Size")
				world.runtime.observe(node, "Position")
				expect(world.host.liveSubscriptions()):toBe(2)
				error "abort observation"
			end)
		end):toThrow "abort observation"
		expect(world.host.liveSubscriptions()):toBe(0)
	end)

	it("settles only after equal ready samples and restarts without retaining idle frames", function()
		local world = Support.world()
		local restart = Compose.cell(0)
		local sample, ready = 0, false
		local value, owner = Support.owned(function()
			return world.runtime.settled {
				sample = function()
					return sample
				end,
				ready = function()
					return ready
				end,
				restart = restart,
				frames = 2,
			}
		end)
		world.host.step(1)
		expect(value:peek()):toBe(false)
		ready = true
		world.host.step(1)
		sample = 1
		world.host.step(1)
		expect(value:peek()):toBe(false)
		world.host.step(1)
		expect(value:peek()):toBe(true)
		expect(world.host.counts().frameListeners):toBe(0)
		restart:set(1)
		expect(value:peek()):toBe(false)
		expect(world.host.counts().frameListeners):toBe(1)
		owner.dispose()
		expect(world.host.counts().frameListeners):toBe(0)
	end)

	it("settles nil snapshots and custom equality and rejects invalid frame counts", function()
		local world = Support.world()
		Compose.withRootOwner(function()
			local value = world.runtime.settled {
				sample = function(): unknown
					return nil
				end,
			}
			local tables = world.runtime.settled {
				sample = function()
					return { x = 1 }
				end,
				equals = function(a: { x: number }, b: { x: number })
					return a.x == b.x
				end,
			}
			world.host.step(0)
			world.host.step(0)
			expect(value:peek()):toBe(true)
			expect(tables:peek()):toBe(true)
			expect(function()
				world.runtime.settled {
					sample = function()
						return 0
					end,
					frames = 0,
				}
			end):toThrow "positive integer"
		end)
	end)

	it("pauses an unobserved clock and limits publishes without losing elapsed time", function()
		local world = Support.world()
		local value, owner = Support.owned(function()
			return world.runtime.clock { interval = 1 }
		end)
		world.host.step(10)
		expect(value:peek()):toBe(0)
		expect(world.host.counts().frameListeners):toBe(0)
		local reader = Compose.createOwner(world.runtime.reactor)
		local reads = 0
		reader.watch(function(use)
			use(value)
			reads += 1
		end)
		for _ = 1, 3 do
			world.host.step(0.25)
		end
		expect(reads):toBe(1)
		world.host.step(0.25)
		expect(value:peek()):toBe(1)
		expect(reads):toBe(2)
		reader.dispose()
		expect(world.host.counts().frameListeners):toBe(0)
		world.host.step(10)
		local resume = Compose.createOwner(world.runtime.reactor)
		resume.watch(function(use)
			use(value)
		end)
		world.host.step(1)
		expect(value:peek()):toBe(2)
		owner.dispose()
		expect(world.host.counts().frameListeners):toBe(0)
		resume.dispose()
	end)

	it("counts down durations and absolute deadlines and stops at zero", function()
		local world = Support.world()
		Compose.withRootOwner(function(owner)
			local duration = world.runtime.clock { duration = 1, interval = 10 }
			local deadline = world.runtime.clock { deadline = 2 }
			owner.watch(function(use)
				use(duration)
				use(deadline)
			end)
			expect(world.host.counts().frameListeners):toBe(1)
			world.host.step(1)
			expect(duration:peek()):toBe(0)
			world.host.step(2)
			expect(deadline:peek()):toBe(0)
			expect(world.host.counts().frameListeners):toBe(0)
		end, world.runtime.reactor)
	end)

	it("shares frames across motion, timelines, scheduler, settled and clocks", function()
		local world = Support.world()
		Compose.withRootOwner(function(owner)
			local target = Compose.cell(0)
			world.runtime.tween(function(use)
				return use(target)
			end)
			target:set(1)
			world.runtime.timeline()
			world.runtime.scheduler().after(1, function() end)
			world.runtime.sequence { steps = { { wait = 1 } } }
			world.runtime.mount(function()
				return world.create "Frame" {
					Compose.MountBudget {
						from = Compose.cell { 1, 2 },
						mountsPerFrame = 1,
						render = function()
							return world.create "Frame" {}
						end,
					},
				}
			end, world.root)
			world.runtime.settled {
				sample = function()
					return 0
				end,
			}
			local clock = world.runtime.clock()
			owner.watch(function(use)
				use(clock)
			end)
			expect(world.host.counts().frameListeners):toBe(1)
		end, world.runtime.reactor)
		expect(world.host.counts().frameListeners):toBe(0)
	end)

	it("sequences waits, callbacks, eased samples and parallel timelines across a large frame", function()
		local world = Support.world()
		local calls: { string } = {}
		local progress = 0
		local sequence, owner = Support.owned(function()
			return world.runtime.sequence {
				steps = {
					{ wait = 0.5 },
					{
						run = function()
							table.insert(calls, "start")
						end,
					},
					{
						parallel = {
							{
								tween = { seconds = 1, ease = Compose.easing.inQuad },
								sample = function(n)
									progress = n
								end,
							},
							{
								timeline = { duration = 0.5, repeats = 2, direction = "alternate" },
								sample = function() end,
							},
						} :: { Compose.SequenceStep },
					},
					{
						run = function()
							table.insert(calls, "end")
						end,
					},
				},
			}
		end)
		world.host.step(1)
		expect(progress):toBe(0.25)
		expect(#calls):toBe(1)
		world.host.step(2)
		expect(progress):toBe(1)
		expect(calls[2]):toBe "end"
		expect(sequence.completed:peek()):toBe(true)
		expect(world.host.counts().frameListeners):toBe(0)
		owner.dispose()
	end)

	it("cancels sequences reentrantly and collapses reduced motion in order", function()
		local world = Support.world()
		local reduced = Compose.cell(false)
		local calls = 0
		local sequence, owner = Support.owned(function()
			return world.runtime.sequence {
				reducedMotion = reduced,
				autoplay = false,
				steps = {
					{ wait = 1 },
					{
						run = function()
							calls += 1
						end,
					},
					{ wait = 1 },
				},
			}
		end)
		expect(world.host.counts().frameListeners):toBe(0)
		sequence.play()
		reduced:set(true)
		expect(calls):toBe(1)
		expect(sequence.completed:peek()):toBe(true)
		expect(world.host.counts().frameListeners):toBe(0)
		sequence.play()
		expect(calls):toBe(2)
		owner.dispose()
		local called = false
		local root = Compose.createOwner(world.runtime.reactor)
		Compose.withOwner(root, function()
			world.runtime.sequence {
				steps = {
					{ run = root.dispose },
					{
						run = function()
							called = true
						end,
					},
				},
			}
		end)
		expect(called):toBe(false)
		expect(world.host.counts().frameListeners):toBe(0)
	end)
end)

return nil
