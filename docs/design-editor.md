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
Chrome uses 15 px body text, 14 px captions and 17 px titles. The **Text** control cycles body text through 15, 17 and 19 px without resizing the Design canvas or its content. The parent container's `ComposeDesignTextSize` attribute remembers the choice when a Design reopens. The Studio plugin persists that attribute with plugin settings across Studio sessions. Other hosts can restore the attribute before mounting and observe it to persist the preference.
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
Source-authored components can also use `{ input = "offset" }` with a required numeric input.
Static inputs become constructor arguments; readable and cell inputs wrap the constructor in a reactive formula.
The caller prepares the number, including any arithmetic. Component input bindings remain editable through source.
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
`Bind.from = "pages.rows"` explicitly selects `rows` on the current `pages` row.
The qualifier must match the current collection. It does not traverse arbitrary inputs or ancestors.
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
Node references emit cells of the library's optional return type, including forward references.
The capture function and selected-reference table preserve that type under strict analysis.
Node fields receive formulas returning the captured non-nil node. Read them after construction;
uncaptured targets and unknown selected names raise `Node reference is not captured`.

A document can set `rootVariant = { input, value, kind, props }` through `Design.document.setRootVariant`.
The required static string input declares its enum `options`.
The matching option selects the alternative wrapper; the others select the ordinary root.
Both wrappers share one unconditional content subtree and keep one direct root name.
List and slot wrappers are supported. The emitted `rootContent` function owns the shared composition.
This selection occurs when the view is built. Prepare the selector in the caller.

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
The 3D stage opens one large scene with orbit, pan, filtered raycast selection and axis movement.
Its Camera control offers Fit, Player eye height, Approach at 20 studs, Close-up and Top-down.
Pass `scene = { world = workspace, camera = workspace.CurrentCamera, eyeHeight = 5.5 }` to render
through the host's actual world camera. Mount that editor as a transparent viewport overlay.
The host supplies Lighting, Atmosphere, materials and environment effects; the editor keeps them.
Owned geometry, emitters, lights and beams then use the normal world renderer and simulation.
Closing releases the preview geometry and restores the borrowed camera's frame, focus, field of view and type.
Without a scene target, the embedded ViewportFrame remains suitable for geometry inspection;
its rendering limits do not establish an in-world appearance match.
Use a named `Preview` for the host's Lighting/Atmosphere presets. Its `select` callback applies the same
settings used in the running scene, through the host. The editor applies the initial choice before
building frames. Keep materials, textures and effects in the shared Design and library; `Beam` accepts
`attachment0` and `attachment1` node references, including forward references. Attachment children
remain attached. Beam references connect on the next host frame, after the complete tree exists.
`Guides` with `enabled = false` removes grid and selection helpers from captures without hiding the Design.
The 3D `Pattern` control plans its rows with [geometric patterns](../src/design/patterns.md).
Fit runs once on the next host frame.
The stage and scene APIs can request another fit.

Pass a `Design.LinkStore` as `options.link` to link source.
The Roblox adapter `studio/design/script-store.luau` wraps `ScriptEditorService`.
The editor uses only the store protocol.

Shift-click or Command/Ctrl-click on the stage toggles a node. Command/Ctrl-click in layers also toggles; Shift-click selects a sibling range. Drag on empty canvas to select intersecting bounds. Selection has a union outline and an outline per node. Escape clears it. Delete, Duplicate, Copy, Paste, Alt+Up/Down and dragging act on the selection. Each edit is one undo step. The inspector shows shared fields, marks differing values as Mixed, and applies an edit to every selected node.

Command/Ctrl+G wraps selected siblings in the library's default list container. Their order stays the same. Command/Ctrl+Shift+G replaces a selected container with its children. Right-click a layer for Wrap and Unwrap. Both commands support undo and redo.

Each layer has Hide and Lock buttons. Hidden subtrees leave the stage preview but remain in emitted components. Locked subtrees cannot be picked or moved on the stage; they remain selectable and editable in layers. Both flags persist in the design header through source edits and undo/redo.

## Device frames

