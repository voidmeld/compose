--!strict

local Compose = require "../src/core"
local TestHost = require "../src/test-host"

local function run(): string
	local host = TestHost.create()
	local runtime = Compose.createRuntime(host.host)
	local create = runtime.create
	local cell = Compose.cell

	local Model = create "Model"
	local Part = create "Part"
	local Label = create "Label"

	local clonedRig = host.makeNode "Rig"

	local caption = cell "idle"

	local container: Compose.Node? = nil

	local dispose = runtime.mount(function()
		local group = Model {
			Name = "Entity",
			Part { Name = "Anchor" },
		}
		container = group

		runtime.adopt(clonedRig)
		runtime.mount(function()
			return clonedRig
		end, group)

		runtime.mountFragment(function()
			return {
				Label {
					Text = function(use): string
						return ("state: %s"):format(use(caption))
					end,
				},
			}
		end, group)

		return group
	end, host.root)

	local group = container :: Compose.Node
	assert(Compose.custodyOf(group) == "owned", "the mount target was demoted to borrowed")
	assert(Compose.custodyOf(clonedRig) == "adopted", "the clone should be adopted")

	caption:set "running"
	runtime:settle()

	local placed = #host.childrenOf(group)
	assert(placed == 3, "the anchor, the rig and the label should all be under the group")

	local unmountBadge = runtime.mount(function()
		return Label { Text = "badge" }
	end, group)
	assert(Compose.custodyOf(group) == "owned", "a top-level mount demoted the target")
	assert(#host.childrenOf(group) == 4, "the badge should be under the group")

	unmountBadge()
	assert(host.isAlive(group), "unmounting the block must not destroy the target")
	assert(#host.childrenOf(group) == 3, "the badge should be gone and nothing else with it")

	runtime.mount(function()
		return Label { Text = "overlay" }
	end, group)
	assert(Compose.outstandingMounts() == 2, "the tree mount and the overlay should both be held")

	dispose()

	assert(not host.isAlive(group), "the owned mount target should have been destroyed")
	assert(not host.isAlive(clonedRig), "the adopted clone should have been destroyed")
	assert(host.isAlive(host.root), "the borrowed root must be left standing")
	assert(#host.leaked() == 1, "only the borrowed root should be left")
	assert(Compose.outstandingMounts() == 0, "a mount was left standing")

	return ("%d children under an owned target, 0 left after disposal"):format(placed)
end

return {
	name = "mount-target",
	what = "mounting into a node the tree already owns, without demoting it to borrowed",
	expected = "3 children under an owned target, 0 left after disposal",
	run = run,
}
