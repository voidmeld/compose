# Design editor

The visual editor is in `src/design-editor`.
Its toolbar, layers, inspector, stage and status bar use the supplied runtime.
All node operations go through that runtime's host.
The editor does not create engine instances or look up ambient services.

## Mount on Roblox

```luau
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)
local Design = require(ReplicatedStorage.compose.design)
local DesignEditor = require(ReplicatedStorage.compose["design-editor"])

local runtime = ComposeRoblox.createRuntime()
local environment = ComposeRoblox.designEnvironment()
local library = DesignEditor.robloxLibrary(runtime, environment)
local document = Design.document.new("Screen", library, "Stack")
local editor = DesignEditor.create(library, document, playerGui, {
    runtime = runtime,
    environment = environment,
    stageSize = { X = 480, Y = 320 },
})

editor.session.insert("Text")
editor.session.change("text", { literal = "Hello" })

editor.dispose()
runtime:dispose()
```
Use a GUI container with a known size as the parent.
Use `roblox3DLibrary` for a scene stage.
The session controls selection and edit history.
Layer dragging calls `session.move`. Inspector controls call session edits.
Resize and numeric drag controls show preview values during movement.
They commit values on release.
A resize commits width, height and fill flags together.
One undo restores the previous size.

### Fields and content

The inspector provides a control for each field type.
It edits `value` fields and other datatypes as Luau literals.
Examples are `{ top = 8, bottom = 8 }` and `{ 0, 10, 0, 20 }`.
Numeric datatypes have one input per component.
With `tokens = true`, each component's ◆ button cycles through token choices.
A token component displays its name. Enter a number to replace it.
The document stores it as `{ token = "size.pill" }` inside the component array.
For example, `{ 1, 0, 0, { token = "size.pill" } }` emits `UDim2.new(1, 0, 0, T.size.pill)` with a `T.` token prefix.
It selects design nodes for `node` fields.
`Design.literal` writes literals. `Design.parseLiteral` reads them.
An invalid literal sets `session.problem` and preserves the previous value.
A render failure after mounting also sets `session.problem` and leaves the editor usable.

A field's `requires` lists sibling fields and allowed values.
For example, `{ presentation = { "gauge" } }` requires that presentation.
An empty allowed list requires any value.
The inspector shows the field only while its requirements hold.
`Design.document.change` rejects the field otherwise.
A change that breaks a requirement clears the dependent value.
A kind's `seeds` supplies children that `insert` adds with it.

A library's `tags = { call, apply }` supports style tags.
The source uses `call(node, { "tag" })`. Direct rendering uses `apply`.
Inside a repeated row, a list can bind a list field of the current item.
`when` can name a boolean item field.
`{ ["$template"] = childId }` renders a child for each item, such as a table column cell.
An output marker with `["$row"] = true` passes the current item.
`perRow = true` writes the literal as a function of the current item.

A `content` field holds a slot input or its own subtree.
`Design.document.content(value, library, id, key, kind)` adds that child.
The source writes `key = function() return <node> end`.
The inspector's add button uses the library's `contentKind`.
A library `token` ending in `.` writes and reads table paths such as `T.space.md`.
A node named from an input keeps its document name as the fallback in generated source.

### Types and live values

Inputs and item fields can set `luauType`, such as `UDim2` or `Controls.Geometry`.
Readable and cell wrappers preserve it in emitted source.
Nested record and list fields retain their types.
The contract header and previews stay plain data.

For live rendering, provide `Design.render` with `bindings`.
These can hold readables, row sources, slots or opaque host values.
Kind builders consume the resolved values.
Conditional children and keyed rows then update through the runtime.
Generated components receive typed props directly.

A kit workspace can provide `token`, `resolveToken`, `tokens` and `slots`.
`tokens` lists inspector choices.
`resolveToken(name)` returns `Design.Resolved`, including native or reactive values.
Use its `value` member for a font, color or palette source.
`token(name)` returns plain preview data when no native resolver is necessary.
Both stages receive the resolvers and preview slots.
A kind's `value` field can forward attribute maps to `Attributes`.
Keep measurements, docking, paging and input policy in the application.
Pass their results through contract inputs and outputs.

### Stages and source links

The 2D stage supports zoom around the cursor, pan, fit, selection outlines, resize controls and a size label.
The 3D stage supports orbit, pan, filtered raycast selection and axis movement.
Fit runs once on the next host frame.
The stage and scene APIs can request another fit.

