--!strict

export type Confidence = "certain" | "likely"

export type Finding = {
	code: string,
	confidence: Confidence,
	offset: number,
	why: string,
	fix: string,
	caveat: string?,
}

local STRUCTURAL_FIELDS: { [string]: { [string]: true } } = {
	keyed = { from = true, key = true, render = true },
	OrderedCollection = {
		from = true,
		key = true,
		render = true,
		mode = true,
		viewport = true,
		direction = true,
		layout = true,
		overscan = true,
		measured = true,
		follow = true,
		followThreshold = true,
		status = true,
		controls = true,
	},
	SpatialCollection = {
		from = true,
		key = true,
		position = true,
		origin = true,
		tiers = true,
		render = true,
		cellSize = true,
		hysteresis = true,
		importance = true,
		pinned = true,
		budget = true,
		status = true,
	},
	LayerStack = { from = true, key = true, render = true, retention = true },
	MountBudget = {
		from = true,
		key = true,
		render = true,
		mountsPerFrame = true,
		priority = true,
		status = true,
	},
	createFocusScope = {
		from = true,
		key = true,
		disabled = true,
		position = true,
		wrap = true,
		initial = true,
		autoFocus = true,
	},
	createPool = { create = true, destroy = true, reset = true, maxRetained = true },
	accumulator = { from = true, reduce = true, initial = true, equals = true },
}

local REQUIRED_FIELDS: { [string]: { string } } = {
	keyed = { "from", "render" },
	OrderedCollection = { "from", "render" },
	SpatialCollection = { "from", "position", "origin", "tiers", "render" },
	LayerStack = { "from", "render" },
	MountBudget = { "from", "mountsPerFrame", "render" },
	createFocusScope = { "from" },
	createPool = { "create", "destroy", "maxRetained" },
	accumulator = { "from", "reduce" },
}

local DIRECTIVES = {
	"show",
	"switch",
	"keyed",
	"indexes",
	"fragment",
	"portal",
	"presence",
	"boundary",
	"OrderedCollection",
	"SpatialCollection",
	"LayerStack",
	"MountBudget",
}

