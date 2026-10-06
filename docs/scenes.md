# Scenes

A scene can hold nodes that `runtime.mount` did not create. This page covers three cases:

- You take over a node that the engine already made.
- You build a 3D tree of parts and lights.
- You test either case with no engine.

Read [`api.md`](api.md) for the full signatures. Read [`ownership.md`](ownership.md) for the custody rules. This page uses those rules and does not repeat them.

## Decorating what already exists

A mount target, a model or a layer that another system owns arrives already built. Compose did not make it.
Three verbs work with such a node:

```luau
runtime.decorate(node, props)
runtime.adopt(node)
runtime.borrow(node)
```

`decorate` applies properties, attributes and event subscriptions to an existing node.

- `decorate` cannot add children. If the array part of the props table has any entry, `decorate` raises `props/decorate-has-children`.
- The bindings and the subscriptions belong to the active owner. Compose releases them when that owner disposes.
- Compose does not otherwise touch the node. A property or an event that the props table does not name keeps its current behavior.
- On a borrowed node, Compose clears every property that `decorate` wrote back to the class default.

```luau
local function Marker(part)
    runtime.decorate(part, {
        Transparency = function(use)
            return if use(highlighted) then 0 else 0.5
        end,
        [Compose.event("Touched")] = onTouched,
    })

    return Host.BillboardGui { ... }
end
```

This component did not build `part`, so `part` is borrowed by default. Compose never destroys a borrowed node.
When the component that called `decorate` disposes, Compose releases the binding and the `Touched` connection.
It leaves `part.Transparency` at its class default.

`adopt` states the opposite decision. It states that this tree must destroy a node that Compose did not build.

```luau
local model = template:Clone()

local dispose = runtime.mount(function()
    runtime.adopt(model)
    return model
end, playerGui)
```

A node has exactly one owner, so `adopt` refuses a node that Compose already owns.
`borrow` is already the default for every node that Compose has not seen. Call `borrow` in two cases only:

- The explicit statement helps a reader.
- A node passed through code that can adopt it, and its custody must return to borrowed.

[Ownership](ownership.md#a-mount-target-keeps-the-custody-it-has) defines mount-target custody and disposal order.

## Building a 3D scene

`runtime.constructors` builds any Roblox class by name. It holds no fixed list.
`Host.Part`, `Host.Model`, `Host.PointLight` and `Host.WeldConstraint` all use the same mechanism: a lazily cached constructor that calls `Instance.new` with that class name.
A nested constructor call nests the instance. A plain string after the class name becomes the `Name` of the instance.

```luau
local Host = runtime.constructors

local function Assembly(position, lit, tint)
    local base = Host.Part "Base" {
        Anchored = false,
        CFrame = runtime.spring(position, { period = 0.25 }),
    }

    local top = Host.Part "Top" {
        Anchored = false,
    }

    return Host.Model "Assembly" {
        base,
        top,

        Host.WeldConstraint {
            Part0 = Compose.static(base),
            Part1 = Compose.static(top),
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

`CFrame` follows a spring here, and `Color` follows a cell or a formula.
Both bind the way every reactive property binds. A function value is a binding. `runtime.spring` and `runtime.tween` return sources that you can pass in directly.
`Brightness` holds a plain Luau `number`, which the core `number` codec animates. It needs nothing from `ComposeRoblox`.
`CFrame` and `Color3` use the codecs that `src/roblox/codecs.luau` registers.

For the `CFrame` rotation limitation and the constant-angular-speed alternative, see [animatable types](roblox.md#what-is-animatable).

`WeldConstraint` and `Weld` get no special treatment. Generic construction builds them.

- `Part0` and `Part1` need `Compose.static(...)`, not a bare `base` or `top`.
- This tree built `base` and `top`. A property value that is an owned node raises `props/child-under-string-key`.
- That diagnostic stops Compose from destroying one node twice: once as a child, and once where the node was also assigned.
- `static` marks the value as a literal. Compose writes the value once and never reads it as a binding.
- Build the weld after both parts exist, as the example above does. Compose does not sequence that for you.

## Testing a scene with no engine

`RobloxEmulator.create(environment, Verify.environmentEngine(environment))`, from `src/test-scene/roblox.luau`, runs the real Roblox adapter over the simulated engine of Verify.
The environment supplies Instances with per-class defaults, methods, signals, an `IsA` chain and virtual time. It needs no Roblox engine.
It is the supported way to test an instance tree, or a 3D scene that you build through `runtime.constructors`, with no engine.

To create the environment and the runtime, follow [the emulator setup](api.md#robloxemulatorcreate).

`emulator.adapter` exercises the real Roblox adapter with operation logging and injected failures.
For its complete surface, use [the emulator API](api.md#robloxemulatorcreate).
For claims that need the engine, see the [simulation limits](roblox.md#what-the-simulation-cannot-check).

`environment.step(delta)` advances virtual time and fires the `Heartbeat` signal.
`runtime.spring`, `runtime.tween` and `runtime.timeline` all subscribe to that signal.
To drive an animation frame by frame with no engine and no wall clock, step the emulator by hand:

```luau
local dispose, assembly = runtime.mount(function()
    return Assembly(position, lit, tint)
end, emulator.root)

environment.step(1 / 60)
environment.step(1 / 60)

local base = assembly:FindFirstChild("Base")
local cframe = environment.propertyOf(base, "CFrame")
```

See [roblox-emulator.luau](../examples/roblox-emulator.luau) for a complete runnable scene test.
