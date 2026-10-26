# Design editor

The visual editor lives in `src/design-editor`. Its toolbar, layer tree, inspector, stage and status bar use the supplied Compose runtime. It creates nodes through `runtime.constructors`; changes, parenting, attributes and subscriptions go through that runtime's host. It does not create engine instances or resolve ambient services.

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

Use a GUI container with a known extent as the parent. Use `roblox3DLibrary` to open the scene stage. The returned session owns selection and edit history. Layer dragging calls `session.move`; inspector controls call session edits. Resizing and numeric scrubbing preview values during movement and commit when released. A resize commits its width, height and fill flags together, so one undo restores the previous size.

The inspector has an editor for each field type. It edits `value` and `datatype` fields as Luau literals, such as `{ top = 8, bottom = 8 }` or `{ 0, 10, 0, 20 }`. It edits `node` fields by choosing a node of the design. `Design.literal(value)` writes a literal as Luau and `Design.parseLiteral(text)` reads it back; an invalid literal sets `session.problem` and keeps the old value. A field's `requires` names the sibling fields and values it depends on, for example `{ presentation = { "gauge" } }`; an empty list requires any value. The inspector shows the field only when its requirements hold, `Design.document.change` refuses the field otherwise, and a change that breaks a requirement clears the dependent value. A kind's `seeds` are the children `insert` adds with it. After the editor mounts, a design that fails to render sets `session.problem` and leaves the editor usable.

A library's `tags = { call, apply }` lets nodes carry style tags; the source wraps a tagged node in `call(node, { "tag" })` and rendering calls `apply`. Inside a repeated row, a list can bind a list field of the row item, and `when` can name a boolean item field. A literal can render a child of a repeated node per item with `{ ["$template"] = childId }`, as a table column's cell does, and an output marker with `["$row"] = true` passes the current item. A field with `perRow = true` holds a literal that the source writes as a function of the current item, as row actions are.

A `content` field holds either a slot input or a subtree of its own: `Design.document.content(value, library, id, key, kind)` adds the child and the source writes `key = function() return <node> end`. The inspector's add button uses the library's `contentKind`. A library `token` that ends with `.` writes tokens as table paths, such as `T.space.md`, and reads them back. A node named from an input always writes its document name as the fallback, so the name survives a round trip.

The 2D stage supports cursor-anchored zoom, pan, fit, selection outlines, resize grips and a size badge. The scene stage supports orbit, pan, filtered raycast picking and axis translation. Fit runs once on the next host frame and can also be requested through the stage or scene API.

For a source link, pass a `Design.LinkStore` as `options.link`. The Roblox-only `studio/design/script-store.luau` adapter wraps `ScriptEditorService`; the editor itself only consumes the store protocol.

## Motion

A library gives motion to bound values with `motion = { call, roles, animate }`. A bound input, state or item value can carry a `motion` role. The source writes it as `<call>(<value>, "role")`, and `Design.render` passes the value through `animate(readable, role)`. The theme of the library owns the timing of each role. The `〜` button next to a bound field steps through the roles.

A library plays timed changes with `sequence = { call, toward, build }`. A design keeps its sequences as data in the header. Each step waits `delay`, moves a number `state` value to `to` over `duration` with `easing` (`toward`), or sets any other value when it starts, and calls `output` at its end. The timing values are theme token names. An event property plays a sequence with `{ play = "id" }`, which the source writes as `sequences.id.play`. A sequence with `autoplay` plays when the design shows. `Design.render` makes one player for each sequence through `build(sequence, states, outputs)` and gives them to `context.players`. The inspector lists the sequences, and **▶** plays one on the stage.

## Studio plugin

Build the plugin from `studio/design/plugin.project.json`. Its **Design** button opens the design module that is selected in the Explorer. If no design module is selected, it opens `ReplicatedStorage.Designs.Screen` and creates it when it is missing. Selecting another design module while the editor is open switches to it. The editor stays linked to the module through `studio/design/script-store.luau`. Edits in the editor write the source, and source edits from Rojo, an agent or the script editor update the editor.

The plugin uses the first package kit that it finds (see [`DesignEditor.kit`](api.md#designeditorkit)). It loads that kit from the game's own copy of the package, so the editor and the game always use the same version. Without a package kit, the plugin opens the built-in Roblox library.

## Vendor the module tree

Keep `core`, `design` and `design-editor` as siblings. Include `roblox` when using the Roblox host or its environment factory. Copying the contents of `src/` preserves these relationships: no editor require contains a `src/` prefix or reaches `studio/`. Consume the public `design-editor` entry point; its internal files are implementation modules.

Provide a runtime and an environment explicitly. The environment supplies value constructors, service lookup and method invocation for opaque host nodes and datatypes. The editor's built-in views use Roblox-shaped classes, properties and methods; a different host must implement those semantics through its host and environment. No ambient engine is needed to load the package. The complete signatures and failure behavior are in the [API reference](api.md#design-editor).

## Headless verification

`tests/design/editor.lute.verify.luau` mounts the actual editor and bundled libraries through the real Roblox host and Verify's reflected simulated engine. It checks geometry, layer reorder, inspector controls, resize history, zoom and fit, toolbar and keyboard actions, source-link status, disposal, failed-build unwind and 3D raycasts.

The test fixture supplies deterministic text measurements for Unicode glyphs. Its layout reader ignores text truncation, which the layout simulator does not model. Fixed design-node geometry and the editor's outline math remain under test; text rendering is not established by those measurements. Native `UDim` integer offsets can round a grip by a screen pixel at 200% zoom.

The engine checks `design-editor-edits-and-outlines` and `design-scene-renders-picks-and-moves` consume the same public package. Passing the CPU gate proves their types, not a native rendering or input experience. Run them using the [engine verification guide](../verification/roblox/README.md).