The Device control selects one named frame. All devices opens a grid; Single device returns to the active frame. Clicking a frame activates it. Selection and edits apply to the same source document across frames. A kit defaults to the eight profiles in `DesignEditor.devices.all`:

| ID | Viewport | Input | Text scale |
| --- | --- | --- | --- |
| `phone-portrait` | 389 × 762 | touch | 1 |
| `phone-landscape` | 749 × 389 | touch | 1 |
| `tablet-portrait` | 820 × 1180 | touch | 1 |
| `tablet-landscape` | 1180 × 820 | touch | 1 |
| `monitor` | 1919 × 1080 | mouse | 1 |
| `ultrawide` | 3439 × 1440 | mouse | 1 |
| `tv` | 1919 × 1080 | gamepad | 1.3 |
| `vr` | 2064 × 2208 per eye | VR | 1.15 |

Profiles include aspect, native GUI insets, cutouts, safe area and camera field of view. Phone, monitor and TV retain Verify's captured viewport and GUI inset values. `devices.get("generic_handheld_720")` exposes its captured 1279 × 720 gamepad profile without adding it to the standard grid. Tablet, ultrawide and VR are design presets. TV adds an overscan safe area of 96 left/right, 112 top and 54 bottom pixels; its native GUI inset remains 58 pixels at the top.

Supply `Workspace.frame(device, scale)` to build each frame's library using the same layout sources as the game. A shared viewport cell cannot represent simultaneous frames. Frame-local sources resolve at the profile's full logical resolution; zoom scales their display. Native measurements used for layout must normalize by `scale`.

The **Actual size** control sets the current UI frame to one logical pixel per host GUI pixel. Each device
remembers this mode across device switches, grid changes and editor resizing. **Fit size** returns that
frame to fitting the available room. Fit clears the mode on visible frames; a zoom clears it on the
affected frame. This mode does not assert a physical display size or change the device's logical inputs.

Supply `backdrop = function() return sceneView end` in the editor options or a frame context to mount
an owned host view behind that frame's UI. It uses the same logical size and zoom as the screen. Build
it with the runtime under the supplied owner; it is released with the frame, including on failed builds.
Use a reactive backdrop builder and a named preview to switch it on and off. A host world camera or
scene view remains responsible for native scene rendering.

Use `previews = { { name = "State", choices = { "ordinary", "empty", "busy", "error" },
initial = "ordinary", select = selectSample } }` to expose sample states. `selectSample` updates the
same borrowed bindings used by the running screen. The initial callback runs once before rendering;
later commands and toolbar clicks use the same callback. Names and choices must be nonempty and unique.
A failed callback preserves the displayed choice. The callback owns rolling back any external mutation
it made before raising. Host teardown restores borrowed environment settings.

Screen roots project their authored ScreenInsets into the frame. Billboard roots project authored stud/offset sizes and world offsets against a centered, 12-stud camera fixture; pixel offsets keep their authored sizes. This is a layout fixture, with its camera declared independently from gameplay. Device grids apply to UI Designs. A 3D Design has one scene and ignores grid requests.

### Editor commands

`editor.execute(request)` returns plain structured state. Actions use these stable arguments:

| Actions | Arguments after `action` |
| --- | --- |
| Read, Fit, Undo, Redo, Duplicate, Delete, Copy, Paste, Wrap, Unwrap, Export, Import, DiscardDrafts | none |
| Camera | `preset`: `fit`, `eye-height`, `approach-20`, `close-up`, `top-down` |
| Orbit | finite `yaw`, `pitch` in degrees |
| Zoom | finite positive `scale`, optional cursor `around = { X, Y }` |
| Pan | finite `x`, `y` in host GUI pixels, relative to the current view |
| ActualSize, AllDevices, Guides | `enabled`: boolean; ActualSize is UI-only, Guides is 3D-only |
| Select | `ids`: node IDs; an empty list clears selection |
| SelectRelative | `direction`: `parent`, `child`, `next`, `previous` |
| Change | `field`, optional `value`: a Design.Value; omit to clear |
| ChangeMany | `changes`: map of fields to Design.Value |
| Insert, Content | `kind`; Content also takes `field` |
| Rename, Tag, Bind | `name`, optional `tags`, optional `binding`, respectively |
| Move | `id`, `destination`, optional `before` sibling index |
| Shift | `step`: sibling offset |
| Hide, Lock | `id` and `hidden` or `locked`: boolean |
| Contract, Replace | `contract`: Design.Contract or `document`: Design.Document, respectively |
| Device | `id`: profile ID |
| Preview | `name`, `choice` |
| TextSize | `size`: 15, 17 or 19 |
| Theme, ThemeValue | `opened`: boolean, or token `id` and `value`, respectively |
| Play | `sequence`: sequence ID |
| Prompt | `text`, optional `count`: 1, 2 or 3, optional `theme`: boolean |
| ChooseDraft | `index`: one-based draft index |

