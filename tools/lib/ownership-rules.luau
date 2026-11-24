--!strict

local parser = require "@std/syntax/parser"
local visitor = require "@std/syntax/visitor"
local syntax = require "@std/syntax"

export type Finding = { path: string, line: number, rule: string, message: string, snippet: string }
export type Naming = {
	hosts: { string },
	forbidName: boolean?,
	namedMounts: boolean?,
	namedRender: boolean?,
	namedReturns: boolean?,
	rootLabel: boolean?,
	component: { typeName: string, field: string, definitionPath: string }?,
}
export type Pattern = { rule: string, pattern: string }
export type Count = { path: string, rule: string, pattern: string, count: number }
export type Options = {
	ownership: boolean?,
	naming: Naming?,
	patterns: { Pattern }?,
	counts: { Count }?,
	nestedCalls: { string }?,
	enabled: ((path: string, rule: string) -> boolean)?,
}

local function member(node: syntax.CstExpr): string?
	if node.tag == "indexname" then
		return node.index.text
	elseif node.tag == "index" and node.index.tag == "string" then
		return node.index.value.text
	end
	return nil
end

local function instanceMember(node: syntax.CstExpr): boolean
	return (node.tag == "indexname" or node.tag == "index")
		and node.expression.tag == "global"
		and node.expression.name.text == "Instance"
end

