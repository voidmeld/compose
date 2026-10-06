--!strict

local Environment = require "../cost-model"
local Support = require "./support"
local Types = require "./types"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local function build1(context: Types.ComposeContext, scale: Scale)
	local Compose = context.library
	local runtime = context.extras.runtime
	local Host = runtime.constructors

	local route = Compose.cell(1)
	local modal = Compose.cell(false)
	local targets = table.create(scale.size) :: { Types.Cell<number> }
	for index = 1, scale.size do
		targets[index] = Compose.cell(0)
	end

	local dispose = runtime.mount(function()
		local panels = table.create(scale.size) :: { unknown }
		for index = 1, scale.size do
			local target = targets[index]
			local moved = runtime.spring(function(use: Types.Use): number
				return use(target) :: number
			end, { period = 0.3, damping = 1 })
			panels[index] = Host.Frame {
				Size = function(use: Types.Use): number
					return math.round((use(moved) :: number) * 1000) / 1000
				end,
				LayoutOrder = index,
			}
		end
		return Host.Frame {
			Host.Frame(panels),
			Compose.show(function(use: Types.Use)
				return use(modal)
			end, function()
				return Host.Frame { Name = "Modal" }
			end),
			Name = function(use: Types.Use): string
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
end
type State1 = typeof(build1({} :: Types.ComposeContext, {} :: Scale))

local function build2(context: Types.BareContext, scale: Scale)
	local Instance = Support.instances(context)
	local made: { Environment.Instance } = {}
	local root = Instance.new "Frame"
	root.Name = "route-1"
	table.insert(made, root)
	local panelFrame = Instance.new "Frame"
	panelFrame.Parent = root
	table.insert(made, panelFrame)

	local panels = table.create(scale.size) :: { Environment.Instance }
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
		modal = nil :: Environment.Instance?,
		scale = scale,
	}
end
type State2 = typeof(build2({} :: Types.BareContext, {} :: Scale))

local animatedNavigation: Scenario = {
	id = "animated-navigation",
	title = "Animated navigation with interrupted springs",
	what = "Route replacement and a modal stack over hundreds of concurrent springs, retargeted "
		.. "mid-flight. Measures per-frame integration and exact release on teardown.",
	lane = "scene",
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
		compose = (({
			build = build1,
			steady = function(state: State1, _context: Types.ComposeContext, tick: number)
				state.runtime:batch(function()
					for offset = 0, 9 do
						local at = ((tick * 11 + offset * 7) % state.scale.size) + 1
						state.targets[at]:set(((tick + offset) % 50) / 50)
					end
				end)
				state.env.step(1 / 60)
			end,
			burst = function(state: State1, _context: Types.ComposeContext, round: number)
				state.runtime:batch(function()
					state.route:set(round)
					state.modal:set(round % 2 == 1)
					for index = 1, state.scale.size do
						state.targets[index]:set((round % 7) / 7)
					end
				end)
				state.env.step(1 / 60)
			end,
			teardown = function(state: State1, _context: Types.ComposeContext)
				state.dispose()
			end,

			snapshot = function(state: State1, context: Types.ComposeContext): string
				for _ = 1, 240 do
					context.env.step(1 / 60)
				end
				local _ = state
				return context.env.snapshot(context.container, { "Name", "Size", "LayoutOrder" })
			end,
		} :: Types.Case<State1, Types.ComposeContext>) :: unknown) :: Types.Case<unknown, Types.Context>,

		bare = (({
			build = build2,
			steady = function(state: State2, context: Types.BareContext, tick: number)
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
			burst = function(state: State2, context: Types.BareContext, round: number)
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
			teardown = function(state: State2, _context: Types.BareContext)
				if state.modal ~= nil then
					state.modal:Destroy()
					state.modal = nil
				end
				Support.destroyAll(state.made)
			end,
			snapshot = function(state: State2, context: Types.BareContext): string
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
		} :: Types.Case<State2, Types.BareContext>) :: unknown) :: Types.Case<unknown, Types.Context>,
	},
}

local function build3(context: Types.ComposeContext, _scale: Scale)
	return { runtime = context.extras.runtime, library = context.library }
end
type State3 = typeof(build3({} :: Types.ComposeContext, {} :: Scale))

local function build4(context: Types.BareContext, _scale: Scale)
	return { env = context.env }
end
type State4 = typeof(build4({} :: Types.BareContext, {} :: Scale))

