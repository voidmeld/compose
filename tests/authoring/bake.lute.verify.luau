--!strict

local fs = require "@std/fs"
local luau = require "@lute/luau"

local Author = require "../../authoring"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local MAPPING: Author.AttributeMapping = {
	{ field = "id", attribute = "PropId" },
	{ field = "model", attribute = "PropModel" },
	{ field = "tier", attribute = "PropTier", optional = true },
}

local function props()
	return Author.set {
		name = "props",
		idKey = "id",
		entries = {
			{ id = "torch", model = "TorchA", tier = 2 },
			{ id = "crate", model = "CrateA" },
		},
	}
end

describe("Author.bake.attributePlan", function()
	it("emits pairs in mapping order, not table order", function()
		local set = props()
		local plan = Author.bake.attributePlan(set:byId "torch" :: Author.Entry, MAPPING)
		expect(plan):toEqual({
			{ key = "PropId", value = "torch" },
			{ key = "PropModel", value = "TorchA" },
			{ key = "PropTier", value = 2 },
		} :: Author.AttributePlan)
	end)

	it("skips an optional field the entry does not carry", function()
		local set = props()
		local plan = Author.bake.attributePlan(set:byId "crate" :: Author.Entry, MAPPING)
		expect(plan):toEqual {
			{ key = "PropId", value = "crate" },
			{ key = "PropModel", value = "CrateA" },
		}
	end)

	it("refuses a required field the entry does not carry", function()
		expect(function()
			Author.bake.attributePlan({ id = "torch" }, MAPPING)
		end):toThrow "model"
	end)

	it("refuses a field value that is not attribute-shaped", function()
		expect(function()
			Author.bake.attributePlan(
				{ id = "torch", model = { nested = true } },
				{ { field = "model", attribute = "PropModel" } }
			)
		end):toThrow "attribute"
	end)
end)

describe("Author.bake.registryModule", function()
	local function bake(): string
		return Author.bake.registryModule {
			name = "PropRegistry",
			set = props(),
			mapping = MAPPING,
		}
	end

	it("names its generator and the inputs digest in the header", function()
		local source = bake()
		expect((string.find(source, "GENERATED FILE", 1, true))):toBeOk()
		expect((string.find(source, "Author.bake.registryModule", 1, true))):toBeOk()
		expect((string.find(source, Author.digest(props()), 1, true))):toBeOk()
	end)

	it("emits every declared id and attribute key", function()
		local source = bake()
		for _, needle in { '["torch"]', '["crate"]', "PropId", "PropModel", "PropTier" } do
			expect((string.find(source, needle, 1, true))):toBeOk()
		end
	end)

	it("compiles as strict Luau and exports the dispatch surface", function()
		local source = bake()
		local load = luau.load(luau.compile(source), "PropRegistry")
		local registry = load()
		expect(type(registry.plan)):toBe "table"
		expect(type(registry.planFor)):toBe "function"
		expect(type(registry.apply)):toBe "function"
		expect(registry.setName):toBe "props"
	end)

	it("applies an entry's attributes to the mount point's parent, in plan order", function()
		local source = bake()
		local registry = luau.load(luau.compile(source), "PropRegistry")()

		local written: { { key: string, value: unknown } } = {}
		local parent = { name = "slot-parent" }
		local directive = registry.apply("torch", function(node: unknown, key: string, value: unknown)
			expect(node):toBe(parent)
			table.insert(written, { key = key, value = value })
		end)
		directive { parent = parent }

		expect(written):toEqual({
			{ key = "PropId", value = "torch" },
			{ key = "PropModel", value = "TorchA" },
			{ key = "PropTier", value = 2 },
		} :: { { key: string, value: unknown } })
	end)

	it("refuses an id the registry was not baked with", function()
		local source = bake()
		local registry = luau.load(luau.compile(source), "PropRegistry")()
		expect(function()
			registry.planFor "throne"
		end):toThrow "throne"
	end)

	it("writes the source to outPath when one is given", function()
		local scratch = "build/authoring-spec"
		fs.createDirectory(scratch, { makeParents = true })
		local outPath = scratch .. "/prop-registry.luau"
		local source = Author.bake.registryModule({
			name = "PropRegistry",
			set = props(),
			mapping = MAPPING,
		}, outPath)
		expect(fs.exists(outPath)):toBe(true)
		expect(fs.readFileToString(outPath)):toBe(source)
		fs.remove(outPath)
	end)

	it("refuses to bake a set whose ids collide", function()
		expect(function()
			Author.bake.registryModule {
				name = "PropRegistry",
				set = Author.set {
					name = "props",
					idKey = "id",
					entries = { { id = "torch" }, { id = "torch" } },
				},
				mapping = { { field = "id", attribute = "PropId" } },
			}
		end):toThrow "torch"
	end)
end)

