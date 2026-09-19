--!strict

local BareSupport = require "./bare-support"
local Types = require "./types"

type Context = Types.Context
type Workload = Types.Workload

local function labelText(index: number): string
	return "row " .. tostring(index)
end

local function coldMount(count: number): Workload
	return {
		id = ("cold-mount-%d"):format(count),
		title = ("Cold construction of %d nodes"):format(count),
		what = ("Builds a frame containing %d text labels from nothing. Measures per-node construction cost."):format(
			count
		),
		samples = if count >= 10000 then 8 else 20,
		iterations = 1,
		warmup = 3,
		cases = {
			compose = {
				prepare = function(_context: Context): any
					return { disposers = {} :: { () -> () } }
				end,
				run = function(state: any, context: Context)
					local Host = context.extras.runtime.constructors
					local dispose = context.extras.runtime.mount(function()
						local children = table.create(count)
						for index = 1, count do
							children[index] = Host.TextLabel { Text = labelText(index) }
						end
						return Host.Frame(children)
					end, context.container)
					table.insert(state.disposers, dispose)
				end,
				snapshot = function(_state: any, context: Context): string
					return context.env.snapshot(context.container, { "Text" })
				end,
				release = function(state: any, _context: Context)
					for index = #state.disposers, 1, -1 do
						state.disposers[index]()
					end
				end,
			},
			bare = {
				prepare = function(_context: Context): any
					return { made = {} :: { { any } } }
				end,
				run = function(state: any, context: Context)
					local _frame, made = BareSupport.buildList(context, count, labelText)
					table.insert(state.made, made)
				end,
				snapshot = function(_state: any, context: Context): string
					return context.env.snapshot(context.container, { "Text" })
				end,
				release = function(state: any, _context: Context)
					for index = #state.made, 1, -1 do
						BareSupport.destroyAll(state.made[index])
						state.made[index] = nil
					end
				end,
			},
		},
		unsupported = {},
	}
end

local mountDispose: Workload = {
	id = "mount-dispose",
	title = "Warm mount and complete disposal",
	what = "Builds a 200-node tree and tears it down again, in one timed operation. Measures the round trip, "
		.. "and the release counters prove the teardown was complete.",
	samples = 20,
	iterations = 5,
	warmup = 3,
	cases = {
		compose = {
			prepare = function(_context: Context): any
				return {}
			end,
			run = function(_state: any, context: Context)
				local Host = context.extras.runtime.constructors
				local dispose = context.extras.runtime.mount(function()
					local children = table.create(200)
					for index = 1, 200 do
						children[index] = Host.TextLabel { Text = labelText(index) }
					end
					return Host.Frame(children)
				end, context.container)
				dispose()
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
				local _frame, made = BareSupport.buildList(context, 200, labelText)
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

return {
	coldMount(100),
	coldMount(1000),
	coldMount(10000),
	mountDispose,
}
