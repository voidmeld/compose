--!strict

local BareSupport = require "./bare-support"
local Types = require "./types"

type Context = Types.Context
type Workload = Types.Workload

local HANDLERS = 200
local ANIMATED = 200
local HUD_ROWS = 40

local BUFF_POOL: { { id: number } } = {}
for index = 1, HUD_ROWS + 1 do
	BUFF_POOL[index] = { id = index }
end

local function buffPrefix(count: number): { { id: number } }
	local list = table.create(count) :: { { id: number } }
	table.move(BUFF_POOL, 1, count, 1, list)
	return list
end
local CYCLES = 30

local events: Workload = {
	id = "events",
	title = "Event connection, dispatch, and release",
	what = ("Connects a handler to each of %d buttons, fires every one, and releases them. The connection "):format(
		HANDLERS
	) .. "counters prove nothing is left attached.",
	samples = 20,
	iterations = 5,
	warmup = 3,
	cases = {
		compose = {
			prepare = function(_context: Context): any
				return { fired = 0 }
			end,
			run = function(state: any, context: Context)
				local Compose = context.library
				local Host = context.extras.runtime.constructors
				local buttons = {}
				local dispose = context.extras.runtime.mount(function()
					local children = table.create(HANDLERS)
					for index = 1, HANDLERS do
						local button = Host.TextButton {
							Text = "b" .. tostring(index),
							[Compose.event "Activated"] = function()
								state.fired += 1
							end,
						}
						buttons[index] = button
						children[index] = button
					end
					return Host.Frame(children)
				end, context.container)
				for _, button in buttons do
					context.env.fire(button, "Activated")
				end
				dispose()
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(_state: any, _context: Context) end,
		},
		bare = {
			prepare = function(_context: Context): any
				return { fired = 0 }
			end,
			run = function(state: any, context: Context)
				local Instance = BareSupport.instances(context)
				local frame = Instance.new "Frame"
				local made = table.create(HANDLERS + 1)
				local connections = table.create(HANDLERS) :: { any }
				made[1] = frame
				for index = 1, HANDLERS do
					local button = Instance.new "TextButton"
					button.Text = "b" .. tostring(index)
					connections[index] = button.Activated:Connect(function()
						state.fired += 1
					end)
					button.Parent = frame
					made[index + 1] = button
				end
				frame.Parent = context.container

				for index = 2, #made do
					context.env.fire(made[index], "Activated")
				end

				for index = #connections, 1, -1 do
					connections[index]:Disconnect()
				end
				BareSupport.destroyAll(made)
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(_state: any, _context: Context) end,
		},
	},
	unsupported = {},
}

local animateMany: Workload = {
	id = "animate-many",
	title = "Hundreds of simultaneous animated values",
	what = ("Retargets %d springs and steps 30 frames. Measures per-frame animation cost, and the property "):format(
		ANIMATED
	) .. "counters show how much of it reaches the host.",
	samples = 12,
	iterations = 1,
	warmup = 3,
	perUnit = {
		{ count = 30, name = "simulated frame" },
		{ count = 30 * ANIMATED, name = "spring-frame" },
	},
	cases = {
		compose = {
			prepare = function(context: Context): any
				local Host = context.extras.runtime.constructors
				local target = context.library.cell(0)
				local dispose = context.extras.runtime.mount(function()
					local children = table.create(ANIMATED)
					for index = 1, ANIMATED do
						local moved = context.extras.runtime.spring(function(use): number
							return (use(target) :: number) + index
						end, { period = 0.3, damping = 1 })
						children[index] = Host.Frame {
							LayoutOrder = function(use)
								return math.round(use(moved))
							end,
						}
					end
					return Host.Frame(children)
				end, context.container)
				return { dispose = dispose, target = target, runtime = context.extras.runtime }
			end,
			run = function(state: any, context: Context)
				state.target:set(100)
				state.runtime:settle()
				for _ = 1, 30 do
					context.env.step(1 / 60)
				end
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container)
			end,
			release = function(state: any, _context: Context)
				state.dispose()
			end,
		},
		bare = {
			prepare = function(context: Context): any
				local Instance = BareSupport.instances(context)
				local frame = Instance.new "Frame"
				local made = table.create(ANIMATED + 1)
				made[1] = frame
				local springs = table.create(ANIMATED)
				for index = 1, ANIMATED do
					local node = Instance.new "Frame"
					node.LayoutOrder = index
					node.Parent = frame
					made[index + 1] = node
					springs[index] = { node = node, position = index, velocity = 0, target = index }
				end
				frame.Parent = context.container
				return { made = made, springs = springs, frame = frame }
			end,
			run = function(state: any, context: Context)
				for _, spring in state.springs do
					spring.target = 100 + spring.node.LayoutOrder
				end

				local frequency = 2 * math.pi / 0.3
				local stiffness = frequency * frequency
				local drag = 2 * frequency
				local fixed = 1 / 120

				for _ = 1, 30 do
					local remaining = 1 / 60
					while remaining > 0 do
						local h = if remaining > fixed then fixed else remaining
						remaining -= h
						for _, spring in state.springs do
							local offset = spring.position - spring.target
							local acceleration = -stiffness * offset - drag * spring.velocity
							spring.velocity += acceleration * h
							spring.position += spring.velocity * h
						end
					end
					for _, spring in state.springs do
						spring.node.LayoutOrder = math.round(spring.position)
					end
					context.env.step(1 / 60)
				end
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container)
			end,
			release = function(state: any, _context: Context)
				BareSupport.destroyAll(state.made)
			end,
		},
	},
}

