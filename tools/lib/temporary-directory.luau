--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

local TemporaryDirectory = {}

function TemporaryDirectory.run<T>(parent: string, prefix: string, body: (string) -> T): T
	assert(string.match(prefix, "^[%w%-]+$") ~= nil, "temporary-directory: invalid prefix")
	local template = string.gsub(parent, "/+$", "") .. "/" .. prefix .. ".XXXXXXXX"
	local allocated = process.run { "mktemp", "-d", template }
	if not allocated.ok then
		error("temporary-directory: allocation failed: " .. allocated.stderr, 0)
	end
	local path = string.gsub(allocated.stdout, "%s+$", "")
	local ok, result = pcall(body, path)
	local cleaned, cleanupError = pcall(function()
		fs.removeDirectory(path, { recursive = true })
		return true
	end)
	if not cleaned then
		error("temporary-directory: cleanup failed for " .. path .. ": " .. tostring(cleanupError), 0)
	end
	if not ok then
		error(result, 0)
	end
	return result
end

return TemporaryDirectory
