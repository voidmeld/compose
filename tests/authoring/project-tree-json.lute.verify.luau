--!strict

local Json = require "@std/json"

local Author = require "../../authoring"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function plan(overrides: { [string]: unknown }?): Author.Plan
	local base: Author.Plan = {
		mounts = {
			{ at = { "ReplicatedStorage" }, name = "Shared", path = "source/shared" },
		},
		targets = {
			{ name = "alpha", document = "build/alpha.project.json" },
		},
	}
	if overrides ~= nil then
		for key, value in overrides do
			((base :: unknown) :: { [string]: unknown })[key] = value
		end
	end
	return base
end

describe("Author.projectTree property values in the emitted project JSON", function()
	it("round-trips a scalar, a numeric array, and a nested single-key typed value byte-for-byte", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "Workspace" },
				name = "Spawn",
				className = "SpawnLocation",
				properties = {
					Anchored = true,
					Duration = 3.5,
					BrickColor = { BrickColor = "Really red" },
					Color = { Color3 = { 1, 0, 0 } },
					CFrame = { CFrame = { 0, 5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
				} :: { [string]: Author.RojoValue },
			},
		}
		local properties = (
			(Author.projectTree(subject).documents.alpha.tree.Workspace :: Author.ProjectNode).Spawn :: Author.ProjectNode
		)["$properties"] :: { [string]: Author.RojoValue }

		expect(Json.serialize((properties.Anchored :: unknown) :: Json.Value)):toBe "true"
		expect(Json.serialize((properties.Duration :: unknown) :: Json.Value)):toBe "3.5"
		expect(Json.serialize((properties.BrickColor :: unknown) :: Json.Value)):toBe '{"BrickColor":"Really red"}'
		expect(Json.serialize((properties.Color :: unknown) :: Json.Value)):toBe '{"Color3":[1,0,0]}'
		expect(Json.serialize((properties.CFrame :: unknown) :: Json.Value)):toBe '{"CFrame":[0,5,0,1,0,0,0,1,0,0,0,1]}'

		local objectKeys = { BrickColor = true, Color = true, CFrame = true }
		for _, key in { "Anchored", "Duration", "BrickColor", "Color", "CFrame" } do
			local encoded = Json.serialize((properties[key] :: unknown) :: Json.Value)
			local decoded = Json.deserialize(encoded)
			local expected: unknown = properties[key]
			if objectKeys[key] then
				expected = Json.object(expected :: { [string]: Json.Value })
			end
			expect(decoded):toEqual(expected)
		end
	end)
end)

return nil
