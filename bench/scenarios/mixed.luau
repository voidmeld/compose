--!strict

local Support = require "./support"
local Types = require "./types"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local animatedNavigation: Scenario = {
	id = "animated-navigation",
	title = "Animated navigation with interrupted springs",
	what = "Route replacement and a modal stack over hundreds of concurrent springs, retargeted "
		.. "mid-flight. Measures per-frame integration and exact release on teardown.",
	lane = "game",
	steadyBudgetSeconds = 0.004,
	scales = {
		{ name = "medium", size = 100 },
		{ name = "large", size = 300 },
		{ name = "extreme", size = 600 },
	},
	steadyFrames = 90,
	burstRounds = 6,
	samples = 7,
	warmup = 2,
	cases = {
		compose = {
			build = function(context: Context, scale: Scale): any
				local Compose = context.library
				local runtime = context.extras.runtime
				local Host = runtime.constructors

				local route = Compose.cell(1)
				local modal = Compose.cell(false)
				local targets = table.create(scale.size)
				for index = 1, scale.size do
					targets[index] = Compose.cell(0)
				end

				local dispose = runtime.mount(function()
					local panels = table.create(scale.size)
					for index = 1, scale.size do
						local target = targets[index]
						local moved = runtime.spring(function(use): number
							return use(target) :: number
						end, { period = 0.3, damping = 1 })
						panels[index] = Host.Frame {
							Size = function(use): number
								return math.round((use(moved) :: number) * 1000) / 1000
							end,
							LayoutOrder = index,
						}
					end
					return Host.Frame {
						Host.Frame(panels),
						Compose.show(function(use)
							return use(modal)
						end, function()
							return Host.Frame { Name = "Modal" }
						end),
						Name = function(use): string
							return ("route-%d"):format(use(route) :: number)
						end,
					}
				end, context.container)

				return {
					dispose = dispose,
					runtime = runtime,
					env = context.env,
					route = route,
					modal = modal,
					targets = targets,
					scale = scale,
				}
			end,
			steady = function(state: any, _context: Context, tick: number)
				state.runtime:batch(function()
					for offset = 0, 9 do
						local at = ((tick * 11 + offset * 7) % state.scale.size) + 1
						state.targets[at]:set(((tick + offset) % 50) / 50)
					end
				end)
				state.env.step(1 / 60)
			end,
			burst = function(state: any, _context: Context, round: number)
				state.runtime:batch(function()
					state.route:set(round)
					state.modal:set(round % 2 == 1)
					for index = 1, state.scale.size do
						state.targets[index]:set((round % 7) / 7)
					end
				end)
				state.env.step(1 / 60)
			end,
			teardown = function(state: any, _context: Context)
				state.dispose()
			end,

			snapshot = function(state: any, context: Context): string
				for _ = 1, 240 do
					context.env.step(1 / 60)
				end
				local _ = state
				return context.env.snapshot(context.container, { "Name", "Size", "LayoutOrder" })
			end,
		},

		bare = {
			build = function(context: Context, scale: Scale): any
				local Instance = Support.instances(context)
				local made: { any } = {}
				local root = Instance.new "Frame"
				root.Name = "route-1"
				table.insert(made, root)
				local panelFrame = Instance.new "Frame"
				panelFrame.Parent = root
				table.insert(made, panelFrame)

				local panels = table.create(scale.size)
				local current = table.create(scale.size, 0)
				local velocity = table.create(scale.size, 0)
				local target = table.create(scale.size, 0)
				for index = 1, scale.size do
					local node = Instance.new "Frame"
					node.Size = 0
					node.LayoutOrder = index
					node.Parent = panelFrame
					table.insert(made, node)
					panels[index] = node
				end
				root.Parent = context.container

				return {
					made = made,
					root = root,
					panelFrame = panelFrame,
					panels = panels,
					current = current,
					velocity = velocity,
					target = target,
					modal = nil :: any,
					scale = scale,
				}
			end,
			steady = function(state: any, context: Context, tick: number)
				local scale = state.scale
				for offset = 0, 9 do
					local at = ((tick * 11 + offset * 7) % scale.size) + 1
					state.target[at] = ((tick + offset) % 50) / 50
				end

				local frequency = 2 * math.pi / 0.3
				local stiffness = frequency * frequency
				local drag = 2 * frequency
				local fixed = 1 / 120
				local remaining = 1 / 60
				while remaining > 0 do
					local h = if remaining > fixed then fixed else remaining
					remaining -= h
					for index = 1, scale.size do
						local offset = state.current[index] - state.target[index]
						local acceleration = -stiffness * offset - drag * state.velocity[index]
						state.velocity[index] += acceleration * h
						state.current[index] += state.velocity[index] * h
					end
				end
				for index = 1, scale.size do
					state.panels[index].Size = math.round(state.current[index] * 1000) / 1000
				end
				context.env.step(1 / 60)
			end,
			burst = function(state: any, context: Context, round: number)
				local Instance = Support.instances(context)
				state.root.Name = ("route-%d"):format(round)
				for index = 1, state.scale.size do
					state.target[index] = (round % 7) / 7
				end
				local wantsModal = round % 2 == 1
				if wantsModal and state.modal == nil then
					local node = Instance.new "Frame"
					node.Name = "Modal"
					node.Parent = state.root
					state.modal = node
				elseif not wantsModal and state.modal ~= nil then
					state.modal:Destroy()
					state.modal = nil
				end
				context.env.step(1 / 60)
			end,
			teardown = function(state: any, _context: Context)
				if state.modal ~= nil then
					state.modal:Destroy()
					state.modal = nil
				end
				Support.destroyAll(state.made)
			end,
			snapshot = function(state: any, context: Context): string
				local frequency = 2 * math.pi / 0.3
				local stiffness = frequency * frequency
				local drag = 2 * frequency
				local fixed = 1 / 120
				for _ = 1, 240 do
					local remaining = 1 / 60
					while remaining > 0 do
						local h = if remaining > fixed then fixed else remaining
						remaining -= h
						for index = 1, state.scale.size do
							local offset = state.current[index] - state.target[index]
							local acceleration = -stiffness * offset - drag * state.velocity[index]
							state.velocity[index] += acceleration * h
							state.current[index] += state.velocity[index] * h
						end
					end
					context.env.step(1 / 60)
				end
				for index = 1, state.scale.size do
					state.panels[index].Size = math.round(state.current[index] * 1000) / 1000
				end
				return context.env.snapshot(context.container, { "Name", "Size", "LayoutOrder" })
			end,
		},
	},
}

