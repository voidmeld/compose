--!strict
local Denylist = require "@verify/src/checks/denylist"
local Walk = require "@verify/src/checks/walk"
local Policy = require "./checks-policy"
local Finish = require "./lib/check-result"

local findings: { string } = {}
for _, file in Walk.files("src", { ".luau", ".lua" }) do
	for _, finding in Denylist.scan(file.path, file.contents, Policy.environments) do
		table.insert(findings, finding)
	end
end
Finish("check-environments", findings)
