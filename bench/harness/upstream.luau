--!strict

local fs = require "@std/fs"
local luau = require "@lute/luau"
local Lock = require "../../dependencies.lock"
local Environment = require "../cost-model"

type Module = { path: string }
local boundary = luau.load(luau.compile "return ...", "benchmark-boundary")

local bytecode: { [string]: luau.Bytecode } = {}

local function normal(path: string): string
	local parts: { string } = {}
	for part in path:gmatch "[^/]+" do
		if part == ".." then
			assert(#parts > 0, "module path escapes the repository")
			table.remove(parts)
		elseif part ~= "." then
			table.insert(parts, part)
		end
	end
	return table.concat(parts, "/")
end

local function module(path: string): unknown
	return setmetatable({ path = path }, {
		__index = function(_self: unknown, key: string): unknown
			if key == "WaitForChild" or key == "FindFirstChild" then
				return function(_object: unknown, child: string): unknown
					return module(path .. "/" .. child)
				end
			elseif key == "FindFirstAncestor" then
				return function(): unknown
					return nil
				end
			elseif key == "GetFullName" then
				return function(): string
					return path
				end
			end
			return module(if key == "Parent" then path:match "^(.*)/[^/]+$" or "" else path .. "/" .. key)
		end,
	})
end

local function create(environment: Environment.Environment)
	local cache: { [string]: unknown } = {}
	local loaded: { [string]: boolean } = {}
	local paths: { [string]: string } = {}
	local allowed: { string } = {}
	for _, dependency in Lock.dependencies do
		for _, surface in dependency.surfaces do
			if surface.role == "benchmark" then
				table.insert(allowed, ".lute/dependencies/" .. dependency.name .. "/" .. surface.root)
			end
		end
	end
	local function resolve(path: string): string
		path = normal(path)
		local present = false
		for _, suffix in { "", ".luau", ".lua", "/init.luau", "/init.lua" } do
			if fs.exists(path .. suffix) and fs.type(path .. suffix) == "file" then
				present = true
				break
			end
		end
		local package = path:match "/([^/]+)$"
		local packages: { [string]: string } = {
			React = "react-upstream/modules/react/src",
			ReactRoblox = "react-upstream/modules/react-roblox/src",
			ReactReconciler = "react-upstream/modules/react-reconciler/src",
			Scheduler = "react-upstream/modules/scheduler/src",
			Shared = "react-upstream/modules/shared/src",
			LuauPolyfill = "polyfill-upstream/modules/luau-polyfill/src",
			Promise = "promise-upstream/lib",
			Symbol = "symbol-upstream/src",
			Signals = "signals/modules/signals/src",
			SignalsExperimental = "signals/modules/signals-experimental/src",
			SignalsScheduler = "signals/modules/signals-scheduler/src",
			SignalsFlags = "signals/modules/signals-flags/src",
		}
		local mapped = if package then packages[package] else nil
		if package == "Promise" and path:find("/reflex/", 1, true) then
			mapped = "reflex-promise/lib"
		end
		if mapped and not present then
			path = ".lute/dependencies/" .. mapped
		elseif not present and path:find("/polyfill-upstream/", 1, true) and package then
			local names: { [string]: string } = {
				Boolean = "boolean",
				Collections = "collections",
				Console = "console",
				ES7Types = "es7-types",
				InstanceOf = "instance-of",
				Math = "math",
				Number = "number",
				String = "string",
				Timers = "timers",
			}
			if names[package] then
				path = ".lute/dependencies/polyfill-upstream/modules/" .. names[package] .. "/src"
			end
		end
		for _, candidate in { path, path .. ".luau", path .. ".lua", path .. "/init.luau", path .. "/init.lua" } do
			if fs.exists(candidate) and fs.type(candidate) == "file" then
				for _, root in allowed do
					if candidate == root or candidate:sub(1, #root + 1) == root .. "/" then
						return candidate
					end
				end
				error("module is outside the benchmark surfaces: " .. candidate, 0)
			end
		end
		error("benchmark module is absent: " .. path, 0)
	end
	local function scan(root: string)
		for _, entry in fs.listDirectory(root) do
			local path = root .. "/" .. entry.name
			if entry.type == "dir" then
				scan(path)
			elseif entry.name:match "%.lua[u]?$" and not entry.name:find(".spec.", 1, true) then
				local name = entry.name:gsub("%.lua[u]?$", "")
				assert(paths[name] == nil, "ambiguous Nevermore module " .. name)
				paths[name] = path
			end
		end
	end
	for _, root in allowed do
		if root:find("/blend/", 1, true) then
			if fs.type(root) == "dir" then
				scan(root)
			else
				local name = root:match "([^/]+)%.lua$"
				if name then
					paths[name] = root
				end
			end
		end
	end
	local load: (string) -> unknown
	function load(request: string): unknown
		local path = resolve(request)
		if loaded[path] then
			return cache[path]
		end
		local globals = table.clone(environment.globals)
		local directory = assert(path:match "^(.*)/[^/]+$")
		globals.script = module(if path:match "/init%.lua[u]?$" then directory else path:gsub("%.lua[u]?$", ""))
		globals.require = function(target: string | Module): unknown
			if type(target) == "table" then
				if target.path:match "/loader$" then
					return {
						load = function(_script: Module)
							return function(name: string): unknown
								return load((assert(paths[name], "Nevermore module is not locked: " .. name)))
							end
						end,
					}
				end
				return load(target.path)
			end
			if target:sub(1, 5) == "@pkg/" then
				local name = target:gsub("^@pkg/@jsdotlua/", ""):gsub("^@pkg/", "")
				if name == "symbol-luau" then
					return load ".lute/dependencies/symbol/src/init.lua"
				elseif name == "promise" then
					return load ".lute/dependencies/react-promise/lib/init.lua"
				end
				local root = if name == "react"
						or name == "react-roblox"
						or name == "react-reconciler"
						or name == "scheduler"
						or name == "shared"
					then "react"
					else "luau-polyfill"
				return load(".lute/dependencies/" .. root .. "/modules/" .. name .. "/src")
			elseif target:sub(1, 6) == "@self/" then
				return load(directory .. "/" .. target:sub(7))
			end
			return load(directory .. "/" .. target)
		end
		local compiled = bytecode[path]
		if compiled == nil then
			compiled = luau.compile(fs.readFileToString(path))
			bytecode[path] = compiled
		end
		local result: unknown = luau.load(compiled, "@" .. path, globals)()
		cache[path] = result
		loaded[path] = true
		return result
	end
	return {
		load = function(path: string)
			return boundary(load(path))
		end,
	}
end

return {
	create = create,
	callback = function(value: unknown): (...unknown) -> ()
		assert(type(value) == "function", "event handler must be a function")
		return boundary(value)
	end,
	entries = function(value: unknown): { [unknown]: unknown }
		assert(type(value) == "table", "children must be a table")
		return boundary(value)
	end,
}
