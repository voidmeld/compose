--!strict

local Diagnostics = require "./diagnostics"
local Set = require "./set"

type Entry = Set.Entry
type EntrySet = Set.EntrySet

export type Point = {
	x: number,
	y: number,
}

export type Bounds = {
	x: number,
	y: number,
	width: number,
	height: number,
}

export type LayoutSheetSpec = {
	name: string,
	coordinateSpace: string,
	unit: string,
	bounds: Bounds,
	scale: number,
	set: EntrySet,
}

export type LayoutTransform = {
	scale: number,
	offsetX: number,
	offsetY: number,
	width: number,
	height: number,
}

export type LayoutSheet = {
	svg: string,
	transform: LayoutTransform,
}

type Annotation = {
	id: string,
	label: string,
	x: number,
	y: number,
}

local HORIZONTAL_MARGIN = 24
local HEADER_HEIGHT = 48
local BOTTOM_MARGIN = 24
local LEGEND_WIDTH = 280
local LEGEND_INSET = 16
local LEGEND_ROW_HEIGHT = 18

local function isFinite(value: unknown): boolean
	if type(value) ~= "number" then
		return false
	end
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function number(value: number): string
	if value == 0 then
		return "0"
	end
	return ("%.17g"):format(value)
end

local function escape(value: string): string
	local escaped = string.gsub(value, "&", "&amp;")
	escaped = string.gsub(escaped, "<", "&lt;")
	escaped = string.gsub(escaped, ">", "&gt;")
	escaped = string.gsub(escaped, '"', "&quot;")
	escaped = string.gsub(escaped, "'", "&apos;")
	return escaped
end

local function refuse(code: string, summary: string, set: EntrySet?, id: string?, fields: Diagnostics.Fields?): never
	local details: Diagnostics.Fields = if fields == nil then {} else table.clone(fields)
	if set ~= nil then
		details.set = set.name
	end
	if id ~= nil then
		details.entryId = id
	end
	return Diagnostics.raise("layout-sheet/" .. code, summary, details)
end

local function requireText(value: unknown, key: string): string
	if type(value) ~= "string" or value == "" then
		refuse("invalid-spec", ("layout sheet has no %s"):format(key), nil, nil, {
			key = key,
			actual = Diagnostics.describe(value),
			expected = "a non-empty string",
		})
	end
	return value :: string
end

local function requireFinite(value: unknown, key: string, set: EntrySet?, id: string?): number
	if not isFinite(value) then
		refuse("nonfinite-geometry", ("%s is not finite"):format(key), set, id, {
			key = key,
			actual = Diagnostics.describe(value),
			expected = "a finite number",
		})
	end
	return value :: number
end

local function requirePositive(value: unknown, key: string, set: EntrySet?, id: string?): number
	local finite = requireFinite(value, key, set, id)
	if finite <= 0 then
		refuse("nonpositive-extent", ("%s must be positive"):format(key), set, id, {
			key = key,
			actual = Diagnostics.describe(value),
			expected = "a finite number greater than zero",
		})
	end
	return finite
end

local function requireLabel(entry: Entry, set: EntrySet, id: string): string?
	local label = entry.label
	if label ~= nil and type(label) ~= "string" then
		refuse("invalid-label", ("entry %q has a non-string label"):format(id), set, id, {
			key = "label",
			actual = Diagnostics.describe(label),
			expected = "a string when present",
		})
	end
	return label :: string?
end

local function requireCoordinateSpace(entry: Entry, declared: string, set: EntrySet, id: string)
	local coordinateSpace = entry.coordinateSpace
	if coordinateSpace ~= nil and coordinateSpace ~= declared then
		refuse("mixed-coordinate-space", ("entry %q uses another coordinate space"):format(id), set, id, {
			key = "coordinateSpace",
			actual = Diagnostics.describe(coordinateSpace),
			expected = declared,
			contract = "one layout sheet contains one declared coordinate space",
		})
	end
end

local function requirePoints(value: unknown, set: EntrySet, id: string): { Point }
	if type(value) ~= "table" then
		refuse("invalid-polyline", ("polyline %q has no points array"):format(id), set, id, {
			key = "points",
			actual = Diagnostics.describe(value),
			expected = "an array of at least two { x, y } points",
		})
	end
	local source = value :: { [any]: any }
	local count = 0
	for key in source do
		if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
			refuse("invalid-polyline", ("polyline %q points are not an array"):format(id), set, id, {
				key = "points",
				expected = "an array of at least two { x, y } points",
			})
		end
		count += 1
	end
	if count ~= #source or count < 2 then
		refuse("short-polyline", ("polyline %q needs at least two points"):format(id), set, id, {
			key = "points",
			actual = ("%d point(s)"):format(count),
			expected = "at least two points",
		})
	end
	local points: { Point } = {}
	for index, point in ipairs(source) do
		if type(point) ~= "table" then
			refuse("invalid-polyline", ("polyline %q point %d is not a point"):format(id, index), set, id, {
				key = "points",
				index = index,
				actual = Diagnostics.describe(point),
				expected = "a table with finite x and y numbers",
			})
		end
		table.insert(points, {
			x = requireFinite(point.x, ("points[%d].x"):format(index), set, id),
			y = requireFinite(point.y, ("points[%d].y"):format(index), set, id),
		})
	end
	return points
