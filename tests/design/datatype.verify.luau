--!strict

local Design = require "../../src/design"
local Core = require "../../src/core"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local received: { [string]: Design.Resolved } = {}

local function build(props: { [string]: Design.Resolved }, _children: { unknown }, _name: string): unknown
	received = props
	return props
end

local function token(name: string): Design.DatatypeComponent
	return { token = name }
end

local function components(...: Design.DatatypeComponent): Design.Literal
	return Design.datatype.literal { ... }
end

local style: { [string | number]: Design.Literal } = { inset = 0, enabled = false }
local defaults: { [string]: Design.Literal } = { Visible = true, Style = style }

local library: Design.Library = {
	name = "Geometry",
	parameter = "UI",
	parameterType = "Controls",
	prelude = {},
	returnType = "GuiObject",
	readable = "Compose.ReadOnlyValue",
	cell = "Compose.Cell",
	token = "T.",
	kinds = {
		Box = {
			fields = {
				Size = { type = "datatype", datatype = "UDim2", tokens = true },
				Position = { type = "datatype", datatype = "UDim2", tokens = true },
				Padding = { type = "datatype", datatype = "UDim", tokens = true },
				Anchor = { type = "datatype", datatype = "Vector2", tokens = true },
				Point = { type = "datatype", datatype = "Vector3", tokens = true },
				Bounds = { type = "datatype", datatype = "Rect", tokens = true },
				Range = { type = "datatype", datatype = "NumberRange", tokens = true },
				Visible = { type = "boolean", default = true },
				Style = { type = "value", default = style },
				Text = { type = "string" },
			},
			defaults = defaults,
			children = "list",
			call = "UI.Box",
			build = build,
		},
	},
}

local function screen(): Design.Document
	local value = Design.document.new("Screen", library, "Box")
	value = Design.document.change(value, library, "n1", "Size", { literal = { 1, 0, 1, 0 } })
	for index = 1, 12 do
		local id
		value, id = Design.document.insert(value, library, "n1", "Box")
		value = Design.document.change(value, library, id, "Size", { literal = { 0, 240, 0, 48 } })
		value = Design.document.change(value, library, id, "Anchor", { literal = { 0, 0 } })
		value = Design.document.change(value, library, id, "Text", { literal = `Choice {index}` })
	end
	return value
end

