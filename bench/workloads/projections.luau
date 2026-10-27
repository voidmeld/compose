--!strict

local Core = require "../../src/core"
local Roblox = require "../../src/roblox"
local ComposeEngine = require "../harness/compose-engine"
local Types = require "./types"
local Environment = require "../cost-model"
local BareSupport = require "./bare-support"

type Selection = { selected: Core.Value<number>, tick: number, dispose: () -> () }
type Observation = { tick: number, write: (number) -> (), dispose: () -> () }
type Keyed = {
	items: Core.Value<{ number }>,
	initial: { number },
	appended: { number },
	flip: boolean,
	dispose: () -> (),
}
type BareSelection = { rows: { Environment.Instance }, tick: number, dispose: () -> () }
type BareAppend = { frame: Environment.Instance, last: Environment.Instance?, dispose: () -> () }

local selection: Types.Workload = {
	id = "projection-selection-500",
	title = "Selection among 500 keyed projections",
	what = "Changes the selected key 400 times among 500 retained rows.",
	samples = 25,
	iterations = 400,
	warmup = 5,
	cases = {
		compose = Types.compose {
			prepare = function(context: Types.ComposeContext): Selection
				local Compose = context.library
				local selected = Compose.cell(1)
				local Host = context.extras.runtime.constructors
				local dispose = context.extras.runtime.mount(function()
					local project = if Compose.selector then Compose.selector(selected) else nil
					local children: { Core.Node } = {}
					for index = 1, 500 do
						local active = if project
							then project(index)
							else Compose.formula(function(use)
								return use(selected) == index
							end)
						children[index] = Host.Frame { Visible = active }
					end
					return Host.Frame(children)
				end, context.container)
				return { selected = selected, tick = 1, dispose = dispose }
			end,
			run = function(state: Selection)
				state.tick = state.tick % 500 + 1
				state.selected:set(state.tick)
			end,
			snapshot = function(_, context: Types.ComposeContext): string
				return context.env.snapshot(context.container, { "Visible" })
			end,
			release = function(state: Selection)
				state.dispose()
			end,
		},
		bare = Types.bare {
			prepare = function(context: Types.BareContext): BareSelection
				local Instance = BareSupport.instances(context)
				local frame = Instance.new "Frame"
				local rows: { Environment.Instance } = {}
				for index = 1, 500 do
					local row = Instance.new "Frame"
					row.Visible = index == 1
					row.Parent = frame
					rows[index] = row
				end
				frame.Parent = context.container
				return {
					rows = rows,
					tick = 1,
					dispose = function()
						frame:Destroy()
					end,
				}
			end,
			run = function(state: BareSelection)
				state.rows[state.tick].Visible = false
				state.tick = state.tick % 500 + 1
				state.rows[state.tick].Visible = true
			end,
			snapshot = function(_, context: Types.BareContext): string
				return context.env.snapshot(context.container, { "Visible" })
			end,
			release = function(state: BareSelection)
				state.dispose()
			end,
		},
	},
	unsupported = {},
}

local observation: Types.Workload = {
	id = "projection-observe-100",
	title = "100 observers of one engine property",
	what = "Publishes one property signal to 100 independent host subscribers.",
	samples = 25,
	iterations = 400,
	warmup = 5,
	cases = {
		compose = Types.compose {
			prepare = function(context: Types.ComposeContext): Observation
				local host = Roblox.createHost(ComposeEngine.engineFor(context.env))
				local node = host.render.createNode "Frame"
				host.render.insertChild(context.container, node)
				local stops: { () -> () } = {}
				local observation = assert(host.observation)
				local count = 0
				for _ = 1, 100 do
					table.insert(
						stops,
						observation.observeProperty(node, "LayoutOrder", function()
							count += 1
						end)
					)
				end
				return {
					tick = 0,
					write = function(value)
						host.render.setProperty(node, "LayoutOrder", value)
						assert(count == value * 100)
					end,
					dispose = function()
						for _, stop in stops do
							stop()
						end
						host.render.destroyNode(node)
					end,
				}
			end,
			run = function(state: Observation)
				state.tick += 1
				state.write(state.tick)
			end,
			snapshot = function(_, context: Types.ComposeContext): string
				return context.env.snapshot(context.container, { "LayoutOrder" })
			end,
			release = function(state: Observation)
				state.dispose()
			end,
		},
	},
	unsupported = { bare = "measures shared host observation dispatch" },
}

local append: Types.Workload = {
	id = "projection-keyed-append-500",
	title = "Single append to a 500-item keyed list",
	what = "Alternates appending and removing one item while retaining the original 500 rows.",
	samples = 25,
	iterations = 400,
	warmup = 5,
	cases = {
		compose = Types.compose {
			prepare = function(context: Types.ComposeContext): Keyed
				local initial: { number } = {}
				for index = 1, 500 do
					initial[index] = index
				end
				local appended = table.clone(initial)
				appended[501] = 501
				local items = context.library.cell(initial)
				local Host = context.extras.runtime.constructors
				local dispose = context.extras.runtime.mount(function()
					return Host.Frame {
						context.library.keyed {
							from = items,
							render = function(value: Core.ReadOnlyValue<number>)
								return Host.TextLabel { Text = tostring(value:peek()) }
							end,
						},
					}
				end, context.container)
				return { items = items, initial = initial, appended = appended, flip = false, dispose = dispose }
			end,
			run = function(state: Keyed)
				state.flip = not state.flip
				state.items:set(if state.flip then state.appended else state.initial)
			end,
			snapshot = function(_, context: Types.ComposeContext): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: Keyed)
				state.dispose()
			end,
		},
		bare = Types.bare {
			prepare = function(context: Types.BareContext): BareAppend
				local Instance = BareSupport.instances(context)
				local frame = Instance.new "Frame"
				for index = 1, 500 do
					local row = Instance.new "TextLabel"
					row.Text = tostring(index)
					row.Parent = frame
				end
				frame.Parent = context.container
				return {
					frame = frame,
					last = nil,
					dispose = function()
						frame:Destroy()
					end,
				}
			end,
			run = function(state: BareAppend, context: Types.BareContext)
				if state.last then
					state.last:Destroy()
					state.last = nil
				else
					local row = BareSupport.instances(context).new "TextLabel"
					row.Text = "501"
					row.Parent = state.frame
					state.last = row
				end
			end,
			snapshot = function(_, context: Types.BareContext): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: BareAppend)
				state.dispose()
			end,
		},
	},
	unsupported = {},
}

return { selection, observation, append }
