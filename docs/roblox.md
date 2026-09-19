# The Roblox adapter

This adapter connects a Compose runtime to Roblox instances. Core remains host-neutral.
Use the core API reference for composition behavior.

```luau
local Compose = require(ReplicatedStorage.compose.core)
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)

local runtime = ComposeRoblox.createRuntime()
local Host = runtime.constructors

local dispose = runtime.mount(Hud, playerGui)
```

Everything Compose knows about Roblox lives in `src/roblox`. `compose-core` never names an engine
object, a service, or a datatype, and `tools/check-boundary.luau` fails the gate if it starts to.

## What it owns and what it does not

Compose destroys instances it creates or explicitly adopts. It preserves borrowed instances, including external mount targets, characters, services and shared layers.
It can decorate and subscribe to borrowed instances without taking ownership. Read [`ownership.md`](ownership.md) before choosing custody.

## Events are discovered, not declared

```luau
Host.TextButton {
    Text = "Press",
    Activated = function() ... end,   -- subscribes
}
```

The adapter reads the member and finds something it can connect to. Be explicit when the difference
matters.

```luau
[Compose.event("Activated")] = handler          -- always an event
[Compose.property("Changed")] = binding         -- always a property
```

An event key naming something that does not exist raises `host/not-an-event` with the class name and
the key.

## Sibling order

