--!strict

local NEAR, MIDDLE = 1, 2

local EFFECT_SLOTS = 16

local AUTHORED_PARTS = 12

local function authored(Instance: any, name: string): any
	local model = Instance.new "Model"
	model.Name = name
	for index = 1, AUTHORED_PARTS do
		local part = Instance.new "MeshPart"
		part.Name = ("Piece%d"):format(index)
		part.Position = index * 3
		part.Transparency = 0
		part.Parent = model
	end
	return model
end

local function drawsMesh(tier: number): boolean
	return tier ~= 3
end

local function transparencyFor(tier: number): number
	if tier == NEAR then
		return 0
	elseif tier == MIDDLE then
		return 0.25
	end
	return 0.75
end

local function effectSlot(sequence: number): number
	return ((sequence - 1) % EFFECT_SLOTS) + 1
end

return {
	EFFECT_SLOTS = EFFECT_SLOTS,
	AUTHORED_PARTS = AUTHORED_PARTS,
	authored = authored,
	drawsMesh = drawsMesh,
	transparencyFor = transparencyFor,
	effectSlot = effectSlot,
}