The commands use the same session, camera and preview callbacks as the visible controls.
Supply `identity = { commit = commit, path = sourcePath }` to bind results to a source revision.
Results include `ok`, `action`, `design`, optional source identity, `selection`, `camera`, active `device`,
available `devices`, `allDevices`, `actualSize`, `zoom`, chrome `textSize`, current `previews` and available
`previewChoices`. Export also returns `source`. Prompt operations are scheduled; `prompt` reports
`busy`, `drafts` and `status` on subsequent Read calls. A rejected session edit returns `ok = false`, as
does a raised callback; failures include `problem` and the next Read command. Read can return an existing
session problem while succeeding. Theme writes validate the same token ranges as the inspector.
The library writes no files itself (`files` is empty); the host reports its actual
source writes and named native captures. The host also owns open, capture and close commands.

```luau
editor.execute({ action = "Camera", preset = "approach-20" })
editor.execute({ action = "Orbit", yaw = 35, pitch = -20 })
editor.execute({ action = "Select", ids = { "n2" } })
editor.execute({ action = "Change", field = "size", value = { literal = { 4, 6, 4 } } })
editor.execute({ action = "Undo" })
editor.execute({ action = "Read" })
```

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

## Prompt and compare

Provide `prompt` with the source path and a submission callback to enable the request box beneath the canvas. Select a node and describe the change. The callback receives a stable snapshot of its path, props, token references and active frame. Its provider owns native capture, authentication, agent invocation and scoped source writes. The source link imports the result.

Ask for two or three variants, or set the variant count. Returned drafts render side by side in independent read-only sessions on the requested device. Choosing a draft calls the provider's pick callback. Discarding releases it without saving. Canonical selection, history and source stay in the original session.

Provide `theme` to expose shared colour, type and spacing fields. Reactive field readers display current token values; the writer persists changes and updates the token inputs used by each frame. A prompt provider can also expose the Theme request scope. These interfaces are in the [API reference](api.md#designeditorcreate).

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
All-device geometry cases omit text measurement and text auto sizing, which Verify cannot resolve at thumbnail scales. They check logical frame bounds and reactive token propagation; native text still requires engine frames.
Its layout reader ignores text truncation because the simulator does not model it.
Tests still check design geometry and outline calculations.
These measurements do not prove native text rendering.
Native `UDim` integer offsets can round a resize control by one screen pixel at 200% zoom.

The native cases are `design-editor-edits-and-outlines` and `design-scene-renders-picks-and-moves`.
They use the same public package.
The CPU gate checks their types, but does not run native rendering or input.
Run them with the [engine verification guide](../verification/roblox/README.md).

The disposable [preview comparison fixture](../studio/design/preview.luau) has `editor-3d`, `game-3d`,
`editor-ui` and `game-ui` cases. Run each separately with
`lute run .lute/dependencies/verify/tools/run.luau --entry studio/design/preview.luau --host studio --context Client --case editor-3d --capture --deadline 120 --output .worker-tmp/native`.
It leaves the fixture visible until its owned Studio closes so the final capture contains the tested frame.
The game cases mount the same Design directly using the editor's recorded camera or UI bounds. Compare
the artboard regions recorded in `region.txt`; chrome and selection outlines are editor-only. UI checks
cycle every sample state, with the final capture showing busy. Particles remain time-dependent between
captures. These generic fixtures do not certify an adopter's screens, assets or physical devices.
