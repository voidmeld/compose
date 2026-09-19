--!strict

local Types = require "./types"

type Context = Types.Context

local function instances(context: Context): any
	return context.env.globals.Instance
end

local function destroyAll(nodes: { any })
	for index = #nodes, 1, -1 do
		local node = nodes[index]
		if node ~= nil then
			node:Destroy()
			nodes[index] = nil
		end
	end
end

local function buildList(context: Context, count: number, text: (index: number) -> string): (any, { any })
	local Instance = instances(context)
	local made = table.create(count + 1)
	local frame = Instance.new "Frame"
	made[1] = frame
	for index = 1, count do
		local label = Instance.new "TextLabel"
		label.Text = text(index)
		label.Parent = frame
		made[index + 1] = label
	end
	frame.Parent = context.container
	return frame, made
end

return {
	instances = instances,
	destroyAll = destroyAll,
	buildList = buildList,
}
