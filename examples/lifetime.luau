--!strict

local Compose = require "../src/core"
local TestHost = require "../src/test-host"

local function run(): string
	local host = TestHost.create()
	local runtime = Compose.createRuntime(host.host)
	local create = runtime.create
	local cell = Compose.cell
	local createOwner = Compose.createOwner
	local inspect = Compose.inspect
	local outstandingMounts = Compose.outstandingMounts

	local Frame = create "Frame"

	local session = createOwner()

	local health = cell(100)
	local opened = 0

	inspect.start()
	inspect.label(session, "session")

	local function openPanel(): () -> ()
		opened += 1
		local dispose = runtime.mount(function()
			session.watch(function(use)
				local _ = use(health)
			end)

			return Frame {
				Name = ("Panel%d"):format(opened),
				Text = function(use): string
					return ("hp %d"):format(use(health))
				end,
			}
		end, host.root)
		return dispose
	end

	for _ = 1, 3 do
		openPanel()()
	end

	assert(outstandingMounts() == 0, "the panels were not disposed")

	local report = inspect.snapshot()
	local held: Compose.InspectOwner? = nil
	for _, entry in report.detached do
		if entry.label == "session" then
			held = entry
		end
	end
	local sessionReport = held :: Compose.InspectOwner

	assert(sessionReport.watches == 3, "expected one leaked watch per panel opened")
	for _, entry in report.mounts do
		assert(entry.disposed, "a panel was still standing")
		assert(entry.holding == 0, "a disposed panel is still holding something")
	end

	session.dispose()

	local text = inspect.format(report)
	inspect.stop()

	assert(
		string.find(text, "owners held outside any mount", 1, true) ~= nil,
		"the report should name where the leak is"
	)
	assert(string.find(text, "must not appear") == nil, "no application value belongs in a report")

	return ("session held %d watch%s after %d panel%s closed"):format(
		sessionReport.watches,
		if sessionReport.watches == 1 then "" else "es",
		opened,
		if opened == 1 then "" else "s"
	)
end

return {
	name = "lifetime",
	what = "finding the subscription that outlived the screen that made it",
	expected = "session held 3 watches after 3 panels closed",
	run = run,
}
