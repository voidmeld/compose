--!strict

local Support = require "./support"
local Types = require "./types"

type Context = Types.Context
type Scale = Types.Scale
type Scenario = Types.Scenario

local combatHud: Scenario = {
	id = "combat-hud",
	title = "Combat HUD under routine and burst load",
	what = "Resource bars, cooldowns, a cast bar, a buff tray and floating combat text. The steady "
		.. "frame updates the fraction that a real frame updates; the burst updates all of it.",
	lane = "game",
	steadyBudgetSeconds = 0.0008,
	scales = {
		{ name = "medium", size = 12, cooldowns = 8, buffs = 12, texts = 8 },
		{ name = "large", size = 30, cooldowns = 16, buffs = 30, texts = 20 },
		{ name = "extreme", size = 60, cooldowns = 32, buffs = 60, texts = 40 },
	},
	steadyFrames = 120,
	burstRounds = 8,
	samples = 9,
	warmup = 2,
	cases = {
		compose = {
			build = function(context: Context, scale: Scale): any
				local Compose = context.library
				local runtime = context.extras.runtime
				local Host = runtime.constructors

				local health = Compose.cell(100)
				local mana = Compose.cell(100)
				local stamina = Compose.cell(100)
				local casting = Compose.cell(0)
				local cooldowns = table.create(scale.cooldowns)
				for index = 1, scale.cooldowns do
					cooldowns[index] = Compose.cell(0)
				end
				local buffs = Compose.cell {}
				local texts = Compose.cell {}

				local healthPercent = Compose.formula(function(use): number
					return (use(health) :: number) / 100
				end)

				local dispose = runtime.mount(function()
					local bars = {}
					for _, pair in { { "Health", healthPercent }, { "Mana", mana }, { "Stamina", stamina } } do
						table.insert(
							bars,
							Host.Frame {
								Name = pair[1],
								Size = pair[2],
							}
						)
					end
					local slots = table.create(scale.cooldowns)
					for index = 1, scale.cooldowns do
						local cell = cooldowns[index]
						slots[index] = Host.Frame {
							Name = ("Cooldown%d"):format(index),
							Size = cell,
							Visible = function(use)
								return use(cell) > 0
							end,
						}
					end
					return Host.Frame {
						Host.Frame(bars),
						Host.Frame(slots),
						Host.Frame {
							Name = "Cast",
							Size = casting,
							Visible = function(use)
								return use(casting) > 0
							end,
						},
						Compose.keyed {
							from = function(use)
								return use(buffs)
							end,
							render = function(value, index)
								return Host.Frame {
									Name = function(use)
										return use(value).name
									end,
									LayoutOrder = index,
								}
							end,
							key = function(buff: any)
								return buff.id
							end,
						},
						Compose.keyed {
							from = function(use)
								return use(texts)
							end,
							render = function(value, index)
								return Host.TextLabel {
									Text = function(use)
										return use(value).text
									end,
									LayoutOrder = index,
								}
							end,
							key = function(line: any)
								return line.id
							end,
						},
					}
				end, context.container)

				return {
					dispose = dispose,
					runtime = runtime,
					health = health,
					mana = mana,
					stamina = stamina,
					casting = casting,
					cooldowns = cooldowns,
					buffs = buffs,
					texts = texts,
					scale = scale,
					nextId = 1,
				}
			end,
			steady = function(state: any, _context: Context, tick: number)
				local scale = state.scale
				state.runtime:batch(function()
					state.health:set(60 + (tick % 40))
					state.mana:set(50 + (tick % 50))
					state.casting:set((tick % 20) / 20)
					local slot = (tick % scale.cooldowns) + 1
					state.cooldowns[slot]:set(1 - (tick % 10) / 10)
				end)
			end,
			burst = function(state: any, _context: Context, round: number)
				local scale = state.scale
				state.runtime:batch(function()
					state.health:set(1 + (round % 5))
					state.mana:set(2 + (round % 7))
					state.stamina:set(3 + (round % 11))
					for index = 1, scale.cooldowns do
						state.cooldowns[index]:set(1)
					end
					local buffs = table.create(scale.buffs)
					for index = 1, scale.buffs do
						buffs[index] = { id = (round * 1000) + index, name = ("buff-%d-%d"):format(round, index) }
					end
					state.buffs:set(buffs)
					local texts = table.create(scale.texts)
					for index = 1, scale.texts do
						texts[index] = { id = (round * 2000) + index, text = ("%d"):format(round * index) }
					end
					state.texts:set(texts)
				end)
			end,
			teardown = function(state: any, _context: Context)
				state.dispose()
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		},

		bare = {
			build = function(context: Context, scale: Scale): any
				local Instance = Support.instances(context)
				local made: { any } = {}
				local root = Instance.new "Frame"
				table.insert(made, root)

				local barFrame = Instance.new "Frame"
				barFrame.Parent = root
				table.insert(made, barFrame)
				local bars = {}
				for _, name in { "Health", "Mana", "Stamina" } do
					local bar = Instance.new "Frame"
					bar.Name = name
					bar.Size = 1
					bar.Parent = barFrame
					table.insert(made, bar)
					bars[name] = bar
				end

				local slotFrame = Instance.new "Frame"
				slotFrame.Parent = root
				table.insert(made, slotFrame)
				local slots = table.create(scale.cooldowns)
				for index = 1, scale.cooldowns do
					local slot = Instance.new "Frame"
					slot.Name = ("Cooldown%d"):format(index)
					slot.Size = 0
					slot.Visible = false
					slot.Parent = slotFrame
					table.insert(made, slot)
					slots[index] = slot
				end

				local cast = Instance.new "Frame"
				cast.Name = "Cast"
				cast.Size = 0
				cast.Visible = false
				cast.Parent = root
				table.insert(made, cast)

				root.Parent = context.container
				return {
					made = made,
					root = root,
					bars = bars,
					slots = slots,
					cast = cast,
					buffNodes = {},
					textNodes = {},
					scale = scale,
					cooldownValues = table.create(scale.cooldowns, 0),
				}
			end,
			steady = function(state: any, _context: Context, tick: number)
				local scale = state.scale
				state.bars.Health.Size = (60 + (tick % 40)) / 100
				state.bars.Mana.Size = 50 + (tick % 50)
				local casting = (tick % 20) / 20
				state.cast.Size = casting
				state.cast.Visible = casting > 0
				local slot = (tick % scale.cooldowns) + 1
				local value = 1 - (tick % 10) / 10
				state.cooldownValues[slot] = value
				state.slots[slot].Size = value
				state.slots[slot].Visible = value > 0
			end,
			burst = function(state: any, context: Context, round: number)
				local Instance = Support.instances(context)
				local scale = state.scale
				state.bars.Health.Size = (1 + (round % 5)) / 100
				state.bars.Mana.Size = 2 + (round % 7)
				state.bars.Stamina.Size = 3 + (round % 11)
				for index = 1, scale.cooldowns do
					state.cooldownValues[index] = 1
					state.slots[index].Size = 1
					state.slots[index].Visible = true
				end

				Support.destroyAll(state.buffNodes)
				for index = 1, scale.buffs do
					local node = Instance.new "Frame"
					node.Name = ("buff-%d-%d"):format(round, index)
					node.LayoutOrder = index
					node.Parent = state.root
					table.insert(state.buffNodes, node)
				end
				Support.destroyAll(state.textNodes)
				for index = 1, scale.texts do
					local node = Instance.new "TextLabel"
					node.Text = ("%d"):format(round * index)
					node.LayoutOrder = index
					node.Parent = state.root
					table.insert(state.textNodes, node)
				end
			end,
			teardown = function(state: any, _context: Context)
				Support.destroyAll(state.buffNodes)
				Support.destroyAll(state.textNodes)
				Support.destroyAll(state.made)
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		},
	},
}

