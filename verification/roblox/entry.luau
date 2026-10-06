--!strict
--!nolint DeprecatedApi

local Checks = require "./checks"
local ComposeRoblox = require "../../src/roblox"
local Roblox = require "../../.lute/dependencies/verify/src/roblox"
local Verify = require "../../.lute/dependencies/verify/src/core"

local ENGINE = "roblox-engine"
local TIMEOUT_SECONDS = 60

local function named(check: Checks.Check): Verify.NamedCase
	return {
		id = check.id,
		name = check.name,
		requires = { ENGINE },
		timeoutSeconds = TIMEOUT_SECONDS,
		run = function(context: Verify.Context)
			local container = Instance.new "Folder"
			container.Name = "ComposeVerification"
			container.Parent = workspace
			context:defer(function()
				container:Destroy()
			end)
			local detail = check.run(container)
			context:step(detail, function() end)
		end,
	}
end

local factory: Roblox.CaseEntryFactory = function(host)
	local cases: { Verify.NamedCase } = {}
	for _, check in Checks do
		table.insert(cases, named(check))
	end
	local environment: { [string]: string } = { runtime = host :: string }
	local capabilities: { string } = {}
	if host ~= "simulator" then
		local engine = Roblox.experienceHost.nativeEngine()
		environment.context = engine.context
		environment.placeId = tostring(engine.placeId)
		environment.gameId = tostring(engine.gameId)
		environment.version = engine.version
		environment.studio = tostring(engine.studio)
		environment.animatableTypes = table.concat(ComposeRoblox.animatableTypes(), ", ")
		table.insert(capabilities, ENGINE)
	end
	return {
		cases = cases,
		now = os.clock,
		options = {
			executor = host,
			capabilities = capabilities,
			environment = environment,
		},
	}
end

return factory
