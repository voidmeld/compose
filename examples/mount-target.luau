--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

local function run(): string
	local test = TestScene.create()
	local runtime = Compose.createRuntime(test.adapter)
	local Host = runtime.constructors
	local cell = Compose.cell

	local clonedRig = test.makeNode "Rig"

	local caption = cell "idle"

	local container: Compose.Node? = nil

	local dispose = runtime.mount(function()
		local group = Host.Model {
			Name = "Entity",
			Host.Part { Name = "Anchor" },
		}
		container = group

		runtime.adopt(clonedRig)
		runtime.mount(function()
			return clonedRig
		end, group)

		runtime.mountFragment(function()
			return {
				Host.Label {
					Text = function(use): string
						return ("state: %s"):format(use(caption))
					end,
				},
			}
		end, group)

		return group
	end, test.root)

	local group = container :: Compose.Node
	assert(Compose.custodyOf(group) == "owned", "the mount target was demoted to borrowed")
	assert(Compose.custodyOf(clonedRig) == "adopted", "the clone should be adopted")

	caption:set "running"
	runtime:settle()

	local placed = #test.childrenOf(group)
	assert(placed == 3, "the anchor, the rig and the label should all be under the group")

	local unmountBadge = runtime.mount(function()
		return Host.Label { Text = "badge" }
	end, group)
	assert(Compose.custodyOf(group) == "owned", "a top-level mount demoted the target")
	assert(#test.childrenOf(group) == 4, "the badge should be under the group")

	unmountBadge()
	assert(test.isAlive(group), "unmounting the block must not destroy the target")
	assert(#test.childrenOf(group) == 3, "the badge should be gone and nothing else with it")

	runtime.mount(function()
		return Host.Label { Text = "overlay" }
	end, group)
	assert(Compose.outstandingMounts() == 2, "the tree mount and the overlay should both be held")

	dispose()

	assert(not test.isAlive(group), "the owned mount target should have been destroyed")
	assert(not test.isAlive(clonedRig), "the adopted clone should have been destroyed")
	assert(test.isAlive(test.root), "the borrowed root must be left standing")
	assert(#test.leaked() == 1, "only the borrowed root should be left")
	assert(Compose.outstandingMounts() == 0, "a mount was left standing")

	return ("%d children under an owned target, 0 left after disposal"):format(placed)
end

return {
	name = "mount-target",
	what = "mounting into a node the tree already owns, without demoting it to borrowed",
	expected = "3 children under an owned target, 0 left after disposal",
	run = run,
}