local sessionCycle: Scenario = {
	id = "session-cycle",
	title = "Zone and session transitions with failure unwinding",
	what = "One steady frame is a whole session: mount a screen, flip it from loading to loaded, "
		.. "and release it. Every fourth builds a subtree that fails part-way and must leave "
		.. "nothing behind. Measures mount, teardown, and the failure path when it runs.",
	lane = "game",
	steadyBudgetSeconds = 0.02,
	scales = {
		{ name = "medium", size = 60 },
		{ name = "large", size = 200 },
		{ name = "extreme", size = 500 },
	},
	steadyFrames = 24,
	burstRounds = 4,
	samples = 7,
	warmup = 2,
	cases = {
		compose = {
			build = function(context: Context, _scale: Scale): any
				return { runtime = context.extras.runtime, library = context.library }
			end,
			steady = function(state: any, context: Context, tick: number)
				local Compose = state.library
				local runtime = state.runtime
				local Host = runtime.constructors
				local scale: any = (context :: any).scale

				local ready = Compose.cell(false)
				local dispose = runtime.mount(function()
					local rows = table.create(scale.size)
					for index = 1, scale.size do
						rows[index] = Host.Frame { Name = ("row-%d"):format(index), LayoutOrder = index }
					end
					return Host.Frame {
						Host.Frame(rows),
						Compose.show(function(use)
							return use(ready)
						end, function()
							return Host.Frame { Name = "Loaded" }
						end, function()
							return Host.Frame { Name = "Loading" }
						end),
					}
				end, context.container)
				ready:set(true)

				if tick % 4 == 0 then
					pcall(function()
						runtime.mount(function()
							local partial = table.create(scale.size)
							for index = 1, scale.size do
								if index == scale.size // 2 then
									error "zone asset missing"
								end
								partial[index] = Host.Frame { Name = ("partial-%d"):format(index) }
							end
							return Host.Frame(partial)
						end, context.container)
					end)
				end

				dispose()
			end,
			burst = function(state: any, context: Context, _round: number)
				for tick = 1, 4 do
					((context :: any).case.steady :: any)(state, context, tick)
				end
			end,
			teardown = function(_state: any, _context: Context) end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "LayoutOrder" })
			end,
		},

		bare = {
			build = function(context: Context, _scale: Scale): any
				return { env = context.env }
			end,
			steady = function(_state: any, context: Context, tick: number)
				local Instance = Support.instances(context)
				local scale: any = (context :: any).scale
				local made: { any } = {}
				local root = Instance.new "Frame"
				table.insert(made, root)
				local rowFrame = Instance.new "Frame"
				rowFrame.Parent = root
				table.insert(made, rowFrame)
				for index = 1, scale.size do
					local node = Instance.new "Frame"
					node.Name = ("row-%d"):format(index)
					node.LayoutOrder = index
					node.Parent = rowFrame
					table.insert(made, node)
				end
				local status = Instance.new "Frame"
				status.Name = "Loading"
				status.Parent = root
				table.insert(made, status)
				root.Parent = context.container
				status:Destroy()
				table.remove(made, #made)
				local loaded = Instance.new "Frame"
				loaded.Name = "Loaded"
				loaded.Parent = root
				table.insert(made, loaded)

				if tick % 4 == 0 then
					local partial: { any } = {}
					local ok = pcall(function()
						local holder = Instance.new "Frame"
						holder.Parent = context.container
						table.insert(partial, holder)
						for index = 1, scale.size do
							if index == scale.size // 2 then
								error "zone asset missing"
							end
							local node = Instance.new "Frame"
							node.Name = ("partial-%d"):format(index)
							node.Parent = holder
							table.insert(partial, node)
						end
					end)
					if not ok then
						Support.destroyAll(partial)
					end
				end

				Support.destroyAll(made)
			end,
			burst = function(state: any, context: Context, _round: number)
				for tick = 1, 4 do
					((context :: any).case.steady :: any)(state, context, tick)
				end
			end,
			teardown = function(_state: any, _context: Context) end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "LayoutOrder" })
			end,
		},
	},
}

