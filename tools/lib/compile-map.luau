--!strict

local parser = require "@std/syntax/parser"
local visitor = require "@std/syntax/visitor"
local Cst = require "@std/syntax/types/cst"

type Edit = { start: number, finish: number, text: string }
type Match = { returned: Cst.CstExpr, call: Cst.CstExprCall, source: Cst.CstExprLocal }
export type Result = { source: string, rewritten: number }

local function offsets(source: string): { number }
	local starts = { 1 }
	for at in string.gmatch(source, "\n()") do
		table.insert(starts, assert(tonumber(at)))
	end
	return starts
end

local function span(lines: { number }, at: Cst.Span): (number, number)
	return lines[at.beginLine] + at.beginColumn - 1, lines[at.endLine] + at.endColumn - 1
end

local function candidate(fn: Cst.CstExprFunction, written: { [Cst.CstLocal]: boolean }): Match?
	if fn.hasVararg or #fn.parameters ~= 1 or #fn.body.statements ~= 1 then
		return nil
	end
	local statement = fn.body.statements[1]
	if statement.tag ~= "return" or #statement.expressions ~= 1 then
		return nil
	end
	local parameter = fn.parameters[1]
	local returned = statement.expressions[1]
	local uses: { Cst.CstExprLocal } = {}
	local foundCall: { value: Cst.CstExprCall? } = { value = nil }
	local walk = visitor.create()
	walk.visitExprLocal = function(node: Cst.CstExprLocal)
		if node["local"] == parameter then
			table.insert(uses, node)
		end
		return true
	end
	walk.visitExprCall = function(node: Cst.CstExprCall)
		if node.func.tag == "local" and node.func["local"] == parameter then
			foundCall.value = node
		end
		return true
	end
	visitor.visit(returned, walk)
	local found = foundCall.value
	if #uses ~= 1 or found == nil or found.func ~= uses[1] or #found.arguments ~= 1 then
		return nil
	end
	local source = found.arguments[1]
	if source.tag ~= "local" or not source.upvalue or written[source["local"]] then
		return nil
	end
	return { returned = returned, call = found, source = source }
end

local function compile(source: string, binding: string): Result
	local root = parser.parse(source).root
	local bound = false
	for _, statement in root.statements do
		if statement.tag == "local" then
			for _, variable in statement.variables do
				if variable.name.text == binding then
					bound = true
				end
			end
		end
	end
	if not bound then
		return { source = source, rewritten = 0 }
	end
	local written: { [Cst.CstLocal]: boolean } = {}
	local named: { [Cst.CstExprFunction]: boolean } = {}
	local scan = visitor.create()
	scan.visitStatAssign = function(node: Cst.CstStatAssign)
		for _, target in node.variables do
			if target.tag == "local" then
				written[target["local"]] = true
			end
		end
		return true
	end
	scan.visitStatCompoundAssign = function(node: Cst.CstStatCompoundAssign)
		local target = node.variable
		if target.tag == "local" then
			written[target["local"]] = true
		end
		return true
	end
	scan.visitStatFunction = function(node: Cst.CstStatFunction)
		named[node.func] = true
		return true
	end
	scan.visitStatLocalFunction = function(node: Cst.CstStatLocalFunction)
		named[node.func] = true
		return true
	end
	visitor.visit(root, scan)
	local lines = offsets(source)
	local edits: { Edit } = {}
	local walk = visitor.create()
	walk.visitExprFunction = function(node: Cst.CstExprFunction)
		if named[node] then
			return true
		end
		local match = candidate(node, written)
		if match == nil then
			return true
		end
		local start, finish = span(lines, node.location)
		local bodyStart, bodyFinish = span(lines, match.returned.location)
		local callStart, callFinish = span(lines, match.call.location)
		local sourceStart, sourceFinish = span(lines, match.source.location)
		local expression = string.sub(source, bodyStart, callStart - 1)
			.. "__value"
			.. string.sub(source, callFinish, bodyFinish - 1)
		table.insert(edits, {
			start = start,
			finish = finish,
			text = `{binding}.map({string.sub(source, sourceStart, sourceFinish - 1)}, function(__value) return {expression} end)`,
		})
		return false
	end
	visitor.visit(root, walk)
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
