--!strict

local Diagnostics = require "./diagnostics"

export type Position = { x: number, y: number, z: number }
export type Space = "xz" | "xyz"

export type Constraint = {
	kind: string,
	subject: string?,
	ids: { string }?,
	from: { string }?,
	anchor: string?,
	path: { Position }?,
	minimum: number?,
	radius: number?,
	halfWidth: number?,
	space: Space?,
	tolerance: number?,
	strict: boolean?,
}

export type Violation = {
	index: number,
	kind: string,
	subject: string,
	other: string?,
	actual: number,
	required: number,
}

local function number(name: string, value: unknown, nonNegative: boolean?): number
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		Diagnostics.raise("placement/non-finite-number", ("%s must be a finite number"):format(name), {
			key = name,
			actual = Diagnostics.describe(value),
			expected = "a finite number",
		})
	end
	if nonNegative == true and (value :: number) < 0 then
		Diagnostics.raise("placement/negative-number", ("%s must not be negative"):format(name), {
			key = name,
			actual = Diagnostics.describe(value),
			expected = "zero or more",
		})
	end
	return value :: number
end

local function position(name: string, value: Position): Position
	if type(value) ~= "table" then
		Diagnostics.raise("placement/non-finite-number", ("%s must be a position"):format(name), {
			key = name,
			actual = Diagnostics.describe(value),
			expected = "a table with finite x, y and z",
		})
	end
	number(name .. ".x", value.x)
	number(name .. ".y", value.y)
	number(name .. ".z", value.z)
	return value
end

local function spaceOf(space: string?, planOnly: boolean, what: string): boolean
	if space == nil or space == "xz" then
		return false
	end
	if space == "xyz" then
		if planOnly then
			Diagnostics.raise("placement/unsupported-space", ("%s measures the plan only"):format(what), {
				actual = '"xyz"',
				expected = 'nil or "xz"',
			})
		end
		return true
	end
	return Diagnostics.raise("placement/unknown-space", ("%s names an unknown space"):format(what), {
		actual = Diagnostics.describe(space),
		expected = if planOnly then 'nil or "xz"' else 'nil, "xz" or "xyz"',
	})
end

local function measure(a: Position, b: Position, xyz: boolean): number
	if xyz then
		return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2)
	end
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

local function distance(a: Position, b: Position, space: Space?): number
	local mode = spaceOf(space, false, "distance")
	return measure(position("a", a), position("b", b), mode)
end

