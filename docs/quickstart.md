# Quickstart

This guide builds one component with the public API.
A component is a function that returns scene content.
A host creates and changes the nodes in that content.
An owner releases the nodes and subscriptions when their lifetime ends.

## Prepare the tools

1. Run `rokit install` in this repository.
2. Select one exact commit of `https://github.com/voidmeld/compose.git` for your application.
3. Record the commit and tree hash in your application.
4. Require the public packages under `src`.

## Build and update a scene

Read [examples/quickstart.luau](../examples/quickstart.luau).
The example uses a test host, so it needs no engine.

1. Create a test scene with `TestScene.create()`.
2. Create a runtime with `Compose.createRuntime(test.adapter)`.
3. Set `local Host = runtime.constructors`.
4. Create a cell with `Compose.cell(0)`.
5. Mount the component with `runtime.mount(component, test.root)`.
6. Change the cell with `count:set(3)`.
7. Run pending updates with `runtime:settle()`.
8. Read the label with `test.propertyOf(root, "Label")`.
9. Call the returned `dispose()` function.

The label must read `clicked 3 times` before disposal.
Disposal releases the node, its binding and its owned resources once, newest first.

Run the example check:

```bash
lute run tools/gate.luau --file tests/examples/examples.verify.luau
```

This command runs all examples. The quickstart case checks the label value.

## Choose a root operation

| Component result | Operation |
| --- | --- |
| One node | `runtime.mount(component, target)` |
| Sibling nodes or a structural directive | `runtime.mountFragment(fragment, target)` |

A structural directive changes a child slot. Examples include `show`, `keyed` and `OrderedCollection`.
`mount` requires one node. Use `mountFragment` for a directive at the root.

Composition calls use a dot: `runtime.mount`, `runtime.mountFragment`, `runtime.create` and `runtime.decorate`.
Runtime controls use a colon: `runtime:batch` and `runtime:settle`.
Cells also use a colon: `count:set(3)`, `count:update(change)` and `count:peek()`.

## Bind state

A cell holds a value. A formula calculates a value from other state.
A reactive function receives `use`. Each `use(value)` call records a dependency.
A change to that dependency updates the property. It does not rebuild the scene.

- Pass a readable directly to bind it: `Label = count`.
- Use a function to transform it: `Label = function(use) return tostring(use(count)) end`.
- Use `count:peek()` for a read that must not record a dependency.

Keep state for one component inside that component.
A cell at module scope shares its state with all users of the module.
Pass a readable to a child that must react to changes.
Pass a plain value to a child that must keep a fixed value.

## Use Roblox

Require `src/roblox` from the copy in your application.
Create the runtime with `ComposeRoblox.createRuntime()`.
Use `runtime.constructors` to build Roblox classes.

```luau
local Compose = require(ReplicatedStorage.compose.core)
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)
local runtime = ComposeRoblox.createRuntime()
local Host = runtime.constructors
local progress = Compose.cell(100)

local dispose = runtime.mount(function()
    return Host.Frame {
        Size = function(use)
            return UDim2.new(use(progress) / 100, 0, 0, 8)
        end,
        BackgroundColor3 = Color3.fromRGB(200, 40, 40),
    }
end, playerGui.Overlay)
```

`playerGui.Overlay` is borrowed. Disposal preserves it and removes the content that Compose added.
For a class name held in a variable, use `runtime.create(kind) { ... }`.
The runtime caches each constructor in `runtime.constructors`.
The core module supplies state functions. The runtime supplies host constructors.

A component returns content. It must not create nested mounts or directly parent or destroy nodes.
Before you manage external resources, read [ownership](ownership.md).
For collections, read the [API reference](api.md#structure).
For complete programs, use the [examples](../examples/README.md).

A test host checks scene behavior. It cannot check native rendering, device input or visual quality.
