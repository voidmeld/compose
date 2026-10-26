--!strict

local Upstream = require "../harness/upstream"
local Environment = require "../cost-model"
local Types = require "./types"
local State = require "./state"
local React = require "./react"

type Producer<T> = {
	getState: (Producer<T>) -> T,
	setState: (Producer<T>, T) -> (),
	subscribe: (Producer<T>, (T) -> ()) -> () -> (),
	flush: (Producer<T>) -> (),
	destroy: (Producer<T>) -> (),
}
type Reflex = { createProducer: <T>(T, {}) -> Producer<T> }

local function create(environment: Environment.Environment): Types.Driver
	local reflex: Reflex = Upstream.create(environment).load ".lute/dependencies/reflex/src"
	local flushers: { [() -> ()]: boolean } = {}
	local state: State.State = {
		value = function<T>(initial: T, emit: (T) -> ()): State.Cell<T>
			local producer = reflex.createProducer(initial, {})
			local disconnect = producer:subscribe(emit)
			local function flush()
				producer:flush()
			end
			flushers[flush] = true
			return {
				read = function(): T
					return producer:getState()
				end,
				write = function(next: T)
					producer:setState(next)
				end,
				release = function()
					flushers[flush] = nil
					disconnect()
					producer:destroy()
				end,
			}
		end,
		batch = function(run: () -> ())
			run()
			for flush in flushers do
				flush()
			end
		end,
	}
	return React.create(environment, state)
end

return { create = create }