describe("Design datatype components", function()
	local cases: { { field: string, expression: string, components: Design.Literal } } = {
		{
			field = "Size",
			expression = "UDim2.new(1, 0, 0, T.size.pill)",
			components = components(1, 0, 0, token "size.pill"),
		},
		{
			field = "Size",
			expression = "UDim2.fromOffset(T.size.zoomButton, T.size.zoomButton)",
			components = components(0, token "size.zoomButton", 0, token "size.zoomButton"),
		},
		{
			field = "Size",
			expression = "UDim2.fromScale(1, T.size.ratio)",
			components = components(1, 0, token "size.ratio", 0),
		},
		{ field = "Size", expression = "UDim2.fromOffset(24, 48)", components = { 0, 24, 0, 48 } },
		{ field = "Size", expression = "UDim2.fromScale(1, 1)", components = { 1, 0, 1, 0 } },
		{ field = "Size", expression = "UDim2.new(1, 2, 3, 4)", components = { 1, 2, 3, 4 } },
		{ field = "Padding", expression = "UDim.new(0, T.size.pill)", components = components(0, token "size.pill") },
		{ field = "Padding", expression = "UDim.new(0.5, 8)", components = { 0.5, 8 } },
		{
			field = "Anchor",
			expression = "Vector2.new(T.size.ratio, 1)",
			components = components(token "size.ratio", 1),
		},
		{ field = "Anchor", expression = "Vector2.new(0.5, 1)", components = { 0.5, 1 } },
		{ field = "Anchor", expression = "Vector2.one", components = { 1, 1 } },
		{ field = "Anchor", expression = "Vector2.zero", components = { 0, 0 } },
		{ field = "Point", expression = "Vector3.one", components = { 1, 1, 1 } },
		{ field = "Point", expression = "Vector3.zero", components = { 0, 0, 0 } },
		{
			field = "Point",
			expression = "Vector3.new(1, T.size.pill, 3)",
			components = components(1, token "size.pill", 3),
		},
		{
			field = "Bounds",
			expression = "Rect.new(0, 0, T.size.pill, 48)",
			components = components(0, 0, token "size.pill", 48),
		},
		{
			field = "Range",
			expression = "NumberRange.new(T.size.pill, 48)",
			components = components(token "size.pill", 48),
		},
	}
	for _, case in cases do
		it(`round trips {case.expression}`, function()
			local value = Design.document.change(
				Design.document.new("Component", library, "Box"),
				library,
				"n1",
				case.field,
				{ literal = case.components }
			)
			local code = Design.emit(value, library)
			expect(string.find(code, `{case.field} = {case.expression},`, 1, true) ~= nil):toBe(true)
			local parsed = Design.parse(code, library)
			expect(parsed.root.props[case.field].literal):toEqual(case.components)
			expect(Design.emit(parsed, library)):toBe(code)
		end)
	end

	it("normalizes long constructors without losing numeric or token components", function()
		local value = Design.document.change(
			Design.document.new("Component", library, "Box"),
			library,
			"n1",
			"Size",
			{ literal = components(0, 24, 0, token "size.minimumTouch") }
		)
		local code = Design.emit(value, library)
		local long = string.gsub(
			code,
			"UDim2%.fromOffset%(24, T%.size%.minimumTouch%)",
			"UDim2.new(0, 24, 0, T.size.minimumTouch)"
		)
		expect(Design.parse(long, library).root.props.Size.literal):toEqual(value.root.props.Size.literal)
		expect(Design.emit(Design.parse(long, library), library)):toBe(code)
		local scaled = Design.document.change(value, library, "n1", "Size", { literal = { 1, 0, 1, 0 } })
		local scaleCode = Design.emit(scaled, library)
		local scaleLong = string.gsub(scaleCode, "UDim2%.fromScale%(1, 1%)", "UDim2.new(1, 0, 1, 0)")
		expect(Design.emit(Design.parse(scaleLong, library), library)):toBe(scaleCode)
	end)

	it("uses resolver calls for components and leaves zero valued tokens intact", function()
		local toy = table.clone(library)
		toy.token = "UI.token"
		local literal = components(token "size.zero", 8, 0, 48)
		local value = Design.document.change(
			Design.document.new("Component", toy, "Box"),
			toy,
			"n1",
			"Size",
			{ literal = literal }
		)
		local code = Design.emit(value, toy)
		expect(string.find(code, 'UDim2.new(UI.token "size.zero", 8, 0, 48)', 1, true) ~= nil):toBe(true)
		expect(Design.parse(code, toy).root.props.Size.literal):toEqual(literal)
		expect(Design.emit(Design.parse(code, toy), toy)):toBe(code)
	end)

	it("resolves numeric components without changing the document or plain value tables", function()
		local typed = components(1, 0, 0, token "size.minimumTouch")
		local value = Design.document.change(
			Design.document.new("Component", library, "Box"),
			library,
			"n1",
			"Size",
			{ literal = typed }
		)
		value = Design.document.change(
			value,
			library,
			"n1",
			"Style",
			{ literal = Design.parseLiteral '{ token = "size.minimumTouch" }' }
		)
		local code = Design.emit(value, library)
		Design.render(value, library, {
			token = function(name: string): Design.Literal
				expect(name):toBe "size.minimumTouch"
				return 48
			end,
		})
		expect(received.Size.literal):toEqual { 1, 0, 0, 48 }
		expect(received.Style.literal):toEqual { token = "size.minimumTouch" }
		expect(Design.emit(value, library)):toBe(code)
		Design.render(value, library, {
			token = function(_name: string): Design.Literal
				return 99
			end,
			resolveToken = function(_name: string): Design.Resolved
				return { value = 44 }
			end,
		})
		expect(received.Size.literal):toEqual { 1, 0, 0, 44 }
	end)

	it("preserves reactive token components and rejects missing or nonnumeric resolutions", function()
		local value = Design.document.change(
			Design.document.new("Component", library, "Box"),
			library,
			"n1",
			"Size",
			{ literal = components(1, 0, 0, token "size.pill") }
		)
		local initial: Design.Literal? = 48
		local height = Core.cell(initial)
		Design.render(value, library, {
			resolveToken = function(_name: string): Design.Resolved
				return { readable = height }
			end,
		})
		local size = assert(received.Size.readable)
		expect(size:peek()):toEqual { 1, 0, 0, 48 }
		height:set(64)
		expect(size:peek()):toEqual { 1, 0, 0, 64 }
		expect(function()
			Design.render(value, library)
		end):toThrow "supply a token resolver"
		expect(function()
			Design.render(value, library, {
				token = function(_name: string): Design.Literal
					return "large"
				end,
			})
		end):toThrow "numeric token"
	end)

	it("validates component shape, token permissions and constructor arity", function()
		local value = Design.document.new("Component", library, "Box")
		local invalid = {
			"{ 1, 2 }",
			'{ 1, 0, 0, "size.pill" }',
			"{ 1, 0, 0, { token = 123 } }",
			'{ 1, 0, 0, { token = "size.pill", extra = 1 } }',
			"{ 1, 0, 0, false }",
			"{ 1, 0, 0, 48, extra = 0 }",
		}
		for _, text in invalid do
			expect(function()
				Design.document.change(value, library, "n1", "Size", { literal = Design.parseLiteral(text) })
			end):toThrow "components"
		end
		local toy = table.clone(library)
		toy.kinds = table.clone(library.kinds)
		toy.kinds.Box = table.clone(library.kinds.Box)
		toy.kinds.Box.fields = table.clone(library.kinds.Box.fields)
		toy.kinds.Box.fields.Size = { type = "datatype", datatype = "UDim2" }
		expect(function()
			Design.document.change(value, toy, "n1", "Size", { literal = components(1, 0, 0, token "size.pill") })
		end):toThrow "components"
	end)

	it("omits literals equal to their field defaults and keeps them unset when parsing", function()
		local value = Design.document.new("Component", library, "Box")
		local code = Design.emit(value, library)
		expect(string.find(code, "Visible =", 1, true)):toBeNil()
		expect(string.find(code, "Style =", 1, true)):toBeNil()
		local parsed = Design.parse(code, library)
		expect(parsed.root.props.Visible):toBeNil()
		expect(Design.emit(parsed, library)):toBe(code)
		value = Design.document.change(value, library, "n1", "Visible", { literal = false })
		value = Design.document.change(
			value,
			library,
			"n1",
			"Style",
			{ literal = Design.parseLiteral "{ inset = 1, enabled = false }" }
		)
		local changed = Design.emit(value, library)
		expect(string.find(changed, "Visible = false", 1, true) ~= nil):toBe(true)
		expect(string.find(changed, "Style =", 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(changed, library), library)):toBe(changed)
	end)

	it("keeps seeded kind defaults that the called control does not apply", function()
		local seeded: { [string]: Design.Literal } = { Text = "Seed" }
		local toy = Design.extend(library, {
			kinds = {
				Seeded = {
					fields = { Text = { type = "string" } },
					defaults = seeded,
					children = "none",
					call = "UI.Seeded",
					build = build,
				},
			},
		})
		local code = Design.emit(Design.document.new("Seeded", toy, "Seeded"), toy)
		expect(string.find(code, `Text = "Seed"`, 1, true) ~= nil):toBe(true)
		expect(Design.emit(Design.parse(code, toy), toy)):toBe(code)
	end)

	it("keeps a representative screen within its recorded emitted byte budget", function()
		local code = Design.emit(screen(), library)
		expect(#code <= 1519):toBe(true)
		expect(Design.emit(Design.parse(code, library), library)):toBe(code)
	end)

	it("omits redundant template wrapper defaults and keeps nondefault keys", function()
		local wrapperDefaults: { [string]: Design.Literal } = { Visible = true }
		local fields: { Design.ItemField } = { { id = "name", type = "string" }, { id = "id", type = "string" } }
		local toy = Design.extend(library, {
			kinds = {
				Rows = {
					fields = {
						from = { type = "value" },
						key = { type = "string", default = "name" },
						Visible = { type = "boolean", default = true },
					},
					defaults = wrapperDefaults,
					children = "template",
					source = "from",
					key = "key",
					template = "render",
					call = "UI.Rows",
					build = build,
				},
			},
		})
		local value = Design.document.setContract(Design.document.new("Rows", toy, "Rows"), toy, {
			inputs = {
				{
					id = "rows",
					kind = "readable",
					type = "list",
					fields = fields,
				},
			},
			outputs = {},
		})
		value = Design.document.bind(value, toy, "n1", { from = "rows", key = "name" })
		value = Design.document.insert(value, toy, "n1", "Box")
		local code = Design.emit(value, toy)
		expect(string.find(code, "key =", 1, true)):toBeNil()
		expect(string.find(code, "Visible =", 1, true)):toBeNil()
		local parsed = Design.parse(code, toy)
		expect(assert(parsed.root.bind).key):toBe "name"
		expect(Design.emit(parsed, toy)):toBe(code)
		value = Design.document.bind(value, toy, "n1", { from = "rows", key = "id" })
		local changed = Design.emit(value, toy)
		expect(string.find(changed, 'key = "id"', 1, true) ~= nil):toBe(true)
		expect(assert(Design.parse(changed, toy).root.bind).key):toBe "id"
	end)
end)

return nil
