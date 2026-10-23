--!strict

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Emulator = require "../../src/test-scene/roblox"
local Support = require "../support"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type World = {
	emulator: Emulator.Emulator,
	runtime: Compose.Runtime,
	create: (kind: string) -> (props: Compose.Props) -> Compose.Node,
	root: Compose.Node,
}

local function world(raiseHandlers: boolean?): World
	Compose.__resetForTests()
	ComposeRoblox.__resetForTests()
	local emulator = Support.emulator(if raiseHandlers then { handlerErrors = "raise" } else nil)
	local runtime = ComposeRoblox.createRuntime(emulator.engine)
	return {
		emulator = emulator,
		runtime = runtime,
		create = runtime.create,
		root = emulator.engine.new "Folder",
	}
end

local function styledWorld()
	local w = world(true)
	local env = w.emulator.environment
	local raw: Emulator.Signal<string> = env.newSignal()
	local styled: Emulator.Signal<()> = env.newSignal()
	local values: { [string]: unknown } = { BackgroundTransparency = 0.4, LayoutOrder = 7 }
	local overrides: { [string]: unknown } = {}
	local signals: { [string]: Emulator.Signal<()> } = {}
	local node = {
		Changed = raw,
		StyledPropertiesChanged = styled,
		IsA = function(_self: unknown, _class: string): boolean
			return false
		end,
		GetStyled = function(_self: unknown, property: string): unknown
			local override = overrides[property]
			return if override ~= nil then override else values[property]
		end,
		GetPropertyChangedSignal = function(_self: unknown, property: string): Emulator.Signal<()>
			if signals[property] == nil then
				signals[property] = env.newSignal()
			end
			return signals[property]
		end,
	}
	local host = ComposeRoblox.createHost(w.emulator.engine)
	return w, host, raw, styled, values, overrides, node
end

