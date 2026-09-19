--!strict

local Compose = require "../src/core"
local TestHost = require "../src/test-host"

type Layer = { id: string }

local function run(): string
	local host = TestHost.create()
	local runtime = Compose.createRuntime(host.host)
	local create = runtime.create
	local Root = create "Root"
	local Node = create "Node"
	local resourceCreates = 0
	local focused = ""

	local dispose, root = runtime.mount(function()
		local actions = Compose.cell { { id = "hud" }, { id = "menu" } }
		local focus = Compose.createFocusScope {
			from = actions,
			key = function(action: { id: string })
				return action.id
			end,
		}
		focused = focus.next() or ""

		local pool = Compose.createPool {
			create = function()
				resourceCreates += 1
				return {}
			end,
			reset = function() end,
			destroy = function() end,
			maxRetained = 1,
		}
		pool.acquire().release()
		pool.acquire().release()

		return Root {
			Compose.LayerStack {
				from = Compose.cell({ { id = "world" }, { id = "overlay" } } :: { Layer }),
				key = function(layer: Layer)
					return layer.id
				end,
				render = function(layer)
					return Node {
						Id = function(use)
							return use(layer).id
						end,
					}
				end,
			},
			Compose.MountBudget {
				from = Compose.cell { { id = "near" }, { id = "far" } },
				key = function(item: { id: string })
					return item.id
				end,
				mountsPerFrame = 2,
				render = function(item)
					return Node {
						Id = function(use)
							return use(item).id
						end,
					}
				end,
			},
		}
	end, host.root)

	local summary = ("%d nodes | %s | %d resource"):format(#host.childrenOf(root), focused, resourceCreates)
	dispose()
	assert(host.liveNodes() == 1, "the composed scene leaked")
	return summary
end

return {
	name = "composition-primitives",
	what = "layers, bounded admission, logical focus and explicit resource reuse in one owned scene",
	expected = "4 nodes | hud | 1 resource",
	run = run,
}
