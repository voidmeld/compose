# Quickstart

This example creates one runtime and one owned component through the public API.
Your application defines its architecture and supplies the host implementation.

`Host` names the primitive constructors a component uses. A host adapter implements node operations
for the runtime. `TestScene` supplies a fake scene, its `adapter`, and inspection helpers for tests.

## The smallest thing that works

```luau
local Compose = require(path.to.compose.core)
local TestScene = require(path.to.compose["test-scene"])

local test = TestScene.create()
local runtime = Compose.createRuntime(test.adapter)

local Host = runtime.constructors

local count = Compose.cell(0)

local dispose, root = runtime.mount(function()
    return Host.Panel {
        Title = "Clicks",
        Label = function(use)
            return "clicked " .. use(count) .. " times"
        end,
    }
end, test.root)

count:set(3)
runtime:settle()

test.propertyOf(root, "Label")   --> "clicked 3 times"

dispose()
```

Host composition functions use a dot: `runtime.mount(...)`, `runtime.mountFragment(...)`,
`runtime.create(kind)`, and `runtime.decorate(...)`. Runtime controls and reactive values are
objects: use `runtime:batch(...)`, `runtime:settle()`, `count:set(3)`, and `count:peek()`.

Choose the root operation from what the builder returns:

| Builder result | Root operation |
| --- | --- |
| exactly one node | `runtime.mount(component, target)` |
| sibling nodes or a structural directive such as `show`, `keyed`, or `OrderedCollection` | `runtime.mountFragment(fragment, target)` |

Do not return a directive from `runtime.mount`. Directives occupy child slots. `mount` requires one node.

Six things happened:

- **`Host.Panel` selects a constructor.** `runtime.constructors` lazily caches each host-kind constructor and binds it to that runtime.
- **A cell is an object.** `count:peek()` reads, `count:set(v)` writes, and `count:update(fn)` writes
  from the previous value.
- **`Label` is a reactive function.** Changing `count` updates that property without rebuilding or comparing the whole tree.
  Use `Label = count` to bind the value directly.
- **`use` makes a tracked dependency visible.** An intentional untracked read is `count:peek()`.
- **`runtime:settle()` drains that runtime's queue.** Scheduling belongs to the runtime, so separate
  runtimes cannot interleave each other's work.
- **`dispose()` releases the node, binding, and every owned resource**, newest first and exactly once.

## On Roblox

```luau
local Compose = require(ReplicatedStorage.compose.core)
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)

local runtime = ComposeRoblox.createRuntime()

local Host = runtime.constructors

local health = Compose.cell(100)

local function HealthBar(value)
    return Host.Frame {
        Size = function(use)
            return UDim2.new(use(value) / 100, 0, 0, 8)
        end,
        BackgroundColor3 = Color3.fromRGB(200, 40, 40),
    }
end

local dispose = runtime.mount(function()
    return HealthBar(health)
end, playerGui.Hud)
```

`playerGui.Hud` is borrowed. When `dispose()` runs, Compose removes what it added and preserves the borrowed root. Read [`ownership.md`](ownership.md) before adopting or decorating an object
Compose did not create.

For a dynamic host kind, use `runtime.create(kind) { ... }`. The core `Compose` module supplies
reactive helpers; host constructors come from this runtime's `constructors` table. An application
may export that table as its own `Compose` module, making `Compose.Text { ... }` a runtime-bound
constructor call where its host supports `Text`. Keep the core module under a separate name such
as `ComposeCore` when both are used.

## Components

A component is a function that returns composition. It does not register itself or manage node lifetimes directly.
Do not create nested mounts, parent or destroy nodes, or retain nested mount disposers inside a component.

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

Pass a readable when the child should react and a value when it should not. Keep per-instance state
inside the component. A module-scope cell is deliberately shared state.

Use the [`api.md`](api.md) reference for collections and structural directives. Read
[`ownership.md`](ownership.md) before managing external resources.

## Closing a consumer repair

Reproduce the failure with the consumer's ownership root, host, style inputs and viewport.
Check the final composed geometry and hit targets, including safe-area offsets and reactive resizing.
A copied layout formula does not check that result.

Run focused lifecycle and failure tests that could detect a defect in the change. Then run the contributor gate.
After updating the dependency pin, replay the consumer's actual scenario.
A passing host emulator does not establish engine rendering, touch input or visual quality.
