--!strict

local Author = require "../../authoring"
local Test = require "../harness"

local describe, it, expect = Test.describe, Test.it, Test.expect

local function worldEntries(entries: { Author.Entry }): Author.EntrySet
	return Author.set {
		name = "world-layout",
		idKey = "id",
		entries = entries,
	}
end

local function bake(entries: { Author.Entry }, name: string?): Author.LayoutSheet
	return Author.bake.layoutSheet {
		name = name or "Neutral world",
		coordinateSpace = "world-xz",
		unit = "stud",
		bounds = { x = -10, y = -5, width = 30, height = 20 },
		scale = 2,
		set = worldEntries(entries),
	}
end

describe("Author.bake.layoutSheet", function()
	it("returns the explicit input-to-sheet transform", function()
		local result = bake {
			{ id = "anchor", kind = "point", x = -10, y = -5 },
		}
		expect(result.transform):toEqual {
			scale = 2,
			offsetX = 44,
			offsetY = 58,
			width = 388,
			height = 112,
		}
		expect(result.svg):toContain '<circle class="point" cx="24" cy="48" r="4"/>'
	end)

	it("sorts geometry by semantic id independently of authored order", function()
		local first = bake {
			{ id = "zeta", kind = "point", x = 2, y = 3, label = "Last" },
			{ id = "alpha", kind = "rect", x = 0, y = 0, width = 4, height = 2 },
		}
		local second = bake {
			{ id = "alpha", kind = "rect", x = 0, y = 0, width = 4, height = 2 },
			{ id = "zeta", kind = "point", x = 2, y = 3, label = "Last" },
		}
		expect(first.svg):toBe(second.svg)
	end)

	it("maps a rotated footprint around its transformed center", function()
		local result = bake {
			{ id = "tower", kind = "rect", x = 0, y = 5, width = 4, height = 2, rotationDegrees = 30 },
		}
		expect(result.svg):toContain '<rect class="shape" x="44" y="68" width="8" height="4" transform="rotate(30 48 70)"/>'
	end)

	it("escapes names, labels, and semantic ids without changing the transform", function()
		local plain = bake({ { id = "a", kind = "point", x = 0, y = 0, label = "A" } }, "A")
		local escaped = bake({
			{ id = "a&<\"'", kind = "point", x = 0, y = 0, label = '<Gate & "camp">' },
		}, '<Map & "plan">')
		expect(escaped.transform):toEqual(plain.transform)
		expect(escaped.svg):toContain "&lt;Map &amp; &quot;plan&quot;&gt;"
		expect(escaped.svg):toContain 'id="a&amp;&lt;&quot;&apos;"'
		expect(escaped.svg):toContain "&lt;Gate &amp; &quot;camp&quot;&gt;"
	end)

	it("keeps nested boundaries visible and renders annotations after all geometry", function()
		local result = bake {
			{ id = "child", kind = "rect", x = 2, y = 2, width = 4, height = 4, label = "Child" },
			{ id = "z-parent", kind = "rect", x = 0, y = 0, width = 20, height = 12, label = "Parent" },
		}
		expect(result.svg):toContain ".shape{fill:none;"
		local child = string.find(result.svg, '<g id="child"', 1, true) :: number
		local parent = string.find(result.svg, '<g id="z-parent"', 1, true) :: number
		local annotations = string.find(result.svg, '<g class="annotations">', 1, true) :: number
		expect(child < parent):toBe(true)
		expect(parent < annotations):toBe(true)
		expect(result.svg):toContain 'data-for="child"'
		expect(result.svg):toContain ">1. Child</text>"
		expect(result.svg):toContain ">2. Parent</text>"
	end)

	it("separates title and metadata without changing geometry placement", function()
		local result = bake({ { id = "anchor", kind = "point", x = -10, y = -5 } }, "A long narrow-sheet title")
		expect(result.svg):toContain '<text class="title" x="24" y="19">A long narrow-sheet title</text>'
		expect(result.svg):toContain '<text class="meta" x="24" y="38">world-xz · stud</text>'
		expect(result.svg):toContain '<circle class="point" cx="24" cy="48" r="4"/>'
	end)

	it("renders a UI rectangle, point, and polyline in one declared space", function()
		local result = Author.bake.layoutSheet {
			name = "Panel plan",
			coordinateSpace = "ui-pixels",
			unit = "pixel",
			bounds = { x = 0, y = 0, width = 100, height = 80 },
			scale = 1,
			set = Author.set {
				name = "panel",
				idKey = "key",
				entries = {
					{ key = "frame", kind = "rect", x = 10, y = 10, width = 80, height = 60, label = "Frame" },
					{ key = "focus", kind = "point", x = 50, y = 40 },
					{
						key = "flow",
						kind = "polyline",
						points = { { x = 20, y = 20 }, { x = 50, y = 40 }, { x = 80, y = 60 } },
					},
				},
			},
		}
		expect(result.svg):toContain 'points="44,68 74,88 104,108"'
		expect(result.svg):toContain 'data-kind="rect"'
		expect(result.svg):toContain 'data-kind="point"'
	end)

	it("refuses duplicate ids and mixed coordinate spaces", function()
		expect(function()
			bake {
				{ id = "same", kind = "point", x = 0, y = 0 },
				{ id = "same", kind = "point", x = 1, y = 1 },
			}
		end):toThrow "duplicate-id"
		expect(function()
			bake {
				{ id = "mixed", kind = "point", coordinateSpace = "ui-pixels", x = 0, y = 0 },
			}
		end):toThrow "mixed-coordinate-space"
	end)

	it("refuses non-finite geometry and invalid positive extents", function()
		expect(function()
			bake {
				{ id = "bad-point", kind = "point", x = math.huge, y = 0 },
			}
		end):toThrow "nonfinite-geometry"
		expect(function()
			bake {
				{ id = "bad-rect", kind = "rect", x = 0, y = 0, width = 0, height = 2 },
			}
		end):toThrow "nonpositive-extent"
		expect(function()
			Author.bake.layoutSheet {
				name = "Bad bounds",
				coordinateSpace = "ui-pixels",
				unit = "pixel",
				bounds = { x = 0, y = 0, width = -1, height = 80 },
				scale = 1,
				set = worldEntries {},
			}
		end):toThrow "nonpositive-extent"
		expect(function()
			Author.bake.layoutSheet {
				name = "Bad scale",
				coordinateSpace = "ui-pixels",
				unit = "pixel",
				bounds = { x = 0, y = 0, width = 100, height = 80 },
				scale = 0,
				set = worldEntries {},
			}
		end):toThrow "scale"
	end)

	it("refuses a polyline shorter than two points and an unknown kind", function()
		expect(function()
			bake {
				{ id = "short", kind = "polyline", points = { { x = 0, y = 0 } } },
			}
		end):toThrow "short-polyline"
		expect(function()
			bake {
				{ id = "ellipse", kind = "ellipse", x = 0, y = 0 },
			}
		end):toThrow "unknown-kind"
	end)
end)

return nil
