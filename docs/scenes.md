# Scenes

This guide covers existing nodes, 3D scene trees and tests without an engine.
The [API reference](api.md) gives signatures.
The [ownership guide](ownership.md) defines custody and disposal order.

## Decorating what already exists

A mount target, model or external layer can exist before Compose sees it.
Use these operations for existing nodes:

```luau
runtime.decorate(node, props)
runtime.adopt(node)
runtime.borrow(node)
```
`decorate` applies properties, attributes and event subscriptions.
It rejects children with `props/decorate-has-children` if the props array has any entry.
Bindings and subscriptions belong to the active owner.
Properties and events absent from the props table keep their current behavior.
On a borrowed node, disposal resets written properties to class defaults.

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
Compose did not create `part`, so it borrows the node by default.
Disposal releases the binding and `Touched` connection.
It preserves `part` and leaves `Transparency` at its class default.

Use `adopt` when the Compose tree must destroy an existing node:

```luau
local model = template:Clone()

local dispose = runtime.mount(function()
    runtime.adopt(model)
    return model
end, playerGui)
```
Each node has one owner. `adopt` rejects a node that Compose already owns.
Use `borrow` to make external custody clear or to restore borrowed custody after code that can adopt the node.
The [mount-target rules](ownership.md#a-mount-target-keeps-the-custody-it-has) define target lifetime and disposal order.

## Building a 3D scene

`runtime.constructors` builds Roblox classes by name without a fixed class list.
`Host.Part`, `Host.Model`, `Host.PointLight` and `Host.WeldConstraint` use the same constructor mechanism.
The runtime caches each constructor and calls `Instance.new` with that class name.
A nested constructor creates a child.
A string after the class name supplies the Instance name.

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
`CFrame` follows a spring in this example.
`Color` follows a cell or formula.
A function value binds a property.
Spring and tween results can also bind properties directly.

The core number codec animates `Brightness`.
The Roblox codecs animate `CFrame` and `Color3`.
For rotation limits, see [animatable types](roblox.md#what-is-animatable).

Welds use normal constructors.
Wrap `Part0` and `Part1` with `Compose.static(...)` to write the owned node as a literal property value.
A bare owned node under a string key raises `props/child-under-string-key`.
This diagnostic prevents a node from receiving two destruction registrations.
`static` writes once and prevents reactive interpretation.
Build the weld after both parts exist.
Compose does not choose that construction order.

## Testing a scene with no engine

`RobloxEmulator.create(environment, Verify.environmentEngine(environment))` runs the real Roblox adapter against Verify's simulation.
It provides class defaults, methods, signals, `IsA` relationships and virtual time.
It can test Instance trees and 3D constructor scenes without Roblox.
Follow the [emulator setup](api.md#robloxemulatorcreate) for the environment and runtime.

The emulator adds operation logging and failure injection to the real adapter.
The [emulator API](api.md#robloxemulatorcreate) gives its full surface.
The [simulation limits](roblox.md#what-the-simulation-cannot-check) identify claims that need an engine.

`environment.step(delta)` advances virtual time and fires `Heartbeat`.
Springs, tweens and timelines use that signal through the host frame capability.
Step it manually to test animation without a wall clock:

```luau
local dispose, assembly = runtime.mount(function()
    return Assembly(position, lit, tint)
end, emulator.root)

environment.step(1 / 60)
environment.step(1 / 60)

local base = assembly:FindFirstChild("Base")
local cframe = environment.propertyOf(base, "CFrame")
```
[roblox-emulator.luau](../examples/roblox-emulator.luau) is a complete runnable scene test.
