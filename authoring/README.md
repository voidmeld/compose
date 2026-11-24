# Build-time authoring

The `authoring` package checks content tables and generates files.
Its outputs include source modules, layout sheets and Rojo project trees.
Use it in build tools, outside the application runtime.
The application provides entries with semantic IDs.

```luau
local Author = require "./path/to/authoring"

local props = Author.set {
    name = "props",
    idKey = "id",
    entries = {
        { id = "lamp", model = "wall-lamp" },
    },
}

local ok, violations = Author.validate(props, {
    idPattern = "^%l[%l%d%-]*$",
    unique = true,
    required = { "model" },
})
assert(ok, tostring(#violations) .. " content violations")
```
Run your script with `lute run yourscript.luau`.
Requires resolve relative to that script.

## Choose an operation

| Task | Contract |
| --- | --- |
| Group entries and query IDs or roles | [Author.set](../docs/api.md#authorset) |
| Check required fields, IDs and references | [Author.validate](../docs/api.md#authorvalidate) |
| Detect changed content | [Author.digest](../docs/api.md#authordigest) |
| Find missing handlers | [Author.coverage](../docs/api.md#authorcoverage) |
| Resolve anchors, offsets, routes and spread rules; check geometry | [Author.placement](../docs/api.md#authorplacement) |
| Generate Rojo project trees | [Author.projectTree](../docs/api.md#authorprojecttree) |
| Render a plan for inspection | [Layout sheets](#layout-sheets) |
| Generate runtime data or attribute application | [Registry modules](#the-generated-registry-module) and [data modules](#the-generated-data-module) |

This guide defines bake output formats and build-time boundaries.
The API reference defines the other public calls.
The application must check generated output with build and runtime tests.

## Compile a layout

1. Pass placement rules to `Author.placement.resolve`.
2. Check the positions with `Author.placement.check`.
3. Emit the data for the application.

The application provides content, distances and constraints.
Compose resolves geometry without engine state or application rules.
The [placement API](../docs/api.md#authorplacement) defines rule shapes, coordinate spaces and errors.
Keep one source plan.
Regenerate its outputs after changes.
Do not edit generated files separately.

## Attribute plans

`Author.bake.attributePlan(entry, mapping)` returns `{ { key, value } }` in mapping order.
A mapping row is `{ field = "size", attribute = "Size", optional = true }`.
The bake skips absent optional fields and rejects absent required fields.
Use the same mapping with `registryModule` to generate application code.

## Layout sheets

`Author.bake.layoutSheet(spec)` creates an SVG from a 2D view of a plan.
Use it to inspect the plan during builds and edits.
Compare the sheet with actual placement or native captures.
The source plan remains the authority.
The application can project 2D or 3D data into sheet entries without changing that plan.

The specification names a coordinate space, unit, positive bounds, positive scale and an `Author.set`.
Each entry has a `kind`: `rect`, `point` or `polyline`.

```luau
local sheet = Author.bake.layoutSheet {
    name = "Site plan",
    coordinateSpace = "world-xz",
    unit = "m",
    bounds = { x = -20, y = -10, width = 40, height = 20 },
    scale = 4,
    set = Author.set {
        name = "site",
        idKey = "id",
        entries = {
            { id = "building", kind = "rect", x = -8, y = -4, width = 16, height = 8, rotationDegrees = 15 },
            { id = "entrance", kind = "point", x = -14, y = 0, label = "Entrance" },
            { id = "path", kind = "polyline", points = { { x = -14, y = 0 }, { x = 0, y = 0 } } },
        },
    },
}
```
The returned `transform` is `{ scale, offsetX, offsetY, width, height }`.
Coordinates map through `sheetX = x * scale + offsetX` and `sheetY = y * scale + offsetY`.

- Header, margin and legend sizes stay fixed. Label changes do not move geometry.
- Entries render in semantic-ID order with transparent footprints.
- Numbered marks and matching legend rows follow the geometry. They identify nested boundaries and dense points without a packing solver.
- The bake rejects duplicate IDs, mixed coordinate spaces, unknown kinds, non-finite geometry and nonpositive extents.
- A polyline requires at least two points.
- The bake does not resolve layouts, place content, walk terrain or UI, or create a runtime registry.

## Build-time boundary

Authoring emits plans and source files.
It does not create live services, runtime metadata hosts or mount hooks.
A generated directive is source that the application ships.
Core does not depend on this package.

Keep semantic meaning in declared set entries.
Do not create a second scene graph with per-node manifests.
Coverage reads declarations without executing application scripts.
Authoring imports and exports nothing from `src/core`.
Generated directives use only the documented mount-point `parent` field.

`tools/compose-check.luau` reports runtime authoring imports as `CMP032`.
It reports manual changes to generated registry modules as `CMP033`.
See the [API reference](../docs/api.md).

## The generated registry module

`Author.bake.registryModule` writes strict Luau without dependencies.
It generates:

- A `PLAN` table keyed by ID and an attribute-to-entry mapping.
- `planFor(id)`, which rejects unknown IDs.
- `apply(id, setAttribute)`, which returns a Compose directive.

The directive applies a plan to `mountPoint.parent` through the supplied setter.
The header records the generator and input digests for change detection.
For a host with `render.setAttribute`, pass `host.render.setAttribute` as the setter.
For attributes written by hand, use the [Attributes property](../docs/api.md#attributes).

## The generated data module

`Author.bake.dataModule { name, idKey, entries }` writes strict Luau without dependencies.
The module returns records keyed by ID, with sorted record and field keys.
Values can be strings, finite numbers, booleans or nested tables of those values.
It preserves structure without converting tables into scalar attribute rows.

The output contains the strict directive, types and data.
It has no commentary or digest header.
Compare it with a fresh bake to detect stale output.
The bake rejects invalid values, duplicate IDs and missing ID fields before it writes output.

## Verification

Tests cover sets, coverage, validation, digests, registry modules, data modules, placement and project trees.
They reject invalid content and check repeatable output.
Use focused tests during edits.
Follow [the maintainer guide](../AGENTS.md) for integration checks.
