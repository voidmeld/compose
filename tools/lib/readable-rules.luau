--!strict

export type Rule = {
	code: string,
	pattern: string,
	why: string,
	fix: string,
	bodyNames: boolean?,
}

local BODY_NAMES: { [string]: true } = {
	["function"] = true,
	["body"] = true,
	["source"] = true,
	["render"] = true,
	["window"] = true,
	["compute"] = true,
	["builder"] = true,
	["condition"] = true,
	["from"] = true,
	["when"] = true,
	["produce"] = true,
	["read"] = true,
	["effect"] = true,
	["fn"] = true,
}

local function isBodyName(name: string): boolean
	if BODY_NAMES[name] then
		return true
	end
	return string.sub(name, -4) == "Body" and #name > 4
end

local RULES: { Rule } = {
	{
		code = "CMP011",
		pattern = "%f[%w_]([%w_]+)%s*%(use%)",
		why = "a tracked read is use(x), not x(use)",
		fix = "write use(x); only a reactive body is called with the reader",
		bodyNames = true,
	},
	{
		code = "CMP016",

		pattern = "local%s+[%w_]+%s*,%s*[%w_]+%s*=%s*[%w_.]*cell%s*%([^,()\n]*%)%s*\n",
		why = "a cell is one object, not a value and a setter",
		fix = "write `local value = Compose.cell(x)` and use value:set(...) and value:peek()",
	},
}

local function occurrences(contents: string, rule: Rule): { { offset: number, capture: string? } }
	local found: { { offset: number, capture: string? } } = {}
	local from = 1
	while true do
		local start, stop, name = string.find(contents, rule.pattern, from)
		if start == nil then
			break
		end
		from = (stop :: number) + 1
		if rule.bodyNames and isBodyName(name :: string) then
			continue
		end
		table.insert(found, { offset = start :: number, capture = if rule.bodyNames then name :: string else nil })
	end
	return found
end

return {
	rules = RULES,
	bodyNames = BODY_NAMES,
	isBodyName = isBodyName,
	occurrences = occurrences,
}
