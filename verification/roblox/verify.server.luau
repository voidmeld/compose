--!strict

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Checks = require(script.Parent.checks)
local Identity = require(ReplicatedStorage.ComposeVerificationIdentity)
local Compose = require(ReplicatedStorage.compose.core)
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)

local PREFIX = "COMPOSE-VERIFY"
local NATIVE_PREFIX = "COMPOSE-NATIVE"

local function nativeTarget(name: string)
	print(("%s|target|%s|profiler-required"):format(NATIVE_PREFIX, name))
end

local container = Instance.new "Folder"
container.Name = "ComposeVerification"
container.Parent = workspace

print(PREFIX .. "|begin")
print(("%s|env|sourceCommit|%s"):format(PREFIX, Identity.sourceCommit))
print(("%s|env|sourceTree|%s"):format(PREFIX, Identity.sourceTree))
print(("%s|env|sourceDirty|%s"):format(PREFIX, tostring(Identity.sourceDirty)))
nativeTarget "reactive.cell"
nativeTarget "structure.keyed"
nativeTarget "animation.stepSpring"
local summary = Checks.run(Compose, ComposeRoblox, container)

for key, value in summary.environment do
	print(("%s|env|%s|%s"):format(PREFIX, key, tostring(value)))
end

for _, result in summary.results do
	print(("%s|%s|%s|%s"):format(PREFIX, if result.passed then "pass" else "FAIL", result.name, result.detail))
end

print(("%s|total|%d passed|%d failed"):format(PREFIX, summary.passed, summary.failed))
print(PREFIX .. "|end")

container:Destroy()
