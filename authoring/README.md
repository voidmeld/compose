# Build-time authoring

The `authoring` package of Compose validates content tables and generates build artifacts. These include source modules, layout sheets and Rojo project trees.
Use it from build tools, outside the application runtime.
The application supplies entries with semantic IDs. The package checks and transforms those declarations.

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

Run the script with `lute run yourscript.luau`. Requires resolve relative to that script.

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

This guide owns the bake output formats and the build-time boundaries. The API reference owns the other public calls.
The application verifies generated output through its build and runtime tests.

## Compile a layout

1. Pass the authored placement rules to `Author.placement.resolve`.
2. Check the resulting positions with `Author.placement.check`.
3. Emit the data that the application consumes.

A layout sheet provides a 2D view for inspection.
The application supplies content, distances and constraints. Compose resolves generic geometry without engine state or application rules.

[The placement API](../docs/api.md#authorplacement) owns the rule schema, the coordinate spaces and the refusals.
Keep one authored plan and regenerate its outputs. Do not edit the outputs separately.

## Attribute plans

`Author.bake.attributePlan(entry, mapping)` returns `{ { key, value } }` in mapping order.
A mapping row is `{ field = "size", attribute = "Size", optional = true }`.
An absent optional field is skipped. An absent required field refuses.
To emit application code, use the same mapping with `registryModule`.

## Layout sheets

`Author.bake.layoutSheet(spec)` creates an SVG from a selected 2D view of an authored plan.
Use the sheet to inspect the plan during builds and edits. The plan remains authoritative.
You can compare the deterministic sheet with the actual placement or with native captures.

A consumer can project 2D or 3D plan data into sheet entries without changing the source representation.
The specification names a coordinate space, a unit, positive bounds, a positive scale and an `Author.set`.
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
Input coordinates map as `sheetX = x * scale + offsetX` and `sheetY = y * scale + offsetY`.

- The header, the margin and the legend have fixed dimensions. A change of labels therefore does not move geometry.
- Entries render in semantic-ID order with transparent footprints.
- After the geometry, the sheet adds numbered marks and matching legend rows for labeled entries. This exposes nested boundaries and dense points without a packing solver.
- The bake refuses duplicate IDs, mixed coordinate spaces, unknown kinds, non-finite geometry, nonpositive extents and polylines with fewer than two points.
- The bake does not solve a layout, place content, traverse terrain or UI, or establish a runtime registry.

## Build-time boundary

Keep authoring work outside the application runtime:

- **No runtime metadata hosts.** Authoring emits plans and source. It does not create a service or a live registry for scenes to query.
- **No mount hooks.** Nothing here runs inside a Compose mount. A generated directive is inert source that the application ships. Compose does not know that this package exists.
- **No per-node manifests.** Semantic meaning belongs to the entries in a declared set. Do not create a second scene graph through node-specific manifests.
- **Queries read authored data.** Coverage checks declarations without executing application scripts.
- **No exports from `src/`.** Authoring requires nothing from `src/core` and re-exports nothing of it. The one seam that a generated module shares with Compose is structural: the documented mount-point `parent` field.

`tools/compose-check.luau` reports runtime imports of this package as `CMP032`.
It reports manual edits to a generated `registryModule` as `CMP033`. See [`../docs/api.md`](../docs/api.md).

## The generated registry module

`Author.bake.registryModule` writes strict Luau without dependencies. It generates these items:

- A `PLAN` table keyed by ID, and the attribute-to-entry mapping.
- `planFor(id)`, which rejects unknown IDs.
- `apply(id, setAttribute)`, which returns a Compose directive.

The directive applies the plan to `mountPoint.parent` through the setter that you supply.
The generated header names the generator and the input digests. They identify whether the input changed.

The setter that you pass is usually the setter of the host.
On a runtime whose host implements `render.setAttribute`, `host.render.setAttribute` is the correct argument.
For attributes that you write by hand instead of baking, the node prop is shorter. See [`../docs/api.md`](../docs/api.md#attributes).

## The generated data module

`Author.bake.dataModule { name, idKey, entries }` writes a strict Luau module without dependencies.
The module returns records keyed by ID. Records and their fields use sorted key order.
A field can contain a string, a finite number, a boolean or a nested table of those values.
This preserves structured data without flattening it into scalar attribute rows.

The output contains the strict directive, the types and the data. It has no commentary and no digest header.
To detect stale output, compare it with a fresh bake.
The bake refuses before it writes anything if a field value is not serializable, if an ID is duplicate, or if an entry lacks its ID field.

## Verification

The tests for set, coverage, validation, digest, registry, data module, placement and project tree refute malformed content and nondeterministic output.
Use the focused tests while you edit. For final integration, follow [AGENTS](../AGENTS.md).