local function distanceToPath(point: Position, path: { Position }, space: "xz"?): number
	spaceOf(space, true, "distanceToPath")
	position("point", point)
	if type(path) ~= "table" or #path < 2 then
		Diagnostics.raise("placement/short-path", "a path needs at least two points", {
			actual = if type(path) == "table" then tostring(#path) else Diagnostics.describe(path),
			expected = "two or more positions",
		})
	end
	for index, vertex in path do
		position(("path[%d]"):format(index), vertex)
	end
	local best = math.huge
	for index = 1, #path - 1 do
		local a, b = path[index], path[index + 1]
		local abx, abz = b.x - a.x, b.z - a.z
		local apx, apz = point.x - a.x, point.z - a.z
		local lengthSquared = abx * abx + abz * abz
		local t = if lengthSquared > 0 then math.clamp((apx * abx + apz * abz) / lengthSquared, 0, 1) else 0
		local cx, cz = a.x + abx * t - point.x, a.z + abz * t - point.z
		best = math.min(best, math.sqrt(cx * cx + cz * cz))
	end
	return best
end

local function alongLateral(point: Position, from: Position, to: Position, space: "xz"?): (number, number, number)
	spaceOf(space, true, "alongLateral")
	position("point", point)
	position("from", from)
	position("to", to)
	local dx, dz = to.x - from.x, to.z - from.z
	local length = math.sqrt(dx * dx + dz * dz)
	if length <= 0 then
		Diagnostics.raise("placement/degenerate-segment", "a segment needs two distinct ends", {
			actual = "both ends share one plan position",
		})
	end
	local ux, uz = dx / length, dz / length
	local px, pz = point.x - from.x, point.z - from.z
	return px * ux + pz * uz, px * -uz + pz * ux, length
end

local function nearest<T>(point: Position, items: { T }, positionOf: (T) -> Position): (T?, number)
	position("point", point)
	local best: T? = nil
	local bestDistance = math.huge
	for index, item in items do
		local d = measure(point, position(("items[%d]"):format(index), positionOf(item)), false)
		if d < bestDistance then
			best, bestDistance = item, d
		end
	end
	return best, bestDistance
end

local function ring(count: number, radius: number): { { x: number, z: number } }
	if type(count) ~= "number" or count % 1 ~= 0 or count < 1 or count == math.huge then
		Diagnostics.raise("placement/bad-ring", "a ring needs a whole positive count", {
			actual = Diagnostics.describe(count),
		})
	end
	number("radius", radius, true)
	local offsets: { { x: number, z: number } } = {}
	for index = 1, count do
		local angle = (index - 1) * 2 * math.pi / count
		offsets[index] = { x = math.cos(angle) * radius, z = math.sin(angle) * radius }
	end
	return offsets
end

local SPREAD_TURN = 2.399963229728653

local function spread(ordinal: number, step: number): (number, number)
	if type(ordinal) ~= "number" or ordinal % 1 ~= 0 or ordinal < 1 or ordinal == math.huge then
		Diagnostics.raise("placement/bad-ordinal", "a spread ordinal must be a whole number of one or more", {
			actual = Diagnostics.describe(ordinal),
		})
	end
	number("step", step, true)
	local radius = if ordinal == 1 then 0 else step * math.sqrt(ordinal - 1)
	local angle = ordinal * SPREAD_TURN
	return math.cos(angle) * radius, math.sin(angle) * radius
end

local function pathPoint(path: { Position }, along: number, lateral: number, y: number): Position
	number("along", along)
	number("lateral", lateral)
	number("y", y)
	if type(path) ~= "table" or #path < 2 then
		Diagnostics.raise("placement/short-path", "a path needs at least two points", {
			actual = if type(path) == "table" then tostring(#path) else Diagnostics.describe(path),
			expected = "two or more positions",
		})
	end
	for index, vertex in path do
		position(("path[%d]"):format(index), vertex)
	end
	local count = #path
	for index = 1, count - 1 do
		local a, b = path[index], path[index + 1]
		if a.x == b.x and a.z == b.z then
			Diagnostics.raise("placement/degenerate-segment", "a path segment needs two distinct ends", {
				index = index,
				actual = "both ends share one plan position",
			})
		end
	end
	local start = path[1]
	local ux, uz, travelled = 0, 0, 0
	for index = 1, count - 1 do
		local a, b = path[index], path[index + 1]
		local dx, dz = b.x - a.x, b.z - a.z
		local length = math.sqrt(dx * dx + dz * dz)
		start, ux, uz = a, dx / length, dz / length
		if index == count - 1 or along <= travelled + length then
			break
		end
		travelled += length
	end
	local t = along - travelled
	return { x = start.x + ux * t + -uz * lateral, y = y, z = start.z + uz * t + ux * lateral }
end

local function finite(constraint: Constraint, index: number, field: string, value: number?): number
	return number(("constraint %d %s"):format(index, field), value, true)
end

local function lookup(points: { [string]: Position }, constraint: Constraint, index: number, id: string?): Position
	local found = if id ~= nil then points[id] else nil
	if found == nil then
		Diagnostics.raise(
			"placement/unknown-point",
			("constraint %d names a point that is not declared"):format(index),
			{
				index = index,
				actual = Diagnostics.describe(id),
				expected = ("an id declared in points for a %s constraint"):format(tostring(constraint.kind)),
			}
		)
	end
	return position(("constraint %d point %s"):format(index, tostring(id)), found :: Position)
end

local function refuseField(index: number, field: string, expected: string, value: unknown): never
	return Diagnostics.raise("placement/bad-constraint", ("constraint %d needs %s"):format(index, field), {
		key = field,
		index = index,
		actual = Diagnostics.describe(value),
		expected = expected,
	})
end

local function idOf(index: number, field: string, value: unknown): string
	if type(value) ~= "string" or value == "" then
		refuseField(index, field, "a non-empty point id", value)
	end
	return value :: string
end

local function idsOf(index: number, field: string, value: unknown, least: number): { string }
	if type(value) ~= "table" or #(value :: { unknown }) < least then
		refuseField(index, field, ("a list of %d or more point ids"):format(least), value)
	end
	for _, id in value :: { unknown } do
		idOf(index, field, id)
	end
	return value :: { string }
end

local function check(points: { [string]: Position }, constraints: { Constraint }): { Violation }
	if type(points) ~= "table" then
		Diagnostics.raise("placement/bad-constraint", "check needs a points table keyed by id", {
			actual = Diagnostics.describe(points),
		})
	end
	if type(constraints) ~= "table" then
		Diagnostics.raise("placement/bad-constraint", "check needs a list of constraints", {
			actual = Diagnostics.describe(constraints),
		})
	end
	local violations: { Violation } = {}
	for index, constraint in constraints do
		if type(constraint) ~= "table" then
			refuseField(index, "a constraint table", "a table with a kind", constraint)
		end
		local kind = constraint.kind
		local label: string = constraint.kind
		local space = spaceOf(constraint.space, kind == "path", ("constraint %d"):format(index))
		if kind == "separation" then
			local ids = idsOf(index, "ids", constraint.ids, 2)
			local minimum = finite(constraint, index, "minimum", constraint.minimum)
			local tolerance = if constraint.tolerance ~= nil
				then number(("constraint %d tolerance"):format(index), constraint.tolerance, true)
				else 0
			for first = 1, #ids do
				local a = lookup(points, constraint, index, ids[first])
				for second = first + 1, #ids do
					local actual = measure(a, lookup(points, constraint, index, ids[second]), space)
					if actual + tolerance < minimum then
						table.insert(violations, {
							index = index,
							kind = label,
							subject = ids[first],
							other = ids[second],
							actual = actual,
							required = minimum,
						})
					end
				end
			end
		elseif kind == "clearance" then
			local subject = lookup(points, constraint, index, idOf(index, "subject", constraint.subject))
			local minimum = finite(constraint, index, "minimum", constraint.minimum)
			local tolerance = if constraint.tolerance ~= nil
				then number(("constraint %d tolerance"):format(index), constraint.tolerance, true)
				else 0
			local nearestId: string? = nil
			local nearestDistance = math.huge
			local candidates = idsOf(index, "from", constraint.from, 1)
			for _, id in candidates do
				local actual = measure(subject, lookup(points, constraint, index, id), space)
				if actual < nearestDistance then
					nearestId, nearestDistance = id, actual
				end
			end
			local violated = if constraint.strict == true
				then nearestDistance <= minimum
				else nearestDistance + tolerance < minimum
			if nearestId ~= nil and violated then
				table.insert(violations, {
					index = index,
					kind = label,
					subject = constraint.subject :: string,
					other = nearestId,
					actual = nearestDistance,
					required = minimum,
				})
			end
		elseif kind == "within" then
			local subject = lookup(points, constraint, index, idOf(index, "subject", constraint.subject))
			local anchor = lookup(points, constraint, index, idOf(index, "anchor", constraint.anchor))
			local radius = finite(constraint, index, "radius", constraint.radius)
			local actual = measure(subject, anchor, space)
			if actual > radius then
				table.insert(violations, {
					index = index,
					kind = label,
					subject = constraint.subject :: string,
					other = constraint.anchor,
					actual = actual,
					required = radius,
				})
			end
		elseif kind == "path" then
			local subject = lookup(points, constraint, index, idOf(index, "subject", constraint.subject))
			local halfWidth = finite(constraint, index, "halfWidth", constraint.halfWidth)
			if type(constraint.path) ~= "table" then
				refuseField(index, "path", "a path of two or more positions", constraint.path)
			end
			local actual = distanceToPath(subject, constraint.path :: { Position }, nil)
			if actual > halfWidth then
				table.insert(violations, {
					index = index,
					kind = label,
					subject = constraint.subject :: string,
					actual = actual,
					required = halfWidth,
				})
			end
		else
			Diagnostics.raise("placement/unknown-constraint", ("constraint %d has an unknown kind"):format(index), {
				index = index,
				actual = Diagnostics.describe(kind),
				expected = "separation, clearance, within or path",
			})
		end
	end
	return violations
end

export type Rule = {
	id: string,
	kind: string,
	x: number?,
	y: number?,
	z: number?,
	from: string?,
	dx: number?,
	dy: number?,
	dz: number?,
	route: string?,
	along: number?,
	lateral: number?,
	ordinal: number?,
}

export type ResolveSpec = {
	anchors: { [string]: Position }?,
	routes: { [string]: { Position } }?,
	spreadDistance: number?,
	entries: { Rule },
}

local function resolve(spec: ResolveSpec): { [string]: Position }
	if type(spec) ~= "table" or type(spec.entries) ~= "table" then
		Diagnostics.raise("placement/bad-rule", "resolve needs a spec table with an entries list", {
			actual = Diagnostics.describe(if type(spec) == "table" then spec.entries else spec),
			expected = "{ entries = { rules } }",
		})
	end
	local anchors = spec.anchors or {}
	local routes = spec.routes or {}
	local rules: { [string]: Rule } = {}
	for _, rule in spec.entries do
		if type(rule.id) ~= "string" or rule.id == "" then
			Diagnostics.raise("placement/bad-rule", "a rule has no id", {
				actual = Diagnostics.describe(rule.id),
				expected = "a non-empty string",
			})
		end
		if rules[rule.id] ~= nil or anchors[rule.id] ~= nil then
			Diagnostics.raise("placement/duplicate-id", "a rule id is declared twice or shadows an anchor", {
				entryId = rule.id,
			})
		end
		rules[rule.id] = rule
	end
	local resolved: { [string]: Position } = {}
	local visiting: { [string]: boolean } = {}
	local chain: { string } = {}

	local function field(rule: Rule, name: string, optional: boolean?): number
		local value = ((rule :: unknown) :: { [string]: unknown })[name]
		if value == nil and optional == true then
			return 0
		end
		return number(("rule %s %s"):format(rule.id, name), value)
	end

	local function reference(rule: Rule, solve: (string) -> Position): Position
		local id = rule.from
		if type(id) ~= "string" then
			Diagnostics.raise("placement/unknown-anchor", ("rule %s names no anchor"):format(rule.id), {
				entryId = rule.id,
				actual = Diagnostics.describe(id),
				expected = "an anchor or rule id in from",
			})
		end
		return solve(id :: string)
	end

	local function solve(id: string): Position
		local done = resolved[id]
		if done ~= nil then
			return done
		end
		local rule = rules[id]
		if rule == nil then
			local anchor = anchors[id]
			if anchor == nil then
				Diagnostics.raise("placement/unknown-anchor", "a rule names an anchor that is not declared", {
					entryId = chain[#chain],
					actual = Diagnostics.describe(id),
					expected = "an id in anchors or entries",
				})
			end
			resolved[id] = position(("anchor %s"):format(id), anchor)
			return resolved[id]
		end
		if visiting[id] then
			table.insert(chain, id)
			Diagnostics.raise("placement/cyclic-reference", "relative placements refer to each other in a cycle", {
				entryId = id,
				detail = table.concat(chain, " -> "),
			})
		end
		visiting[id] = true
		table.insert(chain, id)
		local kind = rule.kind
		local result: Position
		if kind == "absolute" then
			result = { x = field(rule, "x"), y = field(rule, "y", true), z = field(rule, "z") }
		elseif kind == "offset" then
			local base = reference(rule, solve)
			result =
				{ x = base.x + field(rule, "dx"), y = base.y + field(rule, "dy", true), z = base.z + field(rule, "dz") }
		elseif kind == "route" then
			local path = routes[rule.route :: string]
			if path == nil then
				Diagnostics.raise("placement/unknown-route", "a rule names a route that is not declared", {
					entryId = id,
					actual = Diagnostics.describe(rule.route),
					expected = "an id in routes",
				})
			end
			result = pathPoint(path, field(rule, "along"), field(rule, "lateral"), field(rule, "y", true))
		elseif kind == "spread" then
			local base = reference(rule, solve)
			local dx, dz = spread(rule.ordinal :: number, number("spreadDistance", spec.spreadDistance, true))
			result = { x = base.x + dx, y = base.y, z = base.z + dz }
		else
			Diagnostics.raise("placement/unknown-rule", "a rule has an unknown kind", {
				entryId = id,
				actual = Diagnostics.describe(kind),
				expected = "absolute, offset, route or spread",
			})
		end
		table.remove(chain)
		visiting[id] = nil
		resolved[id] = result
		return result
	end

	local placed: { [string]: Position } = {}
	for _, rule in spec.entries do
		placed[rule.id] = solve(rule.id)
	end
	return placed
end

return {
	distance = distance,
	distanceToPath = distanceToPath,
	alongLateral = alongLateral,
	nearest = nearest,
	ring = ring,
	check = check,
	spread = spread,
	pathPoint = pathPoint,
	resolve = resolve,
}
