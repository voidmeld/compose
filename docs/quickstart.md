# Quickstart

This document creates one runtime and one owned component, demonstrating the public entry points;
it does not define application architecture or host implementation.

## The smallest thing that works

```luau
local Compose = require(path.to.compose.core)
local TestHost = require(path.to.compose["test-host"])

local host = TestHost.create()
local runtime = Compose.createRuntime(host.host)

local create = runtime.create
local Panel = create "Panel"

local count = Compose.cell(0)

local dispose, root = runtime.mount(function()
    return Panel {
        Title = "Clicks",
        Label = function(use)
            return "clicked " .. use(count) .. " times"
        end,
    }
end, host.root)

count:set(3)
runtime:settle()

host.propertyOf(root, "Label")   --> "clicked 3 times"

dispose()
```

Host composition functions use a dot: `runtime.mount(...)`, `runtime.mountFragment(...)`,
`runtime.create(...)`, and `runtime.decorate(...)`. Runtime controls and reactive values are
objects: use `runtime:batch(...)`, `runtime:settle()`, `count:set(3)`, and `count:peek()`.

Choose the root operation from what the builder returns:

| Builder result | Root operation |
| --- | --- |
| exactly one node | `runtime.mount(component, target)` |
| sibling nodes or a structural directive such as `show`, `keyed`, or `OrderedCollection` | `runtime.mountFragment(fragment, target)` |

Do not return a directive from `runtime.mount`; directives occupy child slots, while `mount`
requires one node.

Six things happened:

- **`create "Panel"` names a constructor.** Name the constructors a file uses once, at its top.
- **A cell is an object.** `count:peek()` reads, `count:set(v)` writes, and `count:update(fn)` writes
  from the previous value.
- **`Label` is a function, so it binds.** Changing `count` writes that property; it does not rerender
  or diff the whole tree. `Label = count` is the direct-binding form.
- **`use` makes a tracked dependency visible.** An intentional untracked read is `count:peek()`.
- **`runtime:settle()` drains that runtime's queue.** Scheduling belongs to the runtime, so separate
  runtimes cannot interleave each other's work.
- **`dispose()` releases the node, binding, and every owned resource**, newest first and exactly once.

## On Roblox

```luau
local Compose = require(ReplicatedStorage.compose.core)
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)

local runtime = ComposeRoblox.createRuntime()

local create = runtime.create
local Frame = create "Frame"

local health = Compose.cell(100)

local function HealthBar(value)
    return Frame {
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

`playerGui.Hud` is borrowed. Compose removes what it added when `dispose()` runs and leaves the
borrowed root standing. Read [`ownership.md`](ownership.md) before adopting or decorating an object
Compose did not create.

## Components

A component is a function that returns composition. It does not register, mount, parent, destroy,
or retain a nested mount disposer.

```luau
local function Row(label: string, selected: Compose.Readable<boolean>)
    return Frame {
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

Reproduce the failed component with the same ownership root, mounted host, style inputs, and viewport
as the consumer. Assert final composed geometry and hit targets, including safe-area offsets and
reactive resize, rather than a copied layout formula. Run the smallest lifecycle and failure case
that could refute the change, then the contributor gate. A passing host emulator does not establish
engine rendering, touch input, or visual quality; the consumer replays its actual scenario after repinning.
