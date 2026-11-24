--!strict

local fs = require "@std/fs"
local process = require "@lute/process"
local CompileMap = require "./lib/compile-map"

local USAGE = [[usage: lute run tools/compile-map.luau --binding NAME [--check] FILE...

Rewrites single-source reactive bodies such as `function(use) return f(use(x)) end`
into `NAME.map(x, function(value) return f(value) end)` in place. NAME is the local
bound to Compose in each file; files without it are left alone. A body is rewritten
only when it returns one expression, reads `use` exactly once on a local that is
never reassigned, and passes `use` nowhere else. --check reports what would change
and writes nothing.]]

local binding: string? = nil
local check = false
local files: { string } = {}
local index = 2
while index <= #process.args do
	local argument = process.args[index]
	if argument == "--binding" then
		binding = process.args[index + 1]
		index += 2
	elseif argument == "--check" then
		check = true
		index += 1
	else
		table.insert(files, argument)
		index += 1
	end
end
if binding == nil or #files == 0 then
	print(USAGE)
	process.exit(2)
end
local total = 0
for _, path in files do
	local source = fs.readFileToString(path)
	local result = CompileMap.compile(source, assert(binding))
	if result.rewritten > 0 then
		total += result.rewritten
		print(`{path}: {result.rewritten} binding(s)`)
		if not check then
			fs.writeStringToFile(path, result.source)
		end
	end
end
print(`{total} binding(s) {if check then "would be rewritten" else "rewritten"}`)
