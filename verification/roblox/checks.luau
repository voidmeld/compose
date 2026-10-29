--!strict
--!nolint DeprecatedApi

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Scenes = require "./checks-scenes"

type Readable<T> = { peek: (self: Readable<T>) -> T }
type OptionalNumberCell = Readable<number?> & {
	set: (self: OptionalNumberCell, value: number?) -> (),
	update: (self: OptionalNumberCell, body: (number?) -> number?) -> (),
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
		id = "styled-property-observation",
		name = "observes native style changes, raw overrides and resets through shared channels",
		requires = { "roblox-engine", "roblox-client" },
		run = function(_container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			return Compose.withRootOwner(function(): string
				Compose.cleanup(function()
					runtime:dispose()
				end)
				local screen = Instance.new "ScreenGui"
				runtime.adopt(screen)
				screen.Enabled = false
				local sheet = Instance.new "StyleSheet"
				sheet.Parent = screen
				local rule = Instance.new "StyleRule"
				rule.Selector = "TextLabel"
				rule:SetProperties { TextSize = 23, FontFace = Font.fromEnum(Enum.Font.SourceSans) }
				rule.Parent = sheet
				local link = Instance.new "StyleLink"
				link.StyleSheet = sheet
				link.Parent = screen
				local label = Instance.new "TextLabel"
				label.Parent = screen
				screen.Parent = assert(game:GetService("Players").LocalPlayer):WaitForChild "PlayerGui"
				local render = game:GetService("RunService").PreRender
				local function settled(expected: number)
					local deadline = os.clock() + 2
					repeat
						render:Wait()
					until label:GetStyled "TextSize" == expected or os.clock() >= deadline
					assertThat(
						label:GetStyled "TextSize" == expected,
						"native stylesheet did not settle: " .. rule.SelectorError
					)
				end
				settled(23)
				local raw = runtime.observe(label, "TextSize")
				local size = runtime.observe(label, "TextSize", { styled = true })
				local font = runtime.observe(label, "FontFace", { styled = true })
				assertThat(raw ~= size, "raw and styled observations shared a cache entry")
				assertThat(
					size == runtime.observe(label, "TextSize", { styled = true }),
					"styled acquisition was not shared"
				)
				assertThat(size:peek() == 23, "the initial stylesheet value was not observed")
				rule:SetProperties { TextSize = 31, FontFace = Font.fromEnum(Enum.Font.Gotham) }
				settled(31)
				assertThat(size:peek() == 31, "a stylesheet write did not update TextSize")
				assertThat(
					(font:peek() :: Font).Family == (label:GetStyled "FontFace" :: Font).Family,
					"FontFace did not update"
				)
				assertThat(raw:peek() == label.TextSize, "style changes corrupted the raw observation")
				label.TextSize = 41
				settled(41)
				assertThat(size:peek() == 41 and raw:peek() == 41, "a raw override did not update both observations")
				rule:SetProperties { TextSize = 35, FontFace = Font.fromEnum(Enum.Font.SourceSans) }
				render:Wait()
				assertThat(size:peek() == 41, "a masked stylesheet write replaced the raw override")
				label:ResetPropertyToDefault "TextSize"
				settled(35)
				assertThat(size:peek() == 35, "reset did not reveal the current stylesheet value")
				assertThat(raw:peek() == label.TextSize, "reset left the raw observation stale")
				return "styled TextSize and FontFace followed native style changes; raw overrides masked style until reset; cache identities remained distinct"
			end, runtime.reactor)
		end,
	},
	{
		id = "styled-valuebase-observation",
		name = "observes ValueBase Value and Name writes and resets without depending on Changed",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			return Compose.withRootOwner(function(): string
				Compose.cleanup(function()
					runtime:dispose()
				end)
				for _, class in { "StringValue", "NumberValue" } do
					local node = Instance.new(class)
					runtime.adopt(node)
					node.Parent = container
					local originalName = node.Name
					local originalValue: unknown = if class == "StringValue"
						then (node :: StringValue).Value
						else (node :: NumberValue).Value
					local name = runtime.observe(node, "Name", { styled = true })
					local value = runtime.observe(node, "Value", { styled = true })
					node.Name = "ChangedName"
					if class == "StringValue" then
						(node :: StringValue).Value = "changed value"
					else
						(node :: NumberValue).Value = 42
					end
					game:GetService("RunService").Heartbeat:Wait()
					assertThat(name:peek() == "ChangedName", class .. " Name write was missed")
					assertThat(
						value:peek() == (if class == "StringValue" then "changed value" else 42),
						class .. " Value write was missed"
					)
					node:ResetPropertyToDefault "Name"
					if class == "StringValue" then
						(node :: StringValue):ResetPropertyToDefault "Value"
					else
						(node :: NumberValue):ResetPropertyToDefault "Value"
					end
					game:GetService("RunService").Heartbeat:Wait()
					assertThat(name:peek() == originalName, class .. " Name reset was missed")
					assertThat(value:peek() == originalValue, class .. " Value reset was missed")
				end
				return "StringValue and NumberValue Name and Value writes and resets matched GetStyled"
			end, runtime.reactor)
		end,
	},
	{
		id = "property-readables-before-render",
		name = "shares property readables and samples settled layout before showing it",
		requires = { "roblox-engine", "roblox-client" },
		run = function(_container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local player = assert(game:GetService("Players").LocalPlayer)
			local render = game:GetService("RunService").PreRender
			return Compose.withRootOwner(function(): string
				local screen = Instance.new "ScreenGui"
				runtime.adopt(screen)
				screen.Enabled = false
				screen.Parent = player:WaitForChild "PlayerGui"
				local _, node = runtime.mount(function()
					return runtime.constructors.TextLabel {
						Size = UDim2.fromOffset(300, 80),
						Position = UDim2.fromOffset(24, 32),
						Text = "Measured before presentation",
						TextSize = 20,
					}
				end, screen)
				local bounds = runtime.observe(node, "TextBounds")
				assertThat(bounds == runtime.observe(node, "TextBounds"), "TextBounds acquisition was not shared")
				local position = runtime.observe(node, "AbsolutePosition")
				local size = runtime.observe(node, "AbsoluteSize")
				local read = assert(runtime.host.observation).readProperty
				local settled = runtime.settled {
					sample = function(): string
						return tostring(read(node, "TextBounds"))
							.. tostring(read(node, "AbsoluteSize"))
							.. tostring(read(node, "AbsolutePosition"))
					end,
					ready = function(): boolean
						return (read(node, "TextBounds") :: Vector2).X > 0
					end,
				}
				for _ = 1, 120 do
					if settled:peek() then
						break
					end
					render:Wait()
				end
				assertThat(settled:peek(), "hidden text layout did not settle within 120 render frames")
				assertThat(bounds:peek() == read(node, "TextBounds"), "TextBounds readable lagged the settled property")
				assertThat(
					size:peek() == read(node, "AbsoluteSize"),
					"AbsoluteSize readable lagged the settled property"
				)
				screen.Enabled = true
				render:Wait()
				assertThat(
					position:peek() == read(node, "AbsolutePosition"),
					"AbsolutePosition readable lagged the first visible frame"
				)
				return "hidden layout settled; shared TextBounds, AbsoluteSize and AbsolutePosition matched engine reads before presentation"
			end, runtime.reactor)
		end,
	},
	{
		id = "instance-lifecycle",
		name = "creates and destroys a real Instance",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local dispose, frame = runtime.mount(function()
				return runtime.constructors.Frame { Name = "Probe" }
			end, container)

			assertThat(typeof(frame) == "Instance", "expected an Instance, got " .. typeof(frame))
			assertThat((frame :: Frame).Parent == container, "the frame was not parented to the container")
			dispose()
			assertThat((frame :: Instance).Parent == nil, "the frame survived disposal")
			assertThat(container.Parent ~= nil, "Compose destroyed the mount target")
			return "Instance created, parented, and destroyed; mount target untouched"
		end,
	},
	{
		id = "typed-property-refusal",
		name = "the engine rejects a badly typed property, and Compose unwinds",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local before = #container:GetChildren()
			local ok, err = pcall(function()
				runtime.mount(function()
					return runtime.constructors.Frame { BackgroundColor3 = "not a colour" }
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
		id = "clear-property-default",
		name = "clearProperty restores the real class default on a borrowed Instance",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local borrowed = Instance.new "Frame"
			borrowed.Parent = container
			local originalOrder = borrowed.LayoutOrder
			local originalVisible = borrowed.Visible

			local dispose = runtime.mount(function()
				runtime.decorate(borrowed, { LayoutOrder = 99, Visible = false })
				return runtime.constructors.Frame {}
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
		id = "attributes-key",
		name = "the Attributes key writes, clears and refuses on a real Instance",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local tier = Compose.cell(1 :: number?) :: OptionalNumberCell

			local dispose, frame = runtime.mount(function()
				return runtime.constructors.Frame {
					Attributes = { Tier = tier, Faction = "north" },
				}
			end, container)

			assertThat((frame :: Frame):GetAttribute "Tier" == 1, "the attribute was not written")
			assertThat((frame :: Frame):GetAttribute "Faction" == "north", "the static attribute was not written")

			tier:set(7)
			runtime:settle()
			assertThat((frame :: Frame):GetAttribute "Tier" == 7, "the attribute did not follow its cell")

			tier:set(nil)
			runtime:settle()
			assertThat((frame :: Frame):GetAttribute "Tier" == nil, "nil did not clear the attribute")
			dispose()

			local before = #container:GetChildren()
			local ok, err = pcall(function()
				runtime.mount(function()
					return runtime.constructors.Frame { Attributes = { Tier = { deep = true } } }
				end, container)
			end)
			assertThat(not ok, "the engine stored a table in an attribute")
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
		id = "event-connection",
		name = "an event key connects to a real RBXScriptSignal and releases on disposal",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local fired = 0
			local dispose, button = runtime.mount(function()
				return runtime.constructors.TextButton {
					Text = "probe",
					Activated = function()
						fired += 1
					end,
				}
			end, container)

			assertThat(
				typeof((button :: TextButton).Activated) == "RBXScriptSignal",
				"Activated was written as a property instead of being connected"
			)
			dispose()
			assertThat(fired == 0, "the handler ran without user input")
			return "Activated resolved to an RBXScriptSignal and was not overwritten"
		end,
	},
	{
		id = "property-changed-signal",
		name = "GetPropertyChangedSignal fires for an engine-driven change",
		run = function(container: Instance): string
			local host = ComposeRoblox.createHost()
			local observation = assert(host.observation)
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
		id = "keyed-layout-order",
		name = "LayoutOrder from a keyed collection actually reorders a UIListLayout",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local rows = Compose.cell { "a", "b", "c" }

			local screen = Instance.new "ScreenGui"
			screen.Parent = container

			local dispose, frame = runtime.mount(function()
				return runtime.constructors.Frame {
					Size = UDim2.fromOffset(200, 200),
					runtime.constructors.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder },
					Compose.keyed {
						from = rows,
						render = function(value, index)
							return runtime.constructors.TextLabel {
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
			assertThat(byText.c == 1 and byText.a == 2 and byText.b == 3, "LayoutOrder did not follow the keyed index")

			local positions: { { text: string, y: number } } = {}
			for _, child in (frame :: Instance):GetChildren() do
				if child:IsA "TextLabel" then
					table.insert(positions, { text = child.Text, y = (child :: TextLabel).AbsolutePosition.Y })
				end
			end
			table.sort(positions, function(left: { text: string, y: number }, right: { text: string, y: number })
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
		id = "spring-heartbeat",
		name = "a spring settles on the real Heartbeat and then stops",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local target = Compose.cell(UDim2.fromScale(0, 0))
			local dispose, frame = runtime.mount(function()
				local smooth = runtime.spring(function(use)
					return use(target)
				end, { period = 0.2, damping = 1 })
				return runtime.constructors.Frame {
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
		id = "disposed-tree-collectable",
		name = "a disposed tree is collectable",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local alive = setmetatable({}, { __mode = "v" })
			do
				local dispose, frame = runtime.mount(function()
					return runtime.constructors.Frame { runtime.constructors.TextLabel {} }
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
		id = "heap-baseline",
		name = "heap returns to baseline after repeated mount and dispose",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()

			local function cycle()
				local children = table.create(200)
				local dispose = runtime.mount(function()
					for index = 1, 200 do
						children[index] = runtime.constructors.TextLabel { Text = "row " .. tostring(index) }
					end
					return runtime.constructors.Frame(children)
				end, container)
				dispose()
			end

			local function settle(): number
				local lowest = collectgarbage "count"
				for _ = 1, 40 do
					local junk: { { number } }? = table.create(2000) :: { { number } }
					for index = 1, 2000 do
						(junk :: { { number } })[index] = { index }
					end
					junk = nil
					task.wait()
					local sample = collectgarbage "count"
					if sample < lowest then
						lowest = sample
					end
				end
				return lowest
			end

			for _ = 1, 16 do
				cycle()
			end
			settle()
			local first = settle()
			for _ = 1, 8 do
				cycle()
			end
			local last = settle()
			local perCycle = (last - first) / 8

			assertThat(perCycle < 64, ("heap grew %.1f KB per mount/dispose cycle, which is a leak"):format(perCycle))
			return ("%.2f KB per cycle across 8 cycles of a 201-node tree after 16 warm-up cycles"):format(perCycle)
		end,
	},
	{
		id = "direct-instance-race",
		name = "Compose against direct Instance work, on the engine",
		run = function(container: Instance): string
			local runtime: Compose.Runtime = ComposeRoblox.createRuntime()
			local COUNT = 400
			local ROUNDS = 5

			local function race(first: () -> (), second: () -> ()): (number, number)
				first()
				second()
				local firstSamples: { number } = table.create(ROUNDS) :: { number }
				local secondSamples: { number } = table.create(ROUNDS) :: { number }
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
						children[index] = runtime.constructors.TextLabel { Text = "row " .. tostring(index) }
					end
					return runtime.constructors.Frame(children)
				end, container)
				dispose()
			end)

			local plain = Instance.new "TextLabel"
			plain.Parent = container
			local text = Compose.cell "value 0"
			local disposeBound = runtime.mount(function()
				return runtime.constructors.TextLabel {
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
				("building through Compose cost %.1fx direct Instance work, which is out of band"):format(buildRatio)
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
}

for _, check in Scenes do
	table.insert(checks, check)
end
return checks
