# compose-authoring

compose-authoring validates and bakes authored Luau tables before runtime, supporting authored
content during builds and edits without running with the application or changing `src/`.

An application keeps writing content the way it already does, as plain Luau tables. This
package gives those tables a semantic wrapper at authoring time.

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
| `Author.validate` | Checks the declared rules and returns `(ok, violations)`. Each violation is `{ setName, entryId, rule, detail }`. Violations come back in entry order, then rule order: `idPattern`, `unique`, `required`, `refs`. An absent field is `required`'s business; `refs` skips it. |
| `set:byId`, `set:byRole` | Run deterministic queries over the authored data. |
| `Author.digest` | Computes a content digest: 16 lowercase hex characters, stable across key order and entry order. It includes the declaration's name, `idKey`, and `roleKey`, so renaming a set changes the digest. This is change detection, not cryptography. |
| `Author.coverage` | Reports which authored ids and roles fall through a registry key list. |
| `Author.bake.attributePlan` | `attributePlan(entry, { { field = "hp", attribute = "HP", optional = true } })` returns `{ { key, value } }` in mapping order. A row that is optional and absent is skipped; a row that is required and absent refuses. |
| `Author.bake.layoutSheet` | Renders one semantic entry set of rectangles, points, and polylines as deterministic SVG, with the exact input-to-sheet transform returned beside it. |
| `Author.bake.registryModule` | Generates a plain Luau registry module from the same mapping. |
| `Author.bake.dataModule` | Generates a plain Luau module returning a typed table of records keyed by id, each record a nested table of strings, numbers, and booleans. |

The Roblox-serialization emitters live under [`roblox/`](roblox/). Everything else is
host-neutral plain data. Run scripts as `lute yourscript.luau`; requires resolve relative
to the requiring file. In the compose repository the specs live in `tests/authoring/`, and
the ordinary gate covers the package.

## Layout sheets

`Author.bake.layoutSheet(spec)` turns one selected 2D view of an authoritative authored plan into a
small neutral SVG for build and edit-time inspection. The plan remains the source of layout truth;
the sheet is a deterministic view that can later be compared with placement or native captures.
Callers may project richer 2D or 3D plan data into the sheet entries without changing their
authoritative representation. The specification names one coordinate space, unit, positive bounds,
positive scale, and an `Author.set`. Entries have a `kind` of `rect`, `point`, or `polyline`:

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
`sheetX = x * scale + offsetX` and `sheetY = y * scale + offsetY`. A fixed header and margin reserve
space for the title and metadata, and a fixed legend width reserves annotations, so changing names
or labels cannot change geometry placement. Entries render in semantic-id order with transparent
footprints. Labeled entries receive compact numbered marks after all geometry and matching legend
rows, keeping nested boundaries and dense point semantics inspectable without a packing solver.
Duplicate ids, mixed coordinate spaces, unknown kinds, non-finite geometry, nonpositive extents,
and polylines shorter than two points refuse the bake.
The bake does not solve a layout, place content, traverse terrain or UI, or establish a runtime
registry.

## What this package refuses, on purpose

Each of these is a runtime tax on data that only changes at edit time.

- **No runtime metadata hosts.** Authoring emits plans and source. It never stands up a
  service or live registry object that a scene must query while players are in it.
- **No mount hooks.** Nothing here runs inside a Compose mount. A generated directive is
  inert source the application ships, and Compose stays unaware this package exists.
- **No per-node manifests.** Authored meaning attaches to entries in one declared set,
  not to individual scene nodes. A manifest per node would be a second scene graph that
  drifts from the first.
- **Queries read authored data.** Coverage checks declarations without executing application scripts.
- **No exports from `src/`.** Authoring requires nothing from compose-core and
  re-exports nothing of it. The one seam a generated module shares with Compose is
  structural: the documented mount-point `parent` field.

The zero-bytes-at-runtime claim above is enforced, not only stated. `tools/compose-check.luau`
reports a runtime `require` of this package as `CMP032`, and it reports a `registryModule` bake
edited by hand after generation as `CMP033`. See [`../docs/api.md`](../docs/api.md).

## The generated registry module

`Author.bake.registryModule` writes strict, dependency-free Luau. It produces a `PLAN` dispatch
table keyed by id, the attribute-to-entry join, plus `planFor(id)`, which refuses an unknown
id, and `apply(id, setAttribute)`, which returns an ordinary Compose directive. That directive
is a function of a mount point that applies the plan to `mountPoint.parent` through the
host-specific setter the application supplies. The generated header names the generator
and the digests of both inputs, so a reader can tell "regenerated from the same data" apart
from "the data moved" without reading the diff.

The setter the caller passes is usually the host's own. On a runtime whose host implements
`render.setAttribute`, `host.render.setAttribute` is exactly the right argument. For
attributes written by hand rather than baked, the node prop is shorter. See
[`../docs/api.md`](../docs/api.md#attributes).

## The generated data module

`Author.bake.dataModule { name, idKey, entries }` writes a strict, dependency-free Luau module
that returns one table of records keyed by id, sorted by id, each record's own fields in sorted
key order. A record field may be a string, a finite number, a boolean, or a nested table of them,
so a compiled plan can keep its authored shape — a position or a cell join — as a require rather
than flattening it to scalar attribute rows. The generated header carries the same generator-line
and digest convention as `registryModule`: a digest over the baked records and a digest over the
emitted body, so a hand edit or a stale regeneration is as visible as it is for a registry module.
A non-serialisable field value, a duplicate id, or an entry missing its id field refuses the bake
before anything is written.

## Verification

The set, coverage, validation, digest, registry, data-module and project-tree tests refute malformed
content and nondeterministic output. Run them through the framework gate. Applications verify
generated modules through their own build and runtime tests.
