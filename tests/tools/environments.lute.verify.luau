--!strict

local Test = require "../harness"
local Denylist = require "../../.lute/dependencies/verify/src/checks/denylist"
local Policy = require "../../tools/checks-policy"
local Lute = require "../../.lute/dependencies/verify/src/lute"
local Dynamic = require "../../src/core/dynamic"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function forbidEnvironment(path: string, source: string): string
	return if path == "src/roblox/ambient.luau"
		then "local getfenv = function() error('environment access is forbidden') end\n" .. source
		else source
end

describe("production environments", function()
	it("rejects calls and aliases of environment access", function()
		for _, source in { "return getfenv(0)", "local change = setfenv; return change" } do
			expect(#Denylist.scan("src/roblox/ambient.luau", source, Policy.environments)):toBe(1)
		end
		expect(Denylist.scan("src/core/init.luau", "local getfenvFree = game; return getfenvFree", Policy.environments)):toEqual {}
	end)
	it("keeps injection available when Roblox globals are absent", function()
		local loader = Lute.loader.new {
			transform = forbidEnvironment,
		}
		local ambient = loader.require "src/roblox/ambient.luau"
		expect(function()
			Dynamic.invoke(Dynamic.read(ambient, "ambient"))
		end):toThrow "the Roblox engine is not present"
		expect(function()
			Dynamic.invoke(Dynamic.read(ambient, "service"), "Players")
		end):toThrow "inject the requested service"
		expect(Dynamic.invoke(Dynamic.read(ambient, "cancelThread"), coroutine.create(function() end))):toBe(false)
	end)
	it("reads services and cancellation from direct globals", function()
		local marker = {}
		local cancelled: thread? = nil
		local loader = Lute.loader.new {
			transform = forbidEnvironment,
			globals = {
				game = {
					GetService = function(_self: unknown, name: string): unknown
						expect(name):toBe "Players"
						return marker
					end,
				},
				task = {
					cancel = function(target: thread)
						cancelled = target
					end,
				},
			},
		}
		local ambient = loader.require "src/roblox/ambient.luau"
		expect(Dynamic.invoke(Dynamic.read(ambient, "service"), "Players")):toBe(marker)
		local target = coroutine.create(function() end)
		expect(Dynamic.invoke(Dynamic.read(ambient, "cancelThread"), target)):toBe(true)
		expect(cancelled):toBe(target)
	end)
	it("builds the ambient engine and design values from direct globals", function()
		local marker = {}
		local client = true
		local disconnected = 0
		local signal = {
			Connect = function(_self: unknown, callback: (number) -> ())
				callback(0.25)
				return {
					Disconnect = function()
						disconnected += 1
					end,
				}
			end,
		}
		local serverSignal = {
			Connect = function(_self: unknown, callback: (number) -> ())
				callback(0.5)
				return {
					Disconnect = function()
						disconnected += 1
					end,
				}
			end,
		}
		local loader = Lute.loader.new {
			transform = forbidEnvironment,
			globals = {
				game = {
					GetService = function(_self: unknown, name: string)
						expect(name):toBe "RunService"
						return {
							IsClient = function()
								return client
							end,
							PreRender = signal,
							Heartbeat = serverSignal,
						}
					end,
				},
				Instance = {
					new = function(name: string)
						expect(name):toBe "Frame"
						return marker
					end,
				},
				Vector2 = {
					new = function(x: number, y: number)
						return { X = x, Y = y }
					end,
				},
			},
		}
		local ambient = loader.require "src/roblox/ambient.luau"
		local engine = Dynamic.invoke(Dynamic.read(ambient, "ambient"))
		expect(Dynamic.invoke(Dynamic.read(engine, "new"), "Frame")):toBe(marker)
		local delta = 0
		local heartbeat = Dynamic.read(engine, "heartbeat")
		local connection = Dynamic.invoke(Dynamic.read(heartbeat, "Connect"), heartbeat, function(value: number)
			delta = value
		end)
		expect(delta):toBe(0.25)
		Dynamic.invoke(Dynamic.read(connection, "Disconnect"), connection)
		expect(disconnected):toBe(1)
		local design = Dynamic.invoke(Dynamic.read(ambient, "designEnvironment"), Dynamic.read)
		local vector = Dynamic.invoke(Dynamic.read(Dynamic.read(design, "values"), "vector2"), 3, 4)
		expect(vector):toEqual { X = 3, Y = 4 }
		client = false
		local server = Dynamic.invoke(Dynamic.read(ambient, "ambient"))
		local serverHeartbeat = Dynamic.read(server, "heartbeat")
		local serverConnection = Dynamic.invoke(
			Dynamic.read(serverHeartbeat, "Connect"),
			serverHeartbeat,
			function(value: number)
				delta = value
			end
		)
		expect(delta):toBe(0.5)
		Dynamic.invoke(Dynamic.read(serverConnection, "Disconnect"), serverConnection)
		expect(disconnected):toBe(2)
	end)
end)

return nil
