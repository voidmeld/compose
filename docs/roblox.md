# The Roblox adapter

This adapter connects a Compose runtime to Roblox Instances. Core remains host-neutral.
For composition behavior, use the core API reference.

```luau
local Compose = require(ReplicatedStorage.compose.core)
local ComposeRoblox = require(ReplicatedStorage.compose.roblox)

local runtime = ComposeRoblox.createRuntime()
local Host = runtime.constructors

local dispose = runtime.mount(Overlay, playerGui)
```

Everything that Compose knows about Roblox lives in `src/roblox`.
`src/core` never names an engine object, a service or a datatype. `tools/check-boundary.luau` fails the gate if it starts to.

## Ownership

To decide whether a scene creates, adopts or borrows an Instance, use [ownership](ownership.md).
The adapter follows the same lifetime rules as every Compose host.

## Events are discovered, not declared

```luau
Host.TextButton {
    Text = "Press",
    Activated = function() ... end,   -- subscribes
}
```

The adapter reads the member and finds something that it can connect to.
When the difference matters, be explicit:

```luau
[Compose.event("Activated")] = handler          -- always an event
[Compose.property("Changed")] = binding         -- always a property
```

An event key that names something that does not exist raises `host/not-an-event` with the class name and the key.

## Sibling order

**Roblox has no child-ordering API.** `Instance.Parent` appends, `GetChildren` returns insertion order and nothing reorders.
The adapter `insertChild` therefore parents the node. The adapter **omits `moveChild` entirely**.
Omission is how the host protocol declares that a host cannot order children.
See [`host-protocol.md`](host-protocol.md#hosts-that-cannot-order-children).

The adapter does not reparent later siblings to simulate insertion.
That would rebuild their render state and would not give the layout order that the engine uses.

Roblox reads order from properties, so use properties:

```luau
keyed {
    from = rows,
    key = idOf,
    render = function(row, index)
        return Frame { LayoutOrder = index }
    end,
}
```

Use `LayoutOrder` for `UIListLayout` and `UIGridLayout`. Use `ZIndex` for overlap.
The keyed and indexed collections of Compose give `render` a reactive index for exactly this purpose.

## Clearing a property

Roblox has no verb that resets a property.
The first time that Compose must clear property `P` on class `C`, it builds one throwaway `C`, reads `P`, caches the value and destroys the throwaway.
Clearing then writes that default.
The cost is one extra Instance for each pair of class and property, for the lifetime of the process.

This path applies only to properties that Compose wrote on a **borrowed** object.
It restores class defaults, not the previous property values of the object.
Compose destroys owned objects. It does not clear their properties.

## Attributes

`Attributes = { ... }` on a node writes each entry with `Instance:SetAttribute`. A nil value clears the attribute.
For the prop itself, see [`api.md`](api.md#attributes).

`SetAttribute` **raises** for a name that the engine does not accept and for a datatype that it cannot serialize.
The adapter turns that raise into the reported `false` and reason that the host protocol asks for.
The refusal therefore arrives as `props/attribute-value`, with the node, the attribute and the engine message.
It does not arrive as a raw engine error from inside a watch.

The attribute store of the engine accepts fewer types than its property system, and the engine defines the valid attribute names.
The simulated engine refuses a name that is empty, that holds a character other than a letter, a digit or an underscore, that begins with `RBX` or that exceeds 100 characters.
It refuses a table, a function and a buffer. `TestScene` stores only a string, a number, a boolean and `nil`, and it checks no names.
To verify the exact set of attribute datatypes, use [native checks](../verification/roblox/README.md).

## Cleanup

To register connection, thread or Instance cleanup with the active owner, use [ComposeRoblox.cleanup](api.md#composerobloxcleanup).
If you pass an Instance, you transfer the responsibility to destroy it.

## What is animatable

Compose animates `number`, `Vector2`, `Vector3`, `Color3`, `UDim`, `UDim2` and `CFrame`.
`ComposeRoblox.animatableTypes()` lists what the running engine supports.

`CFrame` carries rotation as a quaternion. Compose renormalizes it before decoding and matches its sign to the current leg, so that a small turn never takes the long way round.
Componentwise interpolation followed by renormalization is **not** slerp. The angular rate varies across the arc.
If you need constant angular speed, animate an angle and construct the `CFrame` from it.

Three shapes are deliberately absent:

- Enums, which are not continuous. Use `show` or `switch`.
- `NumberSequence` and `ColorSequence`. Their keypoint counts can differ, so the halfway point is a design decision.
- Skeletal animation, which belongs to the engine `Animator`.

## How the adapter is verified

The adapter receives an **injected engine table**, defined in `src/roblox/engine.luau`.
It provides `Instance.new`, Heartbeat, `typeof` and the datatype constructors. Tests can therefore execute the actual adapter outside the engine.

[`tests/roblox/`](../tests/roblox) runs the adapter against [`src/test-scene/roblox.luau`](../src/test-scene/roblox.luau).
That file connects the simulated engine of Verify to the adapter. See [the simulated engine](#the-simulated-engine).
The actual adapter branches execute there. They include these branches:

- the probe that decides whether a key is an event or a property
- the default sampling behind `clearProperty`
- connection release
- animation on the frame loop

## The simulated engine

[Verify](https://github.com/voidmeld/verify/blob/main/docs/api.md) owns the simulated Roblox engine: Instances, classes, signals, virtual time and disposal accounting.
Use it when a component reads Instance properties or calls methods through a ref, for example `instance:SetAttribute(...)` or `instance.Parent`.
The opaque nodes in `src/test-scene` cannot support those operations.

To create the environment and the runtime, follow [the emulator setup](api.md#robloxemulatorcreate).

`emulator.adapter` is `ComposeRoblox.createHost(emulator.engine)`.
`emulator.render` is the renderer of that adapter. Compose wraps it only to log operations and inject failures.
The tests use the real adapter rules. `moveChild` is absent here because it is absent there.
[The runnable example](../examples/roblox-emulator.luau) shows a component that uses Instance methods.

### What the simulation cannot check

`RobloxEmulator.create` uses the environment that you pass. The default environment, `Verify.testEnvironment()`, has a small set of built-in classes and no property validation.
An environment that `Verify.reflection.create` builds from a reflection database adds every class of the database, its defaults and its property types.

- **Property validation with the default environment.** It accepts a string that you write to a `Color3` property. The reflection environment rejects a wrong datatype and a write to a read-only property. The engine remains the authority.
- **Classes outside the environment.** The default environment knows the built-in classes (instances, folders, models, parts, GUI objects, `Humanoid` and the animation classes). It takes more through `defineClass`. A reflection environment knows the classes of its database only.
- **`WaitForChild`.** The environment does not provide it. It models `Destroy` (the destroyed instance locks its parent, destroys its descendants and disconnects its signals), `Clone`, `Archivable`, the `FindFirst` family and `IsA`.
- **Signal timing.** The environment models `GetPropertyChangedSignal`, `Changed`, `AttributeChanged`, `ChildAdded`, `ChildRemoved`, `Destroying`, `DescendantAdded`, `DescendantRemoving` and `AncestryChanged`. It dispatches each signal immediately. The engine can defer a signal and show different callback timing.
- **Layout.** The environment has no layout engine. No test there can show `LayoutOrder` reordering a `UIListLayout`.
- **Physics, replication, streaming and services.** None of them exist here. Instances carry tags, but the `CollectionService` service does not exist. `Enum` is permissive and carries no engine values.
- **Animation.** A track records that something told it to play, stop or change speed. Nothing advances, blends, weights or fires markers, and no track has a `Length`.
- **Real `Heartbeat` timing** under a variable frame rate. `step(delta)` is a manual clock.
- **Memory that a real collector releases after disposal.**
- **Attribute datatypes.** The environment refuses a short list of types and a set of invalid names. It does not prove the exact set that the engine accepts.
- **`typeof`.** Environment nodes are Lua tables with a metatable. Engine nodes are userdata that `typeof` identifies as `Instance`. The engine seam reports `"Instance"` for both, and that seam is the only thing that Compose may ask. Native checks must verify the engine classification.

### Engine checks

Core uses the language `type` primitive for reference values. The engine-specific `typeof` belongs at the host boundary.
A passing emulated host cannot establish native Instance classification, class defaults, layout, Heartbeat or rendering behavior.

[The engine verification guide](../verification/roblox/README.md) builds the local plugin or the module-preserving Rojo check project.
Record the exact source and runtime observations outside this source tree. The CPU gate does not claim that these checks ran.

## Deploying

`default.project.json` maps `src/core` and `src/roblox` into a `compose` folder.
It excludes `src/test-scene`, which keeps the test adapter out of the production artifact.

```bash
rojo serve default.project.json
```

Compose uses string requires throughout, written as `require("./sibling")` and `require("@self/child")`.
It needs no aliases and no particular position in the DataModel.