describe("roblox adapter", function()
	describe("styled observation", function()
		it("observes ValueBase Value and Name through property signals instead of Changed payloads", function()
			for _, kind in { "StringValue", "NumberValue" } do
				local w = world(true)
				local env = w.emulator.environment
				local changed: Emulator.Signal<unknown> = env.newSignal()
				local styled: Emulator.Signal<()> = env.newSignal()
				local valueSignal: Emulator.Signal<()> = env.newSignal()
				local nameSignal: Emulator.Signal<()> = env.newSignal()
				local signals: { [string]: Emulator.Signal<()> } = { Value = valueSignal, Name = nameSignal }
				local initial: unknown = if kind == "StringValue" then "" else 0
				local nextValue: unknown = if kind == "StringValue" then "next" else 12
				local values: { [string]: unknown } = { Value = initial, Name = "Value" }
				local node = {
					Changed = changed,
					StyledPropertiesChanged = styled,
					IsA = function(_self: unknown, class: string): boolean
						return class == "ValueBase"
					end,
					GetStyled = function(_self: unknown, property: string): unknown
						return values[property]
					end,
					GetPropertyChangedSignal = function(_self: unknown, property: string): Emulator.Signal<()>
						return signals[property]
					end,
				}
				local observed, owner = Support.owned(function()
					return {
						w.runtime.observe(node, "Value", { styled = true }),
						w.runtime.observe(node, "Name", { styled = true }),
					}
				end)
				values.Value = nextValue
				changed:Fire(nextValue)
				signals.Value:Fire()
				expect(observed[1]:peek()):toBe(nextValue)
				values.Name = "renamed"
				signals.Name:Fire()
				expect(observed[2]:peek()):toBe "renamed"
				values.Value, values.Name = initial, "Value"
				changed:Fire(initial)
				signals.Value:Fire()
				signals.Name:Fire()
				expect(observed[1]:peek()):toBe(initial)
				expect(observed[2]:peek()):toBe "Value"
				owner.dispose()
				expect(env.liveConnections()):toBe(0)
			end
		end)

		it("shares the style channel and observes only the requested raw properties", function()
			local w, host, raw, styled, values, overrides, node = styledWorld()
			local runtime = Compose.createRuntime(host)
			local env = w.emulator.environment
			local before = env.liveConnections()
			local first = Compose.createOwner(runtime.reactor)
			local second = Compose.createOwner(runtime.reactor)
			local alpha = Compose.withOwner(first, function()
				return runtime.observe(node, "BackgroundTransparency", { styled = true })
			end)
			local order = Compose.withOwner(second, function()
				expect(runtime.observe(node, "BackgroundTransparency", { styled = true })):toBe(alpha)
				return runtime.observe(node, "LayoutOrder", { styled = true })
			end)
			expect(env.liveConnections() - before):toBe(3)
			overrides.LayoutOrder = 11
			raw:Fire("LayoutOrder")
			expect(order:peek()):toBe(7)
			overrides.LayoutOrder = nil
			expect(alpha:peek()):toBe(0.4)
			expect(order:peek()):toBe(7)
			local notifications = 0
			Compose.withOwner(first, function()
				Compose.watch(function(use)
					use(alpha)
					notifications += 1
				end)
			end)
			overrides.BackgroundTransparency = 0.8
			node:GetPropertyChangedSignal("BackgroundTransparency"):Fire()
			expect(alpha:peek()):toBe(0.8)
			local masked = notifications
			values.BackgroundTransparency, values.LayoutOrder = 0.2, 9
			styled:Fire()
			expect(alpha:peek()):toBe(0.8)
			expect(notifications):toBe(masked)
			expect(order:peek()):toBe(9)
			overrides.BackgroundTransparency = nil
			node:GetPropertyChangedSignal("BackgroundTransparency"):Fire()
			expect(alpha:peek()):toBe(0.2)
			first.dispose()
			expect(env.liveConnections() - before):toBe(3)
			second.dispose()
			second.dispose()
			expect(env.liveConnections()):toBe(before)
		end)

		it("delivers remaining subscribers after errors and handles reentrant removal and acquisition", function()
			local w, host, _, styled, _, _, node = styledWorld()
			local observe = assert(assert(host.observation).observeStyledProperty)
			local seen = 0
			local stopBroken = observe(node, "BackgroundTransparency", function()
				error "observer refused"
			end)
			local stopGood = observe(node, "LayoutOrder", function()
				seen += 1
			end)
			expect(function()
				styled:Fire()
			end):toThrow "observer refused"
			expect(seen):toBe(1)
			stopBroken()
			stopGood()
			local later = 0
			local stopLater: (() -> ())? = nil
			local stopSelf: (() -> ())? = nil
			stopSelf = observe(node, "LayoutOrder", function()
				assert(stopSelf)()
				stopLater = observe(node, "LayoutOrder", function()
					later += 1
				end)
			end)
			styled:Fire()
			expect(later):toBe(0)
			styled:Fire()
			expect(later):toBe(1)
			assert(stopLater)()
			expect(w.emulator.environment.liveConnections()):toBe(0)
		end)

		it("unwinds failed style or property channel acquisition", function()
			local w, host, _, styled, _, _, node = styledWorld()
			local env = w.emulator.environment
			node.StyledPropertiesChanged = (
				{
					Connect = function(): Emulator.Connection
						error "style channel refused"
					end,
				} :: unknown
			) :: Emulator.Signal<()>
			local runtime = Compose.createRuntime(host)
			Compose.withRootOwner(function(owner)
				expect(function()
					runtime.observe(node, "BackgroundTransparency", { styled = true })
				end):toThrow "style channel refused"
				expect(owner.size()):toBe(0)
			end)
			expect(env.liveConnections()):toBe(0)
			node.StyledPropertiesChanged = styled
			node.GetPropertyChangedSignal = function(): Emulator.Signal<()>
				return (
					{
						Connect = function(): Emulator.Connection
							error "property channel refused"
						end,
					} :: unknown
				) :: Emulator.Signal<()>
			end
			Compose.withRootOwner(function(owner)
				expect(function()
					runtime.observe(node, "BackgroundTransparency", { styled = true })
				end):toThrow "property channel refused"
				expect(owner.size()):toBe(0)
			end)
			expect(env.liveConnections()):toBe(0)
		end)

		it("skips subscribers removed during fanout and disconnects both channels after a cleanup error", function()
			local w, host, _, styled, _, _, node = styledWorld()
			local observe = assert(assert(host.observation).observeStyledProperty)
			local calls = 0
			local first: (() -> ())? = nil
			local second: (() -> ())? = nil
			first = observe(node, "LayoutOrder", function()
				calls += 1
				assert(second)()
			end)
			second = observe(node, "LayoutOrder", function()
				calls += 1
				assert(first)()
			end)
			styled:Fire()
			expect(calls):toBe(1)
			assert(first)()
			assert(second)()
			local signal = node:GetPropertyChangedSignal "LayoutOrder"
			node.GetPropertyChangedSignal = function()
				return (
					{
						Connect = function(_self: unknown, listener: () -> ())
							local connection = signal:Connect(listener)
							return {
								Disconnect = function()
									connection:Disconnect()
									error "raw disconnect refused"
								end,
							}
						end,
					} :: unknown
				) :: Emulator.Signal<()>
			end
			local stop = observe(node, "LayoutOrder", function() end)
			expect(stop):toThrow "raw disconnect refused"
			expect(w.emulator.environment.liveConnections()):toBe(0)
			stop()
		end)
	end)

	describe("the host contract", function()
		it("satisfies the protocol Compose validates", function()
			local emulator = Support.emulator()
			local host = ComposeRoblox.createHost(emulator.engine)
			expect(host.name):toBe "roblox"
			expect(host.events):toBeOk()
			expect(host.observation):toBeOk()
			expect(host.frames):toBeOk()
			expect(Compose.createRuntime(host)):toBeOk()
		end)

		it("creates, parents, and destroys engine objects", function()
			local w = world()
			local dispose, frame = w.runtime.mount(function()
				return w.create "Frame" { Name = "Panel" }
			end, w.root)

			expect(w.emulator.environment.propertyOf((frame :: unknown) :: Emulator.Instance, "Name")):toBe "Panel"
			expect(w.emulator.environment.childrenOf((w.root :: unknown) :: Emulator.Instance)):toEqual { frame }

			dispose()
			expect(w.emulator.environment.childrenOf((w.root :: unknown) :: Emulator.Instance)):toEqual {}
		end)

		it("detaches live children and accepts already detached or externally destroyed children", function()
			local emulator = Support.emulator()
			local host = ComposeRoblox.createHost(emulator.engine)
			local parent = (emulator.engine.new "Folder" :: unknown) :: Emulator.Instance
			local child = (emulator.engine.new "Frame" :: unknown) :: Emulator.Instance
			host.render.insertChild(parent, child)
			host.render.removeChild(parent, child)
			expect(child.Parent):toBe(nil)
			expect(emulator.environment.isAlive((child :: unknown) :: Emulator.Instance)):toBe(true)
			host.render.removeChild(parent, child)
			child:Destroy()
			expect(child.Parent):toBe(nil)
			host.render.removeChild(parent, child)
			expect(emulator.environment.childrenOf((parent :: unknown) :: Emulator.Instance)):toEqual {}
			parent:Destroy()
		end)

		it("disposes once after an external subtree reset and releases borrowed-node subscriptions", function()
			local w = world()
			local borrowed = (w.emulator.engine.new "TextButton" :: unknown) :: Emulator.Instance
			borrowed.Parent = (w.root :: unknown) :: Emulator.Instance
			local released, clicks = 0, 0
			local dispose, frame = w.runtime.mount(function()
				Compose.cleanup(function()
					released += 1
				end)
				w.runtime.connect(borrowed, "Activated", function()
					clicks += 1
				end)
				return w.create "Frame" { w.create "TextLabel" { Text = "owned" } }
			end, w.root)
			w.emulator.environment.fire((borrowed :: unknown) :: Emulator.Instance, "Activated")
			expect(clicks):toBe(1)
			local nativeFrame = frame :: Emulator.Instance
			nativeFrame:Destroy()
			expect(nativeFrame.Parent):toBe(nil)
			dispose()
			dispose()
			w.emulator.environment.fire((borrowed :: unknown) :: Emulator.Instance, "Activated")
			expect(clicks):toBe(1)
			expect(released):toBe(1)
			expect(w.emulator.environment.isAlive((borrowed :: unknown) :: Emulator.Instance)):toBe(true)
			expect(borrowed.Parent):toBe(w.root)
			expect(w.emulator.environment.liveConnections()):toBe(0)
			borrowed:Destroy()
		end)

		it("leaves the mount target alone", function()
			local w = world()
			local before = w.emulator.environment.liveObjects()
			local dispose = w.runtime.mount(function()
				return w.create "Frame" {}
			end, w.root)
			dispose()
			expect(w.emulator.environment.liveObjects()):toBe(before)
		end)

		it("destroys the whole subtree and leaks nothing", function()
			local w = world()
			local before = w.emulator.environment.liveObjects()
			local dispose = w.runtime.mount(function()
				return w.create "Frame" {
					w.create "TextLabel" { Text = "a" },
					w.create "Frame" { w.create "TextLabel" { Text = "b" } },
				}
			end, w.root)
			expect(w.emulator.environment.liveObjects()):toBe(before + 4)
			dispose()
			expect(w.emulator.environment.liveObjects()):toBe(before)
			expect(w.emulator.environment.liveConnections()):toBe(0)
		end)
	end)

	describe("properties and events", function()
		it("binds a property reactively", function()
			local w = world()
			local text = Compose.cell "first"
			local dispose, label = w.runtime.mount(function()
				return w.create "TextLabel" {
					Text = function(use)
						return use(text)
					end,
				}
			end, w.root)

			expect(w.emulator.environment.propertyOf((label :: unknown) :: Emulator.Instance, "Text")):toBe "first"
			text:set "second"
			w.runtime:settle()
			expect(w.emulator.environment.propertyOf((label :: unknown) :: Emulator.Instance, "Text")):toBe "second"
			dispose()
		end)

		it("discovers that a connectable member is an event", function()
			local w = world()
			local clicks = 0
			local dispose, button = w.runtime.mount(function()
				return w.create "TextButton" {
					Text = "Press",
					Activated = function()
						clicks += 1
					end,
				}
			end, w.root)

			expect(w.emulator.environment.propertyOf((button :: unknown) :: Emulator.Instance, "Activated")):toBeNil()
			w.emulator.environment.fire((button :: unknown) :: Emulator.Instance, "Activated")
			expect(clicks):toBe(1)

			dispose()
			expect(w.emulator.environment.liveConnections()):toBe(0)
		end)

		it("honours an explicit event key", function()
			local w = world()
			local touched = 0
			local dispose, part = w.runtime.mount(function()
				return w.create "Part" {
					[Compose.event "Touched"] = function()
						touched += 1
					end,
				}
			end, w.root)

			w.emulator.environment.fire((part :: unknown) :: Emulator.Instance, "Touched")
			expect(touched):toBe(1)
			dispose()
		end)

		it("raises a named diagnostic for an event that does not exist", function()
			local w = world()
			local ok, err: unknown = pcall(function()
				w.runtime.mount(function()
					return w.create "Frame" {
						[Compose.event "NoSuchEvent"] = function() end,
					}
				end, w.root)
			end)
			expect(ok):toBe(false)
			expect(tostring(err)):toContain "host/not-an-event"
		end)

		it("restores a class default when clearing a borrowed object's property", function()
			local w = world()
			local borrowed = (w.emulator.engine.new "Frame" :: unknown) :: Emulator.Instance
			expect(w.emulator.environment.propertyOf((borrowed :: unknown) :: Emulator.Instance, "LayoutOrder")):toBe(0)

			local dispose = w.runtime.mount(function()
				w.runtime.decorate(borrowed, { LayoutOrder = 42, Visible = false })
				return w.create "Frame" {}
			end, w.root)

			expect(w.emulator.environment.propertyOf((borrowed :: unknown) :: Emulator.Instance, "LayoutOrder")):toBe(
				42
			)
			expect(w.emulator.environment.propertyOf((borrowed :: unknown) :: Emulator.Instance, "Visible")):toBe(false)

			dispose()
			expect(w.emulator.environment.propertyOf((borrowed :: unknown) :: Emulator.Instance, "LayoutOrder")):toBe(0)
			expect(w.emulator.environment.propertyOf((borrowed :: unknown) :: Emulator.Instance, "Visible")):toBe(true)
		end)

		it("observes a property changed from outside Compose", function()
			local w = world()
			local emulator = w.emulator
			local frame = (emulator.engine.new "Frame" :: unknown) :: Emulator.Instance
			local host = ComposeRoblox.createHost(emulator.engine)
			local observation = host.observation :: Compose.Observation

			local seen = 0
			local unsubscribe = observation.observeProperty(frame, "Visible", function()
				seen += 1
			end)

			emulator.environment.poke((frame :: unknown) :: Emulator.Instance, "Visible", false)
			expect(seen):toBe(1)
			frame.Visible = false
			expect(seen):toBe(1)

			unsubscribe()
			unsubscribe()
			emulator.environment.poke((frame :: unknown) :: Emulator.Instance, "Visible", true)
			expect(seen):toBe(1)
		end)
	end)

	describe("attributes", function()
		it("writes and follows an attribute", function()
			local w = world()
			local tier = Compose.cell(1)
			local dispose, frame = w.runtime.mount(function()
				return w.create "Frame" { Attributes = { Tier = tier, Faction = "north" } }
			end, w.root)

			expect(w.emulator.environment.attributeOf((frame :: unknown) :: Emulator.Instance, "Tier")):toBe(1)
			expect(w.emulator.environment.attributeOf((frame :: unknown) :: Emulator.Instance, "Faction")):toBe "north"

			expect(w.emulator.environment.propertyOf((frame :: unknown) :: Emulator.Instance, "Tier")):toBe(nil)

			tier:set(4)
			w.runtime:settle()
			expect(w.emulator.environment.attributeOf((frame :: unknown) :: Emulator.Instance, "Tier")):toBe(4)
			dispose()
		end)

		it("clears an attribute when its value becomes nil", function()
			local w = world()
			local tier = Compose.cell(1 :: number?)
			local dispose, frame = w.runtime.mount(function()
				return w.create "Frame" { Attributes = { Tier = tier } }
			end, w.root)

			tier:set(nil)
			w.runtime:settle()
			expect(w.emulator.environment.attributeOf((frame :: unknown) :: Emulator.Instance, "Tier")):toBe(nil)
			dispose()
		end)

		it("reports a value the store will not hold rather than raising raw", function()
			local w = world()

			local ok, err: unknown = pcall(function()
				w.runtime.mount(function()
					return w.create "Frame" { Attributes = { Tier = { deep = true } } }
				end, w.root)
			end)
			expect(ok):toBe(false)

			local report = Compose.parseDiagnostic(tostring(err))
			expect(report ~= nil):toBe(true)
			expect((report :: Compose.Diagnostic).code):toBe "props/attribute-value"
			expect(#w.emulator.environment.childrenOf((w.root :: unknown) :: Emulator.Instance)):toBe(0)
		end)
	end)

	describe("structure", function()
		it("mounts a keyed collection and keeps identity across a reorder", function()
			local w = world()
			local rows = Compose.cell { "a", "b", "c" }
			local dispose, frame = w.runtime.mount(function()
				return w.create "Frame" {
					Compose.keyed {
						from = function(use: Compose.Use)
							return use(rows)
						end,
						render = function(value, index)
							return w.create "TextLabel" {
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
			end, w.root)

			local before = w.emulator.environment.childrenOf((frame :: unknown) :: Emulator.Instance)
			rows:set { "c", "a", "b" }
			w.runtime:settle()

			local after = w.emulator.environment.childrenOf((frame :: unknown) :: Emulator.Instance)
			expect(#after):toBe(3)
			local byText: { [string]: number } = {}
			for _, child in after do
				byText[tostring(w.emulator.environment.propertyOf((child :: unknown) :: Emulator.Instance, "Text"))] =
					w.emulator.environment.propertyOf((child :: unknown) :: Emulator.Instance, "LayoutOrder") :: number
			end
			expect(byText.c):toBe(1)
			expect(byText.a):toBe(2)
			expect(byText.b):toBe(3)

			for _, child in before do
				expect(after):toContain(child)
			end
			dispose()
		end)
	end)

	describe("animation", function()
		it("registers a codec for every datatype the engine supplies", function()
			local emulator = Support.emulator()
			expect(ComposeRoblox.animatableTypes(emulator.engine)):toEqual {
				"CFrame",
				"Color3",
				"UDim",
				"UDim2",
				"Vector2",
				"Vector3",
			}
		end)

		it("springs a UDim2 to its target on the heartbeat", function()
			local w = world()
			local UDim2 = w.emulator.engine.datatypes.UDim2 :: (
				number,
				number,
				number,
				number
			) -> { X: { Scale: number, Offset: number }, Y: { Scale: number, Offset: number } }
			local target = Compose.cell(UDim2(0, 0, 0, 0))

			local dispose, frame = w.runtime.mount(function()
				local smooth = w.runtime.spring(function(use)
					return use(target)
				end, { period = 0.2, damping = 1 })
				return w.create "Frame" {
					Size = function(use)
						return use(smooth)
					end,
				}
			end, w.root)

			target:set(UDim2(1, 100, 0.5, 20))
			w.runtime:settle()
			for _ = 1, 240 do
				w.emulator.environment.step(1 / 60)
			end

			local size =
				w.emulator.environment.propertyOf((frame :: unknown) :: Emulator.Instance, "Size") :: { X: { Scale: number, Offset: number }, Y: { Scale: number, Offset: number } }
			expect(size.X.Scale):toBeCloseTo(1, 1e-6)
			expect(size.X.Offset):toBe(100)
			expect(size.Y.Scale):toBeCloseTo(0.5, 1e-6)
			expect(size.Y.Offset):toBe(20)
			dispose()
		end)

		it("clamps a Color3 that a spring overshoots past", function()
			local w = world()
			local Color3 =
				w.emulator.engine.datatypes.Color3 :: (number, number, number) -> { R: number, G: number, B: number }
			local target = Compose.cell(Color3(0, 0, 0))

			local dispose, frame = w.runtime.mount(function()
				local smooth = w.runtime.spring(function(use)
					return use(target)
				end, { period = 0.2, damping = 0.25 })
				return w.create "Frame" {
					BackgroundColor3 = function(use)
						return use(smooth)
					end,
				}
			end, w.root)

			target:set(Color3(1, 1, 1))
			w.runtime:settle()
			local sawOvershoot = false
			for _ = 1, 200 do
				w.emulator.environment.step(1 / 60)
				local colour = w.emulator.environment.propertyOf(
					(frame :: unknown) :: Emulator.Instance,
					"BackgroundColor3"
				) :: { R: number, G: number, B: number }
				expect(colour.R):toBeLessThanOrEqual(1)
				expect(colour.R):toBeGreaterThanOrEqual(0)
				if colour.R == 1 then
					sawOvershoot = true
				end
			end
			expect(sawOvershoot):toBe(true)
			dispose()
		end)

		it("disconnects from the heartbeat once settled and after disposal", function()
			local w = world()
			local target = Compose.cell(0)
			local dispose = w.runtime.mount(function()
				local smooth = w.runtime.spring(function(use)
					return use(target)
				end, { period = 0.1 })
				return w.create "Frame" {
					LayoutOrder = function(use)
						return math.round(use(smooth))
					end,
				}
			end, w.root)

			local idle = w.emulator.environment.liveConnections()
			target:set(10)
			w.runtime:settle()
			expect(w.emulator.environment.liveConnections()):toBe(idle + 1)

			for _ = 1, 200 do
				w.emulator.environment.step(1 / 60)
			end
			expect(w.emulator.environment.liveConnections()):toBe(idle)

			dispose()
			expect(w.emulator.environment.liveConnections()):toBe(0)
		end)

		it("round-trips a CFrame through the quaternion codec", function()
			local Codecs = require "../../src/roblox/codecs"

			local rotation = { 0, 0, 1, 0, 1, 0, -1, 0, 0 }
			local x, y, z, wComponent = Codecs.quaternionFromRotation(rotation)
			local rebuilt = Codecs.rotationFromQuaternion(x, y, z, wComponent)
			for index = 1, 9 do
				expect(rebuilt[index]):toBeCloseTo(rotation[index], 1e-9)
			end
		end)
	end)

	describe("cleanup", function()
		it("disconnects an engine connection", function()
			local w = world()
			local cleanup = ComposeRoblox.createCleanup(w.emulator.engine.typeName)
			local button = (w.emulator.engine.new "TextButton" :: unknown) :: Emulator.Instance
			local dispose = w.runtime.mount(function()
				local connection = ((button :: Emulator.Instance).Activated :: Emulator.Signal<()>):Connect(
					function() end
				)
				cleanup(connection)
				return w.create "Frame" {}
			end, w.root)

			expect(w.emulator.environment.liveConnections()):toBe(1)
			dispose()
			expect(w.emulator.environment.liveConnections()):toBe(0)
		end)

		it("destroys an engine object handed to it", function()
			local w = world()
			local cleanup = ComposeRoblox.createCleanup(w.emulator.engine.typeName)
			local extra = (w.emulator.engine.new "Folder" :: unknown) :: Emulator.Instance
			local before = w.emulator.environment.liveObjects()
			local dispose = w.runtime.mount(function()
				cleanup(extra)
				return w.create "Frame" {}
			end, w.root)
			dispose()
			expect(w.emulator.environment.liveObjects()):toBe(before - 1)
		end)
	end)
end)

return nil