local raidNameplates: Scenario = {
	id = "raid-nameplates",
	title = "Raid frames and world-space nameplates",
	what = "40 keyed raid frames plus up to 1000 keyed nameplates. The steady frame changes a "
		.. "handful of them; the burst reorders the roster and flips every plate's visibility.",
	lane = "game",
	steadyBudgetSeconds = 0.001,
	scales = {
		{ name = "medium", size = 200, raid = 40, churn = 4 },
		{ name = "large", size = 500, raid = 40, churn = 10 },
		{ name = "extreme", size = 1000, raid = 40, churn = 20 },
	},
	steadyFrames = 120,
	burstRounds = 6,
	samples = 7,
	warmup = 2,
	cases = {
		compose = {
			build = function(context: Context, scale: Scale): any
				local Compose = context.library
				local runtime = context.extras.runtime
				local Host = runtime.constructors

				local raid = Compose.cell(Support.combatants(scale.raid, "party"))
				local plates = Compose.cell(Support.combatants(scale.size, "plate"))
				local culled = Compose.cell(false)

				local function row(value: any, index: any)
					return Host.Frame {
						Name = function(use)
							return use(value).name
						end,
						Size = function(use): number
							local unit: any = use(value)
							return unit.health / unit.maximum
						end,
						Text = function(use)
							return use(value).status
						end,
						LayoutOrder = index,
					}
				end

				local dispose = runtime.mount(function()
					return Host.Frame {
						Host.Frame {
							Compose.keyed {
								from = function(use)
									return use(raid)
								end,
								render = row,
								key = function(unit: any)
									return unit.id
								end,
							},
						},
						Host.Frame {
							Compose.keyed {
								from = function(use)
									return use(plates)
								end,
								render = function(value: any, index: any)
									return Host.Frame {
										Name = function(use)
											return use(value).name
										end,
										Size = function(use): number
											local unit: any = use(value)
											return unit.health / unit.maximum
										end,
										Visible = function(use)
											return use(value).visible and not use(culled)
										end,
										LayoutOrder = index,
									}
								end,
								key = function(unit: any)
									return unit.id
								end,
							},
						},
					}
				end, context.container)

				return {
					dispose = dispose,
					runtime = runtime,
					raid = raid,
					plates = plates,
					culled = culled,
					scale = scale,
					generation = 0,
				}
			end,
			steady = function(state: any, _context: Context, tick: number)
				local scale = state.scale
				state.runtime:batch(function()
					local roster = state.plates:peek()
					local next = table.clone(roster)
					for offset = 0, scale.churn - 1 do
						local at = ((tick * 7 + offset * 13) % #next) + 1
						local unit = table.clone(next[at])
						unit.health = ((tick + offset) % 100) + 1
						unit.status = if (tick + offset) % 3 == 0 then "burning" else "none"
						next[at] = unit
					end
					state.plates:set(next)
					local party = table.clone(state.raid:peek())
					local partyAt = (tick % #party) + 1
					local member = table.clone(party[partyAt])
					member.health = (tick % 100) + 1
					party[partyAt] = member
					state.raid:set(party)
				end)
			end,
			burst = function(state: any, _context: Context, round: number)
				local _scale = state.scale
				state.generation += 1
				state.runtime:batch(function()
					local roster = state.plates:peek()
					local leaving = math.max(1, math.floor(#roster / 10))
					local next = table.create(#roster)
					for index = leaving + 1, #roster do
						table.insert(next, roster[index])
					end
					for index = 1, leaving do
						table.insert(next, {
							id = 100000 * state.generation + index,
							name = ("plate-new-%d-%d"):format(state.generation, index),
							health = (index % 100) + 1,
							maximum = 100,
							status = "none",
							visible = true,
						})
					end
					state.plates:set(next)
					state.culled:set(round % 2 == 1)
				end)
			end,
			teardown = function(state: any, _context: Context)
				state.dispose()
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		},

		bare = {
			build = function(context: Context, scale: Scale): any
				local Instance = Support.instances(context)
				local made: { any } = {}
				local root = Instance.new "Frame"
				table.insert(made, root)
				local raidFrame = Instance.new "Frame"
				raidFrame.Parent = root
				table.insert(made, raidFrame)
				local plateFrame = Instance.new "Frame"
				plateFrame.Parent = root
				table.insert(made, plateFrame)

				local raid = Support.combatants(scale.raid, "party")
				local plates = Support.combatants(scale.size, "plate")

				local raidNodes: { [number]: any } = {}
				local plateNodes: { [number]: any } = {}
				for index, unit in raid do
					local node = Instance.new "Frame"
					node.Name = unit.name
					node.Size = unit.health / unit.maximum
					node.Text = unit.status
					node.LayoutOrder = index
					node.Parent = raidFrame
					raidNodes[unit.id] = node
				end
				for index, unit in plates do
					local node = Instance.new "Frame"
					node.Name = unit.name
					node.Size = unit.health / unit.maximum
					node.Visible = unit.visible
					node.LayoutOrder = index
					node.Parent = plateFrame
					plateNodes[unit.id] = node
				end

				root.Parent = context.container
				return {
					made = made,
					root = root,
					raidFrame = raidFrame,
					plateFrame = plateFrame,
					raid = raid,
					plates = plates,
					raidNodes = raidNodes,
					plateNodes = plateNodes,
					culled = false,
					scale = scale,
					generation = 0,
				}
			end,
			steady = function(state: any, _context: Context, tick: number)
				local scale = state.scale
				for offset = 0, scale.churn - 1 do
					local at = ((tick * 7 + offset * 13) % #state.plates) + 1
					local unit = state.plates[at]
					unit.health = ((tick + offset) % 100) + 1
					unit.status = if (tick + offset) % 3 == 0 then "burning" else "none"
					local node = state.plateNodes[unit.id]
					node.Size = unit.health / unit.maximum
				end
				local partyAt = (tick % #state.raid) + 1
				local member = state.raid[partyAt]
				member.health = (tick % 100) + 1
				state.raidNodes[member.id].Size = member.health / member.maximum
			end,
			burst = function(state: any, context: Context, round: number)
				local Instance = Support.instances(context)
				state.generation += 1
				local roster = state.plates
				local leaving = math.max(1, math.floor(#roster / 10))
				local next = table.create(#roster)
				for index = leaving + 1, #roster do
					table.insert(next, roster[index])
				end
				for index = 1, leaving do
					table.insert(next, {
						id = 100000 * state.generation + index,
						name = ("plate-new-%d-%d"):format(state.generation, index),
						health = (index % 100) + 1,
						maximum = 100,
						status = "none",
						visible = true,
					})
				end

				local wanted: { [number]: boolean } = {}
				for _, unit in next do
					wanted[unit.id] = true
				end
				for id, node in state.plateNodes do
					if not wanted[id] then
						node:Destroy()
						state.plateNodes[id] = nil
					end
				end
				state.culled = round % 2 == 1
				for index, unit in next do
					local node = state.plateNodes[unit.id]
					if node == nil then
						node = Instance.new "Frame"
						node.Name = unit.name
						node.Size = unit.health / unit.maximum
						node.Parent = state.plateFrame
						state.plateNodes[unit.id] = node
					end
					node.LayoutOrder = index
					node.Visible = unit.visible and not state.culled
				end
				state.plates = next
			end,
			teardown = function(state: any, _context: Context)
				for id, node in state.plateNodes do
					node:Destroy()
					state.plateNodes[id] = nil
				end
				for id, node in state.raidNodes do
					node:Destroy()
					state.raidNodes[id] = nil
				end
				Support.destroyAll(state.made)
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		},
	},
}

local raidNameplatesSparse: Scenario = {
	id = "raid-nameplates-sparse",
	title = "Raid frames and nameplates, updated per unit",
	what = "The same screen as `raid-nameplates`, with a stable list identity and one cell per "
		.. "unit. Both implementations touch only the units that changed.",
	lane = "game",
	steadyBudgetSeconds = 0.001,
	scales = {
		{ name = "medium", size = 200, raid = 40, churn = 4 },
		{ name = "large", size = 500, raid = 40, churn = 10 },
		{ name = "extreme", size = 1000, raid = 40, churn = 20 },
	},
	steadyFrames = 120,
	burstRounds = 6,
	samples = 7,
	warmup = 2,
	cases = {
		compose = {
			build = function(context: Context, scale: Scale): any
				local Compose = context.library
				local runtime = context.extras.runtime
				local Host = runtime.constructors

				local function roster(count: number, prefix: string)
					local units = Support.combatants(count, prefix)
					local held = table.create(count)
					for index, unit in units do
						held[index] = {
							id = unit.id,
							name = unit.name,
							health = Compose.cell(unit.health),
							status = Compose.cell(unit.status),
							visible = Compose.cell(unit.visible),
						}
					end
					return held
				end

				local raid = roster(scale.raid, "party")
				local plates = roster(scale.size, "plate")
				local raidList = Compose.cell(raid)
				local plateList = Compose.cell(plates)
				local culled = Compose.cell(false)

				local dispose = runtime.mount(function()
					return Host.Frame {
						Host.Frame {
							Compose.keyed {
								from = function(use)
									return use(raidList)
								end,
								render = function(value: any, index: any)
									local unit: any = value:peek()
									return Host.Frame {
										Name = unit.name,
										Size = function(use): number
											return (use(unit.health) :: number) / 100
										end,
										Text = unit.status,
										LayoutOrder = index,
									}
								end,
								key = function(unit: any)
									return unit.id
								end,
							},
						},
						Host.Frame {
							Compose.keyed {
								from = function(use)
									return use(plateList)
								end,
								render = function(value: any, index: any)
									local unit: any = value:peek()
									return Host.Frame {
										Name = unit.name,
										Size = function(use): number
											return (use(unit.health) :: number) / 100
										end,
										Visible = function(use)
											return use(unit.visible) and not use(culled)
										end,
										LayoutOrder = index,
									}
								end,
								key = function(unit: any)
									return unit.id
								end,
							},
						},
					}
				end, context.container)

				return {
					dispose = dispose,
					runtime = runtime,
					raid = raid,
					plates = plates,
					plateList = plateList,
					culled = culled,
					scale = scale,
					generation = 0,
					Compose = Compose,
				}
			end,
			steady = function(state: any, _context: Context, tick: number)
				local scale = state.scale
				state.runtime:batch(function()
					for offset = 0, scale.churn - 1 do
						local at = ((tick * 7 + offset * 13) % #state.plates) + 1
						local unit = state.plates[at]
						unit.health:set(((tick + offset) % 100) + 1)
						unit.status:set(if (tick + offset) % 3 == 0 then "burning" else "none")
					end
					local partyAt = (tick % #state.raid) + 1
					state.raid[partyAt].health:set((tick % 100) + 1)
				end)
			end,
			burst = function(state: any, _context: Context, round: number)
				local Compose = state.Compose
				state.generation += 1
				state.runtime:batch(function()
					local roster = state.plateList:peek()
					local leaving = math.max(1, math.floor(#roster / 10))
					local next = table.create(#roster)
					for index = leaving + 1, #roster do
						table.insert(next, roster[index])
					end
					for index = 1, leaving do
						table.insert(next, {
							id = 100000 * state.generation + index,
							name = ("plate-new-%d-%d"):format(state.generation, index),
							health = Compose.cell((index % 100) + 1),
							status = Compose.cell "none",
							visible = Compose.cell(true),
						})
					end
					state.plates = next
					state.plateList:set(next)
					state.culled:set(round % 2 == 1)
				end)
			end,
			teardown = function(state: any, _context: Context)
				state.dispose()
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		},

		bare = {
			build = function(context: Context, scale: Scale): any
				local Instance = Support.instances(context)
				local made: { any } = {}
				local root = Instance.new "Frame"
				table.insert(made, root)
				local raidFrame = Instance.new "Frame"
				raidFrame.Parent = root
				table.insert(made, raidFrame)
				local plateFrame = Instance.new "Frame"
				plateFrame.Parent = root
				table.insert(made, plateFrame)

				local raid = Support.combatants(scale.raid, "party")
				local plates = Support.combatants(scale.size, "plate")
				local raidNodes: { [number]: any } = {}
				local plateNodes: { [number]: any } = {}
				for index, unit in raid do
					local node = Instance.new "Frame"
					node.Name = unit.name
					node.Size = unit.health / unit.maximum
					node.Text = unit.status
					node.LayoutOrder = index
					node.Parent = raidFrame
					raidNodes[unit.id] = node
				end
				for index, unit in plates do
					local node = Instance.new "Frame"
					node.Name = unit.name
					node.Size = unit.health / unit.maximum
					node.Visible = unit.visible
					node.LayoutOrder = index
					node.Parent = plateFrame
					plateNodes[unit.id] = node
				end
				root.Parent = context.container
				return {
					made = made,
					plateFrame = plateFrame,
					raid = raid,
					plates = plates,
					raidNodes = raidNodes,
					plateNodes = plateNodes,
					culled = false,
					scale = scale,
					generation = 0,
				}
			end,
			steady = function(state: any, _context: Context, tick: number)
				local scale = state.scale
				for offset = 0, scale.churn - 1 do
					local at = ((tick * 7 + offset * 13) % #state.plates) + 1
					local unit = state.plates[at]
					unit.health = ((tick + offset) % 100) + 1
					unit.status = if (tick + offset) % 3 == 0 then "burning" else "none"
					state.plateNodes[unit.id].Size = unit.health / unit.maximum
				end
				local partyAt = (tick % #state.raid) + 1
				local member = state.raid[partyAt]
				member.health = (tick % 100) + 1
				state.raidNodes[member.id].Size = member.health / member.maximum
			end,
			burst = function(state: any, context: Context, round: number)
				local Instance = Support.instances(context)
				state.generation += 1
				local roster = state.plates
				local leaving = math.max(1, math.floor(#roster / 10))
				local next = table.create(#roster)
				for index = leaving + 1, #roster do
					table.insert(next, roster[index])
				end
				for index = 1, leaving do
					table.insert(next, {
						id = 100000 * state.generation + index,
						name = ("plate-new-%d-%d"):format(state.generation, index),
						health = (index % 100) + 1,
						maximum = 100,
						status = "none",
						visible = true,
					})
				end
				local wanted: { [number]: boolean } = {}
				for _, unit in next do
					wanted[unit.id] = true
				end
				for id, node in state.plateNodes do
					if not wanted[id] then
						node:Destroy()
						state.plateNodes[id] = nil
					end
				end
				state.culled = round % 2 == 1
				for index, unit in next do
					local node = state.plateNodes[unit.id]
					if node == nil then
						node = Instance.new "Frame"
						node.Name = unit.name
						node.Size = unit.health / unit.maximum
						node.Parent = state.plateFrame
						state.plateNodes[unit.id] = node
					end
					node.LayoutOrder = index
					node.Visible = unit.visible and not state.culled
				end
				state.plates = next
			end,
			teardown = function(state: any, _context: Context)
				for id, node in state.plateNodes do
					node:Destroy()
					state.plateNodes[id] = nil
				end
				for id, node in state.raidNodes do
					node:Destroy()
					state.raidNodes[id] = nil
				end
				Support.destroyAll(state.made)
			end,
			snapshot = function(_state: any, context: Context): string
				return context.env.snapshot(context.container, { "Name", "Size", "Visible", "Text", "LayoutOrder" })
			end,
		},
	},
}

return {
	combatHud = combatHud,
	raidNameplates = raidNameplates,
	raidNameplatesSparse = raidNameplatesSparse,
}
