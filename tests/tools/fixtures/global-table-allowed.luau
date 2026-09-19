--!strict

local slot = "compose.lint-contract.fixture"

local function stash(value: number)
	_G[slot] = value
end

local function recall(): number?
	local held = _G[slot]
	return if type(held) == "number" then held else nil
end

return { stash = stash, recall = recall }
