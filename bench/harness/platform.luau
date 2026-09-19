--!strict
--!nolint DeprecatedApi

local function tryRequire(name: string): any?
	local ok, module = pcall(require, name)
	if ok then
		return module
	end
	return nil
end

local luteFs = tryRequire("@std/" .. "fs")
local luteLuau = tryRequire("@lute/" .. "luau")
local luneFs = tryRequire("@lune/" .. "fs")
local luneLuau = tryRequire("@lune/" .. "luau")

export type Runtime = "lute" | "lune" | "unknown"

local runtime: Runtime = if luteLuau ~= nil then "lute" elseif luneLuau ~= nil then "lune" else "unknown"

local function name(): Runtime
	return runtime
end

local function isFile(path: string): boolean
	if luteFs ~= nil then
		return luteFs.exists(path) and luteFs.type(path) == "file"
	end
	if luneFs ~= nil then
		local metadata = luneFs.metadata(path)
		return metadata.exists and metadata.kind == "file"
	end
	error("platform: no filesystem available", 0)
end

local function readFile(path: string): string
	if luteFs ~= nil then
		return luteFs.readFileToString(path)
	end
	if luneFs ~= nil then
		return luneFs.readFile(path)
	end
	error("platform: no filesystem available", 0)
end

local function writeFile(path: string, contents: string)
	if luteFs ~= nil then
		luteFs.writeStringToFile(path, contents)
		return
	end
	if luneFs ~= nil then
		luneFs.writeFile(path, contents)
		return
	end
	error("platform: no filesystem available", 0)
end

local function createDirectory(path: string)
	if luteFs ~= nil then
		luteFs.createDirectory(path, { makeParents = true })
		return
	end
	if luneFs ~= nil then
		luneFs.writeDir(path)
		return
	end
	error("platform: no filesystem available", 0)
end

local function loadChunk(source: string, chunkName: string, environment: { [string]: any }): () -> any
	if luteLuau ~= nil then
		return luteLuau.load(luteLuau.compile(source), chunkName, environment)
	end
	if luneLuau ~= nil then
		return luneLuau.load(source, { debugName = chunkName, environment = environment, injectGlobals = false })
	end
	error("platform: no Luau loader available", 0)
end

local collect2: ((string) -> any)? = nil
do
	local globals = (getfenv and getfenv(0) or {}) :: { [string]: any }
	local found = globals.collectgarbage
	if type(found) == "function" then
		collect2 = found :: (string) -> any
	end
end

local function hasHeapMeasurement(): boolean
	return collect2 ~= nil
end

local SETTLE_ROUNDS = 400
local SETTLE_CHUNK = 4000

local function settledHeapKilobytes(): number?
	local gc = collect2
	if gc == nil then
		return nil
	end

	local lowest = (gc "count" :: any) :: number
	for _ = 1, SETTLE_ROUNDS do
		local junk = table.create(SETTLE_CHUNK)
		for index = 1, SETTLE_CHUNK do
			junk[index] = { index }
		end
		junk = nil :: any
		local sample = (gc "count" :: any) :: number
		if sample < lowest then
			lowest = sample
		end
	end
	return lowest
end

local function heapKilobytes(): number?
	local gc = collect2
	if gc == nil then
		return nil
	end
	return (gc "count" :: any) :: number
end

return {
	name = name,
	isFile = isFile,
	readFile = readFile,
	writeFile = writeFile,
	createDirectory = createDirectory,
	loadChunk = loadChunk,
	hasHeapMeasurement = hasHeapMeasurement,
	settledHeapKilobytes = settledHeapKilobytes,
	heapKilobytes = heapKilobytes,
	SETTLE_ROUNDS = SETTLE_ROUNDS,
	SETTLE_CHUNK = SETTLE_CHUNK,
}
