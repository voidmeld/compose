# Quickstart

This guide creates one runtime and one owned component through the public API.
The runnable file is [examples/quickstart.luau](../examples/quickstart.luau). The [README](../README.md#getting-started) quotes it.
Your application defines its architecture and supplies the host implementation.

`Host` names the primitive constructors that a component uses. A host adapter implements the node operations for the runtime.
`TestScene` supplies a fake scene, its `adapter` and inspection helpers for tests.

## Build and update a scene

Read [examples/quickstart.luau](../examples/quickstart.luau). It does these steps:

1. It creates a test scene and a runtime: `Compose.createRuntime(test.adapter)`.
2. It binds `local Host = runtime.constructors`.
3. It creates a cell with `Compose.cell(0)`.
4. It mounts a component with `runtime.mount(component, test.root)`. The component returns one `Host.Panel`.
5. It changes the cell with `count:set(3)` and drains the queue with `runtime:settle()`.
6. It reads the property with `test.propertyOf(root, "Label")` and gets `clicked 3 times`.
7. It disposes the mount.

Host composition functions use a dot: `runtime.mount(...)`, `runtime.mountFragment(...)`, `runtime.create(kind)` and `runtime.decorate(...)`.
Runtime controls and reactive values are objects: use `runtime:batch(...)`, `runtime:settle()`, `count:set(3)` and `count:peek()`.

Choose the root operation from the result of the builder:

| Builder result | Root operation |
| --- | --- |
| exactly one node | `runtime.mount(component, target)` |
| sibling nodes or a structural directive such as `show`, `keyed` or `OrderedCollection` | `runtime.mountFragment(fragment, target)` |

Do not return a directive from `runtime.mount`. Directives occupy child slots. `mount` requires one node.

These rules apply to the example:

- **`Host.Panel` selects a constructor.** `runtime.constructors` lazily caches the constructor of each host kind and binds it to that runtime.
- **A cell is an object.** `count:peek()` reads. `count:set(v)` writes. `count:update(fn)` writes from the previous value.
- **`Label` is a reactive function.** A change to `count` updates that property. It does not rebuild or compare the whole tree. To bind the value directly, use `Label = count`.
- **`use` makes a tracked dependency visible.** For an intentional untracked read, use `count:peek()`.
- **`runtime:settle()` drains the queue of that runtime.** Scheduling belongs to the runtime, so separate runtimes cannot interleave their work.
- **`dispose()` releases the node, the binding and every owned resource**, newest first and exactly once.

## On Roblox

```luau
local Compose = require(ReplicatedStorage.compose.core)
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)

local runtime = ComposeRoblox.createRuntime()

local Host = runtime.constructors

local progress = Compose.cell(100)

local function ProgressBar(value)
    return Host.Frame {
        Size = function(use)
            return UDim2.new(use(value) / 100, 0, 0, 8)
        end,
        BackgroundColor3 = Color3.fromRGB(200, 40, 40),
    }
end

local dispose = runtime.mount(function()
    return ProgressBar(progress)
end, playerGui.Overlay)
```

`playerGui.Overlay` is borrowed. When `dispose()` runs, Compose removes what it added and keeps the borrowed root.
Before you adopt or decorate an object that Compose did not create, read [`ownership.md`](ownership.md).

For a dynamic host kind, use `runtime.create(kind) { ... }`.
The core `Compose` module supplies reactive helpers. Host constructors come from the `constructors` table of the runtime.
An application can export that table as its own `Compose` module. Then `Compose.Text { ... }` is a runtime-bound constructor call where the host supports `Text`.
If you use both modules, keep the core module under a separate name, such as `ComposeCore`.

## Components

A component is a function that returns composition. It does not register itself and does not manage node lifetimes directly.
Do not create nested mounts, parent or destroy nodes, or keep nested mount disposers inside a component.

```luau
local function Row(label: string, selected: Compose.Readable<boolean>)
    return Host.TextLabel {
        Text = label,
        BackgroundTransparency = function(use)
            return if use(selected) then 0 else 1
        end,
    }
end
```

Pass a readable when the child must react. Pass a value when it must not.
Keep per-instance state inside the component. A module-scope cell is deliberately shared state.

For collections and structural directives, use the [`api.md`](api.md) reference.
Before you manage external resources, read [`ownership.md`](ownership.md).

## Verify the result

For focused checks and integration, use the [consumer skill](../.agents/skills/compose/SKILL.md).
A passing test host proves scene behavior. It does not prove native rendering, touch input or visual quality.
