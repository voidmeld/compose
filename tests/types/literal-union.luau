--!strict

local Compose = require "../../src/core"

type Phase = "dawn" | "day" | "dusk" | "night"
type Tide = "ebb" | "flood"

type Clock = {
	now: Compose.Cell<number>,
	hour: Compose.Formula<number>,
	phase: Compose.Formula<Phase>,
	tide: Compose.Formula<Tide>,
	chosen: Compose.Cell<Phase>,
}

local function phaseAt(hour: number): Phase
	if hour < 6 then
		return "night"
	elseif hour < 8 then
		return "dawn"
	elseif hour < 18 then
		return "day"
	end
	return "dusk"
end

local function tideAt(hour: number): Tide
	return if hour % 12 < 6 then "flood" else "ebb"
end

local function clock(): Clock
	local now = Compose.cell(0)
	local chosen: Compose.Cell<Phase> = Compose.cell("day" :: Phase)
	local hour = Compose.formula(function(use): number
		return use(now) % 24
	end)
	local phase = Compose.formula(function(use): Phase
		return phaseAt(use(hour))
	end)
	local tide = Compose.formula(function(use): Tide
		return tideAt(use(hour))
	end)
	return table.freeze {
		now = now,
		hour = hour,
		phase = phase,
		tide = tide,
		chosen = chosen,
	} :: Clock
end

local function readPhase(value: Clock): Phase
	return value.phase:peek()
end

local function isDawn(value: Clock): boolean
	return Compose.sample(value.phase) == "dawn"
end

return {
	clock = clock,
	readPhase = readPhase,
	isDawn = isDawn,
}
