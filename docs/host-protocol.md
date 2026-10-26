# Writing a host adapter

A host adapter implements node operations for a runtime.
Pass it to `Compose.createRuntime(adapter)`.
Core uses these operations for all node access.
The [API reference](api.md) gives the component calls.

`runtime.constructors` supplies the `Host` constructors used by components.
`TestScene.create()` supplies a test scene with an `adapter`.

## `Node` is `unknown`, and that is the enforcement

Core treats each host node as `unknown`.
Strict type checking rejects direct access to the node representation.
The test host uses frozen empty tables for nodes.
It stores node data in private tables.
The gate checks that core has no dependency on an engine's node representation.

## Required and optional capabilities

```luau
export type Host = {
    name: string,
    render: Renderer,              -- required
    events: Events?,
    observation: Observation?,
    frames: Frames?,
    naming: Naming?,
    describeNode: ((node) -> string)?,
    typeNameOf: ((value) -> string)?,
}
```
Omit capabilities that the host cannot provide.
`Compose.createRuntime` checks supplied capabilities once, during runtime creation.
It rejects a missing required method at that boundary.

### `render`, required

```luau
createNode(kind) -> Node
setProperty(node, key, value) -> ()
setAttribute(node, name, value) -> (ok, reason?)   -- optional; see "Hosts with an attribute store"
clearProperty(node, key) -> ()
insertChild(parent, child, position?) -> ()
moveChild(parent, child, position) -> ()      -- optional; see "Hosts that cannot order children"
removeChild(parent, child) -> ()
destroyNode(node) -> ()
```
### `events`, optional

```luau
connectEvent(node, event, handler) -> Unsubscribe
classifyKey(node, key)? -> "property" | "event"
```
Implement `classifyKey` if the host can distinguish events from properties.
Then an event key such as `Activated = handler` creates a subscription.
Otherwise, keys select properties.
Use `Compose.event(name)` to select an event explicitly on either host.

### `observation`, optional

```luau
readProperty(node, key) -> unknown
observeProperty(node, key, listener) -> Unsubscribe
readStyledProperty(node, key)? -> unknown
observeStyledProperty(node, key, listener)? -> Unsubscribe
```
Implement observation to detect property changes from outside Compose.
Supply both styled methods, or neither method.
A styled read returns the effective value, including explicit overrides.
Its subscription reports raw and style changes that can affect that value.
`runtime.observe(..., { styled = true })` rejects a host without styled observation.
It does not substitute a raw read.
Subscriptions borrow their node and release native resources on unsubscribe.

### `frames`, optional

```luau
onFrame(listener) -> Unsubscribe
now() -> number
```
Animation requires this capability.
An animation call fails if the host has no frame capability.

### `naming`, optional

`naming = { setName(node, label) }` applies constructor labels such as `Host.Frame "Summary" { ... }`.
Omit it if nodes have no names.

### `typeNameOf`, optional

`typeNameOf(value)` returns the datatype name for codec selection.
The default is `typeof`.
Supply this method if the host represents datatypes as plain tables.

### Hosts with an attribute store

Omit `setAttribute` if the host has no attribute store.
Then the `Attributes` property raises `host/no-attributes` before it writes values.

```luau
setAttribute(node, "Tier", 3)        -> true
setAttribute(node, "Tier", { ... })  -> false, "this store holds scalars, not a table"
setAttribute(node, "Tier", nil)      -> true      -- nil clears the attribute
```
For a rejected value, return `false` and a reason.
Compose reports `props/attribute-value` with the node, attribute and reason.
The host determines which attribute values it accepts.
Raise all other host failures so Compose can release the failed operation's resources.
A nil value clears the attribute.
A binding uses this operation to clear attributes from a borrowed node on disposal.

## Positions

Each position is a 1-based index in the parent's child list.
It describes the required state after the call.
A position beyond the list length appends the child.

```luau
insertChild(parent, child, 2)     -- child ends up second
insertChild(parent, child, nil)   -- child ends up last
moveChild(parent, child, 1)       -- child ends up first, others shift right
```
Do not independently remove duplicates or change child order.
Compose calculates positions. Tests compare host operations with those positions.

### Hosts that cannot order children

Omit `moveChild` only if the host has no child-order operation.
The host then appends children and supplies order through another mechanism.
For Roblox, see [sibling order](roblox.md#sibling-order).
Do not supply a `moveChild` method that does nothing.

Without `moveChild`, keyed collections skip node arrangement.
They do not calculate a longest increasing subsequence or keep a live position map.
They still reuse rows and update row values and reactive indices.
The reactive index stays exact.
The host still receives `insertChild` positions, but can ignore them.
Use the [benchmark procedure](benchmarks.md) to measure the cost on your host.

## What a host must guarantee

1. Return a distinct table or userdata from each `createNode` call.
2. Complete each operation before it returns.
3. Make `destroyNode` release the node and its descendants.
4. Make repeated destruction safe.
5. Make repeated unsubscribe calls safe.
6. Stop listener calls after unsubscribe, including events already in progress.
7. Raise failures except for attribute-value rejection.

Numbers and strings cannot carry custody or weak references.
Functions cannot be nodes because child lists identify directives by their callable type.

## A minimal host

```luau
local nodes = setmetatable({}, { __mode = "k" })

local host: Compose.Host = {
    name = "example",
    render = {
        createNode = function(kind)
            local node = table.freeze({})
            nodes[node] = { kind = kind, properties = {}, children = {} }
            return node
        end,
        setProperty = function(node, key, value)
            nodes[node].properties[key] = value
        end,
        clearProperty = function(node, key)
            nodes[node].properties[key] = nil
        end,
        insertChild = function(parent, child, position)
            local children = nodes[parent].children
            table.insert(children, position or #children + 1, child)
        end,
        moveChild = function(parent, child, position)
            local children = nodes[parent].children
            table.remove(children, table.find(children, child))
            table.insert(children, position, child)
        end,
        removeChild = function(parent, child)
            local children = nodes[parent].children
            table.remove(children, table.find(children, child))
        end,
        destroyNode = function(node)
            nodes[node] = nil
        end,
    },
}
```
This example shows the renderer's method shapes.
A complete host must also release descendants and support repeated cleanup safely.

## Testing a host

Use [`src/test-scene`](../src/test-scene) as a reference.
Adapt the [runtime tests](../tests/runtime) and [lifecycle tests](../tests/lifecycle) to your host.
Start with failures. `test.failNext(operation)` shows how to test error reporting and cleanup.
