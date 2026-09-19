--!strict

local Compose = require "../../src/core"
local ComposeRoblox = require "../../src/roblox"
local Emulator = require "../../src/test-host/roblox"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function fresh(): Emulator.Emulator
	Compose.__resetForTests()
	ComposeRoblox.__resetForTests()
	return Emulator.create()
end

local function operations(emulator: Emulator.Emulator): { string }
	local names: { string } = {}
	for _, entry in emulator.log() do
		table.insert(names, entry.operation)
	end
	return names
end

describe("roblox emulator", function()
	describe("instance shape", function()
		it("gives a node dot-accessible properties and a parent", function()
			local emulator = fresh()
			local frame = emulator.createInstance("Frame", { Name = "Panel", Parent = emulator.root })

			expect(frame.Name):toBe "Panel"
			expect(frame.ClassName):toBe "Frame"
			expect(frame.Parent):toBe(emulator.root)
			expect(frame.Visible):toBe(true)
			expect(emulator.childrenOf(emulator.root)):toEqual { frame }
		end)

		it("parents the children in the array part before it parents itself", function()
			local emulator = fresh()
			local inner = emulator.createInstance "TextLabel"
			local outer = emulator.createInstance("Frame", { inner, Name = "Outer", Parent = emulator.root })

			expect(emulator.childrenOf(outer)):toEqual { inner }
			expect(inner.Parent):toBe(outer)
			expect(outer.Parent):toBe(emulator.root)
		end)

		it("answers IsA along the class chain, and no further", function()
			local emulator = fresh()
			local label = emulator.createInstance "TextLabel"

			expect(label:IsA "TextLabel"):toBe(true)
			expect(label:IsA "GuiObject"):toBe(true)
			expect(label:IsA "Instance"):toBe(true)
			expect(label:IsA "BasePart"):toBe(false)
		end)

		it("finds a child by name, by class, and by descent", function()
			local emulator = fresh()
			local outer = emulator.createInstance("Frame", { Parent = emulator.root })
			local middle = emulator.createInstance("Folder", { Name = "Middle", Parent = outer })
			local deep = emulator.createInstance("TextLabel", { Name = "Deep", Parent = middle })

			expect(outer:FindFirstChild "Middle"):toBe(middle)
			expect(outer:FindFirstChild "Deep"):toBe(nil)
			expect(outer:FindFirstChild("Deep", true)):toBe(deep)
			expect(outer:FindFirstChildOfClass "Folder"):toBe(middle)
			expect(#outer:GetDescendants()):toBe(2)

			expect(deep:IsDescendantOf(outer)):toBe(true)
			expect(outer:IsAncestorOf(deep)):toBe(true)
			expect(outer:IsDescendantOf(deep)):toBe(false)
		end)

		it("stores attributes and refuses a value the store will not hold", function()
			local emulator = fresh()
			local frame = emulator.createInstance "Frame"

			frame:SetAttribute("Tier", 3)
			frame:SetAttribute("Faction", "north")
			expect(frame:GetAttribute "Tier"):toBe(3)
			expect(emulator.attributeOf(frame, "Faction")):toBe "north"
			expect(frame:GetAttributes()):toEqual { Tier = 3, Faction = "north" }

			expect(function()
				frame:SetAttribute("Tier", { deep = true })
			end):toThrow "cannot hold a value of type"
		end)

		it("destroys a subtree, detaches it, and refuses a later write", function()
			local emulator = fresh()
			local before = emulator.liveObjects()
			local outer = emulator.createInstance("Frame", { Parent = emulator.root })
			emulator.createInstance("TextLabel", { Parent = outer })
			expect(emulator.liveObjects()):toBe(before + 2)

			outer:Destroy()
			expect(emulator.liveObjects()):toBe(before)
			expect(emulator.isAlive(outer)):toBe(false)
			expect(emulator.childrenOf(emulator.root)):toEqual {}
			expect(function()
				outer.Name = "late"
			end):toThrow "destroyed Instance"
		end)
	end)

	describe("signals", function()
		it("connects, fires and disconnects a class event", function()
			local emulator = fresh()
			local button = emulator.createInstance "TextButton"
			local clicks = 0

			local connection = button.Activated:Connect(function()
				clicks += 1
			end)
			expect(emulator.liveConnections()):toBe(1)

			button.Activated:Fire()
			emulator.fire(button, "Activated")
			expect(clicks):toBe(2)

			connection:Disconnect()
			connection:Disconnect()
			expect(emulator.liveConnections()):toBe(0)
			emulator.fire(button, "Activated")
			expect(clicks):toBe(2)
		end)

		it("reports an event the class does not have", function()
			local emulator = fresh()
			local folder = emulator.createInstance "Folder"
			expect(function()
				emulator.fire(folder, "Activated")
			end):toThrow "has no event"
		end)

		it("fires ChildAdded, ChildRemoved and Destroying", function()
			local emulator = fresh()
			local parent = emulator.createInstance "Folder"
			local seen: { string } = {}

			parent.ChildAdded:Connect(function()
				table.insert(seen, "added")
			end)
			parent.ChildRemoved:Connect(function()
				table.insert(seen, "removed")
			end)
			parent.Destroying:Connect(function()
				table.insert(seen, "destroying")
			end)

			local child = emulator.createInstance("Frame", { Parent = parent })
			child.Parent = nil
			parent:Destroy()

			expect(seen):toEqual { "added", "removed", "destroying" }
		end)

		it("follows a property and an attribute with their changed signals", function()
			local emulator = fresh()
			local frame = emulator.createInstance "Frame"
			local properties, attributes = 0, 0

			frame:GetPropertyChangedSignal("Visible"):Connect(function()
				properties += 1
			end)
			frame:GetAttributeChangedSignal("Tier"):Connect(function()
				attributes += 1
			end)

			frame.Visible = false
			frame.Visible = false
			frame:SetAttribute("Tier", 1)
			frame:SetAttribute("Tier", 1)

			expect(properties):toBe(1)
			expect(attributes):toBe(1)
		end)

		it("hands out a standalone signal with the same shape", function()
			local emulator = fresh()
			local signal = emulator.newSignal()
			local heard: { any } = {}

			local connection = signal:Connect(function(value: any)
				table.insert(heard, value)
			end)
			signal:Fire "first"
			connection:Disconnect()
			signal:Fire "second"

			expect(heard):toEqual { "first" }
		end)

		it("refuses to assign over an event", function()
			local emulator = fresh()
			local button = emulator.createInstance "TextButton"
			expect(function()
				button.Activated = 1
			end):toThrow "cannot be assigned"
		end)
	end)

	describe("classes", function()
		it("refuses a class it does not know, and an abstract one", function()
			local emulator = fresh()
			expect(function()
				emulator.createInstance "NoSuchClass"
			end):toThrow "Unable to create an Instance"
			expect(function()
				emulator.createInstance "GuiObject"
			end):toThrow "Unable to create an Instance"
		end)

		it("takes a class the consumer defines, with inherited defaults and events", function()
			local emulator = fresh()
			emulator.defineClass("ViewportFrame", {
				super = "GuiObject",
				properties = { CurrentCamera = false },
				events = { "Rendered" },
			})

			local viewport = emulator.createInstance "ViewportFrame"
			expect(viewport.ClassName):toBe "ViewportFrame"
			expect(viewport.Name):toBe "ViewportFrame"
			expect(viewport.LayoutOrder):toBe(0)
			expect(viewport:IsA "GuiObject"):toBe(true)

			local rendered = 0
			viewport.Rendered:Connect(function()
				rendered += 1
			end)
			emulator.fire(viewport, "Rendered")
			expect(rendered):toBe(1)
		end)

		it("refuses a class whose super is not defined", function()
			local emulator = fresh()
			expect(function()
				emulator.defineClass("Late", { super = "NotYet" })
			end):toThrow "is not defined yet"
		end)

		it("loads an animation track that plays and stops", function()
			local emulator = fresh()
			local animator = emulator.createInstance "Animator"
			local animation = emulator.createInstance "Animation"

			local track = animator:LoadAnimation(animation)
			expect(track.ClassName):toBe "AnimationTrack"
			expect(track.Animation):toBe(animation)
			expect(track.IsPlaying):toBe(false)

			local stops = 0
			track.Stopped:Connect(function()
				stops += 1
			end)

			track:Play(0.1, 1, 2)
			expect(track.IsPlaying):toBe(true)
			expect(track.Speed):toBe(2)

			track:Stop()
			track:Stop()
			expect(track.IsPlaying):toBe(false)
			expect(stops):toBe(1)
		end)
	end)

	describe("the host", function()
		it("is the adapter's own host, and cannot order children", function()
			local emulator = fresh()
			expect(emulator.host.name):toBe "roblox"
			expect(emulator.host.render):toBe(emulator.render)
			expect(emulator.render.moveChild):toBeNil()
			expect(Compose.createRuntime(emulator.host)):toBeOk()
		end)

		it("logs the render verbs a mount and a disposal issue", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.host)
			local Frame = runtime.create "Frame"

			emulator.clearLog()
			local dispose, frame = runtime.mount(function()
				return Frame { Name = "Panel", Attributes = { Tier = 2 } }
			end, emulator.root)

			expect(emulator.propertyOf(frame, "Name")):toBe "Panel"
			expect(emulator.attributeOf(frame, "Tier")):toBe(2)
			expect(operations(emulator)):toContain "createNode"
			expect(operations(emulator)):toContain "setProperty"
			expect(operations(emulator)):toContain "setAttribute"
			expect(operations(emulator)):toContain "insertChild"

			local entry = emulator.log()[1]
			expect(entry.operation):toBe "createNode"
			expect(entry.className):toBe "Frame"

			emulator.clearLog()
			dispose()
			expect(operations(emulator)):toContain "destroyNode"
			expect(emulator.childrenOf(emulator.root)):toEqual {}
		end)

		it("drives the frame loop from step", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.host)
			local Frame = runtime.create "Frame"
			local target = Compose.cell(0)

			local dispose, frame = runtime.mount(function()
				local smooth = runtime.spring(function(use)
					return use(target)
				end, { period = 0.1 })
				return Frame {
					LayoutOrder = function(use)
						return math.round(use(smooth))
					end,
				}
			end, emulator.root)

			target:set(10)
			runtime:settle()
			for _ = 1, 200 do
				emulator.step(1 / 60)
			end
			expect(emulator.propertyOf(frame, "LayoutOrder")):toBe(10)
			expect(emulator.now()):toBeCloseTo(200 / 60, 1e-9)

			dispose()
			expect(emulator.liveConnections()):toBe(0)
		end)
	end)

	describe("failure injection", function()
		it("unwinds a failed node creation and leaves nothing behind", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.host)
			local Frame = runtime.create "Frame"
			local before = emulator.liveObjects()

			emulator.failNext "createNode"
			local ok, err: any = pcall(function()
				runtime.mount(function()
					return Frame {}
				end, emulator.root)
			end)

			expect(ok):toBe(false)
			expect(tostring(err)):toContain "injected failure in createNode"
			expect(emulator.liveObjects()):toBe(before)
			expect(emulator.childrenOf(emulator.root)):toEqual {}
		end)

		it("unwinds a failed property write and destroys the node it was writing to", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.host)
			local Frame = runtime.create "Frame"
			local before = emulator.liveObjects()

			emulator.failNext "setProperty"
			local ok = pcall(function()
				runtime.mount(function()
					return Frame { Name = "Doomed" }
				end, emulator.root)
			end)

			expect(ok):toBe(false)
			expect(emulator.liveObjects()):toBe(before)
			expect(emulator.childrenOf(emulator.root)):toEqual {}
		end)

		it("refuses an attribute on demand, and reports it by name", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.host)
			local Frame = runtime.create "Frame"

			emulator.failNext "setAttribute"
			local ok, err: any = pcall(function()
				runtime.mount(function()
					return Frame { Attributes = { Tier = 1 } }
				end, emulator.root)
			end)

			expect(ok):toBe(false)
			local report = Compose.parseDiagnostic(tostring(err))
			expect(report ~= nil):toBe(true)
			expect((report :: any).code):toBe "props/attribute-value"
			expect(emulator.childrenOf(emulator.root)):toEqual {}
		end)

		it("counts down the injected failures and then stops", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.host)
			local Frame = runtime.create "Frame"

			emulator.failNext("createNode", 2)
			for _ = 1, 2 do
				expect(pcall(function()
					runtime.mount(function()
						return Frame {}
					end, emulator.root)
				end)):toBe(false)
			end

			local dispose = runtime.mount(function()
				return Frame {}
			end, emulator.root)
			expect(#emulator.childrenOf(emulator.root)):toBe(1)
			dispose()
		end)

		it("clears an injection that was never spent", function()
			local emulator = fresh()
			local runtime = Compose.createRuntime(emulator.host)
			local Frame = runtime.create "Frame"

			emulator.failNext "insertChild"
			emulator.clearFailures()
			local dispose = runtime.mount(function()
				return Frame {}
			end, emulator.root)
			expect(#emulator.childrenOf(emulator.root)):toBe(1)
			dispose()
		end)
	end)
end)

return nil
