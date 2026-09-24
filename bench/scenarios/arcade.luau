--!strict

local Support = require "./support"
local Types = require "./types"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local TILES = 96
local EFFECTS = 24
local PROJECTILES = 32
local VISIBLE = 120
local WORLD = 4000

export type Entity = {
	id: number,
	kind: string,
	x: number,
	y: number,
	depth: number,
	facing: number,
	health: number,
	team: number,
}

local worlds: { [number]: { Entity } } = {}
local function population(count: number): { Entity }
	local held = worlds[count]
	if held ~= nil then
		return held
	end
	local next = Support.sequence(20260215)
	local made = table.create(count) :: { Entity }
	for index = 1, count do
		made[index] = {
			id = index,
			kind = if next() < 0.75 then "unit" else "structure",
			x = math.floor(next() * WORLD),
			y = math.floor(next() * WORLD),
			depth = index % 8,
			facing = math.floor(next() * 8),
			health = math.floor(next() * 100) + 1,
			team = (index % 3) + 1,
		}
	end
	worlds[count] = made
	return made
end

local function cameraAt(frame: number): (number, number)
	local angle = frame * 0.021
	return WORLD / 2 + math.cos(angle) * 1200, WORLD / 2 + math.sin(angle) * 900
end

local function within(entity: Entity, cx: number, cy: number, radius: number): boolean
	local dx, dy = entity.x - cx, entity.y - cy
	return dx * dx + dy * dy <= radius * radius
end

local function visibleAt(all: { Entity }, cx: number, cy: number): { Entity }
	local found: { Entity } = {}
	local radius = 700
	for _, entity in all do
		if within(entity, cx, cy, radius) then
			table.insert(found, entity)
			if #found >= VISIBLE then
				break
			end
		end
	end
	table.sort(found, function(left: Entity, right: Entity): boolean
		if left.depth ~= right.depth then
			return left.depth < right.depth
		end
		return left.id < right.id
	end)
	return found
end

local function spriteOf(entity: Entity, facing: number): string
	return ("%s-%d-%d"):format(entity.kind, entity.team, facing)
end

local function healthAt(entity: Entity, frame: number): number
	if (entity.id + frame) % 11 == 0 then
		return (entity.health + frame) % 100 + 1
	end
	return entity.health
end

local function facingAt(entity: Entity, order: number, frame: number): number
	if (entity.id + frame) % 29 == 0 then
		return (entity.facing + order) % 8
	end
	return entity.facing
end

local function projectileAt(slot: number, frame: number): (number, number, boolean)
	local age = (frame + slot * 7) % 40
	local alive = age < 24
	return slot * 37 + age * 11, slot * 23 + age * 5, alive
end

local PARITY_KEYS = { "Name", "Image", "Position", "Depth", "Health", "Visible", "Text", "LayoutOrder" }

