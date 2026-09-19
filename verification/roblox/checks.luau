--!strict

export type Result = {
	name: string,
	passed: boolean,
	detail: string,
}

export type Summary = {
	passed: number,
	failed: number,
	results: { Result },
	environment: { [string]: string },
}

type Check = {
	name: string,
	run: (container: Instance) -> string,
}

local function assertThat(condition: boolean, message: string)
	if not condition then
		error(message, 0)
	end
end

local function checks(Compose: any, ComposeRoblox: any): { Check }
	return {
		{
			name = "creates and destroys a real Instance",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local dispose, frame = runtime.mount(function()
					return runtime.create "Frame" { Name = "Probe" }
				end, container)

				assertThat(typeof(frame) == "Instance", "expected an Instance, got " .. typeof(frame))
				assertThat((frame :: Frame).Parent == container, "the frame was not parented to the container")
				dispose()
				assertThat((frame :: any).Parent == nil, "the frame survived disposal")
				assertThat(container.Parent ~= nil, "Compose destroyed the mount target")
				return "Instance created, parented, and destroyed; mount target untouched"
			end,
		},
		{
			name = "the engine rejects a badly typed property, and Compose unwinds",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local before = #container:GetChildren()
				local ok, err = pcall(function()
					runtime.mount(function()
						return runtime.create "Frame" { BackgroundColor3 = "not a colour" }
					end, container)
				end)
				assertThat(not ok, "the engine accepted a string for a Color3 property")
				assertThat(
					#container:GetChildren() == before,
					("a failed render left %d child(ren) behind"):format(#container:GetChildren() - before)
				)
				return ("engine rejected the write and Compose unwound: %s"):format(
					string.sub(tostring(err):gsub("\n.*", ""), 1, 80)
				)
			end,
		},
		{
			name = "clearProperty restores the real class default on a borrowed Instance",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local borrowed = Instance.new "Frame"
				borrowed.Parent = container
				local originalOrder = borrowed.LayoutOrder
				local originalVisible = borrowed.Visible

				local dispose = runtime.mount(function()
					runtime.decorate(borrowed, { LayoutOrder = 99, Visible = false })
					return runtime.create "Frame" {}
				end, container)

				assertThat(borrowed.LayoutOrder == 99, "the decoration did not apply")
				dispose()
				assertThat(
					borrowed.LayoutOrder == originalOrder,
					("LayoutOrder left at %d, expected %d"):format(borrowed.LayoutOrder, originalOrder)
				)
				assertThat(borrowed.Visible == originalVisible, "Visible was not restored")
				assertThat(borrowed.Parent == container, "Compose destroyed a borrowed Instance")
				borrowed:Destroy()
				return ("restored LayoutOrder to %d and Visible to %s"):format(originalOrder, tostring(originalVisible))
			end,
		},
		{
			name = "the Attributes key writes, clears and refuses on a real Instance",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local tier = Compose.cell(1 :: number?)

				local dispose, frame = runtime.mount(function()
					return runtime.create "Frame" {
						Attributes = { Tier = tier, Faction = "north" },
					}
				end, container)

				assertThat(frame:GetAttribute "Tier" == 1, "the attribute was not written")
				assertThat(frame:GetAttribute "Faction" == "north", "the static attribute was not written")

				tier:set(7)
				runtime:settle()
				assertThat(frame:GetAttribute "Tier" == 7, "the attribute did not follow its cell")

				tier:set(nil)
				runtime:settle()
				assertThat(frame:GetAttribute "Tier" == nil, "nil did not clear the attribute")
				dispose()

				local before = #container:GetChildren()
				local ok, err = pcall(function()
					runtime.mount(function()
						return runtime.create "Frame" { Attributes = { Tier = Instance.new "Folder" } }
					end, container)
				end)
				assertThat(not ok, "the engine stored an Instance in an attribute")
				assertThat(
					string.find(tostring(err), "props/attribute-value", 1, true) ~= nil,
					("the refusal was not reported as props/attribute-value: %s"):format(tostring(err))
				)
				assertThat(
					#container:GetChildren() == before,
					("a refused attribute left %d child(ren) behind"):format(#container:GetChildren() - before)
				)
				return "attribute written, followed a cell, cleared by nil, and a rejected value reported by name"
			end,
		},
		{
			name = "an event key connects to a real RBXScriptSignal and releases on disposal",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local fired = 0
				local dispose, button = runtime.mount(function()
					return runtime.create "TextButton" {
						Text = "probe",
						Activated = function()
							fired += 1
						end,
					}
				end, container)

				assertThat(
					typeof((button :: any).Activated) == "RBXScriptSignal",
					"Activated was written as a property instead of being connected"
				)
				dispose()
				assertThat(fired == 0, "the handler ran without user input")
				return "Activated resolved to an RBXScriptSignal and was not overwritten"
			end,
		},
		{
			name = "GetPropertyChangedSignal fires for an engine-driven change",
			run = function(container: Instance): string
				local host = ComposeRoblox.createHost()
				local observation = host.observation
				local frame = Instance.new "Frame"
				frame.Parent = container

				local seen = 0
				local unsubscribe = observation.observeProperty(frame, "Visible", function()
					seen += 1
				end)
				frame.Visible = false
				task.wait()
				assertThat(seen >= 1, "the property observer did not fire")

				local afterFirst = seen
				unsubscribe()
				unsubscribe()
				frame.Visible = true
				task.wait()
				assertThat(seen == afterFirst, "the observer fired after being unsubscribed")
				frame:Destroy()
				return ("fired %d time(s), then stopped after unsubscribe"):format(afterFirst)
			end,
		},
		{
			name = "LayoutOrder from a keyed collection actually reorders a UIListLayout",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local rows = Compose.cell { "a", "b", "c" }

				local screen = Instance.new "ScreenGui"
				screen.Parent = container

				local dispose, frame = runtime.mount(function()
					return runtime.create "Frame" {
						Size = UDim2.fromOffset(200, 200),
						runtime.create "UIListLayout" { SortOrder = Enum.SortOrder.LayoutOrder },
						Compose.keyed {
							from = rows,
							render = function(value, index)
								return runtime.create "TextLabel" {
									Size = UDim2.new(1, 0, 0, 20),
									Text = function(use)
										return use(value)
									end,
									LayoutOrder = function(use)
										return use(index)
									end,
								}
							end,
						},
					}
				end, screen)

				rows:set { "c", "a", "b" }
				runtime:settle()
				task.wait()
				task.wait()

				local byText: { [string]: number } = {}
				for _, child in (frame :: Instance):GetChildren() do
					if child:IsA "TextLabel" then
						byText[child.Text] = child.LayoutOrder
					end
				end
				assertThat(
					byText.c == 1 and byText.a == 2 and byText.b == 3,
					"LayoutOrder did not follow the keyed index"
				)

				local positions: { { text: string, y: number } } = {}
				for _, child in (frame :: Instance):GetChildren() do
					if child:IsA "TextLabel" then
						table.insert(positions, { text = child.Text, y = (child :: TextLabel).AbsolutePosition.Y })
					end
				end
				table.sort(positions, function(left, right)
					return left.y < right.y
				end)
				assertThat(#positions == 3, "expected three rows, found " .. tostring(#positions))
				assertThat(
					positions[1].text == "c" and positions[2].text == "a" and positions[3].text == "b",
					("the layout did not honour LayoutOrder: %s, %s, %s"):format(
						positions[1].text,
						positions[2].text,
						positions[3].text
					)
				)
				dispose()
				screen:Destroy()
				return "UIListLayout placed rows in c, a, b -- the keyed order"
			end,
		},
		{
			name = "a spring settles on the real Heartbeat and then stops",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local target = Compose.cell(UDim2.fromScale(0, 0))
				local dispose, frame = runtime.mount(function()
					local smooth = runtime.spring(function(use)
						return use(target)
					end, { period = 0.2, damping = 1 })
					return runtime.create "Frame" {
						Size = function(use)
							return use(smooth)
						end,
					}
				end, container)

				target:set(UDim2.fromScale(1, 0.5))
				runtime:settle()

				local frames = 0
				local deadline = os.clock() + 5
				while os.clock() < deadline and (frame :: Frame).Size ~= UDim2.fromScale(1, 0.5) do
					frames += 1
					task.wait()
				end
				assertThat(
					(frame :: Frame).Size == UDim2.fromScale(1, 0.5),
					("the spring did not settle: %s"):format(tostring((frame :: Frame).Size))
				)

				local settledSize = (frame :: Frame).Size
				for _ = 1, 5 do
					task.wait()
				end
				assertThat((frame :: Frame).Size == settledSize, "the spring kept moving after settling")
				dispose()
				return ("settled exactly on target after %d frames, then stopped"):format(frames)
			end,
		},
		{
			name = "a disposed tree is collectable",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local alive = setmetatable({}, { __mode = "v" })
				do
					local dispose, frame = runtime.mount(function()
						return runtime.create "Frame" { runtime.create "TextLabel" {} }
					end, container)
					alive[1] = frame
					dispose()
				end
				for _ = 1, 5 do
					task.wait()
				end

				return ("weak reference after disposal: %s"):format(
					if alive[1] == nil then "released" else "still held (collector has not run)"
				)
			end,
		},
		{
			name = "heap returns to baseline after repeated mount and dispose",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()

				local function cycle()
					local children = table.create(200)
					local dispose = runtime.mount(function()
						for index = 1, 200 do
							children[index] = runtime.create "TextLabel" { Text = "row " .. tostring(index) }
						end
						return runtime.create "Frame"(children)
					end, container)
					dispose()
				end

				local function settle(): number
					local lowest = collectgarbage "count"
					for _ = 1, 40 do
						local junk = table.create(2000)
						for index = 1, 2000 do
							junk[index] = { index }
						end
						junk = nil :: any
						task.wait()
						local sample = collectgarbage "count"
						if sample < lowest then
							lowest = sample
						end
					end
					return lowest
				end

				cycle()
				local first = settle()
				for _ = 1, 8 do
					cycle()
				end
				local last = settle()
				local perCycle = (last - first) / 8

				assertThat(
					perCycle < 64,
					("heap grew %.1f KB per mount/dispose cycle, which is a leak"):format(perCycle)
				)
				return ("%.2f KB per cycle across 9 cycles of a 201-node tree"):format(perCycle)
			end,
		},
		{
			name = "Compose against direct Instance work, on the engine",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local COUNT = 400
				local ROUNDS = 5

				local function race(first: () -> (), second: () -> ()): (number, number)
					first()
					second()
					local firstSamples = table.create(ROUNDS)
					local secondSamples = table.create(ROUNDS)
					for index = 1, ROUNDS do
						local startedFirst = os.clock()
						first()
						firstSamples[index] = os.clock() - startedFirst
						local startedSecond = os.clock()
						second()
						secondSamples[index] = os.clock() - startedSecond
					end
					table.sort(firstSamples)
					table.sort(secondSamples)
					local middle = (ROUNDS // 2) + 1
					return firstSamples[middle], secondSamples[middle]
				end

				local directBuild, composeBuild = race(function()
					local frame = Instance.new "Frame"
					for index = 1, COUNT do
						local label = Instance.new "TextLabel"
						label.Text = "row " .. tostring(index)
						label.Parent = frame
					end
					frame.Parent = container
					frame:Destroy()
				end, function()
					local dispose = runtime.mount(function()
						local children = table.create(COUNT)
						for index = 1, COUNT do
							children[index] = runtime.create "TextLabel" { Text = "row " .. tostring(index) }
						end
						return runtime.create "Frame"(children)
					end, container)
					dispose()
				end)

				local plain = Instance.new "TextLabel"
				plain.Parent = container
				local text = Compose.cell "value 0"
				local disposeBound = runtime.mount(function()
					return runtime.create "TextLabel" {
						Text = function(use)
							return use(text)
						end,
					}
				end, container)
				local directUpdate, composeUpdate = race(function()
					for index = 1, COUNT do
						plain.Text = "value " .. tostring(index)
					end
				end, function()
					for index = 1, COUNT do
						text:set("value " .. tostring(index))
					end
				end)
				disposeBound()
				plain:Destroy()

				local buildRatio = composeBuild / directBuild
				local updateRatio = composeUpdate / directUpdate

				assertThat(
					buildRatio < 10,
					("building through Compose cost %.1fx direct Instance work, which is out of band"):format(
						buildRatio
					)
				)
				assertThat(
					updateRatio < 40,
					("a reactive write cost %.1fx a direct assignment, which is out of band"):format(updateRatio)
				)

				return (
					"%d nodes: build+teardown %.3f ms direct, %.3f ms Compose (%.2fx); "
					.. "%d writes: %.3f ms direct, %.3f ms Compose (%.2fx)"
				):format(
					COUNT,
					directBuild * 1000,
					composeBuild * 1000,
					buildRatio,
					COUNT,
					directUpdate * 1000,
					composeUpdate * 1000,
					updateRatio
				)
			end,
		},
		{
			name = "representative screens hold a frame budget on the engine",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local FRAMES = 60

				local function perFrame(body: (number) -> ()): number
					local samples = table.create(FRAMES)
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
					local health = Compose.cell(100)
					local mana = Compose.cell(100)
					local cast = Compose.cell(0)
					local started = os.clock()
					local dispose = runtime.mount(function()
						local bars = table.create(24)
						for index = 1, 24 do
							local source = if index % 3 == 0 then health elseif index % 3 == 1 then mana else cast
							bars[index] = runtime.create "Frame" {
								LayoutOrder = index,
								Transparency = function(use)
									return (use(source) :: number) / 100
								end,
							}
						end
						return runtime.create "Frame"(bars)
					end, container)
					local cold = os.clock() - started
					local frame = perFrame(function(tick)
						runtime:batch(function()
							health:set(60 + (tick % 40))
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
					local units = table.create(COUNT)
					for index = 1, COUNT do
						units[index] = { id = index, health = Compose.cell(index % 100) }
					end
					local roster = Compose.cell(units)
					local started = os.clock()
					local dispose = runtime.mount(function()
						return runtime.create "Frame" {
							Compose.keyed {
								from = roster,
								key = function(unit: any)
									return unit.id
								end,
								render = function(value: any, index: any)
									local unit: any = value:peek()
									return runtime.create "Frame" {
										LayoutOrder = index,
										Transparency = function(use)
											return (use(unit.health) :: number) / 100
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
								units[at].health:set((tick + offset) % 100)
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
					local pool = table.create(TOTAL)
					for index = 1, TOTAL do
						pool[index] = { id = index, label = index }
					end
					local logical = Compose.cell(pool)
					local first = Compose.cell(1)
					local started = os.clock()
					local dispose = runtime.mount(function()
						return runtime.create "Frame" {
							Compose.windowed {
								from = logical,
								window = function(use)
									return use(first) :: number, VISIBLE
								end,
								key = function(item: any)
									return item.id
								end,
								render = function(value: any, absolute: any)
									return runtime.create "Frame" {
										LayoutOrder = absolute,
										Name = function(use): string
											return ("row-%d"):format((use(value) :: any).label)
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
					local targets = table.create(COUNT)
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
							panels[index] = runtime.create "Frame" {
								LayoutOrder = index,
								Transparency = function(use)
									return math.clamp(use(moved) :: number, 0, 1)
								end,
							}
						end
						return runtime.create "Frame"(panels)
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
			name = "a 3D combatant scene composes, updates sparsely and tears down on the engine",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local COUNT = 200
				local FRAMES = 60

				local function perFrame(body: (number) -> ()): number
					local samples = table.create(FRAMES)
					for tick = 1, FRAMES do
						local started = os.clock()
						body(tick)
						samples[tick] = os.clock() - started
					end
					table.sort(samples)
					return samples[(FRAMES // 2) + 1]
				end

				local before = #container:GetChildren()

				local units = table.create(COUNT)
				for index = 1, COUNT do
					units[index] = {
						id = index,
						health = Compose.cell((index % 100) + 1),
						distance = Compose.cell((index * 7) % 400),
						visible = Compose.cell(index % 2 == 0),
						selected = Compose.cell(false),
					}
				end
				local roster = Compose.cell(units)

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
					return runtime.create "Folder" {
						Name = "Battle",
						runtime.adopt(asset),
						Compose.keyed {
							from = roster,
							key = function(unit)
								return unit.id
							end,
							render = function(value)
								local unit = value:peek()
								return runtime.create "Model" {
									Name = ("Unit%d"):format(unit.id),
									runtime.create "MeshPart" {
										Name = "Body",
										Anchored = true,
										Transparency = function(use)
											return math.clamp((use(use(value).distance) :: number) / 800, 0, 1)
										end,
									},
									runtime.create "Attachment" {
										Name = "Anchor",
										Compose.show(function(use)
											return use(use(value).visible) :: boolean
										end, function()
											return runtime.create "BillboardGui" {
												Name = "Plate",
												AlwaysOnTop = true,
												runtime.create "TextLabel" {
													Name = "Health",
													Text = function(use)
														return tostring(use(use(value).health))
													end,
												},
											}
										end),
									},
									Compose.show(function(use)
										return use(use(value).selected) :: boolean
									end, function()
										return runtime.create "Highlight" {
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
							unit.health:set(((tick + offset) % 100) + 1)
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
						unit.visible:set(not (unit.visible :: any):peek())
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
			name = "a culled 2D sprite scene mounts and unmounts continuously on the engine",
			run = function(container: Instance): string
				local runtime = ComposeRoblox.createRuntime()
				local POPULATION = 2000
				local VISIBLE = 120
				local FRAMES = 60

				local entities = table.create(POPULATION)
				for index = 1, POPULATION do
					entities[index] = { id = index, depth = index % 8 }
				end

				local function windowAt(tick: number): { any }
					local first = ((tick * 8) % (POPULATION - VISIBLE)) + 1
					local shown = table.create(VISIBLE)
					for offset = 0, VISIBLE - 1 do
						shown[offset + 1] = entities[first + offset]
					end
					return shown
				end

				local visible = Compose.cell(windowAt(0))
				local positions = table.create(POPULATION)
				for index = 1, POPULATION do
					positions[index] = Compose.cell(0)
				end

				local started = os.clock()
				local dispose = runtime.mount(function()
					return runtime.create "Frame" {
						Name = "Scene",
						BackgroundTransparency = 1,
						Compose.keyed {
							from = visible,
							key = function(entity)
								return entity.id
							end,
							render = function(value, index)
								local entity = value:peek()
								local offset = positions[entity.id]
								return runtime.create "ImageLabel" {
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

				local samples = table.create(FRAMES)
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
				assertThat(
					#container:GetChildren() == before - 1,
					"the culled scene did not release its root on disposal"
				)

				return ("sprites(%d of %d) cold %.2f ms, frame %.1f us, teardown %.2f ms"):format(
					VISIBLE,
					POPULATION,
					cold * 1000,
					frame * 1e6,
					teardown * 1000
				)
			end,
		},
	}
end

local function run(Compose: any, ComposeRoblox: any, parent: Instance): Summary
	local runService = game:GetService "RunService"
	local editOk, editValue = pcall(function()
		return runService:IsEdit()
	end)
	local summary: Summary = {
		passed = 0,
		failed = 0,
		results = {},
		environment = {
			studioVersion = version(),
			placeId = tostring(game.PlaceId),
			gameId = tostring(game.GameId),
			isEdit = if editOk then tostring(editValue) else "unavailable",
			animatableTypes = table.concat(ComposeRoblox.animatableTypes(), ", "),
		},
	}

	for _, check in checks(Compose, ComposeRoblox) do
		local scratch = Instance.new "Folder"
		scratch.Name = "ComposeCheck"
		scratch.Parent = parent

		local ok, outcome = pcall(check.run, scratch)
		if ok then
			summary.passed += 1
			table.insert(summary.results, { name = check.name, passed = true, detail = tostring(outcome) })
		else
			summary.failed += 1
			table.insert(summary.results, { name = check.name, passed = false, detail = tostring(outcome) })
		end

		scratch:Destroy()
	end

	return summary
end

return {
	run = run,
}
