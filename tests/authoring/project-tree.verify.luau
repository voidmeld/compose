--!strict

local Author = require "../../authoring"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function plan(overrides: { [string]: any }?): Author.Plan
	local base: Author.Plan = {
		mounts = {
			{ at = { "ReplicatedStorage" }, name = "Shared", path = "source/shared" },
			{ at = { "ServerScriptService" }, name = "Boot", path = "source/server/boot.luau" },
		},
		targets = {
			{ name = "alpha", document = "build/alpha.project.json" },
		},
	}
	if overrides ~= nil then
		for key, value in overrides do
			(base :: any)[key] = value
		end
	end
	return base
end

describe("Author.projectTree", function()
	it("builds one document per target with the declared branches", function()
		local result = Author.projectTree(plan())
		expect(result.order):toEqual { "alpha" }
		expect(result.documents.alpha):toEqual {
			name = "alpha",
			tree = {
				["$className"] = "DataModel",
				ReplicatedStorage = {
					["$className"] = "Folder",
					Shared = { ["$path"] = "source/shared" },
				},
				ServerScriptService = {
					["$className"] = "Folder",
					Boot = { ["$path"] = "source/server/boot.luau" },
				},
			},
		}
	end)

	it("lists every mounted path in the manifest, sorted", function()
		local result = Author.projectTree(plan())
		expect(result.manifest.targets[1].paths):toEqual { "source/server/boot.luau", "source/shared" }
	end)

	it("gives the same digest for the same plan and a different one for a changed plan", function()
		local first = Author.projectTree(plan())
		local again = Author.projectTree(plan())
		expect(again.manifest.digest):toEqual(first.manifest.digest)

		local changed = plan()
		table.insert(changed.mounts, { at = { "ReplicatedStorage" }, name = "Extra", path = "source/extra.luau" })
		expect(Author.projectTree(changed).manifest.digest == first.manifest.digest):toEqual(false)
	end)

	it("refuses a mount whose script parent sibling is not mounted beside it", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "ReplicatedStorage", "Shared" },
				name = "Reader",
				path = "source/shared/reader.luau",
				siblings = { "source/shared/writer.luau" },
			},
		}
		expect(function()
			Author.projectTree(subject)
		end):toThrow "writer.luau"
	end)

	it("accepts a mount whose sibling is mounted beside it", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "ReplicatedStorage", "Shared" },
				name = "Reader",
				path = "source/shared/reader.luau",
				siblings = { "source/shared/writer.luau" },
			},
			{ at = { "ReplicatedStorage", "Shared" }, name = "Writer", path = "source/shared/writer.luau" },
		}
		local result = Author.projectTree(subject)
		expect(#result.manifest.targets[1].paths):toEqual(2)
	end)

	it("refuses a sibling mounted under another branch", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "ReplicatedStorage", "Shared" },
				name = "Reader",
				path = "source/shared/reader.luau",
				siblings = { "source/shared/writer.luau" },
			},
			{ at = { "ServerScriptService" }, name = "Writer", path = "source/shared/writer.luau" },
		}
		expect(function()
			Author.projectTree(subject)
		end):toThrow "beside"
	end)

	it("refuses a bare relative require", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "ReplicatedStorage" },
				name = "Shared",
				path = "source/shared",
				requires = { "@app/config", "../other/thing" },
			},
		}
		expect(function()
			Author.projectTree(subject)
		end):toThrow "bare-relative-require"
	end)

	it("allows a relative require when the plan asks for it", function()
		local subject = plan()
		subject.requirePolicy = "any"
		subject.mounts = {
			{ at = { "ReplicatedStorage" }, name = "Shared", path = "source/shared", requires = { "./thing" } },
		}
		expect(Author.projectTree(subject).order):toEqual { "alpha" }
	end)

	it("stamps a per-target identity as an injected value", function()
		local subject = plan()
		subject.targets = {
			{
				name = "alpha",
				document = "build/alpha.project.json",
				identity = {
					at = { "ReplicatedStorage" },
					name = "BuildIdentity",
					values = { commit = "abc123", clean = true },
				},
			},
		}
		local result = Author.projectTree(subject)
		expect(result.documents.alpha.tree.ReplicatedStorage.BuildIdentity):toEqual {
			["$className"] = "Configuration",
			["$attributes"] = { commit = "abc123", clean = true },
		}
		expect(result.manifest.targets[1].identityValues):toEqual { commit = "abc123", clean = true }
	end)

	it("mounts a generated identity module when the target names its path", function()
		local subject = plan()
		subject.targets = {
			{
				name = "alpha",
				document = "build/alpha.project.json",
				identity = {
					at = { "ReplicatedStorage" },
					name = "BuildIdentity",
					path = "build/generated/alpha-identity.luau",
					values = { commit = "abc123" },
				},
			},
		}
		local result = Author.projectTree(subject)
		expect(result.documents.alpha.tree.ReplicatedStorage.BuildIdentity):toEqual {
			["$path"] = "build/generated/alpha-identity.luau",
		}
	end)

	it("gives two targets different identities from one mount plan", function()
		local subject = plan()
		subject.targets = {
			{
				name = "alpha",
				document = "build/alpha.project.json",
				identity = { at = { "ReplicatedStorage" }, name = "BuildIdentity", values = { commit = "aaa" } },
			},
			{
				name = "beta",
				document = "build/beta.project.json",
				identity = { at = { "ReplicatedStorage" }, name = "BuildIdentity", values = { commit = "bbb" } },
			},
		}
		local result = Author.projectTree(subject)
		expect(result.documents.alpha.tree.ReplicatedStorage.BuildIdentity["$attributes"]):toEqual { commit = "aaa" }
		expect(result.documents.beta.tree.ReplicatedStorage.BuildIdentity["$attributes"]):toEqual { commit = "bbb" }
		expect(result.documents.alpha.tree.ReplicatedStorage.Shared):toEqual { ["$path"] = "source/shared" }
	end)

	it("drops a variant-excluded path and keeps the rest", function()
		local subject = plan()
		subject.variants = {
			{ name = "release", excludePrefixes = { "source/server/" } },
		}
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "release" } }
		local result = Author.projectTree(subject)
		expect(result.manifest.targets[1].paths):toEqual { "source/shared" }
		expect(result.documents.alpha.tree.ServerScriptService):toEqual(nil)
	end)

	it("drops an exact and a suffix exclusion", function()
		local subject = plan()
		subject.mounts = {
			{ at = { "ReplicatedStorage" }, name = "Shared", path = "source/shared" },
			{ at = { "ReplicatedStorage" }, name = "Probe", path = "source/shared/Probe.client.luau" },
			{ at = { "ReplicatedStorage" }, name = "Fixture", path = "source/fixture.luau" },
		}
		subject.variants = {
			{
				name = "release",
				excludeExact = { "source/fixture.luau" },
				excludeSuffixes = { "Probe.client.luau" },
			},
		}
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "release" } }
		expect(Author.projectTree(subject).manifest.targets[1].paths):toEqual { "source/shared" }
	end)

	it("adds a variant-only mount and variant properties", function()
		local subject = plan()
		subject.variants = {
			{
				name = "release",
				mounts = { { at = { "ReplicatedStorage" }, name = "Release", path = "source/release.luau" } },
				properties = { Workspace = { StreamingEnabled = true } } :: { [string]: { [string]: Author.RojoValue } },
			},
		}
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "release" } }
		local result = Author.projectTree(subject)
		expect(result.documents.alpha.tree.ReplicatedStorage.Release):toEqual { ["$path"] = "source/release.luau" }
		expect(result.documents.alpha.tree.Workspace["$properties"]):toEqual { StreamingEnabled = true }
	end)

	it("leaves the base plan untouched when one target takes a variant", function()
		local subject = plan()
		subject.variants = { { name = "release", excludePrefixes = { "source/server/" } } }
		subject.targets = {
			{ name = "alpha", document = "build/alpha.project.json" },
			{ name = "beta", document = "build/beta.project.json", variant = "release" },
		}
		local result = Author.projectTree(subject)
		expect(#result.manifest.targets[1].paths):toEqual(2)
		expect(#result.manifest.targets[2].paths):toEqual(1)
	end)

	it("refuses an unknown variant", function()
		local subject = plan()
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "missing" } }
		expect(function()
			Author.projectTree(subject)
		end):toThrow "missing"
	end)

	it("refuses two mounts at one tree location", function()
		local subject = plan()
		subject.mounts = {
			{ at = { "ReplicatedStorage" }, name = "Shared", path = "source/shared" },
			{ at = { "ReplicatedStorage" }, name = "Shared", path = "source/other" },
		}
		expect(function()
			Author.projectTree(subject)
		end):toThrow "Shared"
	end)

	it("refuses two targets with one name", function()
		local subject = plan()
		subject.targets = {
			{ name = "alpha", document = "build/alpha.project.json" },
			{ name = "alpha", document = "build/other.project.json" },
		}
		expect(function()
			Author.projectTree(subject)
		end):toThrow "alpha"
	end)

	it("refuses a mount that carries neither path nor className", function()
		local subject = plan()
		subject.mounts = { { at = { "ReplicatedStorage" }, name = "Shared" } }
		expect(function()
			Author.projectTree(subject)
		end):toThrow "Shared"
	end)

	it("refuses a plan that mounts nothing and a plan with no target", function()
		local empty = plan()
		empty.mounts = {}
		expect(function()
			Author.projectTree(empty)
		end):toThrow "mounts nothing"

		local targetless = plan()
		targetless.targets = {}
		expect(function()
			Author.projectTree(targetless)
		end):toThrow "no target"
	end)

	it("keeps properties, attributes, and the unknown-instance flag on a mount", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "Workspace" },
				name = "Terrain",
				className = "Terrain",
				properties = { WaterWaveSize = 0.15 } :: { [string]: Author.RojoValue },
				attributes = { zone = "north" } :: { [string]: Author.RojoValue },
				ignoreUnknownInstances = true,
			},
		}
		expect(Author.projectTree(subject).documents.alpha.tree.Workspace.Terrain):toEqual {
			["$className"] = "Terrain",
			["$properties"] = { WaterWaveSize = 0.15 },
			["$attributes"] = { zone = "north" },
			["$ignoreUnknownInstances"] = true,
		}
	end)

	it("refuses a property value that is not property shaped", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "Workspace" },
				name = "Terrain",
				className = "Terrain",
				properties = { size = { width = 1, height = 2 } :: any },
			},
		}
		expect(function()
			Author.projectTree(subject)
		end):toThrow "property"
	end)

	it("refuses a non-finite number anywhere in a property value", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "Workspace" },
				name = "Terrain",
				className = "Terrain",
				properties = { Color = { Color3 = { 1, math.nan, 0 } } :: any },
			},
		}
		expect(function()
			Author.projectTree(subject)
		end):toThrow "property"
	end)

	it("accepts a scalar, a numeric array, and a nested single-key typed value as properties", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "Workspace" },
				name = "Spawn",
				className = "SpawnLocation",
				properties = {
					Anchored = true,
					BrickColor = { BrickColor = "Really red" },
					Color = { Color3 = { 1, 0, 0 } },
					CFrame = { CFrame = { 0, 5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
				} :: { [string]: Author.RojoValue },
			},
		}
		local properties = Author.projectTree(subject).documents.alpha.tree.Workspace.Spawn["$properties"]
		expect(properties):toEqual {
			Anchored = true,
			BrickColor = { BrickColor = "Really red" },
			Color = { Color3 = { 1, 0, 0 } },
			CFrame = { CFrame = { 0, 5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 } },
		}
	end)

	it("drops a pathless mount and its subtree by tree location", function()
		local subject = plan()
		subject.mounts = {
			{ at = { "ReplicatedStorage" }, name = "Shared", path = "source/shared" },
			{ at = { "ReplicatedStorage" }, name = "Placeholder", className = "Folder" },
			{
				at = { "ReplicatedStorage", "Placeholder" },
				name = "Deep",
				path = "source/deep.luau",
			},
		}
		subject.variants = {
			{
				name = "release",
				excludeAt = { { at = { "ReplicatedStorage" }, name = "Placeholder" } },
			},
		}
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "release" } }
		local result = Author.projectTree(subject)
		expect(result.documents.alpha.tree.ReplicatedStorage.Placeholder):toEqual(nil)
		expect(result.manifest.targets[1].paths):toEqual { "source/shared" }
	end)

	it("keeps other pathless mounts when excludeAt names a different location", function()
		local subject = plan()
		subject.mounts = {
			{ at = { "ReplicatedStorage" }, name = "Shared", path = "source/shared" },
			{ at = { "ReplicatedStorage" }, name = "Placeholder", className = "Folder" },
		}
		subject.variants = {
			{
				name = "release",
				excludeAt = { { at = { "ReplicatedStorage" }, name = "Other" } },
			},
		}
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "release" } }
		local result = Author.projectTree(subject)
		expect(result.documents.alpha.tree.ReplicatedStorage.Placeholder):toEqual { ["$className"] = "Folder" }
	end)

	it("replaces a base mount's properties and identity value at the same location", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "Workspace" },
				name = "Terrain",
				className = "Terrain",
				properties = { WaterWaveSize = 0.15 } :: { [string]: Author.RojoValue },
				attributes = { zone = "north" } :: { [string]: Author.RojoValue },
			},
		}
		subject.variants = {
			{
				name = "release",
				mounts = {
					{
						at = { "Workspace" },
						name = "Terrain",
						className = "Terrain",
						properties = { WaterWaveSize = 0.4 } :: { [string]: Author.RojoValue },
						attributes = { zone = "south" } :: { [string]: Author.RojoValue },
						replace = true,
					},
				},
			},
		}
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "release" } }
		local result = Author.projectTree(subject)
		expect(result.documents.alpha.tree.Workspace.Terrain):toEqual {
			["$className"] = "Terrain",
			["$properties"] = { WaterWaveSize = 0.4 },
			["$attributes"] = { zone = "south" },
		}
	end)

	it("leaves the base plan untouched when a variant replaces a mount", function()
		local subject = plan()
		subject.mounts = {
			{
				at = { "Workspace" },
				name = "Terrain",
				className = "Terrain",
				properties = { WaterWaveSize = 0.15 } :: { [string]: Author.RojoValue },
			},
		}
		subject.variants = {
			{
				name = "release",
				mounts = {
					{
						at = { "Workspace" },
						name = "Terrain",
						className = "Terrain",
						properties = { WaterWaveSize = 0.4 } :: { [string]: Author.RojoValue },
						replace = true,
					},
				},
			},
		}
		subject.targets = {
			{ name = "alpha", document = "build/alpha.project.json" },
			{ name = "beta", document = "build/beta.project.json", variant = "release" },
		}
		local result = Author.projectTree(subject)
		expect(result.documents.alpha.tree.Workspace.Terrain["$properties"]):toEqual { WaterWaveSize = 0.15 }
		expect(result.documents.beta.tree.Workspace.Terrain["$properties"]):toEqual { WaterWaveSize = 0.4 }
	end)

	it("refuses a replace mount with no base mount at its location", function()
		local subject = plan()
		subject.variants = {
			{
				name = "release",
				mounts = {
					{ at = { "Workspace" }, name = "Terrain", className = "Terrain", replace = true },
				},
			},
		}
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "release" } }
		expect(function()
			Author.projectTree(subject)
		end):toThrow "replace-without-base"
	end)

	it("still refuses two mounts at one tree location when replace is absent", function()
		local subject = plan()
		subject.variants = {
			{
				name = "release",
				mounts = {
					{ at = { "ReplicatedStorage" }, name = "Shared", path = "source/other" },
				},
			},
		}
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "release" } }
		expect(function()
			Author.projectTree(subject)
		end):toThrow "duplicate-mount"
	end)

	it("refuses an improperly shaped value inside variant properties too", function()
		local subject = plan()
		subject.variants = {
			{ name = "release", properties = { Workspace = { Color = { r = 1, g = 0 } :: any } } },
		}
		subject.targets = { { name = "alpha", document = "build/alpha.project.json", variant = "release" } }
		expect(function()
			Author.projectTree(subject)
		end):toThrow "property"
	end)
end)

return nil
