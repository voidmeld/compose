--!strict

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Emulator = require "../../src/test-host/roblox"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

type World = {
	emulator: Emulator.Emulator,
	runtime: Compose.Runtime,
	create: (kind: string) -> (props: Compose.Props) -> Compose.Node,
	root: Compose.Node,
}

local function world(): World
	Compose.__resetForTests()
	ComposeRoblox.__resetForTests()
	local emulator = Emulator.create()
	local runtime = ComposeRoblox.createRuntime(emulator.engine)
	return {
		emulator = emulator,
		runtime = runtime,
		create = runtime.create,
		root = emulator.engine.new "Folder",
	}
end

describe("roblox adapter", function()
	describe("the host contract", function()
		it("satisfies the protocol Compose validates", function()
			local emulator = Emulator.create()
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

			expect(w.emulator.propertyOf(frame, "Name")):toBe "Panel"
			expect(w.emulator.childrenOf(w.root)):toEqual { frame }

			dispose()
			expect(w.emulator.childrenOf(w.root)):toEqual {}
		end)

		it("leaves the mount target alone", function()
			local w = world()
			local before = w.emulator.liveObjects()
			local dispose = w.runtime.mount(function()
				return w.create "Frame" {}
			end, w.root)
			dispose()
			expect(w.emulator.liveObjects()):toBe(before)
		end)

		it("destroys the whole subtree and leaks nothing", function()
			local w = world()
			local before = w.emulator.liveObjects()
			local dispose = w.runtime.mount(function()
				return w.create "Frame" {
					w.create "TextLabel" { Text = "a" },
					w.create "Frame" { w.create "TextLabel" { Text = "b" } },
				}
			end, w.root)
			expect(w.emulator.liveObjects()):toBe(before + 4)
			dispose()
			expect(w.emulator.liveObjects()):toBe(before)
			expect(w.emulator.liveConnections()):toBe(0)
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

			expect(w.emulator.propertyOf(label, "Text")):toBe "first"
			text:set "second"
			w.runtime:settle()
			expect(w.emulator.propertyOf(label, "Text")):toBe "second"
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

			expect(w.emulator.propertyOf(button, "Activated")):toBeNil()
			w.emulator.fire(button, "Activated")
			expect(clicks):toBe(1)

			dispose()
			expect(w.emulator.liveConnections()):toBe(0)
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

			w.emulator.fire(part, "Touched")
			expect(touched):toBe(1)
			dispose()
		end)

		it("raises a named diagnostic for an event that does not exist", function()
			local w = world()
			local ok, err: any = pcall(function()
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
			local borrowed = w.emulator.engine.new "Frame"
			expect(w.emulator.propertyOf(borrowed, "LayoutOrder")):toBe(0)

			local dispose = w.runtime.mount(function()
				w.runtime.decorate(borrowed, { LayoutOrder = 42, Visible = false })
				return w.create "Frame" {}
			end, w.root)

			expect(w.emulator.propertyOf(borrowed, "LayoutOrder")):toBe(42)
			expect(w.emulator.propertyOf(borrowed, "Visible")):toBe(false)

			dispose()
			expect(w.emulator.propertyOf(borrowed, "LayoutOrder")):toBe(0)
			expect(w.emulator.propertyOf(borrowed, "Visible")):toBe(true)
		end)

		it("observes a property changed from outside Compose", function()
			local w = world()
			local emulator = w.emulator
			local frame = emulator.engine.new "Frame"
			local host = ComposeRoblox.createHost(emulator.engine)
			local observation = host.observation :: Compose.Observation

			local seen = 0
			local unsubscribe = observation.observeProperty(frame, "Visible", function()
				seen += 1
			end)

			emulator.poke(frame, "Visible", false)
			expect(seen):toBe(1)
			emulator.poke(frame, "Visible", false)
			expect(seen):toBe(1)

			unsubscribe()
			unsubscribe()
			emulator.poke(frame, "Visible", true)
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

			expect(w.emulator.attributeOf(frame, "Tier")):toBe(1)
			expect(w.emulator.attributeOf(frame, "Faction")):toBe "north"

			expect(w.emulator.propertyOf(frame, "Tier")):toBe(nil)

			tier:set(4)
			w.runtime:settle()
			expect(w.emulator.attributeOf(frame, "Tier")):toBe(4)
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
			expect(w.emulator.attributeOf(frame, "Tier")):toBe(nil)
			dispose()
		end)

		it("reports a value the store will not hold rather than raising raw", function()
			local w = world()

			local ok, err: any = pcall(function()
				w.runtime.mount(function()
					return w.create "Frame" { Attributes = { Tier = { deep = true } } }
				end, w.root)
			end)
			expect(ok):toBe(false)

			local report = Compose.parseDiagnostic(tostring(err))
			expect(report ~= nil):toBe(true)
			expect((report :: any).code):toBe "props/attribute-value"
			expect(#w.emulator.childrenOf(w.root)):toBe(0)
		end)
	end)

	describe("structure", function()
		it("mounts a keyed collection and keeps identity across a reorder", function()
			local w = world()
			local rows = Compose.cell { "a", "b", "c" }
			local dispose, frame = w.runtime.mount(function()
				return w.create "Frame" {
					Compose.keyed {
						from = function(use)
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

			local before = w.emulator.childrenOf(frame)
			rows:set { "c", "a", "b" }
			w.runtime:settle()

			local after = w.emulator.childrenOf(frame)
			expect(#after):toBe(3)
			local byText: { [string]: number } = {}
			for _, child in after do
				byText[tostring(w.emulator.propertyOf(child, "Text"))] = w.emulator.propertyOf(child, "LayoutOrder")
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
			local emulator = Emulator.create()
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
			local UDim2 = w.emulator.engine.datatypes.UDim2 :: (number, number, number, number) -> any
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
				w.emulator.step(1 / 60)
			end

			local size = w.emulator.propertyOf(frame, "Size")
			expect(size.X.Scale):toBeCloseTo(1, 1e-6)
			expect(size.X.Offset):toBe(100)
			expect(size.Y.Scale):toBeCloseTo(0.5, 1e-6)
			expect(size.Y.Offset):toBe(20)
			dispose()
		end)

		it("clamps a Color3 that a spring overshoots past", function()
			local w = world()
			local Color3 = w.emulator.engine.datatypes.Color3 :: (number, number, number) -> any
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
				w.emulator.step(1 / 60)
				local colour = w.emulator.propertyOf(frame, "BackgroundColor3")
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

			local idle = w.emulator.liveConnections()
			target:set(10)
			w.runtime:settle()
			expect(w.emulator.liveConnections()):toBe(idle + 1)

			for _ = 1, 200 do
				w.emulator.step(1 / 60)
			end
			expect(w.emulator.liveConnections()):toBe(idle)

			dispose()
			expect(w.emulator.liveConnections()):toBe(0)
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
			local button = w.emulator.engine.new "TextButton"
			local dispose = w.runtime.mount(function()
				local connection = (button :: any).Activated:Connect(function() end)
				cleanup(connection)
				return w.create "Frame" {}
			end, w.root)

			expect(w.emulator.liveConnections()):toBe(1)
			dispose()
			expect(w.emulator.liveConnections()):toBe(0)
		end)

		it("destroys an engine object handed to it", function()
			local w = world()
			local cleanup = ComposeRoblox.createCleanup(w.emulator.engine.typeName)
			local extra = w.emulator.engine.new "Folder"
			local before = w.emulator.liveObjects()
			local dispose = w.runtime.mount(function()
				cleanup(extra)
				return w.create "Frame" {}
			end, w.root)
			dispose()
			expect(w.emulator.liveObjects()):toBe(before - 1)
		end)
	end)
end)

return nil
