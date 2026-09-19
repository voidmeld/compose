--!strict

local BareSupport = require "./bare-support"
local Types = require "./types"

type Context = Types.Context
type Workload = Types.Workload

local LEAF_TREE = 500
local FANOUT = 300
local SOURCES = 300
local REPEATS = 500

local updateLeaf: Workload = {
	id = "update-leaf",
	title = "Single leaf property update",
	what = ("Changes the text of one label in a tree of %d. The interesting number is how many property "):format(
		LEAF_TREE
	) .. "writes it takes: the answer should be one.",
	samples = 30,
	iterations = 50,
	warmup = 5,
	cases = {
		compose = {
			prepare = function(context: Context): any
				local create = context.extras.create
				local text = context.library.cell "value 0"
				local dispose = context.extras.runtime.mount(function()
					local children = table.create(LEAF_TREE)
					for index = 1, LEAF_TREE do
						if index == 1 then
							children[index] = create "TextLabel" { Text = text }
						else
							children[index] = create "TextLabel" { Text = "static " .. tostring(index) }
						end
					end
					return create "Frame"(children)
				end, context.container)
				return { text = text, dispose = dispose, next = 0, runtime = context.extras.runtime }
			end,
			run = function(state: any, _context: Context)
				state.next += 1
				state.text:set("value " .. tostring(state.next))
				state.runtime:settle()
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: any, _context: Context)
				state.dispose()
			end,
		},
		bare = {
			prepare = function(context: Context): any
				local frame, made = BareSupport.buildList(context, LEAF_TREE, function(index: number): string
					return if index == 1 then "value 0" else "static " .. tostring(index)
				end)
				return { made = made, live = context.env.children(frame)[1], next = 0 }
			end,
			run = function(state: any, _context: Context)
				state.next += 1
				state.live.Text = "value " .. tostring(state.next)
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: any, _context: Context)
				BareSupport.destroyAll(state.made)
			end,
		},
	},
	unsupported = {},
}

local updateFanout: Workload = {
	id = "update-fanout",
	title = "One source driving a large fan-out",
	what = ("One value feeds a property on %d nodes at once. Measures how a framework dispatches to many "):format(
		FANOUT
	) .. "dependents, and confirms it writes exactly as many properties as changed.",
	samples = 25,
	iterations = 20,
	warmup = 5,
	cases = {
		compose = {
			prepare = function(context: Context): any
				local create = context.extras.create
				local tint = context.library.cell "tint 0"
				local dispose = context.extras.runtime.mount(function()
					local children = table.create(FANOUT)
					for index = 1, FANOUT do
						children[index] = create "TextLabel" { Text = tint }
					end
					return create "Frame"(children)
				end, context.container)
				return { tint = tint, dispose = dispose, next = 0, runtime = context.extras.runtime }
			end,
			run = function(state: any, _context: Context)
				state.next += 1
				state.tint:set("tint " .. tostring(state.next))
				state.runtime:settle()
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: any, _context: Context)
				state.dispose()
			end,
		},
		bare = {
			prepare = function(context: Context): any
				local frame, made = BareSupport.buildList(context, FANOUT, function(): string
					return "tint 0"
				end)
				return { made = made, rows = context.env.children(frame), next = 0 }
			end,
			run = function(state: any, _context: Context)
				state.next += 1
				local text = "tint " .. tostring(state.next)
				for _, row in state.rows do
					row.Text = text
				end
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: any, _context: Context)
				BareSupport.destroyAll(state.made)
			end,
		},
	},
	unsupported = {},
}

local updateBatched: Workload = {
	id = "update-batched",
	title = "Many independent updates in one batch",
	what = ("%d independent sources, each driving its own node, all updated before anything is allowed to "):format(
		SOURCES
	) .. "observe them. Measures coalescing and confirms no node is written twice.",
	samples = 25,
	iterations = 20,
	warmup = 5,
	cases = {
		compose = {
			prepare = function(context: Context): any
				local create = context.extras.create
				local setters = table.create(SOURCES)
				local dispose = context.extras.runtime.mount(function()
					local children = table.create(SOURCES)
					for index = 1, SOURCES do
						local value = context.library.cell "0"
						setters[index] = value
						children[index] = create "TextLabel" { Text = value }
					end
					return create "Frame"(children)
				end, context.container)
				return { cells = setters, dispose = dispose, next = 0, runtime = context.extras.runtime }
			end,
			run = function(state: any, _context: Context)
				state.next += 1
				local next = tostring(state.next)
				state.runtime:batch(function()
					for _, cell in state.cells do
						cell:set(next)
					end
				end)
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: any, _context: Context)
				state.dispose()
			end,
		},
		bare = {
			prepare = function(context: Context): any
				local frame, made = BareSupport.buildList(context, SOURCES, function(): string
					return "0"
				end)
				return { made = made, rows = context.env.children(frame), next = 0 }
			end,
			run = function(state: any, _context: Context)
				state.next += 1
				local text = tostring(state.next)
				for _, row in state.rows do
					row.Text = text
				end
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: any, _context: Context)
				BareSupport.destroyAll(state.made)
			end,
		},
	},
	unsupported = {},
}

local updateRepeated: Workload = {
	id = "update-repeated",
	title = "Repeated writes to one source",
	what = ("Writes one source %d times inside a single batch. Only the last value should ever reach the "):format(
		REPEATS
	) .. "host, so the property-write count should be one however many writes happened.",
	samples = 25,
	iterations = 10,
	warmup = 5,
	cases = {
		compose = {
			prepare = function(context: Context): any
				local create = context.extras.create
				local value = context.library.cell(0)
				local dispose = context.extras.runtime.mount(function()
					return create "Frame" {
						create "TextLabel" {
							Text = function(use)
								return tostring(use(value))
							end,
						},
					}
				end, context.container)
				return { value = value, dispose = dispose, base = 0, runtime = context.extras.runtime }
			end,
			run = function(state: any, _context: Context)
				state.runtime:batch(function()
					for step = 1, REPEATS do
						state.value:set(state.base + step)
					end
				end)
				state.base += REPEATS
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: any, _context: Context)
				state.dispose()
			end,
		},
		bare = {
			prepare = function(context: Context): any
				local frame, made = BareSupport.buildList(context, 1, function(): string
					return "0"
				end)
				return { made = made, label = context.env.children(frame)[1], base = 0 }
			end,
			run = function(state: any, _context: Context)
				local final = state.base
				for step = 1, REPEATS do
					final = state.base + step
				end
				state.label.Text = tostring(final)
				state.base += REPEATS
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Text" })
			end,
			release = function(state: any, _context: Context)
				BareSupport.destroyAll(state.made)
			end,
		},
	},
	unsupported = {},
}

return {
	updateLeaf,
	updateFanout,
	updateBatched,
	updateRepeated,
}
