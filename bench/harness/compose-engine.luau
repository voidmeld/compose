--!strict

local ComposeRoblox = require "../../src/roblox"
local Environment = require "../environment"

local function engineFor(environment: Environment.Environment): ComposeRoblox.Engine
	local globals = environment.globals
	local instances = globals.Instance
	local runService = globals.game:GetService "RunService"

	return {
		new = function(className: string): any
			return instances.new(className)
		end,
		heartbeat = runService.Heartbeat,
		clock = globals.os.clock,
		typeName = globals.typeof,
		destroy = function(object: any)
			object:Destroy()
		end,
		propertyChanged = function(object: any, property: string): any
			return object:GetPropertyChangedSignal(property)
		end,
		datatypes = {
			Vector2 = globals.Vector2.new,
			Vector3 = globals.Vector3.new,
			Color3 = globals.Color3.new,
			UDim = globals.UDim.new,
			UDim2 = globals.UDim2.new,
			CFrame = function(position: any, _rotation: { number }): any
				return globals.CFrame.new(position)
			end,
		},
		readCFrame = function(value: any): (number, number, number, { number })
			return value.Position.X, value.Position.Y, value.Position.Z, table.clone(value.Rotation)
		end,
	}
end

return {
	engineFor = engineFor,
}
