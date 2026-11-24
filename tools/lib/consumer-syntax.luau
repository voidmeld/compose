--!strict

local function requireString(value: unknown): string
	assert(type(value) == "string")
	return value
end

local function requireNumber(value: unknown, ...: unknown): number
	assert(type(value) == "number")
	return value
end

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
		if string.byte(contents, at) ~= 91 then
			return nil, nil
		end
		local cursor = at + 1
		while string.byte(contents, cursor) == 61 do
			cursor += 1
		end
		if string.byte(contents, cursor) ~= 91 then
			return nil, nil
		end
		return cursor, string.sub(contents, at + 1, cursor - 1)
	end

	local index = 1
	while index <= #contents do
		local here = string.sub(contents, index, index + 1)
		if here == "--" then
			local openerEnd, equals = longBracketAt(index + 2)
			if openerEnd ~= nil then
				local closer = "]" .. (requireString(equals)) .. "]"
				local close = string.find(contents, closer, (requireNumber(openerEnd)) + 1, true)
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
				local closer = "]" .. (requireString(equals)) .. "]"
				local close = string.find(contents, closer, (requireNumber(openerEnd)) + 1, true)
					or (#contents - #closer + 1)
				blank((requireNumber(openerEnd)) + 1, close - 1)
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
			local entry: OpenBlock = { kind = "expression", elseSeen = false }
			table.insert(stack, entry)
			return 0, pendingDo
		end
		pruneFinishedExpressions(stack)
		local entry: OpenBlock = { kind = "statement", elseSeen = false }
		table.insert(stack, entry)
		return 1, pendingDo
	elseif word == "else" then
		pruneFinishedExpressions(stack)
		local top = stack[#stack]
		if top ~= nil and top.kind == "expression" then
			top.elseSeen = true
		end
		return 0, pendingDo
	elseif word == "function" or word == "repeat" then
		local entry: OpenBlock = { kind = "block", elseSeen = false }
		table.insert(stack, entry)
		return 1, pendingDo
	elseif word == "for" or word == "while" then
		local entry: OpenBlock = { kind = "block", elseSeen = false }
		table.insert(stack, entry)
		return 1, pendingDo + 1
	elseif word == "do" then
		if pendingDo > 0 then
			return 0, pendingDo - 1
		end
		local entry: OpenBlock = { kind = "block", elseSeen = false }
		table.insert(stack, entry)
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
			local _, finish = string.find(source, "[%a_][%w_]*", index)
			local wordEnd = requireNumber(finish)
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
			local _, finish = string.find(source, "[%a_][%w_]*", index)
			local wordEnd = requireNumber(finish)
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
		table.insert(ranges, { start = requireNumber(start), finish = blockEnd(source, requireNumber(start)) })
		from = (requireNumber(start)) + 8
	end
	return ranges
end

local function innermostFunction(ranges: { Range }, offset: number): number?
	local innermost: number? = nil
	for _, range in ranges do
		if range.start <= offset and offset <= range.finish then
			if innermost == nil or range.start > (requireNumber(innermost)) then
				innermost = range.start
			end
		end
	end
	return innermost
end

local function boundLocalFunctionCalls(source: string): { [number]: true }
	local blocks: { Range } = {}
	local open: { Range } = {}
	local stack: { OpenBlock } = {}
	local pendingDo = 0
	for at, word in string.gmatch(source, "()([%a_][%w_]*)") do
		local offset = requireNumber(tonumber(at))
		local delta
		delta, pendingDo = scanKeyword(requireString(word), source, offset, stack, pendingDo)
		if delta > 0 then
			local range = { start = offset, finish = #source }
			table.insert(open, range)
			if word ~= "function" then
				table.insert(blocks, range)
			end
		elseif delta < 0 and #open > 0 then
			local range = table.remove(open)
			assert(range ~= nil)
			range.finish = offset
		end
	end
	local functions = functionRanges(source)
	local accepted: { [number]: true } = {}
	for at, nameAt, name in string.gmatch(source, "()%f[%w_]local%s+function%s+()([%a_][%w_]*)%s*%(") do
		local declarationAt = requireNumber(tonumber(at))
		local declarationNameAt = requireNumber(tonumber(nameAt))
		local scopeAt = innermostFunction(functions, declarationAt)
		local scopeEnd = #source
		if scopeAt ~= nil then
			for _, range in functions do
				if range.start == scopeAt then
					scopeEnd = range.finish
				end
			end
		end
		local safe = true
		for _, range in blocks do
			if range.start < declarationAt and declarationAt < range.finish then
				safe = false
			end
		end
		local calls: { number } = {}
		for occurrenceAt, finishAt in string.gmatch(source, "()%f[%w_]" .. (requireString(name)) .. "%f[^%w_]()%s*") do
			local occurrence = requireNumber(tonumber(occurrenceAt))
			local finish = requireNumber(tonumber(finishAt))
			if occurrence == declarationNameAt then
				continue
			end
			local before = string.sub(source, 1, occurrence - 1)
			local after = string.sub(source, finish)
			local directCall = string.match(after, "^%s*%(") ~= nil
			local value = string.match(before, "=%s*$") ~= nil and string.match(after, "^%s*[,}]") ~= nil
			if
				occurrence <= declarationAt
				or occurrence >= scopeEnd
				or string.match(before, "[%.:]%s*$") ~= nil
				or string.match(before, "%f[%w_]function%s+$") ~= nil
				or (not directCall and not value)
			then
				safe = false
			elseif directCall then
				table.insert(calls, occurrence)
			end
		end
		if safe then
			accepted[declarationNameAt] = true
			for _, offset in calls do
				accepted[offset] = true
			end
		end
	end
	return accepted
end

local function callForms(
	masked: string,
	modules: { [string]: true },
	aliases: { [string]: true },
	member: string,
	opening: string
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
		local pattern = "%f[%w_]" .. escapePattern(name) .. "%s*" .. escapePattern(opening)
		while true do
			local start, stop = string.find(masked, pattern, from)
			if start == nil then
				break
			end
			local open = requireNumber(string.find(masked, opening, requireNumber(start), true))
			table.insert(calls, { offset = requireNumber(start), open = open })
			from = (requireNumber(stop)) + 1
		end
	end
	return calls
end

return {
	mask = mask,
	escapePattern = escapePattern,
	matching = matching,
	tableEntries = tableEntries,
	blockEnd = blockEnd,
	functionRanges = functionRanges,
	innermostFunction = innermostFunction,
	boundLocalFunctionCalls = boundLocalFunctionCalls,
	callForms = callForms,
}
