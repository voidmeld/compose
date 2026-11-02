# Geometric patterns

`src/design/patterns` is the pure geometry-planning entry point used by the 3D editor and host adapters.
`rows(properties)` returns stable `id`, `position`, `rotation`, `size` and `color` records. It creates no
instances or reactive resources. `fields` describes those records for Design iteration templates.

`mode` is `linear`, `grid` or `radial`. Linear patterns use `count` and a `spacing` vector. Radial
patterns use `count` and `radius`. Grids use positive integer `columns`/`rows` and a centered `extent`.
`order` selects row or column traversal. `fit = true` divides the grid span into cells, subtracts
`gap` from each cell and retains the authored Y size. Patterns contain at most 500 instances.

`position` and degree `rotation` place the pattern. `size` and hex `color` provide row defaults.
Up to 32 `variants` repeat position offsets, rotations, sizes and colors. `variantBy = "sum"` uses
the grid column plus row; its default uses the instance index. `namePattern` accepts one `%d`, or
two for grid column/row names. `indexOrigin` defaults to one. Invalid values fail explicitly.

The 3D `Pattern` control authors one `render` template with these parameters. Its membership inputs
are values and rebuild with the document. Host adapters may flatten the authoring group while
retaining row order. Select the group to translate the whole pattern; position-bound template
instances preserve their binding when selected with the gizmo.
