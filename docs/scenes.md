# Scenes

Compose does not require every node in a tree to be a node it built. This page covers the three
cases where a scene holds nodes that `runtime.mount` did not create:

- you take over a node the engine already made,
- you build a 3D tree of parts and lights,
- you test either of those with no engine.

Read [`api.md`](api.md) for the full signatures. Read [`ownership.md`](ownership.md) for the
custody rules. This page uses those rules and does not repeat them.

## Decorating what already exists

A mount target, a character or a layer that another system owns arrives already built. Compose did
not make it. Three verbs work with such a node:

```luau
runtime.decorate(node, props)
runtime.adopt(node)
runtime.borrow(node)
```

`decorate` applies properties, attributes and event subscriptions to an existing node. `decorate`
cannot add children. If you pass any entry in the array part of the props table, `decorate` raises
`props/decorate-has-children`. The bindings and the subscriptions belong to the active owner, so
Compose releases them when that owner disposes. Compose does not otherwise touch the node. A
property or an event that the props table does not name keeps its current behaviour. On a borrowed
node, Compose clears every property that `decorate` wrote back to the class default.

```luau
local function CharacterHud(character)
    runtime.decorate(character.Humanoid, {
        WalkSpeed = function(use)
            return if use(sprinting) then 24 else 16
        end,
        [Compose.event("Died")] = onDied,
    })

    return Host.BillboardGui { ... }
end
```

This component did not build `character`, so `character` is borrowed by default. Compose never
destroys a borrowed node. When the component that called `decorate` disposes, Compose releases the
binding and the `Died` connection, and leaves `character.Humanoid.WalkSpeed` at its class default.

`adopt` states the opposite decision. It states that this tree must destroy a node that Compose did
not build.

```luau
local rig = engine.spawnCharacter()

local dispose = runtime.mount(function()
    runtime.adopt(rig)
    return rig
end, playerGui)
```

A node has exactly one owner, so `adopt` refuses a node that Compose already owns. `borrow` is
already the default for every node that Compose has not seen. Call `borrow` in two cases only:
when the explicit statement helps a reader, and when a node passed through code that can adopt it
and its custody must return to borrowed.

Two other documents state which custody a mount target keeps, and what that custody means for the
order of disposal. Read
[`the custody of a mount target`](api.md#the-custody-of-a-mount-target) and
[`adopt and borrow are both explicit`](ownership.md#adopt-and-borrow-are-both-explicit). This page
does not restate them.

## Building a 3D scene

`runtime.constructors` builds any Roblox class by name. It holds no fixed list. `Host.Part`,
`Host.Model`, `Host.PointLight` and `Host.WeldConstraint` all use the same mechanism: a lazily
cached constructor that calls `Instance.new` with that class name. A nested constructor call nests
the instance. A plain string after the class name becomes the `Name` of the instance.

```luau
local Host = runtime.constructors

local function Rig(position, lit, tint)
    local torso = Host.Part "Torso" {
        Anchored = false,
        CFrame = runtime.spring(position, { period = 0.25 }),
    }

    local head = Host.Part "Head" {
        Anchored = false,
    }

    return Host.Model "Rig" {
        torso,
        head,

        Host.WeldConstraint {
            Part0 = Compose.static(torso),
            Part1 = Compose.static(head),
        },

        Host.PointLight "Glow" {
            Brightness = function(use)
                return if use(lit) then 2 else 0
            end,
            Color = function(use)
                return use(tint)
            end,
        },
    }
end
```

`CFrame` follows a spring here, and `Color` follows a cell or a formula. Both bind the way every
reactive property binds: a function value is a binding, and `runtime.spring` and `runtime.tween`
return sources that you can pass in directly. `Brightness` holds a plain Luau `number`, which the
core `number` codec animates; it needs nothing from `ComposeRoblox`. `CFrame` and `Color3` use the
codecs that `src/roblox/codecs.luau` registers.

Caution: Compose interpolates the rotation of a `CFrame` componentwise on the quaternion, not by
slerp, so the angular rate is not constant across the turn.
[`what is animatable`](roblox.md#what-is-animatable) states which Roblox datatypes Compose covers,
and states this caveat. If a weld or a joint needs a constant angular speed, animate an angle and
build the `CFrame` from that angle. Do not animate the `CFrame` directly.

`WeldConstraint` and `Weld` get no special treatment. Generic construction builds them. `Part0` and
`Part1` need `Compose.static(...)`, not a bare `torso` or `head`. This tree built `torso` and
`head`, and a property value that is an owned node raises `props/child-under-string-key`. That
diagnostic stops Compose from destroying one node twice: once as a child, and once where the node
was also assigned. `static` marks the value as a literal, so Compose writes the value once and
never reads it as a binding. Build the weld after both parts exist, as the example above does.
Compose does not sequence that for you.

## Testing a scene with no engine

`RobloxEmulator.create()`, from `src/test-scene/roblox.luau`, is a headless stand-in for the Roblox
`Instance` model. It offers dot-accessible properties with per-class defaults, methods, signals and
an `IsA` inheritance chain, and it needs no Roblox engine. It is the supported way to test an
instance tree, or a 3D scene built through `runtime.constructors`, with no engine.

```luau
local RobloxEmulator = require(script.Parent.Parent["test-scene"].roblox)

local emulator = RobloxEmulator.create()
local runtime = Compose.createRuntime(emulator.adapter)
```

`emulator.adapter` is the host that `ComposeRoblox.createHost(emulator.engine)` returns, with one
addition: the emulator wraps the renderer and the naming capability of that host, so that each
such call appends an entry to `emulator.log()` and obeys `emulator.failNext`. Every other capability of the host is the real one.
If you build the host by hand, you get the same real adapter without the log and without the
injected failures:

```luau
local host = ComposeRoblox.createHost(emulator.engine)
local runtime = Compose.createRuntime(host)
```

`emulator.engine` is the injected engine table itself. It carries `new`, `heartbeat`, `clock`,
`typeName`, `destroy`, `propertyChanged`, `datatypes` and `readCFrame`. Pass that table to
`createHost`, and a test runs the real adapter in `src/roblox/host.luau` and the real codecs in
`src/roblox/codecs.luau` against emulated instances, rather than against opaque test-scene nodes.

`emulator.step(delta)` advances the clock of the emulator and fires its `Heartbeat` signal.
`runtime.spring`, `runtime.tween` and `runtime.timeline` all subscribe to that signal. Step the
emulator by hand to drive an animation frame by frame, with no engine and no wall clock:

```luau
local dispose, rig = runtime.mount(function()
    return Rig(position, lit, tint)
end, emulator.root)

emulator.step(1 / 60)
emulator.step(1 / 60)

local torso = rig:FindFirstChild("Torso")
local cframe = emulator.propertyOf(torso, "CFrame")
```

The API reference states the full `Emulator` surface, including `createInstance`, `defineClass`,
`log`, `failNext`, and what the emulator cannot check about the real engine. Read
[`RobloxEmulator.create`](api.md#robloxemulatorcreate). This page does not repeat it.