local hud: Workload = {
	id = "hud",
	title = "Game HUD with rapidly changing values",
	what = ("A health bar, a resource bar, and %d buff rows, updated together each frame the way combat "):format(
		HUD_ROWS
	) .. "actually updates them. The composite case: collections, bindings, and batching at once.",
	samples = 20,
	iterations = 20,
	warmup = 5,
	cases = {
		compose = {
			prepare = function(context: Context): any
				local Compose = context.library
				local Host = context.extras.runtime.constructors
				local health = Compose.cell(100)
				local resource = Compose.cell(50)
				local buffs = Compose.cell {}
				local dispose = context.extras.runtime.mount(function()
					return Host.Frame {
						Host.Frame {
							Text = function(use)
								return "hp " .. tostring(use(health))
							end,
						},
						Host.Frame {
							Text = function(use)
								return "mp " .. tostring(use(resource))
							end,
						},
						Compose.keyed {
							from = function(use)
								return use(buffs)
							end,
							render = function(value, index)
								return Host.TextLabel {

									Text = tostring(Compose.sample(value).id),
									LayoutOrder = function(use)
										return use(index)
									end,
								}
							end,
							key = function(item)
								return item.id
							end,
						},
					}
				end, context.container)
				return {
					dispose = dispose,
					health = health,
					resource = resource,
					buffs = buffs,
					tick = 0,
					runtime = context.extras.runtime,
				}
			end,
			run = function(state: any, _context: Context)
				state.tick += 1
				local list = buffPrefix((state.tick % HUD_ROWS) + 1)
				state.runtime:batch(function()
					state.health:set(100 - (state.tick % 100))
					state.resource:set((state.tick * 3) % 100)
					state.buffs:set(list)
				end)
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text", "LayoutOrder" }, "LayoutOrder")
			end,
			release = function(state: any, _context: Context)
				state.dispose()
			end,
		},
		bare = {
			prepare = function(context: Context): any
				local Instance = BareSupport.instances(context)
				local frame = Instance.new "Frame"
				local hp = Instance.new "Frame"
				hp.Text = "hp 100"
				hp.Parent = frame
				local mp = Instance.new "Frame"
				mp.Text = "mp 50"
				mp.Parent = frame
				frame.Parent = context.container
				return {
					frame = frame,
					hp = hp,
					mp = mp,
					byId = {} :: { [number]: any },
					count = 0,
					tick = 0,
				}
			end,
			run = function(state: any, context: Context)
				local Instance = BareSupport.instances(context)
				state.tick += 1
				local wanted = (state.tick % HUD_ROWS) + 1

				state.hp.Text = "hp " .. tostring(100 - (state.tick % 100))
				state.mp.Text = "mp " .. tostring((state.tick * 3) % 100)

				for index = state.count + 1, wanted do
					local row = Instance.new "TextLabel"
					row.Text = tostring(index)
					row.LayoutOrder = index
					row.Parent = state.frame
					state.byId[index] = row
				end
				for index = state.count, wanted + 1, -1 do
					state.byId[index]:Destroy()
					state.byId[index] = nil
				end
				state.count = wanted
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text", "LayoutOrder" }, "LayoutOrder")
			end,
			release = function(state: any, _context: Context)
				for index = state.count, 1, -1 do
					state.byId[index]:Destroy()
				end
				state.mp:Destroy()
				state.hp:Destroy()
				state.frame:Destroy()
			end,
		},
	},
	unsupported = {},
}

local mountCycles: Workload = {
	id = "mount-cycles",
	title = "Repeated mount and unmount cycles",
	what = ("Builds and tears down a 60-node tree %d times. `leakedInstances` and `leakedConnections` in "):format(
		CYCLES
	) .. "the raw samples are the point: both must be zero.",
	samples = 12,
	iterations = 1,
	warmup = 3,
	perUnit = { { count = CYCLES, name = "mount/unmount cycle" } },
	cases = {
		compose = {
			prepare = function(_context: Context): any
				return {}
			end,
			run = function(_state: any, context: Context)
				local Compose = context.library
				local Host = context.extras.runtime.constructors
				for _ = 1, CYCLES do
					local dispose = context.extras.runtime.mount(function()
						local children = table.create(60)
						for index = 1, 60 do
							children[index] = Host.TextButton {
								Text = "n" .. tostring(index),
								[Compose.event "Activated"] = function() end,
							}
						end
						return Host.Frame(children)
					end, context.container)
					dispose()
				end
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(_state: any, _context: Context) end,
		},
		bare = {
			prepare = function(_context: Context): any
				return {}
			end,
			run = function(_state: any, context: Context)
				local Instance = BareSupport.instances(context)
				for _ = 1, CYCLES do
					local frame = Instance.new "Frame"
					local made = table.create(61)
					local connections = table.create(60) :: { any }
					made[1] = frame
					for index = 1, 60 do
						local button = Instance.new "TextButton"
						button.Text = "n" .. tostring(index)
						connections[index] = button.Activated:Connect(function() end)
						button.Parent = frame
						made[index + 1] = button
					end
					frame.Parent = context.container
					for index = #connections, 1, -1 do
						connections[index]:Disconnect()
					end
					BareSupport.destroyAll(made)
				end
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(_state: any, _context: Context) end,
		},
	},
	unsupported = {},
}

return {
	events,
	animateMany,
	hud,
	mountCycles,
}
