--!strict

local fs = require "@std/fs"
local process = require "@lute/process"

type Options = {
	entries: { string },
	name: string,
	out: string,
	strip: boolean,
}

local function parse(): Options
	local options: Options = { entries = {}, name = "", out = "", strip = false }
	local args = process.args
	local index = 2
	while index <= #args do
		local flag = args[index]
		if flag == "--strip-comments" then
			options.strip = true
			index += 1
			continue
		end
		local value = args[index + 1]
		if flag == "--entry" then
			table.insert(options.entries, value)
		elseif flag == "--name" then
			options.name = value
		elseif flag == "--out" then
			options.out = value
		else
			error(("bundle: unrecognised argument %q"):format(tostring(flag)), 0)
		end
		index += 2
	end
	if #options.entries == 0 or options.name == "" or options.out == "" then
		error("bundle: --entry (at least one), --name, and --out are all required", 0)
	end
	return options
end

local function lines(text: string): { string }
	local out: { string } = {}
	local position = 1
	while true do
		local newline = string.find(text, "\n", position, true)
		if newline == nil then
			table.insert(out, string.sub(text, position))
			break
		end
		table.insert(out, string.sub(text, position, newline - 1))
		position = newline + 1
	end
	return out
end

local function normalise(path: string): string
	local parts: { string } = {}
	for piece in string.gmatch(path, "[^/]+") do
		if piece == "." then
			continue
		elseif piece == ".." then
			if #parts > 0 then
				parts[#parts] = nil
			end
		else
			table.insert(parts, piece)
		end
	end
	return table.concat(parts, "/")
end

local function directoryOf(path: string): string
	local parent = string.match(path, "^(.*)/[^/]+$")
	return if parent ~= nil then parent else ""
end

local function resolve(modulePath: string): string?
	for _, candidate in { modulePath .. ".luau", modulePath .. "/init.luau" } do
		if fs.exists(candidate) and fs.type(candidate) == "file" then
			return candidate
		end
	end
	return nil
end

local function requiresIn(source: string): { string }
	local found: { string } = {}
	local inLongComment = false

	for _, sourceLine in lines(source) do
		local text = sourceLine

		if inLongComment then
			local close = string.find(text, "]]", 1, true)
			if close == nil then
				continue
			end
			inLongComment = false
			text = string.sub(text, close + 2)
		end

		while true do
			local open = string.find(text, "--[[", 1, true)
			if open == nil then
				break
			end
			local close = string.find(text, "]]", open + 4, true)
			if close == nil then
				inLongComment = true
				text = string.sub(text, 1, open - 1)
				break
			end
			text = string.sub(text, 1, open - 1) .. string.sub(text, close + 2)
		end

		local dashes = string.find(text, "--", 1, true)
		if dashes ~= nil then
			text = string.sub(text, 1, dashes - 1)
		end

		for request in string.gmatch(text, 'require%s*%(%s*"([^"]+)"%s*%)') do
			table.insert(found, request)
		end
		for request in string.gmatch(text, 'require%s*"([^"]+)"') do
			table.insert(found, request)
		end
	end

	return found
end

local function collect(modulePath: string, order: { string }, seen: { [string]: string }, visiting: { [string]: true })
	if seen[modulePath] ~= nil then
		return
	end
	if visiting[modulePath] then
		error(("bundle: require cycle at %q"):format(modulePath), 0)
	end
	visiting[modulePath] = true

	local file = resolve(modulePath)
	if file == nil then
		error(("bundle: no module at %q"):format(modulePath), 0)
	end
	local source = fs.readFileToString(file)

	local base = directoryOf(modulePath)

	for _, request in requiresIn(source) do
		local target: string
		if string.sub(request, 1, 6) == "@self/" then
			target = normalise(modulePath .. "/" .. string.sub(request, 7))
		elseif string.sub(request, 1, 1) == "." then
			target = normalise(base .. "/" .. request)
		else
			error(
				("bundle: %s requires %q, which is neither relative nor @self. A bundled package "):format(
					modulePath,
					request
				) .. "cannot reach outside itself.",
				0
			)
		end
		collect(target, order, seen, visiting)
	end

	visiting[modulePath] = nil
	seen[modulePath] = source
	table.insert(order, modulePath)
end

local function rewrite(modulePath: string, source: string, known: { [string]: string }): string
	local base = directoryOf(modulePath)

	source = (
		string.gsub(source, 'require%s*"([^"]+)"', function(request: string): string
			return ('require("%s")'):format(request)
		end)
	)

	return (
		string.gsub(source, 'require%s*%(%s*"([^"]+)"%s*%)', function(request: string): string
			local target: string
			if string.sub(request, 1, 6) == "@self/" then
				target = normalise(modulePath .. "/" .. string.sub(request, 7))
			elseif string.sub(request, 1, 1) == "." then
				target = normalise(base .. "/" .. request)
			else
				return ('require("%s")'):format(request)
			end
			if known[target] == nil then
				return ('require("%s")'):format(request)
			end
			return ('__compose_require("%s")'):format(target)
		end)
	)
end

local function stripComments(source: string): string
	local kept: { string } = {}
	local inLongComment = false

	local function commentStart(text: string): number?
		local quote: string? = nil
		local index = 1
		local length = #text

		while index <= length do
			local character = string.sub(text, index, index)

			if quote ~= nil then
				if character == "\\" then
					index += 2
					continue
				end
				if character == quote then
					quote = nil
				end
				index += 1
				continue
			end

			if character == '"' or character == "'" then
				quote = character
				index += 1
				continue
			end

			if character == "[" and string.sub(text, index + 1, index + 1) == "[" then
				return -1
			end

			if character == "-" and string.sub(text, index + 1, index + 1) == "-" then
				return index
			end

			index += 1
		end

		return nil
	end

	for _, sourceLine in lines(source) do
		local text = sourceLine

		if inLongComment then
			local close = string.find(text, "]]", 1, true)
			if close == nil then
				continue
			end
			inLongComment = false
			text = string.sub(text, close + 2)
		end

		if string.match(text, "^%s*%-%-!") ~= nil then
			table.insert(kept, text)
			continue
		end

		local at = commentStart(text)
		if at == -1 then
			table.insert(kept, text)
			continue
		end

		if at ~= nil then
			if string.sub(text, at, at + 3) == "--[[" then
				local close = string.find(text, "]]", at + 4, true)
				if close == nil then
					inLongComment = true
					text = string.sub(text, 1, at - 1)
				else
					text = string.sub(text, 1, at - 1) .. string.sub(text, close + 2)
				end
			else
				text = string.sub(text, 1, at - 1)
			end
		end

		if string.match(text, "^%s*$") == nil then
			table.insert(kept, (string.gsub(text, "%s+$", "")))
		end
	end

	return table.concat(kept, "\n")
end

local function main(): number
	local options = parse()

	local order: { string } = {}
	local sources: { [string]: string } = {}
	for _, entry in options.entries do
		collect(entry, order, sources, {})
	end

	local out: { string } = {}
	local function line(text: string?)
		table.insert(out, if text ~= nil then text else "")
	end

	line "--!strict"
	line "--[["
	line(("\t%s -- generated bundle. Do not edit."):format(options.name))
	line ""
	line(("\tBuilt from %s by tools/bundle.luau. Every module is inlined"):format(table.concat(options.entries, ", ")))
	line "\tbelow in dependency order, behind a registry that memoises each one exactly as"
	line "\ta module tree would. There is no build step and no dependency: this file is a"
	line "\tModuleScript body."
	line ""
	line(("\t%d modules."):format(#order))
	line "]]"
	line ""
	line "local __compose_modules: { [string]: () -> any } = {}"
	line "local __compose_loaded: { [string]: { value: any } } = {}"
	line ""
	line "local function __compose_require(name: string): any"
	line "\tlocal already = __compose_loaded[name]"
	line "\tif already ~= nil then"
	line "\t\treturn already.value"
	line "\tend"
	line "\tlocal factory = __compose_modules[name]"
	line "\tif factory == nil then"
	line '\t\terror(("bundle: no module named %q"):format(name), 0)'
	line "\tend"
	line "\tlocal value = factory()"
	line "\t__compose_loaded[name] = { value = value }"
	line "\treturn value"
	line "end"
	line ""

	for _, modulePath in order do
		line(("-- ==== %s ===="):format(modulePath))
		line(('__compose_modules["%s"] = function()'):format(modulePath))
		local body = rewrite(modulePath, sources[modulePath], sources)
		if options.strip then
			body = stripComments(body)
		end
		for _, piece in lines(body) do
			line("\t" .. piece)
		end
		line "end"
		line ""
	end

	if #options.entries == 1 then
		line(('return __compose_require("%s")'):format(options.entries[1]))
	else
		line "return {"
		for _, entry in options.entries do
			line(('\t["%s"] = __compose_require("%s"),'):format(entry, entry))
		end
		line "}"
	end

	local directory = directoryOf(options.out)
	if directory ~= "" and not fs.exists(directory) then
		process.run { "mkdir", "-p", directory }
	end
	fs.writeStringToFile(options.out, table.concat(out, "\n") .. "\n")

	print(("bundle: %s -> %s (%d modules)"):format(table.concat(options.entries, " + "), options.out, #order))
	return 0
end

local code = main()
if code ~= 0 then
	process.exit(code)
end
return nil
