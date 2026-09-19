--!strict

export type Combatant = {
	id: number,
	name: string,
	faction: number,
	group: number,
	health: number,
	maximum: number,
	state: number,
	status: number,
	distance: number,
	visible: boolean,
}

export type Change = {
	index: number,
	health: number,
	state: number,
	status: number,
}

export type Visibility = {
	index: number,
	visible: boolean,
	distance: number,
}

export type Identity = {
	kind: string,
	index: number,
	value: number,
}

export type Tick = {
	snapshot: number,
	changes: { Change },
	visibility: { Visibility },
	identity: { Identity },
	combatText: number,
	target: number,
	focus: number,
	assist: number,
	burst: boolean,
}

local function sequence(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(): number
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
end

local FIRST = {
	"Ash",
	"Bram",
	"Cael",
	"Dara",
	"Eryn",
	"Fell",
	"Gale",
	"Hale",
	"Isolde",
	"Jorn",
	"Kest",
	"Lyre",
	"Mor",
	"Nyx",
	"Orin",
	"Pell",
}
local LAST = {
	"Barrow",
	"Crest",
	"Dune",
	"Ember",
	"Fallow",
	"Grove",
	"Harrow",
	"Ives",
	"Kiln",
	"Lock",
	"Marsh",
	"Nettle",
}

local function roster(count: number): { Combatant }
	local next = sequence(20260901)
	local made = table.create(count)
	for index = 1, count do
		local first = FIRST[math.floor(next() * #FIRST) + 1]
		local last = LAST[math.floor(next() * #LAST) + 1]
		local maximum = 1000 + math.floor(next() * 8) * 250
		made[index] = {
			id = index,
			name = ("%s %s %d"):format(first, last, index),
			faction = if index % 2 == 0 then 1 else 2,
			group = ((index - 1) // 5) + 1,
			health = maximum,
			maximum = maximum,
			state = 1,
			status = 0,
			distance = math.floor(next() * 400),
			visible = next() < 0.55,
		}
	end
	return made
end

export type Options = {
	count: number,
	frames: number,
	snapshotHz: number,
	renderHz: number,
	churnLow: number,
	churnHigh: number,
	burstEvery: number,
	identityEvery: number,
	identityFraction: number,
	sweepEvery: number,
}

local function generate(options: Options): { Tick }
	local next = sequence(19831107)
	local count = options.count
	local ticks = table.create(options.frames)
	local framesPerSnapshot = math.max(1, math.floor(options.renderHz / options.snapshotHz))
	local snapshot = 0

	local cursor = 0

	for frame = 1, options.frames do
		local changes: { Change } = {}
		local visibility: { Visibility } = {}
		local identity: { Identity } = {}
		local combatText = 0
		local burst = options.burstEvery > 0 and frame % options.burstEvery == 0
		local carries = frame % framesPerSnapshot == 0

		if carries then
			snapshot += 1
		end

		if burst then
			for index = 1, count do
				local roll = next()
				local state = 1
				if roll < 0.12 then
					state = 0
				elseif roll < 0.20 then
					state = 2
				end
				table.insert(changes, {
					index = index,
					health = math.floor(next() * 400),
					state = state,
					status = math.floor(next() * 256),
				})
			end
			combatText = math.min(count, 240)
		elseif carries then
			local fraction = options.churnLow + next() * (options.churnHigh - options.churnLow)
			local changed = math.max(1, math.floor(count * fraction))
			for _ = 1, changed do
				cursor = (cursor % count) + 1
				local roll = next()
				table.insert(changes, {
					index = cursor,
					health = math.floor(next() * 1000),
					state = if roll < 0.02 then 0 else 1,
					status = if roll < 0.25 then math.floor(next() * 256) else 0,
				})
			end
			combatText = math.min(changed, 48)
		end

		if options.sweepEvery > 0 and frame % options.sweepEvery == 0 then
			local band = math.max(1, count // 4)
			for offset = 1, band do
				local index = ((frame * 7 + offset) % count) + 1
				table.insert(visibility, {
					index = index,
					visible = next() < 0.5,
					distance = math.floor(next() * 400),
				})
			end
		end

		if options.identityEvery > 0 and frame % options.identityEvery == 0 then
			local edits = math.max(1, math.floor(count * options.identityFraction))
			for offset = 1, edits do
				local index = ((frame * 13 + offset) % count) + 1
				local roll = next()
				local kind = "reorder"
				local value = math.floor(next() * 8) + 1
				if roll < 0.2 then
					kind = "leave"
				elseif roll < 0.4 then
					kind = "join"
				elseif roll < 0.55 then
					kind = "death"
				elseif roll < 0.7 then
					kind = "rez"
				elseif roll < 0.85 then
					kind = "faction"
					value = if value % 2 == 0 then 1 else 2
				else
					kind = "group"
				end
				table.insert(identity, { kind = kind, index = index, value = value })
			end
		end

		ticks[frame] = {
			snapshot = snapshot,
			changes = changes,
			visibility = visibility,
			identity = identity,
			combatText = combatText,
			target = ((frame * 3) % count) + 1,
			focus = ((frame * 5) % count) + 1,
			assist = ((frame * 11) % count) + 1,
			burst = burst,
		}
	end

	return ticks
end

local EFFECTS = { "bleed", "burn", "chill", "curse", "haste", "root", "shield", "silence" }

local function effectsOf(status: number): string
	if status == 0 then
		return ""
	end
	local parts: { string } = {}
	for bit = 1, 8 do
		if bit32.band(status, bit32.lshift(1, bit - 1)) ~= 0 then
			table.insert(parts, EFFECTS[bit])
		end
	end
	return table.concat(parts, ",")
end

local function tierOf(distance: number): number
	if distance < 80 then
		return 1
	elseif distance < 220 then
		return 2
	end
	return 3
end

return {
	sequence = sequence,
	roster = roster,
	generate = generate,
	effectsOf = effectsOf,
	tierOf = tierOf,
	EFFECTS = EFFECTS,
}
