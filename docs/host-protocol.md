# Writing a host

This guide connects Compose to a node system, defining every operation Compose needs from a host,
the guarantees a host must meet, and the two capabilities a host may decline; [`api.md`](api.md)
covers the public component API.

`compose-core` never accesses a node directly. It asks a host to create nodes, set properties,
parent nodes, and destroy nodes.

## `Node` is `unknown`, and that is the enforcement

Core code cannot index an `unknown`, so a strict build fails the moment core reaches past the
protocol into a host representation. The test host carries the same idea into the runtime. Its nodes
are `table.freeze({})` with no fields and no methods. Every fact about a node lives in a side table
the host keeps to itself.

A host that must imitate an engine object for Compose to work signals a failed abstraction, and the
gate should say so.

## One required capability, four optional

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

A host that cannot observe properties or has no frame loop implements neither capability. It says so
in its types rather than raising at runtime. `Compose.createRuntime` validates the host once, so a
missing method fails next to the host rather than three frames into a render.

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

Animation needs `frames`. A host without it cannot animate, and it says so at the call site rather
than never moving.

### `typeNameOf`, optional

`typeNameOf` names the type of a value for codec lookup. It defaults to `typeof`, which is right
whenever the language already names the host datatypes. A host whose datatypes are plain tables
supplies its own.

### Hosts with an attribute store

`setAttribute` is the second optional member of `render`. **Omitting it declares that the host has
no attribute store.** The `Attributes` prop of a node then raises `host/no-attributes` rather than
writing anything.

`setAttribute` is also the one verb that does **not** raise on a rejected value.

```luau
setAttribute(node, "Tier", 3)        -> true
setAttribute(node, "Tier", { ... })  -> false, "this store holds scalars, not a table"
setAttribute(node, "Tier", nil)      -> true      -- nil clears the attribute
```

Each attribute store defines which values it accepts, and the answer is data-dependent. A raw raise
from the store names neither the node nor the attribute. Returning `false` with a reason instead
lets Compose refuse with `props/attribute-value`, which names all three. This is a narrow exception
to the raising rule below, and it covers value rejection only. A host that is actually broken must
still raise, and the unwind still happens.

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

A position beyond the current length appends. A host must never renumber, dedupe, or reorder on its
own. The structural primitives of Compose compute exact positions, and the tests assert their
mutation traces against those positions.

### Hosts that cannot order children

`moveChild` is the one optional member of `render`. **Omitting it declares that the host has no
child-ordering API at all.** Attaching a child then appends, nothing reorders, and order is
expressed some other way. Order is usually a property the host reads to lay children out. Roblox is
such a host. See [`roblox.md`](roblox.md#sibling-order).

This is a capability rather than a convenience, and Compose acts on it. A keyed collection over such
a host skips the whole arrangement, meaning the longest-increasing-subsequence pass, the live
position map, and every move. It skips them because it has nothing to carry the answer out with.
Reversing three thousand rows then costs the property writes the reversal implies and no bookkeeping
at all. That is roughly a quarter of the cost of computing an order and then discarding it.

Supplying a `moveChild` that does nothing is therefore worse than omitting it. Compose will believe
the host and pay for arrangements the host cannot perform. A host that omits `moveChild` still
receives positions on `insertChild`, and it may ignore them.

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
5. Failures **raise**. A host that swallows an error hides the unwind Compose would otherwise
   perform, and that unwind is the thing being relied on. The single exception is a value
   `setAttribute` will not store, which the host reports rather than raises.

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

That is a complete, working host. Everything else is optional.

## Testing yours

`src/test-host/` is the reference implementation. The contract tests in `tests/runtime/` and
`tests/lifecycle/` are written against the protocol rather than against any particular host, so
point them at your host and they will report what you got wrong. Start with the failure-injection
suite. `host.failNext(operation)` is the fastest way to learn whether your host raises where Compose
expects it to.
