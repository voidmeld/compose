--!strict

local fs = require "@std/fs"

local Bdd = require "../.lute/dependencies/verify/src/bdd"
local Matchers = require "@self/matchers"
local Verify = require "../.lute/dependencies/verify/src/core"

export type Report = Verify.Report
export type CaseResult = Verify.CaseResult
export type Expectation = Matchers.Expectation
export type Body = Bdd.Body
export type Selection = Verify.Selection

export type Manifest = Verify.Manifest
export type ManifestEntry = Verify.ManifestEntry

export type Host = "neutral" | "lute"

local EXECUTOR = "lute"
local ENVIRONMENT: { [string]: string } = { runtime = "lute" }

local CAPABILITIES: { string } = { "lute" }

local NEUTRAL_SUFFIX = ".verify.luau"
local LUTE_SUFFIX = ".lute.verify.luau"
local ROBLOX_SUFFIX = ".roblox.verify.luau"

local session = Verify.createSession {
	executor = EXECUTOR,
	environment = ENVIRONMENT,
	capabilities = CAPABILITIES,
	now = os.clock,
	surface = Bdd.create :: any,
	prefixCaseIds = false,
}

local function endsWith(name: string, suffix: string): boolean
	return #name >= #suffix and string.sub(name, -#suffix) == suffix
end

local function route(path: string): Host?
	local name = string.match(path, "([^/]+)$") or path
	if endsWith(name, ROBLOX_SUFFIX) then
		error(
			("harness: %s is engine-only source and cannot run under the Lute executor; it belongs under verification/"):format(
				path
			),
			0
		)
	end
	local hosts: { Host } = {}
	if endsWith(name, LUTE_SUFFIX) then
		table.insert(hosts, "lute" :: Host)
	end
	if endsWith(name, NEUTRAL_SUFFIX) and not endsWith(name, LUTE_SUFFIX) then
		table.insert(hosts, "neutral" :: Host)
	end
	if #hosts == 0 then
		return nil
	end
	assert(#hosts == 1, ("harness: %s routes to %d hosts; exactly one is required"):format(path, #hosts))
	return hosts[1]
end

local function discover(root: string): { string }
	local found: { string } = {}
	local function walk(path: string)
		local names: { string } = {}
		local kinds: { [string]: string } = {}
		for _, entry in fs.listDirectory(path) do
			table.insert(names, entry.name)
			kinds[entry.name] = entry.type
		end
		table.sort(names)
		for _, name in names do
			local child = path .. "/" .. name
			if kinds[name] == "dir" then
				walk(child)
			elseif route(child) ~= nil then
				table.insert(found, child)
			end
		end
	end
	if fs.exists(root) then
		walk(root)
	end
	return found
end

local function entryFor(root: string, path: string): ManifestEntry
	local host = route(path)
	if host == nil then
		error(("harness: %s is not a verification source and has no manifest entry"):format(path), 0)
	end
	local prefix = root .. "/"
	local relative = if string.sub(path, 1, #prefix) == prefix then string.sub(path, #prefix + 1) else path
	local suffix = if host == "lute" then LUTE_SUFFIX else NEUTRAL_SUFFIX
	local id = string.sub(relative, 1, #relative - #suffix)
	return {
		id = id,
		source = path,
		group = string.match(id, "^([^/]+)/") or id,
		tags = { host },
		requires = if host == "lute" then { "lute" } else {},
	}
end

local function generate(root: string): Manifest
	local entries: { ManifestEntry } = {}
	for _, path in discover(root) do
		table.insert(entries, entryFor(root, path))
	end
	return Verify.validateManifest { schemaVersion = Verify.MANIFEST_SCHEMA_VERSION, entries = entries }
end

local function sources(manifest: Manifest): { string }
	local checked = Verify.validateManifest(manifest)
	local paths: { string } = {}
	for _, entry in checked.entries do
		if route(entry.source) == nil then
			error(
				("harness: manifest entry %q names %s, which is not a verification source"):format(
					entry.id,
					entry.source
				),
				0
			)
		end
		table.insert(paths, entry.source)
	end
	return paths
end

local function load(locator: string)
	if route(locator) == nil then
		error(("harness: %s is not a verification source and cannot be loaded"):format(locator), 0)
	end
	session:open(locator)

	local ok, thrown: any = pcall(require, "../" .. string.sub(locator, 1, #locator - 5))
	session:close()
	if ok then
		return
	end
	session:adoptReport(
		locator,
		session:sourceReport("source:" .. locator .. ":load", locator, "failed", tostring(thrown))
	)
end

export type HostOptions = {
	selection: Selection?,
}

local function host(options: HostOptions?): Verify.Host
	local settings: HostOptions = if options ~= nil then options else {}
	session:setSelection(settings.selection)

	local adapter = {} :: Verify.Host
	adapter.name = EXECUTOR
	adapter.capabilities = CAPABILITIES
	adapter.environment = ENVIRONMENT
	adapter.now = os.clock
	adapter.runBatch = function(batch: Verify.PlanBatch): Verify.BatchOutcome
		session:reset()
		for _, unit in batch.units do
			load(unit.locator)
		end
		return { status = "returned", report = session:run() }
	end
	return adapter
end

local verbs = session.verbs
local describe: (name: string, register: () -> ()) -> () = verbs.describe
local it: (name: string, body: Body) -> () = verbs.it
local itSkip: (name: string, reason: string, body: Body?) -> () = verbs.itSkip
local beforeEach: (body: Body) -> () = verbs.beforeEach
local afterEach: (body: Body) -> () = verbs.afterEach
local skip: (reason: string) -> never = verbs.skip

return {
	describe = describe,
	it = it,
	itSkip = itSkip,
	beforeEach = beforeEach,
	afterEach = afterEach,
	skip = skip,
	expect = Matchers.expect,
	deepEquals = Matchers.deepEquals,
	describeValue = Matchers.describeValue,

	discover = discover,
	route = route,
	entryFor = entryFor,
	generate = generate,
	sources = sources,
	host = host,
}