local function mask(contents: string): string
	local chars = table.create(#contents)
	for index = 1, #contents do
		chars[index] = string.sub(contents, index, index)
	end

	local function blank(from: number, through: number)
		for index = from, through do
			if chars[index] ~= "\n" then
				chars[index] = " "
			end
		end
	end

	local function longBracketAt(at: number): (number?, string?)
		local _, relativeEnd, equals = string.find(string.sub(contents, at), "^%[(=*)%[")
		if relativeEnd == nil then
			return nil, nil
		end
		return at + (relativeEnd :: number) - 1, equals :: string
	end

	local index = 1
	while index <= #contents do
		local here = string.sub(contents, index, index + 1)
		if here == "--" then
			local openerEnd, equals = longBracketAt(index + 2)
			if openerEnd ~= nil then
				local closer = "]" .. (equals :: string) .. "]"
				local close = string.find(contents, closer, (openerEnd :: number) + 1, true)
					or (#contents - #closer + 1)
				blank(index, close + #closer - 1)
				index = close + #closer
			else
				local close = string.find(contents, "\n", index + 2, true) or (#contents + 1)
				blank(index, close - 1)
				index = close
			end
		elseif string.sub(contents, index, index) == "[" then
			local openerEnd, equals = longBracketAt(index)
			if openerEnd ~= nil then
				local closer = "]" .. (equals :: string) .. "]"
				local close = string.find(contents, closer, (openerEnd :: number) + 1, true)
					or (#contents - #closer + 1)
				blank((openerEnd :: number) + 1, close - 1)
				index = close + #closer
			else
				index += 1
			end
		else
			local quote = string.sub(contents, index, index)
			if quote == '"' or quote == "'" then
				local cursor = index + 1
				while cursor <= #contents do
					local character = string.sub(contents, cursor, cursor)
					if character == "\\" then
						cursor += 2
					elseif character == quote then
						break
					else
						cursor += 1
					end
				end
				blank(index + 1, math.min(cursor - 1, #contents))
				index = cursor + 1
			else
				index += 1
			end
		end
	end
	return table.concat(chars)
end

local function escapePattern(value: string): string
	return (string.gsub(value, "([^%w])", "%%%1"))
end

local function matching(source: string, openAt: number, opening: string, closing: string): number?
	local depth = 0
	for index = openAt, #source do
		local character = string.sub(source, index, index)
		if character == opening then
			depth += 1
		elseif character == closing then
			depth -= 1
			if depth == 0 then
				return index
			end
		end
	end
	return nil
end

local function nextNonSpace(source: string, from: number): number?
	local at = string.find(source, "%S", from)
	return at
end

local function normalizedPath(argument: string): string
	local out = string.lower(argument)
	out = string.gsub(out, "%[%s*['\"]([%w_%-]+)['\"]%s*%]", ".%1")
	out = string.gsub(out, "%s+", "")
	return out
end

local function coreAliases(contents: string, masked: string): { [string]: true }
	local aliases: { [string]: true } = { Compose = true }
	local from = 1
	while true do
		local start, stop, name = string.find(masked, "local%s+([%w_]+)%s*=%s*require%s*%(", from)
		if start == nil then
			break
		end
		local open = string.find(masked, "(", stop :: number, true) :: number?
		if open == nil then
			break
		end
		local close = matching(masked, open :: number, "(", ")")
		if close == nil then
			break
		end
		local path = normalizedPath(string.sub(contents, (open :: number) + 1, (close :: number) - 1))
		if string.find(path, "compose.core", 1, true) ~= nil then
			aliases[name :: string] = true
		end
		from = (close :: number) + 1
	end
	return aliases
end

local function memberAliases(masked: string, modules: { [string]: true }, member: string): { [string]: true }
	local aliases: { [string]: true } = {}
	for module in modules do
		local pattern = "local%s+([%w_]+)%s*=%s*" .. escapePattern(module) .. "%." .. member .. "%f[^%w_]"
		for alias in string.gmatch(masked, pattern) do
			aliases[alias] = true
		end
	end
	return aliases
end

local function lane(text: string, seed: number): number
	local hash = seed
	for index = 1, #text do
		hash = bit32.bxor(hash, string.byte(text, index))
		local low = bit32.band(hash, 0xFFFF) * 16777619
		local high = bit32.rshift(hash, 16) * 16777619
		hash = bit32.band(low + bit32.lshift(bit32.band(high, 0xFFFF), 16), 0xFFFFFFFF)
	end
	return hash
end

local function digestText(text: string): string
	return ("%08x%08x"):format(lane(text, 2166136261), lane(text, 0x811C9DC7))
end

local BUILD_TOOLING_DIRS = { "/tools/", "/lute/", "/bench/", "/tests/" }

local SPECIFICATION_SUFFIXES = { "%.verify%.luau$", "%.spec%.luau$" }

local function isBuildTooling(relativePath: string?): boolean
	if relativePath == nil then
		return false
	end
	local normalized = "/" .. (string.gsub(relativePath, "\\", "/"))
	for _, piece in BUILD_TOOLING_DIRS do
		if string.find(normalized, piece, 1, true) ~= nil then
			return true
		end
	end
	for _, suffix in SPECIFICATION_SUFFIXES do
		if string.find(normalized, suffix) ~= nil then
			return true
		end
	end
	return false
end

local function namesAuthoringPackage(path: string): boolean
	return string.find(path, "%f[%w%-]compose%-authoring%f[^%w%-]") ~= nil
end

local function add(found: { Finding }, seen: { [string]: true }, finding: Finding)
	local key = finding.code .. ":" .. tostring(finding.offset)
	if seen[key] == nil then
		seen[key] = true
		table.insert(found, finding)
	end
end

type Entry = { offset: number, text: string }

local EXPRESSION_CONTEXT_WORDS: { [string]: true } = {
	["return"] = true,
	["and"] = true,
	["or"] = true,
	["not"] = true,
	["while"] = true,
	["until"] = true,
	["in"] = true,
}

type OpenBlock = { kind: "statement" | "expression" | "block", elseSeen: boolean }

local function pruneFinishedExpressions(stack: { OpenBlock })
	while #stack > 0 and stack[#stack].kind == "expression" and stack[#stack].elseSeen do
		table.remove(stack)
	end
end

local function inExpressionContext(source: string, before: number, stack: { OpenBlock }): boolean
	local index = before
	while index >= 1 and string.match(string.sub(source, index, index), "%s") ~= nil do
		index -= 1
	end
	if index < 1 then
		return false
	end
	local character = string.sub(source, index, index)
	if string.find("=(,{[+-*/%^<~#;:.", character, 1, true) ~= nil then
		return true
	end
	if string.match(character, "[%w_]") ~= nil then
		local wordStart = index
		while wordStart > 1 and string.match(string.sub(source, wordStart - 1, wordStart - 1), "[%w_]") ~= nil do
			wordStart -= 1
		end
		local word = string.sub(source, wordStart, index)
		if word == "then" or word == "else" or word == "elseif" then
			pruneFinishedExpressions(stack)
			local top = stack[#stack]
			return top ~= nil and top.kind == "expression"
		end
		return EXPRESSION_CONTEXT_WORDS[word] == true
	end
	return false
end

local function scanKeyword(
	word: string,
	source: string,
	wordAt: number,
	stack: { OpenBlock },
	pendingDo: number
): (number, number)
	if word == "if" then
		if inExpressionContext(source, wordAt - 1, stack) then
			table.insert(stack, { kind = "expression" :: "expression", elseSeen = false })
			return 0, pendingDo
		end
		pruneFinishedExpressions(stack)
		table.insert(stack, { kind = "statement" :: "statement", elseSeen = false })
		return 1, pendingDo
	elseif word == "else" then
		pruneFinishedExpressions(stack)
		local top = stack[#stack]
		if top ~= nil and top.kind == "expression" then
			top.elseSeen = true
		end
		return 0, pendingDo
	elseif word == "function" or word == "repeat" then
		table.insert(stack, { kind = "block" :: "block", elseSeen = false })
		return 1, pendingDo
	elseif word == "for" or word == "while" then
		table.insert(stack, { kind = "block" :: "block", elseSeen = false })
		return 1, pendingDo + 1
	elseif word == "do" then
		if pendingDo > 0 then
			return 0, pendingDo - 1
		end
		table.insert(stack, { kind = "block" :: "block", elseSeen = false })
		return 1, pendingDo
	elseif word == "end" or word == "until" then
		while #stack > 0 and stack[#stack].kind == "expression" do
			table.remove(stack)
		end
		if #stack > 0 then
			table.remove(stack)
		end
		return -1, pendingDo
	end
	return 0, pendingDo
end

local function tableEntries(source: string, openAt: number): { Entry }
	local close = matching(source, openAt, "{", "}")
	if close == nil then
		return {}
	end
	local entries: { Entry } = {}
	local braceDepth = 1
	local parenDepth = 0
	local bracketDepth = 0
	local blockDepth = 0
	local pendingDo = 0
	local stack: { OpenBlock } = {}
	local entryAt = openAt + 1
	local index = openAt + 1
	while index < close do
		local character = string.sub(source, index, index)
		if character == "{" then
			braceDepth += 1
		elseif character == "}" then
			braceDepth -= 1
		elseif character == "(" then
			parenDepth += 1
		elseif character == ")" then
			parenDepth -= 1
		elseif character == "[" then
			bracketDepth += 1
		elseif character == "]" then
			bracketDepth -= 1
		elseif string.match(character, "[%a_]") then
			local _, relativeEnd = string.find(string.sub(source, index), "^[%a_][%w_]*")
			local wordEnd = index + (relativeEnd :: number) - 1
			local word = string.sub(source, index, wordEnd)
			local delta
			delta, pendingDo = scanKeyword(word, source, index, stack, pendingDo)
			blockDepth = math.max(0, blockDepth + delta)
			index = wordEnd
		elseif character == "," and braceDepth == 1 and parenDepth == 0 and bracketDepth == 0 and blockDepth == 0 then
			table.insert(entries, { offset = entryAt, text = string.sub(source, entryAt, index - 1) })
			entryAt = index + 1
		end
		index += 1
	end
	table.insert(entries, { offset = entryAt, text = string.sub(source, entryAt, close - 1) })
	return entries
end

local function blockEnd(source: string, openAt: number): number
	local depth = 0
	local pendingDo = 0
	local stack: { OpenBlock } = {}
	local index = openAt
	while index <= #source do
		local character = string.sub(source, index, index)
		if string.match(character, "[%a_]") ~= nil then
			local _, relativeEnd = string.find(string.sub(source, index), "^[%a_][%w_]*")
			local wordEnd = index + (relativeEnd :: number) - 1
			local word = string.sub(source, index, wordEnd)
			local delta
			delta, pendingDo = scanKeyword(word, source, index, stack, pendingDo)
			depth += delta
			if delta < 0 and depth <= 0 then
				return wordEnd
			end
			index = wordEnd + 1
		else
			index += 1
		end
	end
	return #source
end

type Range = { start: number, finish: number }

local function functionRanges(source: string): { Range }
	local ranges: { Range } = {}
	local from = 1
	while true do
		local start = string.find(source, "%f[%w_]function%f[^%w_]", from)
		if start == nil then
			break
		end
		table.insert(ranges, { start = start :: number, finish = blockEnd(source, start :: number) })
		from = (start :: number) + 8
	end
	return ranges
end

local function innermostFunction(ranges: { Range }, offset: number): number?
	local innermost: number? = nil
	for _, range in ranges do
		if range.start <= offset and offset <= range.finish then
			if innermost == nil or range.start > (innermost :: number) then
				innermost = range.start
			end
		end
	end
	return innermost
end

local function callForms(
	masked: string,
	modules: { [string]: true },
	aliases: { [string]: true },
	member: string
): { { offset: number, open: number } }
	local calls: { { offset: number, open: number } } = {}
	local names: { string } = {}
	for alias in aliases do
		table.insert(names, alias)
	end
	for module in modules do
		table.insert(names, module .. "." .. member)
	end
	for _, name in names do
		local from = 1
		local pattern = "%f[%w_]" .. escapePattern(name) .. "%s*%("
		while true do
			local start, stop = string.find(masked, pattern, from)
			if start == nil then
				break
			end
			local open = string.find(masked, "(", start :: number, true) :: number
			table.insert(calls, { offset = start :: number, open = open })
			from = (stop :: number) + 1
		end
	end
	return calls
end

local function tableForms(
	masked: string,
	modules: { [string]: true },
	aliases: { [string]: true },
	member: string
): { { offset: number, open: number } }
	local forms: { { offset: number, open: number } } = {}
	local names: { string } = {}
	for alias in aliases do
		table.insert(names, alias)
	end
	for module in modules do
		table.insert(names, module .. "." .. member)
	end
	for _, name in names do
		local from = 1
		local pattern = "%f[%w_]" .. escapePattern(name) .. "%s*{"
		while true do
			local start, stop = string.find(masked, pattern, from)
			if start == nil then
				break
			end
			local open = string.find(masked, "{", start :: number, true) :: number
			table.insert(forms, { offset = start :: number, open = open })
			from = (stop :: number) + 1
		end
	end
	return forms
end

local function scan(contents: string, relativePath: string?): { Finding }
	local source = mask(contents)
	local modules = coreAliases(contents, source)
	local found: { Finding } = {}
	local seen: { [string]: true } = {}

	local structuralAliases: { [string]: { [string]: true } } = {}
	for primitive in STRUCTURAL_FIELDS do
		structuralAliases[primitive] = memberAliases(source, modules, primitive)
		for _, call in callForms(source, modules, structuralAliases[primitive], primitive) do
			local first = nextNonSpace(source, call.open + 1)
			if first == nil or string.sub(source, first :: number, first :: number) ~= "{" then
				add(found, seen, {
					code = "CMP017",
					confidence = "certain",
					offset = call.offset,
					why = primitive .. " takes one table of named options",
					fix = "write " .. primitive .. " { ... } with the documented named fields",
					caveat = nil,
				})
			end
		end

		local forms = tableForms(source, modules, structuralAliases[primitive], primitive)
		for _, call in callForms(source, modules, structuralAliases[primitive], primitive) do
			local first = nextNonSpace(source, call.open + 1)
			if first ~= nil and string.sub(source, first :: number, first :: number) == "{" then
				table.insert(forms, { offset = call.offset, open = first :: number })
			end
		end
		local known = STRUCTURAL_FIELDS[primitive]
		local knownNames: { string } = {}
		for name in known do
			table.insert(knownNames, name)
		end
		table.sort(knownNames)
		for _, form in forms do
			local provided: { [string]: true } = {}
			local dynamic = false
			local required: { string } = REQUIRED_FIELDS[primitive] or {}
			for _, entry in tableEntries(source, form.open) do
				local field = string.match(entry.text, "^%s*([%a_][%w_]*)%s*=")
				if field ~= nil then
					provided[field] = true
				elseif string.find(entry.text, "%S") ~= nil then
					dynamic = true
				end
				if field ~= nil and known[field] == nil then
					add(found, seen, {
						code = "CMP018",
						confidence = "certain",
						offset = entry.offset,
						why = ("%s has no option named %s"):format(primitive, field),
						fix = "use only: " .. table.concat(knownNames, ", "),
						caveat = nil,
					})
				end
			end
			if not dynamic then
				for _, field in required do
					if provided[field] == nil then
						add(found, seen, {
							code = "CMP025",
							confidence = "certain",
							offset = form.offset,
							why = ("%s requires the %s option"):format(primitive, field),
							fix = ("add %s = ... to the options table"):format(field),
							caveat = nil,
						})
					end
				end
			end
		end
	end

	local requireFrom = 1
	while true do
		local start, stop = string.find(source, "%f[%w_]require%s*%(", requireFrom)
		if start == nil then
			break
		end
		local open = string.find(source, "(", start :: number, true) :: number
		local close = matching(source, open, "(", ")")
		if close == nil then
			break
		end
		local path = normalizedPath(string.sub(contents, open + 1, (close :: number) - 1))
		if
			string.find(path, "compose.core.", 1, true) ~= nil
			or string.find(path, "compose.roblox.", 1, true) ~= nil
			or string.find(path, "compose.src.", 1, true) ~= nil
		then
			add(found, seen, {
				code = "CMP019",
				confidence = "certain",
				offset = start :: number,
				why = "the import reaches through Compose's documented package entry point",
				fix = "import compose.core or compose.roblox and use only their documented public exports",
				caveat = nil,
			})
		end
		if namesAuthoringPackage(path) and not isBuildTooling(relativePath) then
			add(found, seen, {
				code = "CMP032",
				confidence = "certain",
				offset = start :: number,
				why = "the authoring layer is a build/edit-time companion -- a runtime require drags "
					.. "validation, codegen, and serialization machinery onto the hot path the library's "
					.. "performance contract protects",
				fix = "move the use into a build tool or spec, or consume the baked artifact (generated "
					.. "module, attributes) instead",
				caveat = nil,
			})
		end
		requireFrom = (stop :: number) + 1
	end

	local cleanupAliases = memberAliases(source, modules, "cleanup")
	local cleanupNames: { string } = {}
	for alias in cleanupAliases do
		table.insert(cleanupNames, alias)
	end
	for module in modules do
		table.insert(cleanupNames, module .. ".cleanup")
	end
	for _, cleanup in cleanupNames do
		for _, mount in { "mount", "mountFragment" } do
			local pattern = "%f[%w_]" .. escapePattern(cleanup) .. "%s*%(%s*[%w_.]+%." .. mount .. "%s*%("
			local from = 1
			while true do
				local start, stop = string.find(source, pattern, from)
				if start == nil then
					break
				end
				add(found, seen, {
					code = "CMP020",
					confidence = "likely",
					offset = start :: number,
					why = "a nested mount already belongs to the active owner; registering its disposer again changes teardown order",
					fix = "call runtime.mount or runtime.mountFragment directly inside the component; retain its disposer only for a top-level mount",
					caveat = "this is valid when the mount runs with no active owner and this cleanup is its deliberate lifetime",
				})
				from = (stop :: number) + 1
			end
		end
	end
	for _, mount in { "mount", "mountFragment" } do
		for start in string.gmatch(source, "()([%w_.]+)%.own%s*%(%s*[%w_.]+%." .. mount .. "%s*%(") do
			local offset = tonumber(start) :: number
			add(found, seen, {
				code = "CMP020",
				confidence = "likely",
				offset = offset,
				why = "a nested mount already belongs to the active owner; registering its disposer again changes teardown order",
				fix = "call the nested mount directly and let its active owner hold it",
				caveat = "this is valid when the mount ran outside that owner and is intentionally transferred into it",
			})
		end
	end

	local createAliases: { [string]: true } = { create = true }
	for alias in string.gmatch(source, "local%s+([%w_]+)%s*=%s*[%w_.]+%.create%f[^%w_]") do
		createAliases[alias] = true
	end
	local constructors: { [string]: true } = {}
	for create in createAliases do
		for _, suffix in { "%s*['\"]", "%s*%(%s*['\"]" } do
			local pattern = "local%s+([%w_]+)%s*=%s*" .. escapePattern(create) .. suffix
			for constructor in string.gmatch(source, pattern) do
				constructors[constructor] = true
			end
		end
	end
	local directiveSymbols: { [string]: true } = {}
	for _, directive in DIRECTIVES do
		for alias in memberAliases(source, modules, directive) do
			directiveSymbols[alias] = true
		end
		for module in modules do
			directiveSymbols[module .. "." .. directive] = true
		end
	end
	for constructor in constructors do
		local forms = tableForms(source, {}, { [constructor] = true }, "")
		local labelled = "%f[%w_]" .. escapePattern(constructor) .. "%s*['\"][^'\"]*['\"]%s*{"
		local from = 1
		while true do
			local start, stop = string.find(source, labelled, from)
			if start == nil then
				break
			end
			local open = string.find(source, "{", start :: number, true) :: number
			table.insert(forms, { offset = start :: number, open = open })
			from = (stop :: number) + 1
		end
		for _, form in forms do
			for _, entry in tableEntries(source, form.open) do
				local trimmed = string.gsub(entry.text, "^%s+", "")
				if string.match(trimmed, "^function%s*%(%s*[%w_]*%s*%)") ~= nil then
					add(found, seen, {
						code = "CMP022",
						confidence = "likely",
						offset = entry.offset,
						why = "a function in child position is a directive and receives a MountPoint, not an ordinary child callback",
						fix = "call the component and place its node here, or author an explicit directive that accepts a MountPoint",
						caveat = "this is valid if the function is intentionally a custom directive",
					})
				else
					local symbol = string.match(trimmed, "^([%w_.]+)%s*$")
					if symbol ~= nil and directiveSymbols[symbol] then
						add(found, seen, {
							code = "CMP023",
							confidence = "certain",
							offset = entry.offset,
							why = "a directive constructor was placed in the tree without being called",
							fix = ("call %s(...) so it returns a directive"):format(symbol),
							caveat = nil,
						})
					end
				end
			end
		end
	end

	for _, operation in { "mountFragment", "mount" } do
		for start in string.gmatch(source, "()[%w_]+%s*:%s*" .. operation .. "%s*%(") do
			add(found, seen, {
				code = "CMP026",
				confidence = "likely",
				offset = tonumber(start) :: number,
				why = ("%s is a Compose runtime table function, not a colon method"):format(operation),
				fix = ("use dot syntax: runtime.%s(...)"):format(operation),
				caveat = "this is a false positive if the receiver is not a Compose runtime",
			})
		end
	end

	local mountDirectivePattern = "[%w_.]+%.mount%s*%(%s*function%s*%([^%)]*%)%s*return%s+([%w_.]+)"
	for start, symbol in string.gmatch(source, "()" .. mountDirectivePattern) do
		if directiveSymbols[symbol] then
			add(found, seen, {
				code = "CMP027",
				confidence = "likely",
				offset = tonumber(start) :: number,
				why = "runtime.mount requires one node, but this builder returns a structural directive",
				fix = "use runtime.mountFragment for a top-level directive, or put the directive inside a node",
				caveat = "this is a false positive if mount is not Compose's runtime.mount",
			})
		end
	end

	local identityPattern = "([%w_]+)%s*=%s*function%s*%(use[^%)]*%)%s*return%s+use%s*%(%s*[%w_.]+%s*%)%s*end"
	local from = 1
	while true do
		local start, stop, field = string.find(source, identityPattern, from)
		if start == nil then
			break
		end

		if field ~= "from" then
			add(found, seen, {
				code = "CMP024",
				confidence = "likely",
				offset = start :: number,
				why = "an identity reactive wrapper obscures a direct binding and misses its shared static sink",
				fix = "bind the readable directly: Property = value",
				caveat = "keep the body if it is about to gain a transformation or deliberate dynamic dependencies",
			})
		end
		from = (stop :: number) + 1
	end

	local runtimeNames: { [string]: true } = { runtime = true, Runtime = true }
	for alias in string.gmatch(source, "%f[%w_]local%s+([%w_]+)%s*=%s*[%w_.]*createRuntime%s*%(") do
		runtimeNames[alias] = true
	end
	for name in runtimeNames do
		if modules[name] ~= nil then
			continue
		end
		for _, control in { "watch", "batch", "settle", "pending" } do
			local pattern = "%f[%w_]" .. escapePattern(name) .. "%s*%." .. control .. "%s*%("
			local searchFrom = 1
			while true do
				local start, stop = string.find(source, pattern, searchFrom)
				if start == nil then
					break
				end
				local before = if (start :: number) > 1
					then string.sub(source, (start :: number) - 1, (start :: number) - 1)
					else ""

				if before ~= "." and before ~= ":" then
					add(found, seen, {
						code = "CMP028",
						confidence = "certain",
						offset = start :: number,
						why = (
							"%s is a method on the runtime; the dot call binds the first argument as "
							.. "self, so a watch body passed this way is dropped without an error"
						):format(control),
						fix = ("use method syntax: %s:%s(...)"):format(name, control),
						caveat = nil,
					})
				end
				searchFrom = (stop :: number) + 1
			end
		end
	end

	local ranges = functionRanges(source)

	for _, opener in { "watch", "formula" } do
		local bodyPattern = "%f[%w_]" .. opener .. "%s*%(%s*function%f[^%w_]"
		local bodyFrom = 1
		while true do
			local start, stop = string.find(source, bodyPattern, bodyFrom)
			if start == nil then
				break
			end
			local functionAt = (stop :: number) - 7
			local bodyClose = blockEnd(source, functionAt)
			local peekFrom = functionAt
			while true do
				local peekAt = string.find(source, ":%s*peek%s*%(", peekFrom)
				if peekAt == nil or (peekAt :: number) > bodyClose then
					break
				end
				add(found, seen, {
					code = "CMP029",
					confidence = "likely",
					offset = peekAt :: number,
					why = ":peek() inside a reactive body reads without depending, so this "
						.. opener
						.. " will not re-run when that value changes",
					fix = "read through the body's reader -- use(value) -- so the dependency is tracked",
					caveat = "an untracked read on purpose is legitimate: writing a cell this same watch "
						.. "sets, or a value deliberately sampled once per run",
				})
				peekFrom = (peekAt :: number) + 1
			end
			bodyFrom = (stop :: number) + 1
		end
	end

	local stateAliases: { [string]: { [string]: true } } = {}
	for _, state in { "cell", "formula" } do
		stateAliases[state] = memberAliases(source, modules, state)
		for _, call in callForms(source, modules, stateAliases[state], state) do
			if innermostFunction(ranges, call.offset) == nil then
				add(found, seen, {
					code = "CMP030",
					confidence = "likely",
					offset = call.offset,
					why = ("a %s created at module scope is shared by every consumer of the module and has no owner to dispose it"):format(
						state
					),
					fix = ("create the %s inside a component or mount body so its owner's lifetime bounds it"):format(
						state
					) .. if state == "cell"
						then ", or state the intent with Compose.sharedCell for a deliberate singleton"
						else "",
					caveat = "a deliberate process-wide singleton is legitimate; module scope is then the point"
						.. if state == "cell" then ", and Compose.sharedCell says so in the constructor" else "",
				})
			end
		end
	end

	local cellNames: { string } = {}
	for alias in stateAliases.cell do
		table.insert(cellNames, alias)
	end
	for module in modules do
		table.insert(cellNames, module .. ".cell")
	end
	for _, name in cellNames do
		local declPattern = "()%f[%w_]local%s+([%w_]+)%s*=%s*" .. escapePattern(name) .. "%s*%("
		for declAt, variable in string.gmatch(source, declPattern) do
			local declOffset = tonumber(declAt) :: number
			local declScope = innermostFunction(ranges, declOffset)
			local watchFrom = declOffset
			while true do
				local start, stop = string.find(source, "%f[%w_]watch%s*%(%s*function%f[^%w_]", watchFrom)
				if start == nil then
					break
				end
				if innermostFunction(ranges, start :: number) == declScope then
					local functionAt = (stop :: number) - 7
					local body = string.sub(source, functionAt, blockEnd(source, functionAt))
					if
						string.find(body, "%f[%w_]" .. escapePattern(variable :: string) .. "%s*:%s*set%s*%(") ~= nil
					then
						add(found, seen, {
							code = "CMP031",
							confidence = "likely",
							offset = start :: number,
							why = ("this watch exists to write %s from other reactive values -- an eager derivation that formula computes lazily, with equal values suppressed"):format(
								variable
							),
							fix = (
								"replace the cell and the watch with %s = formula(function(use) return ... end); "
								.. "a merge of discrete events into running state is %s = Compose.accumulator { from = ..., reduce = ... }"
							):format(variable, variable),
							caveat = "a watch that writes a cell is legitimate when the write bridges into imperative code rather than deriving a pure value; one that accumulates history belongs in Compose.accumulator",
						})
					end
				end
				watchFrom = (stop :: number) + 1
			end
		end
	end

	local generatorAt = string.find(contents, "generator: Author.bake.registryModule (authoring/bake.luau)", 1, true)
	if generatorAt ~= nil then
		local closeAt = string.find(contents, "]]", generatorAt :: number, true)
		if closeAt ~= nil then
			local header = string.sub(contents, 1, (closeAt :: number) - 1)
			local bodyAt = string.find(contents, "\n\n", closeAt :: number, true)
			if bodyAt ~= nil then
				local body = string.sub(contents, (bodyAt :: number) + 2)
				local expected = string.match(header, "body digest:%s*(%x+)")
				local actual = digestText(body)
				if expected == nil or string.lower(expected) ~= string.lower(actual) then
					add(found, seen, {
						code = "CMP033",
						confidence = "likely",
						offset = generatorAt :: number,
						why = "the header's body digest no longer matches this file's body -- either the "
							.. "file was hand-edited after Author.bake.registryModule generated it, or it "
							.. "was never regenerated after the data or mapping it names changed",
						fix = "regenerate the module with Author.bake.registryModule and commit the result "
							.. "unedited, or make the change in the entry set or mapping and regenerate from "
							.. "there",
						caveat = "this cannot tell a hand edit apart from a body digest computed by a "
							.. "different bake.luau revision -- if the generator's own emission format "
							.. "changed, regenerating once makes the header true again with no further edit "
							.. "needed",
					})
				end
			end
		end
	end

	table.sort(found, function(left: Finding, right: Finding): boolean
		if left.offset ~= right.offset then
			return left.offset < right.offset
		end
		return left.code < right.code
	end)
	return found
end

return {
	mask = mask,
	scan = scan,
}