local function scan(path: string, source: string, options: Options): { Finding }
	local root = parser.parse(source).root
	local starts = { 1 }
	for position in string.gmatch(source, "()\n") do
		table.insert(starts, position + 1)
	end
	local function offset(location: syntax.Span): number
		return starts[location.beginLine] + location.beginColumn - 1
	end
	local function text(location: syntax.Span): string
		return string.sub(source, offset(location), starts[location.endLine] + location.endColumn - 2)
	end
	local chars = table.create(#source)
	for index = 1, #source do
		chars[index] = string.sub(source, index, index)
	end
	local function blank(location: syntax.Span)
		for index = offset(location), starts[location.endLine] + location.endColumn - 2 do
			if chars[index] ~= "\n" then
				chars[index] = " "
			end
		end
	end
	local masking = visitor.create()
	masking.visitToken = function(token: syntax.CstToken)
		for _, trivia in { token.leadingTrivia, token.trailingTrivia } do
			for _, item in trivia do
				if item.tag ~= "whitespace" then
					blank(item.location)
				end
			end
		end
		return true
	end
	masking.visitExprConstantString = function(node: syntax.CstExprConstantString)
		blank(node.location)
		return true
	end
	masking.visitExprInterpString = function(node: syntax.CstExprInterpString)
		for _, segment in node.strings do
			blank(segment.location)
		end
		return true
	end
	visitor.visit(root, masking)
	local code = table.concat(chars)
	local function masked(location: syntax.Span): string
		return string.sub(code, offset(location), starts[location.endLine] + location.endColumn - 2)
	end
	local findings: { Finding } = {}
	local function report(line: number, rule: string, message: string)
		if options.enabled ~= nil and not options.enabled(path, rule) then
			return
		end
		local start = starts[line] or 1
		local stop = string.find(source, "\n", start, true) or #source + 1
		table.insert(findings, {
			path = path,
			line = line,
			rule = rule,
			message = message,
			snippet = string.sub(source, start, stop - 1),
		})
	end
	local function lineOf(at: number): number
		local _, lines = string.gsub(string.sub(source, 1, at - 1), "\n", "")
		return lines + 1
	end
	local function each(pattern: string, body: (number, number) -> ())
		local cursor = 1
		while cursor <= #code do
			local first, last = string.find(code, pattern, cursor)
			if first == nil or last == nil then
				break
			end
			body(first, last)
			cursor = math.max(first, last) + 1
		end
	end
	for _, row in options.patterns or {} do
		each(row.pattern, function(first: number, _last: number)
			report(lineOf(first), row.rule, "forbidden source pattern")
		end)
	end
	local countRules: { Count } = options.counts or {}
	for _, row in countRules do
		if row.path == path then
			local count = 0
			each(row.pattern, function(_first: number, _last: number)
				count += 1
			end)
			if count ~= row.count then
				report(1, row.rule, ("expected %d occurrence(s), found %d"):format(row.count, count))
			end
		end
	end
	local naming = options.naming
	local aliases: { [string]: string } = {}
	local collect = visitor.create()
	collect.visitStatTypeAlias = function(node: syntax.CstStatTypeAlias)
		aliases[node.name.text] = text(node.type.location)
		return true
	end
	visitor.visit(root, collect)
	local function hasHost(body: string): boolean
		if naming ~= nil then
			for _, host in naming.hosts do
				local escaped = string.gsub(host, "([^%w_])", "%%%1")
				if string.find(body, "%f[%w_]" .. escaped .. "%.") ~= nil then
					return true
				end
			end
		end
		return false
	end
	local function named(annotation: string, typeName: string, seen: { [string]: boolean }): boolean
		local escaped = string.gsub(typeName, "([^%w_])", "%%%1")
		if string.find(annotation, "%f[%w_]" .. escaped .. "%s*%?") ~= nil then
			return false
		end
		if string.find(annotation, "%f[%w_]" .. escaped .. "%f[^%w_]") ~= nil then
			return true
		end
		for alias in string.gmatch(annotation, "[%a_][%w_]*") do
			if aliases[alias] ~= nil and not seen[alias] then
				seen[alias] = true
				if named(aliases[alias], typeName, seen) then
					return true
				end
			end
		end
		return false
	end
	local function component(func: syntax.CstExprFunction)
		local convention = if naming ~= nil then naming.component else nil
		local parameter = func.parameters[1]
		if convention == nil or parameter == nil or parameter.annotation == nil then
			return
		end
		local body = masked(func.body.location)
		local annotation = text(parameter.annotation.location)
		if not hasHost(body) then
			return
		end
		local includes = named(annotation, convention.typeName, {})
		if
			parameter.name.text ~= "props"
			and not includes
			and not string.find(annotation, "Props")
			and not string.match(annotation, "^%s*{")
		then
			return
		end
		if not includes then
			report(func.location.beginLine, "component-type", "component props must include " .. convention.typeName)
		end
		local label = string.gsub(parameter.name.text .. "." .. convention.field, "([^%w_])", "%%%1")
		if string.find(body, "%(" .. label .. "%)%s*{") == nil then
			report(
				func.location.beginLine,
				"component-label",
				"use the component label " .. parameter.name.text .. "." .. convention.field
			)
		end
	end
	local calls: { syntax.CstExprCall } = {}
	local walk = visitor.create()
	walk.visitStat = function(node: syntax.CstStat)
		local naming = options.naming
		if node.tag == "assign" then
			for _, target in node.variables do
				local key = member(target)
				if options.ownership ~= false and key == "Parent" then
					report(target.location.beginLine, "parent-assignment", "parent nodes through Compose")
				elseif naming ~= nil and naming.forbidName and key == "Name" then
					report(target.location.beginLine, "name-assignment", "use a constructor label")
				end
			end
		elseif naming ~= nil then
			if node.tag == "return" then
				for _, value in node.expressions do
					if naming.namedReturns and value.tag == "function" then
						report(value.location.beginLine, "anonymous-component", "return a named function")
					elseif
						naming.rootLabel
						and value.tag == "call"
						and value.func.tag == "indexname"
						and hasHost(masked(value.func.location))
						and #value.arguments == 1
						and value.arguments[1].tag == "table"
					then
						report(value.location.beginLine, "unnamed-root", "give the root constructor a label")
					end
				end
			elseif node.tag == "localfunction" or node.tag == "function" then
				component(node.func)
			elseif node.tag == "typealias" and naming.component ~= nil then
				local convention = naming.component
				local final = string.match(convention.typeName, "([%w_]+)$")
				if node.name.text == final and path ~= convention.definitionPath then
					report(node.location.beginLine, "component-type-definition", "import the shared component type")
				end
			end
		end
		return true
	end
	walk.visitExpr = function(node: syntax.CstExpr)
		if node.tag == "call" then
			local name = member(node.func)
			if options.ownership ~= false then
				if name == "new" and instanceMember(node.func) then
					report(node.location.beginLine, "instance-new", "use a runtime constructor")
				elseif name == "Clone" or name == "Destroy" then
					report(node.location.beginLine, string.lower(name), "use the configured ownership boundary")
				elseif
					name == "createRuntime" or (node.func.tag == "global" and node.func.name.text == "createRuntime")
				then
					report(node.location.beginLine, "runtime-create", "create runtimes at the configured boundary")
				elseif name == "mount" or name == "mountFragment" or name == "app" then
					report(node.location.beginLine, "mount", "mount at the configured ownership boundary")
				end
			end
			if
				naming ~= nil
				and naming.namedMounts
				and name == "mount"
				and node.arguments[1] ~= nil
				and node.arguments[1].tag == "function"
			then
				report(node.location.beginLine, "anonymous-component", "mount a named function")
			end
			for _, pattern in options.nestedCalls or {} do
				if string.match(masked(node.func.location), pattern) ~= nil then
					table.insert(calls, node)
					break
				end
			end
		elseif options.ownership ~= false and member(node) == "fromExisting" then
			if instanceMember(node) then
				report(node.location.beginLine, "from-existing", "use the configured ownership boundary")
			end
		elseif node.tag == "table" and naming ~= nil then
			for _, entry in node.entries do
				local key = if entry.kind == "record"
					then entry.key.text
					elseif entry.kind == "general" and entry.key.tag == "string" then entry.key.value.text
					else nil
				if naming.forbidName and key == "Name" then
					report(entry.location.beginLine, "name-field", "use a constructor label")
				elseif naming.namedRender and key == "render" and entry.value.tag == "function" then
					report(entry.location.beginLine, "anonymous-render", "use a named render function")
				end
			end
		end
		return true
	end
	visitor.visit(root, walk)
	for _, inner in calls do
		for _, outer in calls do
			if
				offset(inner.location) > offset(outer.location)
				and offset(inner.location) < starts[outer.location.endLine] + outer.location.endColumn - 1
			then
				report(inner.location.beginLine, "nested-mount", "build children in the current mount")
				break
			end
		end
	end
	return findings
end

return { scan = scan }
