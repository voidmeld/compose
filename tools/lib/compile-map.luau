--!strict

local parser = require "@std/syntax/parser"

export type Node = { [string]: unknown }
type Location = { beginLine: number, beginColumn: number, endLine: number, endColumn: number }
type Edit = { start: number, finish: number, text: string }

export type Result = { source: string, rewritten: number }

local function children(node: Node, visit: (Node, Node?) -> ())
	for key, value in node do
		if type(key) == "string" and (string.find(key, "rivia") or key == "location") then
			continue
		end
		if type(value) == "table" then
			local child = value :: Node
			if child.kind ~= nil then
				visit(child, node)
			else
				for _, item in child :: { unknown } do
					if type(item) == "table" and (item :: Node).kind ~= nil then
						visit(item :: Node, node)
					end
				end
			end
		end
	end
end

local function walk(node: Node, visit: (Node, Node?) -> boolean, parent: Node?)
	if visit(node, parent) then
		children(node, function(child: Node)
			walk(child, visit, node)
		end)
	end
end

local function location(node: Node): Location
	local value = node.location
	assert(type(value) == "table", "compile-map: node has no location")
	return value :: Location
end

local function offsets(source: string): { number }
	local starts = { 1 }
	for index = 1, #source do
		if string.byte(source, index) == 10 then
			table.insert(starts, index + 1)
		end
	end
	return starts
end

local function span(lines: { number }, at: Location): (number, number)
	return lines[at.beginLine] + at.beginColumn - 1, lines[at.endLine] + at.endColumn - 1
end

local function list(node: Node, key: string): { Node }
	local value = node[key]
	return if type(value) == "table" then value :: { Node } else {}
end

local function assigned(root: Node): { [unknown]: boolean }
	local found: { [unknown]: boolean } = {}
	walk(root, function(node: Node): boolean
		if node.kind == "stat" and (node.tag == "assign" or node.tag == "compoundassign") then
			local targets = if node.tag == "assign" then list(node, "variables") else { node.variable :: Node }
			for _, target in targets do
				if type(target) == "table" and target.tag == "local" then
					found[target["local"]] = true
				end
			end
		end
		return true
	end)
	return found
end

local function candidate(fn: Node, written: { [unknown]: boolean }): (Node?, Node?, Node?)
	if fn.hasVararg == true then
		return nil, nil, nil
	end
	local parameters = list(fn, "parameters")
	local body = fn.body :: Node?
	if #parameters ~= 1 or body == nil then
		return nil, nil, nil
	end
	local statements = list(body, "statements")
	if #statements ~= 1 or statements[1].tag ~= "return" then
		return nil, nil, nil
	end
	local expressions = list(statements[1], "expressions")
	if #expressions ~= 1 then
		return nil, nil, nil
	end
	local parameter = parameters[1]
	local declared = if parameter.kind == "local" then parameter else parameter["local"]
	local returned = expressions[1]
	local uses: { Node } = {}
	local call: Node? = nil
	walk(returned, function(node: Node): boolean
		if node.tag == "local" and node["local"] == declared then
			table.insert(uses, node)
		end
		if node.tag == "call" then
			local func = node.func :: Node?
			if func and func.tag == "local" and func["local"] == declared then
				call = node
			end
		end
		return true
	end)
	local found = call
	if #uses ~= 1 or found == nil or found.func ~= uses[1] then
		return nil, nil, nil
	end
	local arguments = list(found, "arguments")
	if #arguments ~= 1 then
		return nil, nil, nil
	end
	local source = arguments[1]
	if source.tag ~= "local" or source.upvalue ~= true or written[source["local"]] then
		return nil, nil, nil
	end
	return returned, found, source
end

local function compile(source: string, binding: string): Result
	local parsed = parser.parse(source)
	local root = parsed.root :: Node
	local bound = false
	for _, statement in list(root, "statements") do
		if statement.tag == "local" then
			for _, variable in list(statement, "variables") do
				local name = variable.name :: Node?
				if name and name.text == binding then
					bound = true
				end
			end
		end
	end
	if not bound then
		return { source = source, rewritten = 0 }
	end
	local written = assigned(root)
	local lines = offsets(source)
	local edits: { Edit } = {}
	walk(root, function(node: Node, parent: Node?): boolean
		if
			node.kind ~= "expr"
			or node.tag ~= "function"
			or (parent and parent.kind == "stat" and (parent.tag == "localfunction" or parent.tag == "function"))
		then
			return true
		end
		local returned, call, mapped = candidate(node, written)
		if returned == nil or call == nil or mapped == nil then
			return true
		end
		local start, finish = span(lines, location(node))
		local bodyStart, bodyFinish = span(lines, location(returned))
		local callStart, callFinish = span(lines, location(call))
		local sourceStart, sourceFinish = span(lines, location(mapped))
		local expression = string.sub(source, bodyStart, callStart - 1)
			.. "__value"
			.. string.sub(source, callFinish, bodyFinish - 1)
		table.insert(edits, {
			start = start,
			finish = finish,
			text = `{binding}.map({string.sub(source, sourceStart, sourceFinish - 1)}, function(__value) return {expression} end)`,
		})
		return false
	end)
	table.sort(edits, function(left: Edit, right: Edit): boolean
		return left.start > right.start
	end)
	local result = source
	for _, edit in edits do
		result = string.sub(result, 1, edit.start - 1) .. edit.text .. string.sub(result, edit.finish)
	end
	return { source = result, rewritten = #edits }
end

return { compile = compile }
