# compose-authoring

compose-authoring validates Luau content tables and generates build artifacts.
It runs during authoring and builds, not inside the application. It does not change `src/`.
An application supplies plain Luau tables. The package groups their entries by semantic identity for validation and generation.

```luau
local Author = require "./path/to/authoring" -- lute requires start with ./, ../, or @;
-- a directory require resolves its init.luau

local props = Author.set {
    name = "props",
    idKey = "id",
    roleKey = "role",
    entries = require "./path/to/content/props",
}

-- One line in a content spec:
local ok, violations = Author.validate(props, {
    idPattern = "^%l[%l%d%-]*$",
    unique = true,
    refs = { { field = "model", into = models } },
})
```

| Surface | Does |
| --- | --- |
| `Author.set` | Wraps an authored entry array as a semantic entry set. |
| `Author.validate` | Checks the declared rules and returns `(ok, violations)`. Each violation is `{ setName, entryId, rule, detail }`. Violations come back in entry order, then rule order: `idPattern`, `unique`, `required`, `refs`. Use `required` to check absent fields. `refs` skips them. |
| `set:byId`, `set:byRole` | Run deterministic queries over the authored data. |
| `Author.digest` | Computes a content digest: 16 lowercase hex characters, stable across key order and entry order. It includes the declaration's name, `idKey`, and `roleKey`, so renaming a set changes the digest. This is change detection, not cryptography. |
| `Author.coverage` | Reports which authored ids and roles fall through a registry key list. |
| `Author.bake.attributePlan` | `attributePlan(entry, { { field = "hp", attribute = "HP", optional = true } })` returns `{ { key, value } }` in mapping order. A row that is optional and absent is skipped; a row that is required and absent refuses. |
| `Author.bake.layoutSheet` | Renders one semantic entry set of rectangles, points, and polylines as deterministic SVG, with the exact input-to-sheet transform returned beside it. |
| `Author.bake.registryModule` | Generates a plain Luau registry module from the same mapping. |
| `Author.bake.dataModule` | Generates a plain Luau module returning a typed table of records keyed by id, each record a nested table of strings, numbers, and booleans. |

Roblox serialization emitters are in [`roblox/`](roblox/). The other emitters produce host-neutral data.
Run scripts with `lute run yourscript.luau`. Requires resolve relative to the requiring file.
The repository gate runs the package tests in `tests/authoring/`.

## Layout sheets

`Author.bake.layoutSheet(spec)` creates an SVG from a selected 2D view of an authored plan.
Use the sheet to inspect the plan during builds and edits. The plan remains authoritative.
You can compare the deterministic sheet with actual placement or native captures.

Callers can project 2D or 3D plan data into sheet entries without changing the source representation.
The specification names a coordinate space, unit, positive bounds, positive scale and an `Author.set`.
Each entry has a `kind`: `rect`, `point` or `polyline`.

```luau
local sheet = Author.bake.layoutSheet {
    name = "Encounter plan",
    coordinateSpace = "world-xz",
    unit = "stud",
    bounds = { x = -20, y = -10, width = 40, height = 20 },
    scale = 4,
    set = Author.set {
        name = "encounter",
        idKey = "id",
        entries = {
            { id = "keep", kind = "rect", x = -8, y = -4, width = 16, height = 8, rotationDegrees = 15 },
            { id = "spawn", kind = "point", x = -14, y = 0, label = "Spawn" },
            { id = "path", kind = "polyline", points = { { x = -14, y = 0 }, { x = 0, y = 0 } } },
        },
    },
}
```

The returned `transform` is `{ scale, offsetX, offsetY, width, height }`. Input coordinates map as
`sheetX = x * scale + offsetX` and `sheetY = y * scale + offsetY`.
The header, margin and legend have fixed dimensions. Changing labels therefore does not move geometry.
Entries render in semantic-id order with transparent footprints.
After rendering geometry, the sheet adds numbered marks and matching legend rows for labeled entries.
This exposes nested boundaries and dense points without a packing solver.
Duplicate ids, mixed coordinate spaces, unknown kinds, non-finite geometry, nonpositive extents,
and polylines shorter than two points refuse the bake.
The bake does not solve a layout, place content, traverse terrain or UI, or establish a runtime
registry.

## What this package refuses, on purpose

Keep authoring work outside the application runtime:

- **No runtime metadata hosts.** Authoring emits plans and source. It does not create a service or live registry for scenes to query.
- **No mount hooks.** Nothing here runs inside a Compose mount. A generated directive is
  inert source the application ships, and Compose stays unaware this package exists.
- **No per-node manifests.** Semantic meaning belongs to entries in a declared set.
  Do not create a second scene graph through node-specific manifests.
- **Queries read authored data.** Coverage checks declarations without executing application scripts.
- **No exports from `src/`.** Authoring requires nothing from compose-core and
  re-exports nothing of it. The one seam a generated module shares with Compose is
  structural: the documented mount-point `parent` field.

`tools/compose-check.luau` reports runtime imports of this package as `CMP032`.
It reports manual edits to a generated `registryModule` as `CMP033`. See [`../docs/api.md`](../docs/api.md).

## The generated registry module

`Author.bake.registryModule` writes strict Luau without dependencies. It generates:

- A `PLAN` table keyed by id and the attribute-to-entry mapping.
- `planFor(id)`, which rejects unknown IDs.
- `apply(id, setAttribute)`, which returns a Compose directive.

The directive applies the plan to `mountPoint.parent` through the supplied host setter.
The generated header names the generator and input digests. These identify whether the input changed.

The setter the caller passes is usually the host's own. On a runtime whose host implements
`render.setAttribute`, `host.render.setAttribute` is exactly the right argument. For
attributes written by hand rather than baked, the node prop is shorter. See
[`../docs/api.md`](../docs/api.md#attributes).

## The generated data module

`Author.bake.dataModule { name, idKey, entries }` writes a strict Luau module without dependencies.
The module returns records keyed by id. Records and their fields use sorted key order.
A field can contain a string, finite number, boolean or nested table of those values.
This preserves structured data without flattening it into scalar attribute rows.

The header identifies the generator and includes digests of the records and emitted body.
These detect manual edits and stale generated output, as with `registryModule`.
A non-serialisable field value, a duplicate id, or an entry missing its id field refuses the bake
before anything is written.

## Verification

The set, coverage, validation, digest, registry, data-module and project-tree tests refute malformed
content and nondeterministic output. Run them through the framework gate. Applications verify
generated modules through their own build and runtime tests.