local inspector: Scenario = {
	id = "inspector",
	title = "Property inspector with multi-object selection",
	what = "Hundreds of controls bound to a selection. The steady frame edits one field; the "
		.. "burst changes the selection, repointing every control, and applies a batched edit.",
	lane = "app",
	steadyBudgetSeconds = 0.001,
	scales = {
		{ name = "medium", size = 150, objects = 20 },
		{ name = "large", size = 400, objects = 50 },
		{ name = "extreme", size = 800, objects = 100 },
	},
	steadyFrames = 90,
	burstRounds = 6,
	samples = 7,
	warmup = 2,
	cases = {
		compose = {
			build = function(context: Context, scale: Scale): any
				local Compose = context.library
				local runtime = context.extras.runtime
				local Host = runtime.constructors

				local objects = table.create(scale.objects)
				for object = 1, scale.objects do
					local fields = table.create(scale.size)
					for field = 1, scale.size do
						fields[field] = Compose.cell((object * 1000) + field)
					end
					objects[object] = fields
				end
				local selection = Compose.cell(1)

				local dispose = runtime.mount(function()
					local controls = table.create(scale.size)
					for field = 1, scale.size do
						controls[field] = Host.Frame {
							Name = ("field-%d"):format(field),
							Text = function(use): string
								local chosen: any = objects[use(selection) :: number]
								return ("%d"):format(use(chosen[field]) :: number)
							end,
							LayoutOrder = field,
						}
					end
					return Host.Frame(controls)
				end, context.container)

				return {
					dispose = dispose,
					runtime = runtime,
					objects = objects,
					selection = selection,
					scale = scale,
				}
			end,
			steady = function(state: any, _context: Context, tick: number)
				local scale = state.scale
				local chosen = state.objects[state.selection:peek()]
				chosen[(tick % scale.size) + 1]:set(tick)
			end,
			burst = function(state: any, _context: Context, round: number)
				local scale = state.scale
				state.runtime:batch(function()
					state.selection:set((round % scale.objects) + 1)
					local chosen = state.objects[state.selection:peek()]
					for field = 1, scale.size do
						chosen[field]:set((round * 10000) + field)
					end
				end)
			end,
			teardown = function(state: any, _context: Context)
				state.dispose()
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "Text", "LayoutOrder" })
			end,
		},

		bare = {
			build = function(context: Context, scale: Scale): any
				local Instance = Support.instances(context)
				local made: { any } = {}
				local root = Instance.new "Frame"
				table.insert(made, root)
				local objects = table.create(scale.objects) :: { { number } }
				for object = 1, scale.objects do
					local fields = table.create(scale.size) :: { number }
					for field = 1, scale.size do
						fields[field] = (object * 1000) + field
					end
					objects[object] = fields
				end
				local controls = table.create(scale.size)
				for field = 1, scale.size do
					local node = Instance.new "Frame"
					node.Name = ("field-%d"):format(field)
					node.Text = ("%d"):format(objects[1][field])
					node.LayoutOrder = field
					node.Parent = root
					table.insert(made, node)
					controls[field] = node
				end
				root.Parent = context.container
				return { made = made, controls = controls, objects = objects, selection = 1, scale = scale }
			end,
			steady = function(state: any, _context: Context, tick: number)
				local scale = state.scale
				local field = (tick % scale.size) + 1
				state.objects[state.selection][field] = tick
				state.controls[field].Text = ("%d"):format(tick)
			end,
			burst = function(state: any, _context: Context, round: number)
				local scale = state.scale
				state.selection = (round % scale.objects) + 1
				local chosen = state.objects[state.selection]
				for field = 1, scale.size do
					chosen[field] = (round * 10000) + field
					state.controls[field].Text = ("%d"):format(chosen[field])
				end
			end,
			teardown = function(state: any, _context: Context)
				Support.destroyAll(state.made)
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "Text", "LayoutOrder" })
			end,
		},
	},
}

return {
	animatedNavigation = animatedNavigation,
	sessionCycle = sessionCycle,
	inspector = inspector,
}