local composeCase: Types.Case = {
	build = function(context: Context, scale: Scale): any
		local Compose = context.library
		local runtime = context.extras.runtime
		local Host = runtime.constructors

		local all = population(scale.size)

		local positions = table.create(#all)
		local healths = table.create(#all)
		local facings = table.create(#all)
		for index, entity in all do
			positions[index] = Compose.cell(entity.x * 8192 + entity.y)
			healths[index] = Compose.cell(entity.health)
			facings[index] = Compose.cell(entity.facing)
		end

		local visible = Compose.cell(visibleAt(all, cameraAt(0)))
		local projectiles = table.create(PROJECTILES) :: { { position: any, alive: any } }
		for index = 1, PROJECTILES do
			projectiles[index] = { position = Compose.cell(0), alive = Compose.cell(false) }
		end
		local effects = table.create(EFFECTS)
		for index = 1, EFFECTS do
			effects[index] = Compose.cell(false)
		end
		local score = Compose.cell(0)
		local wave = Compose.cell(1)

		local dispose = runtime.mount(function()
			local tiles = table.create(TILES)
			for index = 1, TILES do
				tiles[index] = Host.ImageLabel {
					Name = ("Tile%d"):format(index),
					Image = ("terrain-%d"):format(index % 6),
					LayoutOrder = index,
				}
			end
			local terrain: any = table.clone(tiles)
			terrain.Name = "Terrain"

			local projectileNodes = table.create(PROJECTILES)
			for index = 1, PROJECTILES do
				local slot = projectiles[index]
				projectileNodes[index] = Host.ImageLabel {
					Name = ("Shot%d"):format(index),
					Image = "shot",
					LayoutOrder = index,
					Position = slot.position,
					Visible = slot.alive,
				}
			end
			local shots: any = table.clone(projectileNodes)
			shots.Name = "Projectiles"

			local effectNodes = table.create(EFFECTS)
			for index = 1, EFFECTS do
				local cell = effects[index]
				effectNodes[index] = Host.ImageLabel {
					Name = ("Effect%d"):format(index),
					Image = "burst",
					LayoutOrder = index,
					Visible = cell,
				}
			end
			local burst: any = table.clone(effectNodes)
			burst.Name = "Effects"

			return Host.Frame {
				Name = "Scene",
				Host.Frame(terrain),

				Host.Frame {
					Name = "Entities",
					Compose.keyed {
						from = function(use: any): { Entity }
							return use(visible)
						end,
						render = function(value: any, index: any)
							local entity = value:peek()
							local position = positions[entity.id]
							local health = healths[entity.id]
							local facing = facings[entity.id]
							return Host.ImageLabel {
								Name = ("Sprite%d"):format(entity.id),
								Image = function(use: any): string
									local current = use(value)
									return ("%s-%d-%d"):format(current.kind, current.team, use(facing))
								end,
								Position = position,
								Health = health,
								Depth = entity.depth,
								LayoutOrder = function(use: any): number
									return use(index)
								end,
							}
						end,
						key = function(entity: any): number
							return entity.id
						end,
					},
				},

				Host.Frame(shots),
				Host.Frame(burst),

				Host.Frame {
					Name = "Overlay",
					Host.TextLabel {
						Name = "Score",
						Text = function(use: any): string
							return ("%d"):format(use(score))
						end,
					},
					Host.TextLabel {
						Name = "Wave",
						Text = function(use: any): string
							return ("wave %d"):format(use(wave))
						end,
					},
				},
			}
		end, context.container)

		return {
			dispose = dispose,
			all = all,
			positions = positions,
			healths = healths,
			facings = facings,
			visible = visible,
			projectiles = projectiles,
			effects = effects,
			score = score,
			wave = wave,
			runtime = runtime,
			peakPending = 0,
		}
	end,

	steady = function(state: any, _context: Context, frame: number)
		local runtime = state.runtime
		local all = state.all
		runtime:batch(function()
			local cx, cy = cameraAt(frame)
			local shown = visibleAt(all, cx, cy)

			for order, entity in shown do
				local moved = entity.x + frame % 17
				state.positions[entity.id]:set(moved * 8192 + entity.y + frame % 13)
				state.healths[entity.id]:set(healthAt(entity, frame))
				state.facings[entity.id]:set(facingAt(entity, order, frame))
			end
			state.visible:set(shown)

			for index = 1, PROJECTILES do
				local x, y, alive = projectileAt(index, frame)
				local slot = state.projectiles[index]
				slot.position:set(x * 8192 + y)
				slot.alive:set(alive)
			end
			for index = 1, EFFECTS do
				state.effects[index]:set((frame + index) % 9 < 3)
			end
			state.score:set(frame * 7)
			state.wave:set((frame // 120) + 1)
		end)
		local pending = runtime:pending()
		if pending > state.peakPending then
			state.peakPending = pending
		end
	end,

	burst = function(state: any, _context: Context, round: number)
		local runtime = state.runtime
		runtime:batch(function()
			local cx, cy = cameraAt(round * 733)
			local shown = visibleAt(state.all, cx, cy)
			for _, entity in shown do
				state.positions[entity.id]:set(entity.x * 8192 + entity.y + round)
				state.healths[entity.id]:set(entity.health)
				state.facings[entity.id]:set(entity.facing)
			end
			state.visible:set(shown)
			for index = 1, EFFECTS do
				state.effects[index]:set(true)
			end
			state.wave:set(round + 100)
		end)
	end,

	teardown = function(state: any, _context: Context)
		state.dispose()
	end,

	snapshot = function(_state: any, context: Context): string
		return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
	end,

	probe = function(state: any, _context: Context): { [string]: number }
		return { peakPending = state.peakPending, pendingAtEnd = state.runtime:pending() }
	end,
}

local bareCase: Types.Case = {
	build = function(context: Context, scale: Scale): any
		local Instance = Support.instances(context)
		local made: { any } = {}
		local function new(kind: string, parent: any, properties: { [string]: any }): any
			local node = Instance.new(kind)
			for key, value in properties do
				node[key] = value
			end
			node.Parent = parent
			table.insert(made, node)
			return node
		end

		local all = population(scale.size)
		local root = new("Frame", context.container, { Name = "Scene" })

		local terrain = new("Frame", root, { Name = "Terrain" })
		for index = 1, TILES do
			new("ImageLabel", terrain, {
				Name = ("Tile%d"):format(index),
				Image = ("terrain-%d"):format(index % 6),
				LayoutOrder = index,
			})
		end

		local entityParent = new("Frame", root, { Name = "Entities" })
		local shotParent = new("Frame", root, { Name = "Projectiles" })
		local shots = table.create(PROJECTILES)
		for index = 1, PROJECTILES do
			local x, y, alive = projectileAt(index, 0)
			shots[index] = new("ImageLabel", shotParent, {
				Name = ("Shot%d"):format(index),
				Image = "shot",
				LayoutOrder = index,
				Position = x * 8192 + y,
				Visible = alive,
			})
		end

		local effectParent = new("Frame", root, { Name = "Effects" })
		local effects = table.create(EFFECTS)
		for index = 1, EFFECTS do
			effects[index] = new("ImageLabel", effectParent, {
				Name = ("Effect%d"):format(index),
				Image = "burst",
				LayoutOrder = index,
				Visible = false,
			})
		end

		local overlay = new("Frame", root, { Name = "Overlay" })
		local scoreNode = new("TextLabel", overlay, { Name = "Score", Text = "0" })
		local waveNode = new("TextLabel", overlay, { Name = "Wave", Text = "wave 1" })

		local state = {
			made = made,
			all = all,
			entityParent = entityParent,
			sprites = {} :: { [number]: any },
			shots = shots,
			effects = effects,
			scoreNode = scoreNode,
			waveNode = waveNode,
			Instance = Instance,
		}

		local shown = visibleAt(all, cameraAt(0))
		for order, entity in shown do
			local node = Instance.new "ImageLabel"
			node.Name = ("Sprite%d"):format(entity.id)
			node.Image = spriteOf(entity, entity.facing)
			node.Position = entity.x * 8192 + entity.y
			node.Health = entity.health
			node.Depth = entity.depth
			node.LayoutOrder = order
			node.Parent = entityParent
			state.sprites[entity.id] = node
		end
		return state
	end,

	steady = function(state: any, _context: Context, frame: number)
		local cx, cy = cameraAt(frame)
		local shown = visibleAt(state.all, cx, cy)
		local wanted: { [number]: number } = {}
		for order, entity in shown do
			wanted[entity.id] = order
		end

		for id, node in state.sprites do
			if wanted[id] == nil then
				node:Destroy()
				state.sprites[id] = nil
			end
		end

		for order, entity in shown do
			local moved = entity.x + frame % 17
			local position = moved * 8192 + entity.y + frame % 13
			local health = healthAt(entity, frame)
			local facing = facingAt(entity, order, frame)
			local node = state.sprites[entity.id]
			if node == nil then
				node = state.Instance.new "ImageLabel"
				node.Name = ("Sprite%d"):format(entity.id)
				node.Depth = entity.depth
				node.Parent = state.entityParent
				state.sprites[entity.id] = node
			end
			node.Image = spriteOf(entity, facing)
			node.Position = position
			node.Health = health
			node.LayoutOrder = order
		end

		for index = 1, PROJECTILES do
			local x, y, alive = projectileAt(index, frame)
			local node = state.shots[index]
			node.Position = x * 8192 + y
			node.Visible = alive
		end
		for index = 1, EFFECTS do
			state.effects[index].Visible = (frame + index) % 9 < 3
		end
		state.scoreNode.Text = ("%d"):format(frame * 7)
		state.waveNode.Text = ("wave %d"):format((frame // 120) + 1)
	end,

	burst = function(state: any, _context: Context, round: number)
		local cx, cy = cameraAt(round * 733)
		local shown = visibleAt(state.all, cx, cy)
		local wanted: { [number]: number } = {}
		for order, entity in shown do
			wanted[entity.id] = order
		end
		for id, node in state.sprites do
			if wanted[id] == nil then
				node:Destroy()
				state.sprites[id] = nil
			end
		end
		for order, entity in shown do
			local node = state.sprites[entity.id]
			if node == nil then
				node = state.Instance.new "ImageLabel"
				node.Name = ("Sprite%d"):format(entity.id)
				node.Depth = entity.depth
				node.Parent = state.entityParent
				state.sprites[entity.id] = node
			end
			node.Image = spriteOf(entity, entity.facing)
			node.Position = entity.x * 8192 + entity.y + round
			node.Health = entity.health
			node.LayoutOrder = order
		end
		for index = 1, EFFECTS do
			state.effects[index].Visible = true
		end
		state.waveNode.Text = ("wave %d"):format(round + 100)
	end,

	teardown = function(state: any, _context: Context)
		for _, node in state.sprites do
			node:Destroy()
		end
		state.sprites = {}
		Support.destroyAll(state.made)
	end,

	snapshot = function(_state: any, context: Context): string
		return context.env.snapshot(context.container, PARITY_KEYS, "LayoutOrder")
	end,
}

local arcade: Scenario = {
	id = "arcade-scene",
	title = "A complete 2D game scene, culled to a moving camera",
	what = "Terrain, a large logical population culled to 120 visible sprites, projectiles spawning "
		.. "and despawning, a bounded effect pool and a heads-up layer, driven by a fixed camera "
		.. "circuit. A whole 2D game as one composition.",
	lane = "game",
	steadyBudgetSeconds = 0.0012,
	scales = {
		{ name = "medium", size = 1000 },
		{ name = "large", size = 5000 },
		{ name = "extreme", size = 20000 },
	},
	steadyFrames = 180,
	burstRounds = 8,
	samples = 7,
	warmup = 2,
	cases = { compose = composeCase, bare = bareCase },
}

return {
	arcade = arcade,
	population = population,
	cameraAt = cameraAt,
	visibleAt = visibleAt,
	spriteOf = spriteOf,
	VISIBLE = VISIBLE,
}