**Roblox has no child-ordering API.** `Instance.Parent` appends, `GetChildren` returns insertion
order, and nothing reorders. The adapter `insertChild` therefore parents, and the adapter **omits
`moveChild` entirely**. Omission is how the host protocol declares that a host cannot order
children. See [`host-protocol.md`](host-protocol.md#hosts-that-cannot-order-children).

The adapter does not reparent later siblings to simulate insertion. That would rebuild their render state without providing the layout order the engine uses.

Without `moveChild`, keyed collections skip node arrangement as well as host moves.
They do not compute a longest increasing subsequence or maintain a live position map.
They still update properties and row indices. Measure costs with the [benchmark procedure](benchmarks.md).

Roblox reads order from properties, and so should you.

```luau
keyed {
    from = rows,
    key = idOf,
    render = function(row, index)
        return Frame { LayoutOrder = index }
    end,
}
```

Use `LayoutOrder` for `UIListLayout` and `UIGridLayout`, and use `ZIndex` for overlap. The keyed and
indexed collections of Compose hand `render` a reactive index for exactly this.

Roblox layout does not use Compose's host-move order. Keyed collections still preserve existing rows and their state.
Hosts with child-ordering support also benefit from fewer moves.

## Clearing a property

Roblox has no verb that resets a property. The first time Compose needs to clear property `P` on
class `C`, it builds one throwaway `C`, reads `P`, caches the value, and destroys the throwaway.
Clearing then writes that default. The cost is one extra Instance per class and property pair, for
the lifetime of the process.

This path applies only to properties Compose wrote on a **borrowed** object. It restores class defaults, not the object's previous property values.
Compose destroys owned objects instead of clearing their properties.

## Attributes

`Attributes = { ... }` on a node writes each entry with `Instance:SetAttribute`, and a nil value
clears the attribute. See [`api.md`](api.md#attributes) for the prop itself.

`SetAttribute` **raises** on a name the engine will not accept and on a datatype it cannot
serialise. The adapter turns that raise into the reported `false` and reason the host protocol asks
for. The refusal therefore arrives as `props/attribute-value`, naming the node, the attribute, and
the engine message, rather than as a raw engine error from inside a watch.

The engine's attribute store accepts fewer types than its property system. It does not accept Instances or `Enum` values.
The engine also defines valid attribute names. The emulator approximates these rules.
Use [native checks](../verification/roblox/README.md) to verify actual engine behavior.

## Cleanup

```luau
ComposeRoblox.cleanup(connection)   -- disconnected
ComposeRoblox.cleanup(thread)       -- cancelled
ComposeRoblox.cleanup(instance)     -- destroyed
```

Passing an Instance is an ownership statement. For something you did not create, `runtime.adopt`
says it more clearly. For something you must not destroy, say nothing.

## What is animatable

Compose animates `number`, `Vector2`, `Vector3`, `Color3`, `UDim`, `UDim2`, and `CFrame`.
`ComposeRoblox.animatableTypes()` lists what the running engine actually supports.

`CFrame` carries rotation as a quaternion, renormalised before decoding, with its sign matched to
the current leg so a small turn never takes the long way round. Componentwise interpolation followed
by renormalisation is **not** slerp. The angular rate varies across the arc.
If constant angular speed is required, animate an angle and construct the `CFrame` from it.

Three shapes are deliberately absent:

- Enums, which are not continuous. Use `show` or `switch`.
- `NumberSequence` and `ColorSequence`, whose keypoint counts can differ, which makes halfway a
  design decision.
- Skeletal animation, which belongs to the engine `Animator`.

## How the adapter is verified

The adapter receives an **injected engine table**, defined in `src/roblox/engine.luau`.
It provides `Instance.new`, Heartbeat, `typeof` and datatype constructors. Tests can therefore execute the actual adapter outside the engine.

[`tests/roblox/`](../tests/roblox) runs the adapter against
[`src/test-scene/roblox.luau`](../src/test-scene/roblox.luau), a headless emulation of Instances,
per-class property defaults, `RBXScriptSignal`, `GetPropertyChangedSignal`, and Heartbeat. The
actual adapter branches execute there. Those branches include the probe that decides an event from a
property, the default-sampling behind `clearProperty`, connection release, and animation on the
frame loop.

## The emulator

The emulator is a public test module. Use it when a component reads Instance properties or calls methods through a ref.
For example, the component might call `instance:SetAttribute(...)` or read `instance.Parent`.
The opaque nodes in `src/test-scene` cannot support those operations; they enforce the core protocol boundary instead.

```luau
local RobloxEmulator = require(script.Parent.Parent["test-scene"].roblox)

local emulator = RobloxEmulator.create()
local runtime = Compose.createRuntime(emulator.adapter)
```

`emulator.adapter` is `ComposeRoblox.createHost(emulator.engine)`. `emulator.render` is the renderer of
that adapter, wrapped only to log operations and inject failures. The emulator uses the real adapter rules. `moveChild` is absent
here because it is absent there.

`default.project.json` mounts `src/core` and `src/roblox` into the place. It excludes `src/test-scene`.
This keeps the emulator out of the production artifact.

Emulator nodes have dot-accessible properties with per-class defaults and an inheritance chain for
`IsA`. They carry `:Destroy`, `:GetChildren`, `:GetDescendants`, `:FindFirstChild`,
`:FindFirstChildOfClass`, `:IsDescendantOf`, `:IsAncestorOf`, `:SetAttribute`, `:GetAttribute`,
`:GetAttributes`, `:GetPropertyChangedSignal`, and `:GetAttributeChangedSignal`. They also carry the
`ChildAdded`, `ChildRemoved`, and `Destroying` signals, plus the events of each class. `defineClass`
adds a class the fixture does not ship. Skeletal animation goes as far as `Animator:LoadAnimation`
returning an `AnimationTrack` that records `Play`, `Stop`, and `AdjustSpeed`. The full surface is in
[`api.md`](api.md#robloxemulatorcreate), and
[`../examples/roblox-emulator.luau`](../examples/roblox-emulator.luau) is a runnable program.

### What the emulator cannot check

- **Property type coercion and validation.** The engine rejects a string written to a `Color3`, and
  the emulator accepts it.
- **`Instance.new` for classes the emulator does not know.** It ships a small set and takes more
  through `defineClass`. The engine knows every class and their real defaults.
- **Real `Destroy` semantics**, including locked instances. `Clone`, `Archivable`, and
  `WaitForChild` are absent entirely.
- **The wider signal set.** The emulator models `GetPropertyChangedSignal` and does not model
  `AncestryChanged`, `DescendantAdded`, `DescendantRemoving`, or the generic `Changed`.
- **Layout.** There is no layout engine, so no test there can show `LayoutOrder` reordering a
  `UIListLayout`.
- **Physics, replication, streaming, `Enum` values, services, and `CollectionService` tags.** None
  of them exist here.
- **Animation.** A track records that something told it to play. Nothing advances, blends, weights,
  fires markers, or has a real `Length`.
- **Real `Heartbeat` timing** under a variable frame rate. `step(delta)` is a manual clock.
- **Memory released after disposal**, under a real collector.
- **What an attribute may hold.** The emulator stores scalars and rejects everything else. The
  engine has a wider set of attribute datatypes and its own rules for attribute names, and the
  emulator models neither.
- **`typeof`.** Emulator nodes are Lua tables, and engine nodes are userdata that `typeof` names by
  class. The engine seam reports `"Instance"` for both, and that seam is the only thing Compose may
  ask. Native checks must verify engine classification.

### Engine checks

Core uses the language `type` primitive for reference values; engine-specific `typeof` belongs
at the host boundary. A passing emulated host cannot establish native Instance classification,
class defaults, layout, Heartbeat or rendering behavior.

[The engine verification guide](../verification/roblox/README.md) builds the local plugin or
module-preserving Rojo check project. Record exact source and runtime observations outside this
source tree. The CPU gate does not claim these checks ran.

## Deploying it

`default.project.json` maps `src/core` and `src/roblox` into a `compose` folder.

```bash
rojo serve default.project.json
```

Compose uses string requires throughout, written as `require("./sibling")` and
`require("@self/child")`, so it needs no aliases and no particular position in the DataModel.
