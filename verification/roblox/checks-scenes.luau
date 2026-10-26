--!strict
--!nolint DeprecatedApi

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Design = require "../../src/design"
local DesignEditor = require "../../src/design-editor"

type Readable<T> = { peek: (self: Readable<T>) -> T }
type Use = <T>(value: Readable<T>) -> T
type Layout = {
	kind: ("list" | "grid")?,
	columns: number?,
	itemSize: number?,
	gap: number?,
	crossSize: number?,
	crossGap: number?,
}

export type Check = {
	id: string,
	name: string,
	requires: { string }?,
	run: (container: Instance) -> string,
}

local function assertThat(condition: boolean, message: string)
	if not condition then
		error(message, 0)
	end
end

local checks: { Check } = {
	{
		id = "screen-frame-budget",
		name = "representative screens hold a frame budget on the engine",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local FRAMES = 60

			local function perFrame(body: (number) -> ()): number
				local samples: { number } = table.create(FRAMES) :: { number }
				for tick = 1, FRAMES do
					local started = os.clock()
					body(tick)
					samples[tick] = os.clock() - started
				end
				table.sort(samples)
				return samples[(FRAMES // 2) + 1]
			end

			local before = #container:GetChildren()
			local report = {}

			do
				local level = Compose.cell(100)
				local mana = Compose.cell(100)
				local cast = Compose.cell(0)
				local started = os.clock()
				local dispose = runtime.mount(function()
					local bars = table.create(24)
					for index = 1, 24 do
						local source = if index % 3 == 0 then level elseif index % 3 == 1 then mana else cast
						bars[index] = runtime.constructors.Frame {
							LayoutOrder = index,
							Transparency = function(use)
								return (use(source) :: number) / 100
							end,
						}
					end
					return runtime.constructors.Frame(bars)
				end, container)
				local cold = os.clock() - started
				local frame = perFrame(function(tick)
					runtime:batch(function()
						level:set(60 + (tick % 40))
						mana:set(50 + (tick % 50))
						cast:set(tick % 100)
					end)
				end)
				local released = os.clock()
				dispose()
				table.insert(
					report,
					("hud cold %.2f ms, frame %.1f us, teardown %.2f ms"):format(
						cold * 1000,
						frame * 1e6,
						(os.clock() - released) * 1000
					)
				)
			end

			do
				local COUNT = 200
				type LevelItem = { id: number, level: typeof(Compose.cell(0)) }
				local units: { LevelItem } = table.create(COUNT) :: { LevelItem }
				for index = 1, COUNT do
					units[index] = { id = index, level = Compose.cell(index % 100) }
				end
				local entities = Compose.cell(units)
				local started = os.clock()
				local dispose = runtime.mount(function()
					return runtime.constructors.Frame {
						Compose.keyed {
							from = entities,
							key = function(unit: LevelItem)
								return unit.id
							end,
							render = function(value: Readable<LevelItem>, index: Readable<number>)
								local unit = value:peek()
								return runtime.constructors.Frame {
									LayoutOrder = index,
									Transparency = function(use)
										return (use(unit.level) :: number) / 100
									end,
								}
							end,
						},
					}
				end, container)
				local cold = os.clock() - started
				local frame = perFrame(function(tick)
					runtime:batch(function()
						for offset = 0, 9 do
							local at = ((tick * 7 + offset * 13) % COUNT) + 1
							units[at].level:set((tick + offset) % 100)
						end
					end)
				end)
				local released = os.clock()
				dispose()
				table.insert(
					report,
					("list(%d) cold %.2f ms, frame %.1f us, teardown %.2f ms"):format(
						COUNT,
						cold * 1000,
						frame * 1e6,
						(os.clock() - released) * 1000
					)
				)
			end

			do
				local TOTAL, VISIBLE = 2000, 40
				local pool = table.create(TOTAL) :: { { id: number, label: number } }
				for index = 1, TOTAL do
					pool[index] = { id = index, label = index }
				end
				local logical = Compose.cell(pool)
				local first = Compose.cell(1)
				local started = os.clock()
				local dispose = runtime.mount(function()
					return runtime.constructors.Frame {
						Compose.OrderedCollection {
							from = logical,
							mode = "windowed",
							viewport = function(use: Compose.Use): Compose.OrderedCollectionViewport
								return { offset = use(first) - 1, size = VISIBLE }
							end,
							layout = { itemSize = 1 } :: Layout,
							key = function(item: { id: number, label: number })
								return item.id
							end,
							render = function(
								value: Readable<{ id: number, label: number }>,
								placement: Readable<{ index: number, row: number, column: number, offset: number, size: number, crossOffset: number, crossSize: number }>
							)
								return runtime.constructors.Frame {
									LayoutOrder = function(use: Use)
										return use(placement).index
									end,
									Name = function(use): string
										return ("row-%d"):format(use(value).label)
									end,
								}
							end,
						},
					}
				end, container)
				local cold = os.clock() - started
				local frame = perFrame(function(tick)
					first:set(((tick * 3) % (TOTAL - VISIBLE)) + 1)
				end)
				local released = os.clock()
				dispose()
				table.insert(
					report,
					("window(%d of %d) cold %.2f ms, frame %.1f us, teardown %.2f ms"):format(
						VISIBLE,
						TOTAL,
						cold * 1000,
						frame * 1e6,
						(os.clock() - released) * 1000
					)
				)
			end

			do
				local COUNT = 100
				local targets: { typeof(Compose.cell(0)) } = table.create(COUNT) :: { typeof(Compose.cell(0)) }
				for index = 1, COUNT do
					targets[index] = Compose.cell(0)
				end
				local started = os.clock()
				local dispose = runtime.mount(function()
					local panels = table.create(COUNT)
					for index = 1, COUNT do
						local moved = runtime.spring(function(use): number
							return use(targets[index]) :: number
						end, { period = 0.3, damping = 1 })
						panels[index] = runtime.constructors.Frame {
							LayoutOrder = index,
							Transparency = function(use)
								return math.clamp(use(moved) :: number, 0, 1)
							end,
						}
					end
					return runtime.constructors.Frame(panels)
				end, container)
				local cold = os.clock() - started
				local frame = perFrame(function(tick)
					runtime:batch(function()
						for offset = 0, 9 do
							targets[((tick * 11 + offset * 7) % COUNT) + 1]:set(((tick + offset) % 50) / 50)
						end
					end)
				end)
				local released = os.clock()
				dispose()
				table.insert(
					report,
					("springs(%d) cold %.2f ms, retarget %.1f us, teardown %.2f ms"):format(
						COUNT,
						cold * 1000,
						frame * 1e6,
						(os.clock() - released) * 1000
					)
				)
			end

			local after = #container:GetChildren()
			assertThat(after == before, ("%d child(ren) survived teardown, expected %d"):format(after, before))

			return table.concat(report, "; ")
		end,
	},

	{
		id = "entity-scene-3d",
		name = "a 3D entity scene composes, updates sparsely and tears down on the engine",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local COUNT = 200
			local FRAMES = 60

			local function perFrame(body: (number) -> ()): number
				local samples: { number } = table.create(FRAMES) :: { number }
				for tick = 1, FRAMES do
					local started = os.clock()
					body(tick)
					samples[tick] = os.clock() - started
				end
				table.sort(samples)
				return samples[(FRAMES // 2) + 1]
			end

			local before = #container:GetChildren()

			type Unit = {
				id: number,
				level: typeof(Compose.cell(0)),
				distance: typeof(Compose.cell(0)),
				visible: typeof(Compose.cell(false)),
				selected: typeof(Compose.cell(false)),
			}
			local units: { Unit } = table.create(COUNT) :: { Unit }
			for index = 1, COUNT do
				units[index] = {
					id = index,
					level = Compose.cell((index % 100) + 1),
					distance = Compose.cell((index * 7) % 400),
					visible = Compose.cell(index % 2 == 0),
					selected = Compose.cell(false),
				}
			end
			local entities = Compose.cell(units)

			local asset = Instance.new "Model"
			asset.Name = "AuthoredProp"
			for index = 1, 8 do
				local piece = Instance.new "Part"
				piece.Name = ("Piece%d"):format(index)
				piece.Anchored = true
				piece.Parent = asset
			end

			local started = os.clock()
			local dispose = runtime.mount(function()
				return runtime.constructors.Folder {
					Name = "World",
					runtime.adopt(asset),
					Compose.keyed {
						from = entities,
						key = function(unit: Unit)
							return unit.id
						end,
						render = function(value: Readable<Unit>)
							local unit = value:peek()
							return runtime.constructors.Model {
								Name = ("Item%d"):format(unit.id),
								runtime.constructors.MeshPart {
									Name = "Body",
									Anchored = true,
									Transparency = function(use: Use)
										return math.clamp((use(use(value).distance) :: number) / 800, 0, 1)
									end,
								},
								runtime.constructors.Attachment {
									Name = "Anchor",
									Compose.show(function(use: Use)
										return use(use(value).visible) :: boolean
									end, function()
										return runtime.constructors.BillboardGui {
											Name = "Plate",
											AlwaysOnTop = true,
											runtime.constructors.TextLabel {
												Name = "Health",
												Text = function(use)
													return tostring(use(use(value).level))
												end,
											},
										}
									end),
								},
								Compose.show(function(use: Use)
									return use(use(value).selected) :: boolean
								end, function()
									return runtime.constructors.Highlight {
										Name = "Selected",
										FillTransparency = 0.5,
									}
								end),
							}
						end,
					},
				}
			end, container)
			local cold = os.clock() - started

			local selectedAt = 0
			local frame = perFrame(function(tick)
				runtime:batch(function()
					for offset = 0, COUNT // 10 - 1 do
						local unit = units[((tick * 13 + offset * 7) % COUNT) + 1]
						unit.level:set(((tick + offset) % 100) + 1)
						unit.distance:set((tick * 3 + offset * 11) % 400)
					end
					local wanted = ((tick * 5) % COUNT) + 1
					if wanted ~= selectedAt then
						if selectedAt ~= 0 then
							units[selectedAt].selected:set(false)
						end
						selectedAt = wanted
						units[wanted].selected:set(true)
					end
				end)
			end)

			local sweepStarted = os.clock()
			runtime:batch(function()
				for index = 1, COUNT // 4 do
					local unit = units[index]
					unit.visible:set(not unit.visible:peek())
				end
			end)
			local sweep = os.clock() - sweepStarted

			local released = os.clock()
			dispose()
			local teardown = os.clock() - released

			local after = #container:GetChildren()
			assertThat(after == before, ("%d child(ren) survived teardown, expected %d"):format(after, before))
			assertThat(asset.Parent == nil, "the adopted asset survived teardown")

			return ("scene(%d) cold %.2f ms, frame %.1f us, sweep %.2f ms, teardown %.2f ms"):format(
				COUNT,
				cold * 1000,
				frame * 1e6,
				sweep * 1000,
				teardown * 1000
			)
		end,
	},

	{
		id = "sprite-scene-2d",
		name = "a culled 2D sprite scene mounts and unmounts continuously on the engine",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local POPULATION = 2000
			local VISIBLE = 120
			local FRAMES = 60

			type Entity = { id: number, depth: number }
			local entities: { Entity } = table.create(POPULATION) :: { Entity }
			for index = 1, POPULATION do
				entities[index] = { id = index, depth = index % 8 }
			end

			local function windowAt(tick: number): { Entity }
				local first = ((tick * 8) % (POPULATION - VISIBLE)) + 1
				local shown: { Entity } = table.create(VISIBLE) :: { Entity }
				for offset = 0, VISIBLE - 1 do
					shown[offset + 1] = entities[first + offset]
				end
				return shown
			end

			local visible = Compose.cell(windowAt(0))
			local positions: { typeof(Compose.cell(0)) } = table.create(POPULATION) :: { typeof(Compose.cell(0)) }
			for index = 1, POPULATION do
				positions[index] = Compose.cell(0)
			end

			local started = os.clock()
			local dispose = runtime.mount(function()
				return runtime.constructors.Frame {
					Name = "Scene",
					BackgroundTransparency = 1,
					Compose.keyed {
						from = visible,
						key = function(entity: Entity)
							return entity.id
						end,
						render = function(value: Readable<Entity>, index: Readable<number>)
							local entity = value:peek()
							local offset = positions[entity.id]
							return runtime.constructors.ImageLabel {
								Name = ("Sprite%d"):format(entity.id),
								BackgroundTransparency = 1,
								LayoutOrder = function(use)
									return use(index) :: number
								end,
								ImageTransparency = function(use)
									return math.clamp((use(offset) :: number) / 100, 0, 1)
								end,
							}
						end,
					},
				}
			end, container)
			local cold = os.clock() - started

			local samples: { number } = table.create(FRAMES) :: { number }
			for tick = 1, FRAMES do
				local at = os.clock()
				runtime:batch(function()
					local shown = windowAt(tick)
					for _, entity in shown do
						positions[entity.id]:set((tick * 3 + entity.id) % 100)
					end
					visible:set(shown)
				end)
				samples[tick] = os.clock() - at
			end
			table.sort(samples)
			local frame = samples[(FRAMES // 2) + 1]

			local before = #container:GetChildren()
			local released = os.clock()
			dispose()
			local teardown = os.clock() - released
			assertThat(#container:GetChildren() == before - 1, "the culled scene did not release its root on disposal")

			return ("sprites(%d of %d) cold %.2f ms, frame %.1f us, teardown %.2f ms"):format(
				VISIBLE,
				POPULATION,
				cold * 1000,
				frame * 1e6,
				teardown * 1000
			)
		end,
	},
	{
		id = "design-editor-edits-and-outlines",
		name = "the Compose Design editor renders, outlines, edits, undoes and round-trips a design",
		requires = { "roblox-engine", "roblox-client" },
		run = function(container: Instance): string
			local Players = game:GetService "Players"
			local player = assert(Players.LocalPlayer, "a client player")
			local screen = Instance.new "ScreenGui"
			screen.Name = "ComposeDesignProbe"
			screen.ResetOnSpawn = false
			screen.Parent = player:WaitForChild "PlayerGui"
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local environment = ComposeRoblox.designEnvironment()
			local RobloxLibrary = DesignEditor.robloxLibrary(runtime, environment)
			local value = Design.document.new("Probe", RobloxLibrary, "Stack")
			local text, button
			value, text = Design.document.insert(value, RobloxLibrary, "n1", "Text")
			value, button = Design.document.insert(value, RobloxLibrary, "n1", "Button")
			local exported: string? = nil
			local editor = DesignEditor.create(RobloxLibrary, value, screen, {
				runtime = runtime,
				environment = environment,
				stageSize = { X = 480, Y = 320 },
				onExport = function(source: string)
					exported = source
				end,
			})
			local function settle()
				for _ = 1, 6 do
					game:GetService("RunService").RenderStepped:Wait()
				end
			end
			settle()
			local stage = assert(editor.stage, "a 2D library opens the 2D stage")
			local nodes = stage.nodes
			local label = nodes[text]
			assert(typeof(label) == "Instance" and label:IsA "GuiObject")
			assertThat(label and label:IsA "TextLabel" or false, "the Text layer renders a TextLabel")
			local pressable = nodes[button]
			assert(typeof(pressable) == "Instance" and pressable:IsA "GuiObject")
			assertThat(pressable and pressable:IsA "TextButton" or false, "the Button layer renders a TextButton")
			editor.session.select(text)
			settle()
			local overlay = stage.overlay
			assert(typeof(overlay) == "Instance")
			local outline = overlay:FindFirstChild "DesignSelected"
			assertThat(outline ~= nil and outline:IsA "GuiObject", "the selection outline exists")
			if outline and outline:IsA "GuiObject" and label then
				local offset = (outline.AbsolutePosition - label.AbsolutePosition).Magnitude
				local extent = (outline.AbsoluteSize - label.AbsoluteSize).Magnitude
				assertThat(
					outline.Visible and offset <= 1 and extent <= 1,
					`the outline covers the layer ({offset}, {extent})`
				)
			end
			assertThat(editor.session.change("text", { literal = "Hello" }), "the text edit applies")
			settle()
			local edited = stage.nodes[text]
			assert(typeof(edited) == "Instance" and edited:IsA "GuiObject")
			assertThat(
				edited and edited:IsA "TextLabel" and edited.Text == "Hello" or false,
				"the stage shows the edited text"
			)
			assertThat(editor.session.undo(), "undo applies")
			settle()
			local restored = stage.nodes[text]
			assert(typeof(restored) == "Instance" and restored:IsA "GuiObject")
			assertThat(
				restored and restored:IsA "TextLabel" and restored.Text == "Text" or false,
				"undo restores the text"
			)
			editor.session.select(text)
			stage.zoomTo(2)
			settle()
			local zoomed = stage.nodes[text]
			assert(typeof(zoomed) == "Instance" and zoomed:IsA "GuiObject")
			local zoomedOutline = overlay:FindFirstChild "DesignSelected"
			if zoomed and zoomedOutline and zoomedOutline:IsA "GuiObject" then
				local offset = (zoomedOutline.AbsolutePosition - zoomed.AbsolutePosition).Magnitude
				local extent = (zoomedOutline.AbsoluteSize - zoomed.AbsoluteSize).Magnitude
				assertThat(offset <= 1 and extent <= 1, `the outline follows the layer at 200% ({offset}, {extent})`)
			else
				assertThat(false, "the zoomed layer and outline exist")
			end
			stage.fit()
			assertThat(stage.zoom:peek() <= 1, "fit never enlarges past 100%")
			local root = editor.root
			assert(typeof(root) == "Instance")
			local layers = root:FindFirstChild("DesignLayers", true)
			local rows = 0
			if layers then
				for _, child in layers:GetChildren() do
					if child:IsA "TextButton" then
						rows += 1
					end
				end
			end
			assertThat(rows == 3, `the layers panel lists three layers ({rows})`)
			local exportButton = root:FindFirstChild("Export", true)
			assertThat(exportButton ~= nil, "the toolbar offers Export")
			local source = Design.emit(editor.session.document:peek(), RobloxLibrary)
			local parsed = Design.parse(source, RobloxLibrary)
			assertThat(
				Design.emit(parsed, RobloxLibrary) == source,
				"the exported source parses back to the same design"
			)
			local _ = exported
			editor.dispose()
			runtime:dispose()
			screen:Destroy()
			return "editor rendered three layers, outlined the selection, edited, undid and round-tripped its source"
		end,
	},
	{
		id = "design-scene-renders-picks-and-moves",
		name = "the Compose Design editor opens a 3D library in a scene that renders, picks and moves parts",
		requires = { "roblox-engine", "roblox-client" },
		run = function(container: Instance): string
			local Players = game:GetService "Players"
			local player = assert(Players.LocalPlayer, "a client player")
			local screen = Instance.new "ScreenGui"
			screen.Name = "ComposeDesignSceneProbe"
			screen.ResetOnSpawn = false
			screen.Parent = player:WaitForChild "PlayerGui"
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local environment = ComposeRoblox.designEnvironment()
			local Roblox3D = DesignEditor.roblox3DLibrary(runtime, environment)
			local value = Design.document.new("Probe", Roblox3D, "Model")
			local block
			value, block = Design.document.insert(value, Roblox3D, "n1", "Part")
			value = Design.document.change(value, Roblox3D, block, "size", { literal = { 6, 6, 6 } })
			value = Design.document.change(value, Roblox3D, block, "position", { literal = { 0, 3, 0 } })
			local editor = DesignEditor.create(
				Roblox3D,
				value,
				screen,
				{ stageSize = { X = 0, Y = 0 }, runtime = runtime, environment = environment }
			)
			local function settle()
				for _ = 1, 6 do
					game:GetService("RunService").RenderStepped:Wait()
				end
			end
			settle()
			assertThat(editor.stage == nil, "a 3D library does not open the 2D stage")
			local scene = assert(editor.scene, "a 3D library opens the scene")
			local part = scene.nodes[block]
			assert(typeof(part) == "Instance")
			assertThat(part:IsA "BasePart", "the Part layer renders a BasePart")
			scene.fit()
			settle()
			local viewport = scene.viewport
			assert(typeof(viewport) == "Instance" and viewport:IsA "ViewportFrame")
			local center = viewport.AbsolutePosition + viewport.AbsoluteSize / 2
			assertThat(scene.pick { X = center.X, Y = center.Y } == block, "picking the scene centre finds the part")
			editor.session.select(block)
			assertThat(editor.session.change("position", { literal = { 4, 3, 0 } }), "the position edit applies")
			settle()
			local moved = scene.nodes[block]
			assert(typeof(moved) == "Instance" and moved:IsA "PVInstance")
			assertThat(
				(moved:GetPivot().Position - Vector3.new(4, 3, 0)).Magnitude < 0.01,
				"the scene shows the moved part"
			)
			local source = Design.emit(editor.session.document:peek(), Roblox3D)
			assertThat(Design.emit(Design.parse(source, Roblox3D), Roblox3D) == source, "the 3D source round-trips")
			editor.dispose()
			runtime:dispose()
			screen:Destroy()
			return "the scene rendered, picked, moved and round-tripped a part"
		end,
	},
}

return checks