describe("Author.bake.dataModule", function()
	local function placements(): Author.DataSpec
		return {
			name = "Placements",
			idKey = "id",
			entries = {
				{
					id = "keep-01",
					position = { x = 12, y = 0, z = -4 },
					cells = { terrainRegionId = "region-a", traversalCellId = "cell-3", streamingCellId = "stream-1" },
					active = true,
				},
				{
					id = "spawn-02",
					position = { x = 0, y = 4.5, z = 8 },
					cells = { terrainRegionId = "region-b", traversalCellId = "cell-9", streamingCellId = "stream-2" },
					active = false,
				},
			},
		}
	end

	local function bake(): string
		return Author.bake.dataModule(placements())
	end

	it("names its generator and a records digest in the header", function()
		local source = bake()
		expect((string.find(source, "GENERATED FILE", 1, true))):toBeOk()
		expect((string.find(source, "Author.bake.dataModule", 1, true))):toBeOk()
		expect((string.find(source, "records digest:", 1, true))):toBeOk()
		expect((string.find(source, "body digest:", 1, true))):toBeOk()
	end)

	it("produces byte-identical output across two runs", function()
		expect(bake()):toBe(bake())
	end)

	it("changes the header digest when any value changes", function()
		local before = bake()
		local spec = placements()
		local firstEntry = spec.entries[1] :: any
		firstEntry.position.x = 999
		local after = Author.bake.dataModule(spec)

		expect(before == after):toBe(false)
		local beforeDigest = string.match(before, "records digest:%s*(%x+)")
		local afterDigest = string.match(after, "records digest:%s*(%x+)")
		expect(beforeDigest):toBeOk()
		expect(afterDigest):toBeOk()
		expect(beforeDigest == afterDigest):toBe(false)
	end)

	it("round-trips a nested record through require", function()
		local source = bake()
		local records = luau.load(luau.compile(source), "Placements")()

		expect(records["keep-01"].position.x):toBe(12)
		expect(records["keep-01"].position.y):toBe(0)
		expect(records["keep-01"].position.z):toBe(-4)
		expect(records["keep-01"].cells.terrainRegionId):toBe "region-a"
		expect(records["keep-01"].cells.traversalCellId):toBe "cell-3"
		expect(records["keep-01"].cells.streamingCellId):toBe "stream-1"
		expect(records["keep-01"].active):toBe(true)

		expect(records["spawn-02"].position.y):toBe(4.5)
		expect(records["spawn-02"].cells.streamingCellId):toBe "stream-2"
		expect(records["spawn-02"].active):toBe(false)
	end)

	it("emits ids in sorted order regardless of authored order", function()
		local source = bake()
		local keepAt = string.find(source, '["keep-01"]', 1, true)
		local spawnAt = string.find(source, '["spawn-02"]', 1, true)
		expect(keepAt):toBeOk()
		expect(spawnAt):toBeOk()
		expect((keepAt :: number) < (spawnAt :: number)):toBe(true)
	end)

	it("writes the source to outPath when one is given", function()
		local scratch = "build/authoring-spec"
		fs.createDirectory(scratch, { makeParents = true })
		local outPath = scratch .. "/placements-data.luau"
		local source = Author.bake.dataModule(placements(), outPath)
		expect(fs.exists(outPath)):toBe(true)
		expect(fs.readFileToString(outPath)):toBe(source)
		fs.remove(outPath)
	end)

	it("refuses a non-serialisable field value", function()
		expect(function()
			Author.bake.dataModule {
				name = "Placements",
				idKey = "id",
				entries = { { id = "keep-01", handler = function() end } },
			}
		end):toThrow "bake/not-data-shaped"
	end)

	it("refuses ids that collide", function()
		expect(function()
			Author.bake.dataModule {
				name = "Placements",
				idKey = "id",
				entries = { { id = "keep-01" }, { id = "keep-01" } },
			}
		end):toThrow "bake/duplicate-id"
	end)

	it("refuses an entry missing its id field", function()
		expect(function()
			Author.bake.dataModule {
				name = "Placements",
				idKey = "id",
				entries = { { position = { x = 1, y = 2, z = 3 } } },
			}
		end):toThrow "bake/entry-missing-id"
	end)
end)

return nil
