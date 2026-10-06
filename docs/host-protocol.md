# Writing a host adapter

This guide defines the operations and guarantees that a host adapter must provide. It also describes the optional capabilities.
For the component API, see [`api.md`](api.md).

`src/core` never accesses a node directly. It asks a host to create nodes, set properties, parent nodes and destroy nodes.

The adapter is the object that you pass to `Compose.createRuntime(adapter)`.
Component examples call `runtime.constructors` the `Host` namespace. Those constructors delegate node operations to the adapter.
`TestScene.create()` supplies a fake scene and exposes its adapter as `test.adapter`.

## `Node` is `unknown`, and that is the enforcement

Core cannot index an `unknown`. Strict type checking therefore rejects direct access to the node representation of a host.
The test adapter also enforces this at runtime. Its nodes are `table.freeze({})`, with no fields or methods.
The adapter keeps node data in private side tables.

Core must work without engine-shaped nodes. The gate must detect any dependency on the node representation of an engine.

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

Omit the capabilities that the host does not support.
`Compose.createRuntime` validates each supplied capability once, when it creates the runtime.
A missing required method fails at that boundary.

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

- Implement `classifyKey` when the distinction between a property and an event is discoverable at runtime. Then a user can write `Activated = handler` and the key subscribes.
- Omit `classifyKey` when the distinction is not discoverable. Then keys are properties, unless the user wraps them in `Compose.event(name)`, which is unambiguous everywhere.

### `observation`, optional

```luau
readProperty(node, key) -> unknown
observeProperty(node, key, listener) -> Unsubscribe
```

Implement `observation` to notice when something other than Compose changed a property.

### `frames`, optional

```luau
onFrame(listener) -> Unsubscribe
now() -> number
```

Animation requires `frames`. An animation call fails if the host does not provide this capability.

### `naming`, optional

`naming = { setName(node, label) }` applies the string label in constructor calls such as `Host.Frame "Summary" { ... }`.
Omit it when nodes have no names.

### `typeNameOf`, optional

`typeNameOf` supplies the type name of a value for codec lookup. The default is `typeof`.
Supply this function when the host represents its datatypes as plain tables.

### Hosts with an attribute store

`setAttribute` is optional. **If the host has no attribute store, omit it.**
Then the `Attributes` prop raises `host/no-attributes` without writing values.

`setAttribute` is also the one verb that does **not** raise on a rejected value.

```luau
setAttribute(node, "Tier", 3)        -> true
setAttribute(node, "Tier", { ... })  -> false, "this store holds scalars, not a table"
setAttribute(node, "Tier", nil)      -> true      -- nil clears the attribute
```

The attribute store decides which values it accepts.
For a rejected value, return `false` and a reason. Compose reports `props/attribute-value` with the node, the attribute and the reason.
This exception covers value rejection only. Raise other host failures, so that Compose can release the resources of the failed operation.

If the value is `nil`, the host must clear the attribute.
No separate clear verb exists. A binding on a borrowed node uses that clear to undo itself on disposal.

## Positions

Every position is a **1-based index into the child list of the parent**.
Every position describes the state that Compose wants after the call.

```luau
insertChild(parent, child, 2)     -- child ends up second
insertChild(parent, child, nil)   -- child ends up last
moveChild(parent, child, 1)       -- child ends up first, others shift right
```

A position beyond the current length appends the child.
Do not renumber, remove duplicates or reorder children independently. Compose computes exact positions. Tests compare host operations with those positions.

### Hosts that cannot order children

`moveChild` is optional. **If you omit it, you declare that the host has no child-ordering API at all.**
Then attaching a child appends it, nothing reorders, and order is expressed some other way.
Order is usually a property that the host reads to lay out children. Roblox is such a host. See [`roblox.md`](roblox.md#sibling-order).

Without `moveChild`, keyed collections skip node arrangement.
They do not compute a longest increasing subsequence and do not maintain a live position map.
They still update row values and reactive indices.
To measure the cost on your host, use the [benchmark procedure](benchmarks.md).

Do not supply a `moveChild` function that does nothing. Compose would compute arrangements that the host cannot perform.
A host without `moveChild` still receives `insertChild` positions and can ignore them.

Rows stay keyed, stay reused across updates and still receive a reactive index.
On a host with no ordering, that index is the only order, and it stays exact.

## What a host must guarantee

1. `createNode` returns a distinct node on every call. The node is a table or userdata. Numbers and strings cannot carry custody and cannot be held weakly. Functions are excluded, because a child list distinguishes a node from a directive by asking whether it is callable.
2. Operations are synchronous. When `setProperty` returns, the property is set.
3. `destroyNode` releases the node and its descendants. It is idempotent.
4. An unsubscribe is idempotent. It never fires its listener afterwards, including for an event already in flight.
5. **Raise failures.** Compose uses the error to trigger cleanup. For an unsupported attribute value only, `setAttribute` returns a refusal instead.

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

This example illustrates the method shapes of the renderer.
A complete adapter must also meet the guarantees above, including descendant destruction and idempotent cleanup.

## Testing a host

Use `src/test-scene/` as the reference adapter.
The tests in `tests/runtime/` and `tests/lifecycle/` check the host protocol. Adapt them to your host.
Start with failure injection. `test.failNext(operation)` shows how to check error reporting and cleanup.
