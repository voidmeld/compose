# The Roblox adapter

The adapter connects a Compose runtime to Roblox Instances.
Core uses the host protocol and has no engine dependency.
The [API reference](api.md#srcroblox) gives public calls.

```luau
local Compose = require(ReplicatedStorage.compose.core)
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)

local runtime = ComposeRoblox.createRuntime()
local Host = runtime.constructors

local dispose = runtime.mount(Overlay, playerGui)
```
Native engine access belongs in `src/roblox`.
Core must not name engine objects, services or datatypes.
[The boundary check](../tools/check-boundary.luau) enforces this rule.

## Ownership

Use the [ownership guide](ownership.md) to decide whether to create, adopt or borrow an Instance.
The Roblox adapter follows the same lifetime rules as other hosts.

## Events are discovered, not declared

```luau
Host.TextButton {
    Text = "Press",
    Activated = function() ... end,   -- subscribes
}
```
The adapter reads a member to determine whether it supports event connections.
Use explicit keys when that distinction matters:

```luau
[Compose.event("Activated")] = handler          -- always an event
[Compose.property("Changed")] = binding         -- always a property
```
An invalid event name raises `host/not-an-event` with the class name and key.

## Sibling order

Roblox has no child-order operation.
`Instance.Parent` appends a child. `GetChildren` reports insertion order.
The adapter's `insertChild` parents the node and omits `moveChild`.
This omission declares the host's limitation in the [host protocol](host-protocol.md#hosts-that-cannot-order-children).
The adapter does not reparent later siblings to simulate insertion.
That operation would rebuild render state without supplying the engine's layout order.

```luau
keyed {
    from = rows,
    key = idOf,
    render = function(row, index)
        return Frame { LayoutOrder = index }
    end,
}
```
Use `LayoutOrder` with `UIListLayout` and `UIGridLayout`.
Use `ZIndex` for overlap order.
Keyed and indexed collections provide a reactive index for these properties.

## Clearing a property

Compose resets borrowed properties to sampled class defaults.
For the first reset of property `P` on class `C`, it creates one temporary `C`.
It reads `P`, caches that value and destroys the temporary instance.
Later resets write the cached value.
The cost is one extra Instance for each class/property pair during the process lifetime.
This restores the class default, not the object's previous value.
Compose destroys owned nodes instead of resetting their properties.

## Attributes

The [Attributes property](api.md#attributes) writes each entry through `Instance:SetAttribute`.
A nil value clears the attribute.
`SetAttribute` raises for invalid names and unsupported datatypes.
The adapter converts this error into `false` and the engine's reason.
Compose reports `props/attribute-value` with the node, attribute and reason.

The engine determines valid names and datatypes.
The simulation rejects empty names, names longer than 100 characters and names that start with `RBX`.
Names can contain only letters, digits and underscores.
It rejects table, function and buffer values.
The basic `TestScene` accepts only strings, numbers, booleans and nil, without name checks.
Use [native checks](../verification/roblox/README.md) for the engine's exact attribute datatype rules.

## Cleanup

Use [ComposeRoblox.cleanup](api.md#composerobloxcleanup) for connections, threads and Instances.
An Instance argument transfers responsibility for its destruction to the active owner.

## What is animatable

Compose animates `number`, `Vector2`, `Vector3`, `Color3`, `UDim`, `UDim2` and `CFrame`.
`ComposeRoblox.animatableTypes()` lists the running engine's supported types.

`CFrame` represents rotation as a quaternion.
Compose normalizes it before decoding and matches its sign to the current animation leg.
This prevents a small turn from taking the longer rotation path.
The interpolation is componentwise with normalization. It is not slerp.
For constant angular speed, animate an angle and construct the `CFrame` from it.

These shapes have no Compose animation codec:

- Enums: use `show` or `switch` for discrete values.
- `NumberSequence` and `ColorSequence`: different keypoint counts need application decisions.
- Skeletal animation: use the engine's `Animator`.

## How the adapter is verified

[`src/roblox/engine.luau`](../src/roblox/engine.luau) defines an injected engine table.
It provides instance construction, frame signals, `typeof` and datatype constructors.
Tests can run the real adapter without Roblox.
[The Roblox tests](../tests/roblox) connect it through [`src/test-scene/roblox.luau`](../src/test-scene/roblox.luau).
They check event classification, default sampling, connection release and frame animation.

## The simulated engine

[Verify](https://github.com/voidmeld/verify/blob/main/docs/api.md) provides Instances, classes, signals, virtual time and disposal counts.
Use it for components that access Instance properties or methods through refs.
The basic test host's opaque nodes cannot support those operations.
Follow the [emulator setup](api.md#robloxemulatorcreate) to create the environment and runtime.

`emulator.adapter` uses `ComposeRoblox.createHost(emulator.engine)`.
`emulator.render` adds operation logging and failure injection to that adapter.
It has no `moveChild`, just like the native adapter.
The [emulator example](../examples/roblox-emulator.luau) runs an Instance-based component without Roblox.

### What the simulation cannot check

`RobloxEmulator.create` uses the supplied environment.
The default `Verify.testEnvironment()` has a small class set and no property validation.
`Verify.reflection.create` adds classes, defaults and property types from its reflection database.
The engine remains the authority.

| Area | Limit |
| --- | --- |
| Property validation | The default environment accepts incorrect property datatypes. A reflected environment rejects wrong types and writes to read-only properties. |
| Classes | The default supports built-in instance, folder, model, part, GUI, Humanoid and animation classes. Use `defineClass` to add classes. Reflection supports only its database classes. |
| Methods | `WaitForChild` is absent. The environment models `Destroy`, `Clone`, `Archivable`, `FindFirst` methods and `IsA`. |
| Destruction | It locks the destroyed node's parent, destroys descendants and disconnects signals. |
| Signals | Property, attribute, child, destruction, descendant and ancestry signals run immediately. Native signals can run later. |
| Layout | There is no native layout engine to prove `LayoutOrder` behavior. |
| Services | Physics, replication, streaming and services are absent. Nodes carry tags, but there is no `CollectionService`. |
| Enums | The simulation accepts enum shapes without native values. |
| Animation | Tracks record play, stop and speed calls. They do not advance, blend or fire markers, and have no `Length`. |
| Frames | `step(delta)` drives a manual clock. It does not model variable native frame timing. |
| Memory | Simulated disposal does not prove native collection after disposal. |
| Attributes | Rejected names and types do not prove the engine's exact accepted datatype set. |
| Node types | Simulated nodes are tables. Native nodes are userdata. The engine interface reports `Instance` for both. |

The simulation models `GetPropertyChangedSignal`, `Changed`, `AttributeChanged`, `ChildAdded` and `ChildRemoved`.
It also models `Destroying`, `DescendantAdded`, `DescendantRemoving` and `AncestryChanged`.

### Engine checks

Core uses `type` for reference values. Engine-specific `typeof` stays at the host boundary.
Simulation cannot prove native classification, defaults, layout, frame timing or rendering.
Use the [engine verification guide](../verification/roblox/README.md) to run those checks.
Keep source identity and runtime evidence outside the active source tree.
The CPU gate does not claim an engine run.

## Deploying

`default.project.json` maps `core`, `roblox`, `design` and `design-editor` into a `compose` folder.
It excludes the test host from the production artifact.

```bash
rojo serve default.project.json
```
Compose uses string requires such as `require("./sibling")` and `require("@self/child")`.
It requires no aliases or fixed DataModel position.
