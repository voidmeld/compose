# The Roblox adapter

This adapter creates a runtime over Roblox engine instances and binds the host boundary; it does
not make `compose-core` Roblox-specific, and it does not restate the core API.

```luau
local Compose = require(ReplicatedStorage.compose.core)
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)

local runtime = ComposeRoblox.createRuntime()
local create = runtime.create

local dispose = runtime.mount(Hud, playerGui)
```

Everything Compose knows about Roblox lives in `src/roblox`. `compose-core` never names an engine
object, a service, or a datatype, and `tools/check-boundary.luau` fails the gate if it starts to.

## What it owns and what it does not

Compose destroys what it created, and it destroys what you gave it when you say so. It destroys
nothing else, ever. A mount target, a character, a service, and a layer another system manages are
all decorated, subscribed to, added to, and left standing. Read [`ownership.md`](ownership.md)
before assuming which side a particular object sits on.

## Events are discovered, not declared

```luau
TextButton {
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

Compose cannot close that gap. Reparenting the tail to fake an insert would destroy and rebuild the
render state of every sibling after it. That is precisely the cost keyed collections exist to avoid,
and it would buy an order the engine never reads.

Omitting the method rather than supplying an empty one lets a keyed collection skip the
*arrangement* as well as the move. Sorting three thousand rows on Roblox costs the property writes
the sort implies and nothing else. It runs no longest-increasing-subsequence pass, keeps no live
position map, and does no per-row bookkeeping for an order the engine will not read. Measured, that
took a full reversal from 1.22 ms to 295 µs.

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

One consequence is worth stating. The minimal-move reordering of Compose, which rotates a list of
two hundred with one host move, has **no visible effect on Roblox**, because the engine does not
read sibling order. What it still buys you on Roblox is that rows are not recreated, and that is the
part which matters everywhere. Move minimisation serves hosts that do order.

## Clearing a property

Roblox has no verb that resets a property. The first time Compose needs to clear property `P` on
class `C`, it builds one throwaway `C`, reads `P`, caches the value, and destroys the throwaway.
Clearing then writes that default. The cost is one extra Instance per class and property pair, for
the lifetime of the process.

This path runs only for properties Compose wrote onto a **borrowed** object, meaning something it
was handed and must give back as it found it. Compose destroys the objects it created instead, and
they never take this path.

## Attributes

`Attributes = { ... }` on a node writes each entry with `Instance:SetAttribute`, and a nil value
clears the attribute. See [`api.md`](api.md#attributes) for the prop itself.

`SetAttribute` **raises** on a name the engine will not accept and on a datatype it cannot
serialise. The adapter turns that raise into the reported `false` and reason the host protocol asks
for. The refusal therefore arrives as `props/attribute-value`, naming the node, the attribute, and
the engine message, rather than as a raw engine error from inside a watch.

The engine attribute store is narrower than its property set, holding no Instances and no `Enum`
values, and its rules for names are its own. The emulator approximates those rules, and only the
engine decides. See [`benchmarks.md`](benchmarks.md) `CLM-HOST-003`, which has no witness yet.

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
by renormalisation is **not** slerp, because the angular rate is not constant across the arc. For
UI, camera easing, and prop motion the difference is not visible. For something that must sweep at a
constant angular rate, animate an angle and build the `CFrame` from it.

Three shapes are deliberately absent:

- Enums, which are not continuous. Use `show` or `switch`.
- `NumberSequence` and `ColorSequence`, whose keypoint counts can differ, which makes halfway a
  design decision.
- Skeletal animation, which belongs to the engine `Animator`.

## How the adapter is verified

The engine is an **injectable table**, named once in `src/roblox/engine.luau`. It holds
`Instance.new`, Heartbeat, `typeof`, and the datatype constructors. That seam lets the real adapter
code be tested off-platform rather than only shipped.

[`tests/roblox/`](../tests/roblox) runs the adapter against
[`src/test-host/roblox.luau`](../src/test-host/roblox.luau), a headless emulation of Instances,
per-class property defaults, `RBXScriptSignal`, `GetPropertyChangedSignal`, and Heartbeat. The
actual adapter branches execute there. Those branches include the probe that decides an event from a
property, the default-sampling behind `clearProperty`, connection release, and animation on the
frame loop.

## The emulator

The emulator is a **shipped module** rather than a private fixture, because the problem it solves is
not the problem of Compose alone. `src/test-host` gives opaque nodes as frozen empty tables. That
opacity stops core from reaching around the protocol, and it is exactly wrong for testing a
component whose production code holds a ref and calls `instance:SetAttribute(...)` or reads
`instance.Parent`. Without an Instance-shaped double, every consumer hand-rolls one, and those
doubles disagree with each other and with the adapter.

```luau
local RobloxEmulator = require(script.Parent.Parent["test-host"].roblox)

local emulator = RobloxEmulator.create()
local runtime = Compose.createRuntime(emulator.host)
```

`emulator.host` is `ComposeRoblox.createHost(emulator.engine)`. `emulator.render` is the renderer of
that adapter, wrapped only to log operations and inject failures. Nothing here restates the adapter
rules, so emulator behaviour tracks the adapter rather than drifting from it. `moveChild` is absent
here because it is absent there.

The emulator lives beside the test host rather than under `src/roblox` for one reason.
`default.project.json` maps `src/core` and `src/roblox` into a place, and `src/test-host` sits
deliberately outside it. A test double must not be able to reach a production artefact.

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
  ask. This gap is not hypothetical. See below.

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