Pass a `Design.LinkStore` as `options.link` to link source.
The Roblox adapter `studio/design/script-store.luau` wraps `ScriptEditorService`.
The editor uses only the store protocol.

Shift-click or Command/Ctrl-click on the stage toggles a node. Command/Ctrl-click in layers also toggles; Shift-click selects a sibling range. Drag on empty canvas to select intersecting bounds. Selection has a union outline and an outline per node. Escape clears it. Delete, Duplicate, Copy, Paste, Alt+Up/Down and dragging act on the selection. Each edit is one undo step. The inspector shows shared fields, marks differing values as Mixed, and applies an edit to every selected node.

Command/Ctrl+G wraps selected siblings in the library's default list container. Their order stays the same. Command/Ctrl+Shift+G replaces a selected container with its children. Right-click a layer for Wrap and Unwrap. Both commands support undo and redo.

Each layer has Hide and Lock buttons. Hidden subtrees leave the stage preview but remain in emitted components. Locked subtrees cannot be picked or moved on the stage; they remain selectable and editable in layers. Both flags persist in the design header through source edits and undo/redo.

## Motion

A library provides motion with `motion = { call, roles, animate }`.
A bound input, state or item value can carry a `motion` role.
The source writes `<call>(<value>, "role")`.
Direct rendering calls `animate(readable, role)`.
The library theme sets each role's timing.
The motion button beside a bound field cycles through roles.

A library provides sequences with `sequence = { call, toward, build }`.
The document header stores sequence data.
A step can wait for `delay`.
It can move a numeric `state` to `to` over `duration` with `easing` through `toward`.
It sets other state values at the start.
It calls `output` at the end.
Timing values are theme token names.

An event property with `{ play = "id" }` writes `sequences.id.play`.
`autoplay` plays a sequence when the design appears.
`Design.render` creates each player with `build(sequence, states, outputs)`.
It passes those players to `context.players`.
The inspector lists sequences and provides a stage play button.

## Studio plugin

Build the plugin from `studio/design/plugin.project.json`.
The **Design** button opens the design module selected in Explorer.
With no selected design, it opens `ReplicatedStorage.Designs.Screen`.
It creates that module if necessary.
Selecting another design switches the open editor to it.
The source store links editor changes and module changes in both directions.
This includes source changes from Rojo, an agent or the script editor.

The plugin uses the first package kit it finds.
It loads that kit from the game's copy of the package.
The editor and game thus use the same version.
Without a package kit, it uses the built-in Roblox library.
See [DesignEditor.kit](api.md#designeditorkit).

## Vendor the module tree

Keep `core`, `design` and `design-editor` as siblings.
Include `roblox` for its host or environment factory.
Copy the contents of `src` to preserve these paths.
Editor imports have no `src` prefix and do not reach `studio`.
Use the public `design-editor` entry point.

Provide a runtime and environment explicitly.
The environment provides value constructors, service lookup and method calls for opaque nodes and datatypes.
The built-in views require Roblox-shaped classes, properties and methods.
A different host must implement those operations through its host and environment.
Package loading needs no ambient engine.
The [API reference](api.md#design-editor) gives signatures and failures.

## Headless verification

[The editor tests](../tests/design/editor.lute.verify.luau) mount the real editor and libraries with the Roblox host and reflected simulation.
They check geometry, layer order, inspector controls, resize history, zoom, fit, toolbar actions, keyboard actions and source links.
They also check disposal, failed construction and 3D raycasts.

Selection tests also check modifier clicks, sibling ranges, marquee intersections at several zoom levels, union outlines, mixed inspector edits, group dragging, wrap menus and hide/lock history. Live Studio still needs checks for modifier chords, pointer capture outside the canvas, context-menu placement, outline and marquee appearance, and source-linked persistence after reopening the plugin.

The fixture provides fixed Unicode text measurements.
Its layout reader ignores text truncation because the simulator does not model it.
Tests still check design geometry and outline calculations.
These measurements do not prove native text rendering.
Native `UDim` integer offsets can round a resize control by one screen pixel at 200% zoom.

The native cases are `design-editor-edits-and-outlines` and `design-scene-renders-picks-and-moves`.
They use the same public package.
The CPU gate checks their types, but does not run native rendering or input.
Run them with the [engine verification guide](../verification/roblox/README.md).
