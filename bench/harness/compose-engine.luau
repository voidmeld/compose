--!strict

local ComposeRoblox = require "../../src/roblox"
local Environment = require "../cost-model"
local Engine = require "../../src/roblox/engine"

local function engineFor(environment: Environment.Environment): ComposeRoblox.Engine
	local globals = environment.globals
	local instances = globals.Instance
	local runService = (globals.game:GetService "RunService") :: Environment.RunService

	return {
		new = function(className: string)
			return (instances.new(className) :: unknown) :: Engine.Instance
		end,
		heartbeat = (runService.Heartbeat :: unknown) :: ComposeRoblox.Signal<number>,
		clock = globals.os.clock,
		typeName = globals.typeof,
		destroy = function(object: unknown)
			(object :: Environment.Instance):Destroy()
		end,
		propertyChanged = function(object: unknown, property: string)
			return (
				(object :: Environment.Instance):GetPropertyChangedSignal(property) :: unknown
			) :: ComposeRoblox.Signal<()>
		end,
		datatypes = {
			Vector2 = globals.Vector2.new,
			Vector3 = globals.Vector3.new,
			Color3 = globals.Color3.new,
			UDim = globals.UDim.new,
			UDim2 = globals.UDim2.new,
			CFrame = function(position: Engine.Vector3, _rotation: { number })
				return (
					globals.CFrame.new((position :: unknown) :: Environment.Vector3Value) :: unknown
				) :: Engine.CFrame
			end,
		},
		readCFrame = function(value: Engine.CFrame): (number, number, number, { number })
			local frame = (value :: unknown) :: Environment.CFrameValue
			return frame.Position.X, frame.Position.Y, frame.Position.Z, table.clone(frame.Rotation)
		end,
	}
end

return {
	engineFor = engineFor,
}