end

local function layoutSheet(spec: LayoutSheetSpec): LayoutSheet
	if type(spec) ~= "table" then
		refuse("invalid-spec", "Author.bake.layoutSheet was not given a specification table", nil, nil, {
			actual = Diagnostics.describe(spec),
			expected = "a layout sheet specification",
		})
	end
	local name = requireText(spec.name, "name")
	local coordinateSpace = requireText(spec.coordinateSpace, "coordinateSpace")
	local unit = requireText(spec.unit, "unit")
	if type(spec.bounds) ~= "table" then
		refuse("invalid-bounds", "layout sheet has no bounds", nil, nil, {
			actual = Diagnostics.describe(spec.bounds),
			expected = "finite x and y with positive width and height",
		})
	end
	if type(spec.set) ~= "table" or type(spec.set.entries) ~= "table" or type(spec.set.idOf) ~= "function" then
		refuse("invalid-set", "layout sheet has no semantic entry set", nil, nil, {
			actual = Diagnostics.describe(spec.set),
			expected = "an EntrySet returned by Author.set",
		})
	end

	local set = spec.set
	local bounds = spec.bounds
	local boundsX = requireFinite(bounds.x, "bounds.x", nil, nil)
	local boundsY = requireFinite(bounds.y, "bounds.y", nil, nil)
	local boundsWidth = requirePositive(bounds.width, "bounds.width", nil, nil)
	local boundsHeight = requirePositive(bounds.height, "bounds.height", nil, nil)
	local scale = requirePositive(spec.scale, "scale", nil, nil)
	local geometryWidth = boundsWidth * scale + HORIZONTAL_MARGIN * 2
	local width = geometryWidth + LEGEND_WIDTH
	local height = boundsHeight * scale + HEADER_HEIGHT + BOTTOM_MARGIN
	local offsetX = HORIZONTAL_MARGIN - boundsX * scale
	local offsetY = HEADER_HEIGHT - boundsY * scale
	local transformValues: { [string]: number } =
		{ width = width, height = height, offsetX = offsetX, offsetY = offsetY }
	for key, value in transformValues do
		requireFinite(value, ("transform.%s"):format(key), nil, nil)
	end

	local ids: { string } = {}
	local entries: { [string]: Entry } = {}
	for _, entry in set.entries do
		local id = set:idOf(entry)
		if entries[id] ~= nil then
			refuse("duplicate-id", ("id %q appears more than once in set %q"):format(id, set.name), set, id, {
				contract = "each SVG element has one semantic id",
				fix = "run Author.validate with unique = true and fix the authored data",
			})
		end
		entries[id] = entry
		table.insert(ids, id)
	end
	table.sort(ids)

	local transform: LayoutTransform = {
		scale = scale,
		offsetX = offsetX,
		offsetY = offsetY,
		width = width,
		height = height,
	}
	local function x(input: number): number
		return input * scale + offsetX
	end
	local function y(input: number): number
		return input * scale + offsetY
	end
	local function transformed(input: number, axis: string, setForEntry: EntrySet, id: string): number
		return requireFinite(input, ("transform.%s"):format(axis), setForEntry, id)
	end

	local annotations: { Annotation } = {}
	local lines: { string } = {
		'<?xml version="1.0" encoding="UTF-8"?>',
		('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" role="img" aria-label="%s">'):format(
			number(width),
			number(height),
			number(width),
			number(height),
			escape(name)
		),
		"<style>.sheet{fill:#f5f5f4}.bounds{fill:#fff;stroke:#a8a29e;stroke-width:1}.shape{fill:none;stroke:#292524;stroke-width:1.5}.route{fill:none;stroke:#57534e;stroke-width:2}.point{fill:#292524}.legend{fill:#fafaf9;stroke:#d6d3d1;stroke-width:1}.title{fill:#1c1917;font:600 16px sans-serif}.meta,.legend-label{fill:#57534e;font:12px sans-serif}.legend-title{fill:#1c1917;font:600 12px sans-serif}.mark{fill:#fff;stroke:#292524;stroke-width:1.5}.mark-text{fill:#1c1917;font:600 10px sans-serif;text-anchor:middle;dominant-baseline:central}</style>",
		('<rect class="sheet" x="0" y="0" width="%s" height="%s"/>'):format(number(width), number(height)),
		('<text class="title" x="%s" y="19">%s</text>'):format(number(HORIZONTAL_MARGIN), escape(name)),
		('<text class="meta" x="%s" y="38">%s · %s</text>'):format(
			number(HORIZONTAL_MARGIN),
			escape(coordinateSpace),
			escape(unit)
		),
		('<rect class="bounds" x="%s" y="%s" width="%s" height="%s"/>'):format(
			number(x(boundsX)),
			number(y(boundsY)),
			number(boundsWidth * scale),
			number(boundsHeight * scale)
		),
		('<rect class="legend" x="%s" y="0" width="%s" height="%s"/>'):format(
			number(geometryWidth),
			number(LEGEND_WIDTH),
			number(height)
		),
		('<text class="legend-title" x="%s" y="29">Annotations</text>'):format(number(geometryWidth + LEGEND_INSET)),
	}

	for _, id in ids do
		local entry = entries[id]
		requireCoordinateSpace(entry, coordinateSpace, set, id)
		local label = requireLabel(entry, set, id)
		local kind = entry.kind
		table.insert(lines, ('<g id="%s" data-kind="%s">'):format(escape(id), escape(tostring(kind))))
		if kind == "rect" then
			local entryX = requireFinite(entry.x, "x", set, id)
			local entryY = requireFinite(entry.y, "y", set, id)
			local entryWidth = requirePositive(entry.width, "width", set, id)
			local entryHeight = requirePositive(entry.height, "height", set, id)
			local sheetX = transformed(x(entryX), "x", set, id)
			local sheetY = transformed(y(entryY), "y", set, id)
			local sheetWidth = transformed(entryWidth * scale, "width", set, id)
			local sheetHeight = transformed(entryHeight * scale, "height", set, id)
			local rotation = if entry.rotationDegrees == nil
				then nil
				else requireFinite(entry.rotationDegrees, "rotationDegrees", set, id)
			local rotationAttribute = ""
			if rotation ~= nil and rotation ~= 0 then
				local centerX = transformed(sheetX + sheetWidth / 2, "centerX", set, id)
				local centerY = transformed(sheetY + sheetHeight / 2, "centerY", set, id)
				rotationAttribute = (' transform="rotate(%s %s %s)"'):format(
					number(rotation),
					number(centerX),
					number(centerY)
				)
			end
			table.insert(
				lines,
				('<rect class="shape" x="%s" y="%s" width="%s" height="%s"%s/>'):format(
					number(sheetX),
					number(sheetY),
					number(sheetWidth),
					number(sheetHeight),
					rotationAttribute
				)
			)
			if label ~= nil then
				local labelX = transformed(sheetX + sheetWidth / 2, "labelX", set, id)
				local labelY = transformed(sheetY + sheetHeight / 2, "labelY", set, id)
				table.insert(annotations, { id = id, label = label, x = labelX, y = labelY })
			end
		elseif kind == "point" then
			local sheetX = transformed(x(requireFinite(entry.x, "x", set, id)), "x", set, id)
			local sheetY = transformed(y(requireFinite(entry.y, "y", set, id)), "y", set, id)
			table.insert(
				lines,
				('<circle class="point" cx="%s" cy="%s" r="4"/>'):format(number(sheetX), number(sheetY))
			)
			if label ~= nil then
				table.insert(annotations, { id = id, label = label, x = sheetX, y = sheetY })
			end
		elseif kind == "polyline" then
			local rendered: { string } = {}
			local points = requirePoints(entry.points, set, id)
			local firstX = 0
			local firstY = 0
			for index, point in ipairs(points) do
				local sheetX = transformed(x(point.x), "x", set, id)
				local sheetY = transformed(y(point.y), "y", set, id)
				if index == 1 then
					firstX = sheetX
					firstY = sheetY
				end
				table.insert(rendered, number(sheetX) .. "," .. number(sheetY))
			end
			table.insert(lines, ('<polyline class="route" points="%s"/>'):format(table.concat(rendered, " ")))
			if label ~= nil then
				table.insert(annotations, { id = id, label = label, x = firstX, y = firstY })
			end
		else
			refuse("unknown-kind", ("entry %q has unknown geometry kind"):format(id), set, id, {
				key = "kind",
				actual = Diagnostics.describe(kind),
				expected = '"rect", "point", or "polyline"',
			})
		end
		table.insert(lines, "</g>")
	end
	table.insert(lines, '<g class="annotations">')
	for index, annotation in ipairs(annotations) do
		table.insert(lines, ('<g class="annotation" data-for="%s">'):format(escape(annotation.id)))
		table.insert(
			lines,
			('<circle class="mark" cx="%s" cy="%s" r="8"/>'):format(number(annotation.x), number(annotation.y))
		)
		table.insert(
			lines,
			('<text class="mark-text" x="%s" y="%s">%d</text>'):format(
				number(annotation.x),
				number(annotation.y),
				index
			)
		)
		table.insert(lines, "</g>")
		table.insert(
			lines,
			('<text class="legend-label" x="%s" y="%s">%d. %s</text>'):format(
				number(geometryWidth + LEGEND_INSET),
				number(HEADER_HEIGHT + index * LEGEND_ROW_HEIGHT),
				index,
				escape(annotation.label)
			)
		)
	end
	table.insert(lines, "</g>")
	table.insert(lines, "</svg>")

	return {
		svg = table.concat(lines, "\n") .. "\n",
		transform = transform,
	}
end

return {
	layoutSheet = layoutSheet,
}
