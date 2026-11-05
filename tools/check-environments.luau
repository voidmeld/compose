--!strict
local Checks = require "../.lute/dependencies/verify/src/checks"
local Policy = require "./checks-policy"
local Finish = require "./lib/check-result"
Finish("check-environments", Checks.boundary { root = "src", rules = Policy.environments })
