--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

type Layer = { id: string }

local function run(): string
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors
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

		return Host.Root {
			Compose.LayerStack {
				from = Compose.cell({ { id = "world" }, { id = "overlay" } } :: { Layer }),
				key = function(layer: Layer)
					return layer.id
				end,
				render = function(layer)
					return Host.Node {
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
					return Host.Node {
						Id = function(use)
							return use(item).id
						end,
					}
				end,
			},
		}
	end, test.root)

	local summary = ("%d nodes | %s | %d resource"):format(#test.childrenOf(root), focused, resourceCreates)
	dispose()
	assert(test.liveNodes() == 1, "the composed scene leaked")
	return summary
end

return {
	name = "composition-primitives",
	what = "layers, bounded admission, logical focus and explicit resource reuse in one owned scene",
	expected = "4 nodes | hud | 1 resource",
	run = run,
}
