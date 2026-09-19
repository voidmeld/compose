# Writing a host adapter

This guide defines the operations and guarantees that a host adapter must provide.
It also describes optional capabilities. See [`api.md`](api.md) for the component API.

`compose-core` never accesses a node directly. It asks a host to create nodes, set properties,
parent nodes, and destroy nodes.

The adapter is the object passed to `Compose.createRuntime(adapter)`. Component examples call
`runtime.constructors` the `Host` namespace; those constructors delegate node operations to the
adapter. `TestScene.create()` supplies a fake scene and exposes its adapter as `test.adapter`.

## `Node` is `unknown`, and that is the enforcement

Core cannot index an `unknown`. Strict type checking therefore rejects direct access to a host's node representation.
The test adapter also enforces this at runtime. Its nodes are `table.freeze({})`, with no fields or methods.
The adapter keeps node data in private side tables.

Core must work without engine-shaped nodes. The gate must detect any dependency on an engine's node representation.

## Required and optional capabilities

```luau
export type Host = {
    name: string,
    render: Renderer,              -- required
    events: Events?,
    observation: Observation?,
    frames: Frames?,
    describeNode: ((node) -> string)?,
    typeNameOf: ((value) -> string)?,
}
```

Omit capabilities the host does not support. `Compose.createRuntime` validates each supplied capability once, when the runtime is created.
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

Implement `classifyKey` when the distinction is discoverable at runtime. Callers can then write
`Activated = handler` and have it subscribe. Omit `classifyKey` when the distinction is not
discoverable. Keys are then properties unless the caller wraps them in `Compose.event(name)`, which
is unambiguous everywhere.

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

### `typeNameOf`, optional

`typeNameOf` supplies the value's type name for codec lookup. The default is `typeof`.
Supply this function when the host represents its datatypes as plain tables.

### Hosts with an attribute store

`setAttribute` is optional. **Omit it if the host has no attribute store.**
The `Attributes` prop then raises `host/no-attributes` without writing values.

`setAttribute` is also the one verb that does **not** raise on a rejected value.

```luau
setAttribute(node, "Tier", 3)        -> true
setAttribute(node, "Tier", { ... })  -> false, "this store holds scalars, not a table"
setAttribute(node, "Tier", nil)      -> true      -- nil clears the attribute
```

The attribute store decides which values it accepts. Return `false` and a reason for a rejected value.
Compose reports `props/attribute-value` with the node, attribute and reason.
This exception covers value rejection only. Raise other host failures so Compose can release resources from the failed operation.

A host must clear the attribute when the value is `nil`. No separate clear verb exists, and a
binding on a borrowed node uses that clear to undo itself on disposal.

## Positions

Every position is a **1-based index into the child list of the parent**. Every position describes
the state the caller wants after the call.

```luau
insertChild(parent, child, 2)     -- child ends up second
insertChild(parent, child, nil)   -- child ends up last
moveChild(parent, child, 1)       -- child ends up first, others shift right
```

A position beyond the current length appends the child. Do not renumber, remove duplicates or reorder children independently.
Compose computes exact positions. Tests compare host operations with those positions.

### Hosts that cannot order children

`moveChild` is optional. **Omitting it declares that the host has no
child-ordering API at all.** Attaching a child then appends, nothing reorders, and order is
expressed some other way. Order is usually a property the host reads to lay children out. Roblox is
such a host. See [`roblox.md`](roblox.md#sibling-order).

Without `moveChild`, keyed collections skip node arrangement. They do not compute a longest increasing subsequence or maintain a live position map.
They still update row values and reactive indices. Use the [benchmark procedure](benchmarks.md) to measure the cost on your host.

Do not supply a `moveChild` function that does nothing. Compose would compute arrangements that the host cannot perform.
A host without `moveChild` still receives `insertChild` positions and may ignore them.

Rows stay keyed, stay reused across updates, and still receive a reactive index. On a host with no
ordering that index is the only order there is, and it stays exact.

## What a host must guarantee

1. `createNode` returns a distinct node every call, and that node is a table or userdata. Numbers
   and strings cannot carry custody or be held weakly. Functions are excluded because a child list
   distinguishes a node from a directive by asking whether it is callable.
2. Operations are synchronous. When `setProperty` returns, the property is set.
3. `destroyNode` releases the node and its descendants, and it is idempotent.
4. An unsubscribe is idempotent and never fires its listener afterwards, including for an event
   already in flight.
5. **Raise failures.** Compose uses the error to trigger cleanup.
   For an unsupported attribute value only, `setAttribute` returns a refusal instead.

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

This example illustrates the renderer's method shapes. A complete adapter must also meet the guarantees above, including descendant destruction and idempotent cleanup.

## Testing yours

Use `src/test-scene/` as the reference adapter. The tests in `tests/runtime/` and `tests/lifecycle/` check the host protocol.
Adapt them to your host. Start with failure injection.
`test.failNext(operation)` demonstrates how to check error reporting and cleanup.