local sessionCycle: Scenario = {
	id = "session-cycle",
	title = "Zone and session transitions with failure unwinding",
	what = "One steady frame is a whole session: mount a screen, flip it from loading to loaded, "
		.. "and release it. Every fourth builds a subtree that fails part-way and must leave "
		.. "nothing behind. Measures mount, teardown, and the failure path when it runs.",
	lane = "scene",
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
		compose = (
				(
					{
						build = build3,
						steady = function(
							state: State3,
							context: Types.RunContext<State3, Types.ComposeContext>,
							tick: number
						)
							local Compose = state.library
							local runtime = state.runtime
							local Host = runtime.constructors
							local scale = context.scale

							local ready = Compose.cell(false)
							local dispose = runtime.mount(function()
								local rows = table.create(scale.size) :: { unknown }
								for index = 1, scale.size do
									rows[index] = Host.Frame { Name = ("row-%d"):format(index), LayoutOrder = index }
								end
								return Host.Frame {
									Host.Frame(rows),
									Compose.show(function(use: Types.Use)
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
										local partial = table.create(scale.size) :: { unknown }
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
						burst = function(
							state: State3,
							context: Types.RunContext<State3, Types.ComposeContext>,
							_round: number
						)
							for tick = 1, 4 do
								context.case.steady(state, context, tick)
							end
						end,
						teardown = function(_state: State3, _context: Types.ComposeContext) end,
						snapshot = function(_state: State3, context: Types.ComposeContext): string
							return context.env.snapshot(context.container, { "Name", "LayoutOrder" })
						end,
					} :: Types.Case<State3, Types.RunContext<State3, Types.ComposeContext>>
				) :: unknown
			) :: Types.Case<unknown, Types.Context>,

		bare = (
				(
					{
						build = build4,
						steady = function(
							_state: State4,
							context: Types.RunContext<State4, Types.BareContext>,
							tick: number
						)
							local Instance = Support.instances(context)
							local scale = context.scale
							local made: { Environment.Instance } = {}
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
								local partial: { Environment.Instance } = {}
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
						burst = function(
							state: State4,
							context: Types.RunContext<State4, Types.BareContext>,
							_round: number
						)
							for tick = 1, 4 do
								context.case.steady(state, context, tick)
							end
						end,
						teardown = function(_state: State4, _context: Types.BareContext) end,
						snapshot = function(_state: State4, context: Types.BareContext): string
							return context.env.snapshot(context.container, { "Name", "LayoutOrder" })
						end,
					} :: Types.Case<State4, Types.RunContext<State4, Types.BareContext>>
				) :: unknown
			) :: Types.Case<unknown, Types.Context>,
	},
}

local function build5(context: Types.ComposeContext, scale: Scale)
	local Compose = context.library
	local runtime = context.extras.runtime
	local Host = runtime.constructors

	local objects = table.create(scale.objects) :: { { Types.Cell<number> } }
	for object = 1, scale.objects do
		local fields = table.create(scale.size) :: { Types.Cell<number> }
		for field = 1, scale.size do
			fields[field] = Compose.cell((object * 1000) + field)
		end
		objects[object] = fields
	end
	local selection = Compose.cell(1)

	local dispose = runtime.mount(function()
		local controls = table.create(scale.size) :: { unknown }
		for field = 1, scale.size do
			controls[field] = Host.Frame {
				Name = ("field-%d"):format(field),
				Text = function(use: Types.Use): string
					local chosen = objects[use(selection) :: number]
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
end
type State5 = typeof(build5({} :: Types.ComposeContext, {} :: Scale))

local function build6(context: Types.BareContext, scale: Scale)
	local Instance = Support.instances(context)
	local made: { Environment.Instance } = {}
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
	local controls = table.create(scale.size) :: { Environment.Instance }
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
end
type State6 = typeof(build6({} :: Types.BareContext, {} :: Scale))

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
		compose = (({
			build = build5,
			steady = function(state: State5, _context: Types.ComposeContext, tick: number)
				local scale = state.scale
				local chosen = state.objects[state.selection:peek()]
				chosen[(tick % scale.size) + 1]:set(tick)
			end,
			burst = function(state: State5, _context: Types.ComposeContext, round: number)
				local scale = state.scale
				state.runtime:batch(function()
					state.selection:set((round % scale.objects) + 1)
					local chosen = state.objects[state.selection:peek()]
					for field = 1, scale.size do
						chosen[field]:set((round * 10000) + field)
					end
				end)
			end,
			teardown = function(state: State5, _context: Types.ComposeContext)
				state.dispose()
			end,
			snapshot = function(_state: State5, context: Types.ComposeContext): string
				return context.env.snapshot(context.container, { "Name", "Text", "LayoutOrder" })
			end,
		} :: Types.Case<State5, Types.ComposeContext>) :: unknown) :: Types.Case<unknown, Types.Context>,

		bare = (({
			build = build6,
			steady = function(state: State6, _context: Types.BareContext, tick: number)
				local scale = state.scale
				local field = (tick % scale.size) + 1
				state.objects[state.selection][field] = tick
				state.controls[field].Text = ("%d"):format(tick)
			end,
			burst = function(state: State6, _context: Types.BareContext, round: number)
				local scale = state.scale
				state.selection = (round % scale.objects) + 1
				local chosen = state.objects[state.selection]
				for field = 1, scale.size do
					chosen[field] = (round * 10000) + field
					state.controls[field].Text = ("%d"):format(chosen[field])
				end
			end,
			teardown = function(state: State6, _context: Types.BareContext)
				Support.destroyAll(state.made)
			end,
			snapshot = function(_state: State6, context: Types.BareContext): string
				return context.env.snapshot(context.container, { "Name", "Text", "LayoutOrder" })
			end,
		} :: Types.Case<State6, Types.BareContext>) :: unknown) :: Types.Case<unknown, Types.Context>,
	},
}

return {
	animatedNavigation = animatedNavigation,
	sessionCycle = sessionCycle,
	inspector = inspector,
}
