# API reference

Every public export appears here with a runnable example. `tools/check-public-surface.luau` checks
the exported APIs against this page, because an undocumented API is hard to use and a missing API is misleading.

Examples assume:

```luau
local Compose = require(path.to.compose.core)
local TestScene = require(path.to.compose["test-scene"])

local test = TestScene.create()
local runtime = Compose.createRuntime(test.adapter)
local Host = runtime.constructors
```

Working versions of most of them are under [`../examples`](../examples), and every
behaviour claimed here is asserted somewhere in [`../tests`](../tests).

---

## Reactive state

Cells hold state; formulas derive state. Every reactive body receives `use`, including formulas,
watches, bound properties and structural sources. Reading through `use` records a dependency.
Outside a body, use `:peek()` for an explicit untracked read.

### A value, or a source of one

`Compose.Given<T>` is the type of an argument that accepts one of four things:

- a plain `T`,
- a cell that reads as `T`,
- a formula that reads as `T`,
- a body that returns `T`.

An option field uses `Given` when the field does not care which of the four the caller has.

```luau
type Options = {
    seconds: Compose.Given<number>?,
}

runtime.tween(opacity, { seconds = 0.25 })
runtime.tween(opacity, { seconds = configuredSeconds })
```

`Source<T>` is the narrower union. It accepts a cell, a formula or a body, but not a plain value.
If a constant is a mistake for the field, use `Source`. If a constant is correct, use `Given`.

### `Compose.cell`

`cell(initial, equals?) -> Cell`

Stores a writable value in the reactive graph. `initial` may be a value or a function.
Compose calls an initial-value function only on the first read or write.

```luau
local health = Compose.cell(100)

health:peek()                    --> 100   read, no dependency
health:set(90)
health:update(function(previous) --> 81
    return previous - 9
end)
```

`equals` decides what counts as a change; the default is `==`. A write it calls equal is
suppressed entirely: nothing downstream is marked, and no watch runs.

### `Compose.sharedCell`

`sharedCell(initial, equals?) -> Cell`

Declares a cell with a module-scope lifetime. Use it for deliberate process-wide state,
an exported reactive API or a development override. No owner is required, and disposal is
not expected. The constructor makes that lifetime explicit to readers and consumer lint.

```luau
-- module scope is the point
local presses = Compose.sharedCell(0)

return { presses = presses }
```

It uses the same runtime behaviour and execution paths as `cell`, with an additional metatable
identity flag. Diagnostics identify it as a cell. `Compose.cell` remains valid at module scope.
`sharedCell` declares intent for consumer lint; it does not add a reactive capability.

### `Compose.formula`

`formula(body, equals?) -> Formula`

A cached derivation. `body` receives `use` and must read every dependency through it.

```luau
local percent = Compose.formula(function(use)
    return use(health) / 100
end)

percent:peek()  --> 0.81
```

The body runs on its first read. Compose caches the result and recomputes it only when a
dependency changes. An equal result publishes no change, so downstream consumers do not rerun.

A formula created under an active owner belongs to that owner and releases its upstream
dependencies on teardown or failed-build unwind. Reading an existing formula from another
owner borrows it; the read does not transfer ownership. Outside an active owner, the caller
controls its lifetime with `formula:dispose()`. Explicit disposal is also supported for
owned formulas and removes their cleanup registration immediately.

Disposal is idempotent. It releases dependencies, the body, comparator, and cached value.
Subsequent `:peek()` and `use(formula)` reads raise `reactive/disposed-formula`; disposal
neither evaluates the body nor schedules downstream callbacks. Dispose downstream consumers
before their formula, or give the formula an owner that outlives those consumers.

### `Compose.watch`

`watch(body, label?) -> dispose`

Runs `body` immediately and again when a dependency changes. The active owner controls its
lifetime. The call refuses when there is no active owner.

```luau
Compose.watch(function(use)
    print(use(percent))
end, "health readout")
```

Call the returned disposer to stop the watch early. You do not need to retain it to keep
the watch running. Disposing the owner stops the watch.

Outside a mount, use `owner.watch(body, label?)` with an explicit owner, or
`runtime:watch(body, label?)`, which falls back to the runtime's own owner. The optional
label names this otherwise-handleless watch in a running [`Compose.profile`](#composeprofile)
capture; it is not retained when the profiler is off.

#### Reacting to changes only

No option suppresses the first run. The first run registers the dependencies, so it must happen.
To act only on later changes, give the watch one flag:

```luau
local delivered = false
Compose.watch(function(use)
    local current = use(health)
    if not delivered then
        delivered = true
        return
    end
    flash(current)
end, "health flash")
```

The first run is synchronous. It happens inside the `watch` call itself, before an enclosing batch
closes. A write made later in that same batch is therefore a change. The watch runs again when the
batch settles. The body then reads the value the batch left behind, not the value it started with.

### `Compose.accumulator`

`accumulator { from, reduce, initial?, equals? } -> Readable`

Tracks one readable source. On each change, it calls `reduce(previous, event)` to update
its own readable state. This state can retain information that the event source does not carry.

```luau
local timings = Compose.accumulator {
    from = castFired,                       -- a cell or formula; each change is one event
    reduce = function(previous, event)      -- merge one event into the running state
        return withCast(previous, event)
    end,
    initial = {},                           -- the state before any event
}
```

This combines a cell with a watch that reads and updates the cell. The internal read of
previous state is untracked, so the accumulator cannot retrigger itself through that read.

The subscription belongs to the active owner and ends when that owner disposes.
`reduce` runs immediately with the construction-time value of `from`, then on every change.
It does not wait for the first read, which would miss earlier events.

A cell stores a value, not a queue. Two writes to `from` inside one batch produce one observed change.

An equal reduction result (`equals`, default `==`) does not mark downstream consumers.
If `reduce` raises, the accumulator drops that event and keeps the previous state and subscription.
It reports the error as a watch failure.

### `Compose.reactor`

`reactor() -> Reactor`

Creates a scheduling domain with its own queue, batch depth and drain. Every runtime creates
one. Pass it to `Compose.createOwner(reactor)` to place an owner in that domain.
Domains do not share queues or batch state, so one domain cannot block another's drain.

```luau
local reactor = Compose.reactor()

reactor:batch(function() ... end)  -- watches deferred until it returns; nests
reactor:settle()                   -- run everything pending; no-op inside a batch
reactor:pending()                  -- how many watches are waiting
```

A write outside a batch settles every domain it reached, before it returns.

A reactor needs no host. Cells, formulas and watches are the whole reactive layer, and none of
them touches a host. `Compose.createRuntime(host)` creates a reactor because a runtime also builds
nodes. Some models have no tree: a server-side store, a simulation, a test. For such a model,
create a reactor, create an owner on that reactor, and do not create a runtime.

```luau
local reactor = Compose.reactor()
local owner = Compose.createOwner(reactor)
local ledger = Compose.cell(0)

owner.watch(function(use)
    persist(use(ledger))
end)

reactor:batch(function() ... end)
owner.dispose()
```

### `Compose.sample`

`sample(source) -> value`

Reads a cell, a formula, or a body without depending on anything. Inside a reactive body
prefer `x:peek()`, which says the same thing about one value.

Compose calls a body with an untracked reader. Thus `sample(function(use) return use(count) end)`
returns the body's current value. An argument that is neither a reactive node nor a body
raises `reactive/not-a-source`. A body that reads a non-reactive value raises
`reactive/not-a-node`, naming `Compose.sample`.

### `Compose.isReadable`

`isReadable(value) -> boolean`

True for a cell or a formula. Decided by metatable, which is why an ordinary table passed
as a property value is never mistaken for something reactive.

---

## Ownership

### `Compose.createOwner`

`createOwner() -> Owner`

Creates a root owner. The caller must dispose it. Inside a mounted tree, usually use
`owner.createChild()` instead.

```luau
local owner = Compose.createOwner()
Compose.withOwner(owner, function()
    Compose.watch(function(use) ... end)
end)
owner.dispose()   -- releases everything registered above, newest first, exactly once
```

An `Owner` has `own`, `watch`, `createChild`, `dispose`, `isDisposed`, `size`, `reactor`,
`checkpoint`, `rollbackTo`, and `guardWith`. See [`ownership.md`](ownership.md).

In an entry point, prefer [`Compose.withRootOwner`](#composewithrootowner) or
[`Compose.createRootOwner`](#composecreaterootowner): same owner, with the disposal
guaranteed rather than remembered.

### `Compose.withOwner`

`withOwner(owner, body) -> body's results`

Runs `body` with `owner` active. It ends that activation even if `body` raises. Use it to
call owner-bound primitives from imperative code outside a mount.

An activation belongs to the thread that opened it. A yielding body keeps its owner when
it resumes, regardless of intervening mounts. A thread that Compose resumes inherits the
resumer's owner. A thread with neither has no active owner. See
[`ownership.md`](ownership.md#which-owner-is-active-exactly).

### `Compose.bindOwner`

`bindOwner(body) -> a closure with the same arguments and results`

Captures the active owner. The returned closure activates that owner whenever it calls `body`.
Use it for host callbacks, event handlers, deferred work or completions that run without an active owner.

```luau
local onArrived = Compose.bindOwner(function(child)
    runtime.connect(child, "Changed", handle)   -- owned by the component that bound it
end)
runtime.connect(container, "ChildAdded", onArrived)
```

Raises `owner/no-active-owner` if there is no owner to capture, and
`owner/bind-body-not-a-function` if `body` is not a function. The bound closure passes its
arguments through and returns the body's results; a raise propagates unchanged. Binding does
not extend a lifetime. If the owner is already disposed, it immediately releases anything
the callback registers, as with any late registration.

### `Compose.withRootOwner`

`withRootOwner(body, reactor?) -> body's results`

Creates a root owner, makes it the active one for `body`, and disposes it, newest first,
exactly once, when `body` returns **or** raises. `body` is called with the owner, and its
results are returned. A raise propagates unchanged; if a disposer also raises while
unwinding, both are reported and the body's failure comes first.

Use this form for an entry point with no ambient owner, such as a server main, boot module
or one-shot job. It combines owner creation, activation and guaranteed disposal.

```luau
local report = Compose.withRootOwner(function(owner)
    local pool = Compose.createPool { ... }   -- accepted: the root owner is active
    return measure(pool)
end)
-- the pool is destroyed here, whether `measure` returned or raised
```

Pass `reactor` to put the root in an existing scheduling domain: usually `runtime.reactor`,
so the root batches with the trees mounted under it. Omitted, the owner gets its own.

### `Compose.createRootOwner`

`createRootOwner(body, reactor?) -> RootScope`

Creates a root that stays open after `body` returns. The body runs with the owner active.
If it raises, Compose disposes the partly built root newest first and propagates the failure.

Returns `{ owner, dispose }`. The `dispose` field is `owner.dispose`. Use `owner` to activate
the scope for later work through `Compose.withOwner`.

```luau
local app = Compose.createRootOwner(function(owner)
    local connection = connect()                    -- released at shutdown
    runtime.mount(Hud, test.root)                   -- belongs to this root, not to the process root
end, runtime.reactor)

-- ... the process runs ...

app.dispose()   -- releases everything above, newest first
```

The two root APIs have fixed return types. `withRootOwner` returns the body's results and
closes the root. `createRootOwner` returns a scope that the caller must dispose.

`examples/root-scope.luau` runs both.

### `Compose.currentOwner`

`currentOwner() -> Owner?`

The active owner, or nil. For library code that needs to behave differently
inside and outside a tree. To carry that owner into a callback that runs later, prefer
[`Compose.bindOwner`](#composebindowner) over pairing this with `Compose.withOwner`.

### `Compose.cleanup`

`cleanup(value) -> dispose`

Registers teardown with the active owner. Accepts a function, or a table with a `destroy`
or `dispose` method. Raises when there is no active owner.

```luau
runtime.mount(function()
    local subscription = someService:subscribe(handler)
    Compose.cleanup(function()
        subscription:cancel()
    end)
    return Host.Frame {}
end, test.root)
```

Use [ComposeRoblox.cleanup](#composerobloxcleanup) for Roblox connections, threads and Instances.

### `Compose.custodyOf`

`custodyOf(node) -> "owned" | "adopted" | "borrowed"`

Whether Compose will destroy this node. Anything Compose has not seen is `"borrowed"`, and
borrowed nodes are never destroyed.

---

## Composition

### `Compose.createRuntime`

`createRuntime(host) -> Runtime`

Binds Compose to a host. It validates the host once at construction, so missing methods
fail before rendering starts.

A `Runtime` has:

| Member | Meaning |
| --- | --- |
| `host` | the host it renders to |
| `connect(node, event, handler)` | subscribes to an event on an existing node; returns the unsubscribe |
| `constructors` | string-keyed table of lazily cached constructors bound to this runtime; use `Host.Frame { ... }` |
| `create(kind)` | selects a constructor for a dynamic host kind; call it with props to build a node |
| `decorate(node, props)` | applies props to a node Compose did not create |
| `mount(component, target)` | mounts a one-node component; returns `(dispose, node)` |
| `mountFragment(fragment, target)` | mounts top-level sibling nodes and structural directives; returns `(dispose, staticRoots)` |
| `adopt(node)` | takes responsibility for destroying an existing node |
| `borrow(node)` | states that Compose must never destroy this node |
| `spring(source, options?)` | follows `source` with spring physics |
| `tween(source, options?)` | follows `source` along an easing curve; `seconds` is a number or a source of seconds sampled at each retarget |
| `timeline(options?)` | one owned clock many properties can read |

The `spring` and `tween` option tables both accept `reducedMotion`, a
[reduced motion policy](#reduced-motion).

Bind `local Host = runtime.constructors` once and use host-kind fields directly. Reading a field
lazily caches its constructor; calling it builds through this runtime's host and ownership rules:

```luau
local Host = runtime.constructors

local dispose, root = runtime.mount(function()
    return Host.Frame {
        Title = "Inventory",
        Label = function(use)
            return tostring(use(count)) .. " items"
        end,
        [Compose.event("Activated")] = function() ... end,

        Host.Text { Text = "a static child" },
        Compose.show(isOpen, Details),
    }
end, test.root)
```

`Host.Frame { ... }` is ordinary Luau: the single table argument permits omitting parentheses,
so it is exactly `Host.Frame({ ... })`. Use `runtime.create(className) { ... }` for a dynamic kind.

The core `Compose` module supplies reactive and ownership helpers; it has no host constructors.
An application can export its runtime's `constructors` table as its own `Compose` module and write
`Compose.Text { ... }` where that host supports `Text`. Require core separately as `ComposeCore`
when the component also needs core helpers. Each constructor table belongs to one runtime.

Props: string keys are properties, function values bind reactively, and the array part is
children. Two wrappers cover the cases where a function is ambiguous: `Compose.event` and
`Compose.static`.

`decorate` is for something that already exists: a mount target, a character, a layer
someone else owns. Bindings and subscriptions belong to the active owner; the node does
not. Each mentioned property replaces its previous binding after the first successful host write,
even when the replacement starts with the same value. The previous source stops writing that
property. Unmentioned properties and event subscriptions remain active. Attributes replace bindings
by attribute name, separately from properties.

Only the current binding clears a borrowed property's value when its owner disposes. Disposing an
older owner cannot clear a newer value. Disposing the replacement does not restore an older binding.
If the replacement's first write fails, the previous binding remains active. Applying several props
is not a transaction: a later failure does not restore bindings already replaced.

`connect` subscribes to an event on an existing node:

```luau
runtime.connect(character.Humanoid, "Died", onDied)
```

The subscription belongs to the active owner, so it is released when the subtree is. The
returned unsubscribe is optional to call and safe to call twice.

#### The custody of a mount target

`mount` and `mountFragment` do not change what a target's custody already is:

| Target | Called from | Custody after the mount | Destroyed with the tree? |
| --- | --- | --- | --- |
| a node Compose has never seen, or `borrow`ed | anywhere | `borrowed` | no |
| a node some tree `create`d | inside that mount | stays `owned` | yes, and what was mounted into it goes first |
| a node some tree `adopt`ed | inside that mount | stays `adopted` | yes, and what was mounted into it goes first |
| a node some tree `create`d or `adopt`ed | outside any mount | stays `owned` / `adopted` | yes, and every block mounted into it goes first, in reverse mount order |

The first row applies to a typical top-level `runtime.mount(App, test.root)`. The other rows
apply when a component owns a container and mounts additional content into it outside its props:

```luau
local group = Model { Name = "Entity" }

runtime.mountFragment(function()
    return { Label { Text = captionOf(entity) } }
end, group)

return group
```

`group` remains owned. Tree disposal releases the mounted block before destroying `group`.
Calling only the block's disposer removes its nodes and leaves `group` alive and owned.

Inside a mount, the active owner releases the block before its target, newest first.
**Outside any mount**, the target can still belong to an owner even though none is active.
Compose then attaches the block's disposal ordering to the target node:

```luau
local root = Compose.createOwner()
local stage = Compose.withOwner(root, function()
    return World { Name = "Stage" }
end)

local unmount = runtime.mount(Scene, stage)  -- no active owner here
```

Destroying `stage`, when `root` is disposed, disposes what was mounted into it first, in
reverse mount order, and then destroys the node. Calling `unmount` detaches that block and
leaves `stage` standing, still owned. Two blocks mounted into one target unwind newest
first, exactly as a single owner would have unwound them.

A target that is neither a table nor userdata is still refused with
`mount/target-not-a-node`.

`Compose.portal` is deliberately not part of this. A portal exists to reach a node someone
else manages, and its documented contract is that its target *becomes* borrowed, so a
portal into a node your own tree created demotes it and it will not be destroyed. Mount into
that node instead; portal to the layer you do not own.

### `Compose.labelOf`

`labelOf(node) -> string?`

The label a node was built under, `Part "Ground" { }`, or nil if it was built anonymously.

A label is Compose's own, recorded whether or not the host has any notion of a name, and it
is what a node calls itself in a diagnostic, in the profiler, and in
[`Compose.inspect.node`](#composeinspect). It is **not a key**: duplicates are legal, it never
affects ordering, and keyed collections still identify rows by their key function.

### `Compose.event`

`event(name) -> key`

Marks a props key as an event subscription. Unambiguous on every host, and required on
hosts that cannot tell events from properties at runtime.

```luau
Button { [Compose.event("Activated")] = function() ... end }
```

### `Compose.property`

`property(name) -> key`

Marks a props key as a property write, overriding host classification. For a member that
happens to look connectable but which you want to *write*.

### `Compose.group`

`group(names) -> key`

Binds several named properties from one body. The body returns one value per name, in
order, and each is written only when it differs from what this group last wrote there.

```luau
Part {
    [Compose.group { "Position", "Transparency", "Color" }] = function(use)
        local unit = use(state)
        return unit.position, unit.fade, unit.tint
    end,
}
```

One watch, one dependency set, one queue entry: instead of one of each per property.

**Group properties that change together.** One watch replaces several, but a change to any
dependency recomputes every value in the group. Shared dependencies can reduce scheduling work;
independent dependencies can cause unnecessary recomputation. Measure the actual workload using
the [benchmark protocol](benchmarks.md). Core CPU results do not establish native rendering or device performance.

Nothing is written until the body has returned every value, so a body that raises part-way
leaves the node as it was. On a borrowed node, exactly the declared names are cleared on
disposal, unless a later binding replaced that name. Replacing one group member leaves the other
members reactive; replacing the last member releases the group watch. A name the host classifies as an event raises `props/group-names-an-event`; a
body that returns the wrong number of values raises `props/group-arity`.

### `Attributes`

`Attributes = { name = value | source | use -> value }`

The one **reserved string key**. Its value is a table of attribute names to values, and each
one is written through the host's `render.setAttribute` rather than as a property.

```luau
Part {
    Attributes = {
        Tier = 3,
        Faction = faction,                    -- a cell: rewritten when it changes
        Label = function(use)
            return ("tier %d"):format(use(tier))
        end,
    },
}
```

Attributes follow the same rules as properties, through the same `bind`/`write-once` split:
a cell or a function binds reactively, anything else is written once, and
`Compose.static(value)` writes a function value literally. Three differences:

- **`nil` clears.** Setting an attribute to nil removes it, and that is also how a binding on
  a borrowed node is undone when its owner disposes.
- **Writes dedupe.** A recompute that produces the value already written reaches no host,
  which `Compose.group` does for properties and a plain property binding does not.
- **Names are checked first.** Every name in the table is validated before any of them is
  written, so a bad name leaves the node exactly as it was. Write order is the sorted name
  order, not the table's iteration order.

A name that is not a non-empty string raises `props/attribute-name`; a value the host will
not store raises `props/attribute-value` carrying the host's own reason in `detail`; an owned
node raises `props/child-under-attribute`; a non-table raises `props/attributes-not-a-table`;
and a host whose renderer omits `setAttribute` raises `host/no-attributes`.

`Attributes` is reserved only as a *bare* string key. On a host that genuinely has a property
of that name, `[Compose.property "Attributes"]` writes the property and is never reserved.

### `Compose.static`

`static(value) -> wrapped`

Marks a value as literal, so a function value is written to the property rather than called.

```luau
Widget { OnRequest = Compose.static(handler) }
```

---

## Structure

The structural builders return **directives** for the array part of a props table. Each
directive manages its own range of children through the host-neutral protocol. This section also
describes focus, pool and cache helpers.

### `Compose.show`

`show(condition, builder, fallback?) -> directive`

One subtree, present while `condition` is truthy.

```luau
Screen {
    Compose.show(isLoading, Spinner),
    Compose.show(hasError, ErrorPanel, EmptyState),
}
```

Rebuilt only when the condition's *truthiness* changes, so a counter inside a `show`
survives its condition going 1 → 2 → 3.

A branch may return a node or another directive directly. This keeps nested structure flat:

```luau
Compose.show(isOpen, function()
    return Compose.keyed { from = rows, key = keyOf, render = Row }
end)
```

Return `Compose.fragment(...)` when one branch contributes several sibling nodes.

### `Compose.presence`

`presence(condition, builder, options?) -> directive`

Retains a departing subtree until its exit completes. Without `exit`, it follows the same
execution path as `show`.

```luau
Frame {
    presence(isOpen, Panel, {
        exit = function(nodes)
            return runtime.timeline { duration = 0.2 }
        end,
    }),
}
```

The builder receives `phase` and may return one node or an array of nodes.
`phase.exiting` is a readable that stays true while the subtree is leaving.

`exit` is called once, with the nodes that are leaving, at the moment the condition goes
false. The subtree stays mounted and owned until the thing it returns reports `completed`,
and is then removed and disposed exactly once. Anything with a `completed` readable will do;
a timeline is the obvious one.

`presence` does not animate. Bindings in the retained subtree must read the exit progress
and convert it into host values.

**Re-entry reclaims.** If the condition becomes true during exit, Compose keeps the same subtree
and sets `phase.exiting` false. An animation bound to that value can reverse from its current
position. Compose neither rebuilds nor disposes the subtree. The abandoned exit cannot remove it later.
**Disposal wins.** An owner disposed mid-exit releases the leaving subtree immediately; a
subtree on its way out never outlives the tree that made it. An `exit` that raises, or that
returns something with no `completed`, releases the subtree and reports: a broken exit must
not become a leak.

### `Compose.switch`

`switch(source, branches, fallback?) -> directive`

One of several subtrees, chosen by key. A key with no branch mounts `fallback`, or nothing.
That is deliberately not an error: a key space that grows at runtime should degrade to
empty rather than crash a frame.

```luau
Compose.switch(screen, {
    menu = MainMenu,
    playing = Hud,
    dead = DeathScreen,
}, Loading)
```

Like `show`, each branch may return either a node or another directive.

### `Compose.keyed`

`keyed { from, key?, render } -> directive`

A collection whose rows survive reordering. `render(value, index, key)` receives the value
and the index as **readables**, so a row re-renders in place when its data or its position
changes.

```luau
keyed {
    from = players,
    key = function(player)
        return player.userId
    end,
    render = function(player, index)
        return Row {
            Name = function(use) return use(player).name end,
            LayoutOrder = index,
        }
    end,
}
```

The named `key` and `render` fields distinguish two callbacks that both accept a value.
Use the field names to keep identity selection separate from row construction.

`from` accepts a cell, formula or body. `key` defaults to the value itself. Supply a key
function when values are structural copies rather than stable objects.

Reordering the source **moves** the existing nodes rather than destroying and rebuilding
them, which is what keeps a text field focused, an animation running and a scroll position
still.

If a row factory raises, that row unwinds while reconciliation continues with independent
rows. Successful rows are mounted or reordered, then all factory failures are reported
together. The update is not a transaction: successful rows remain tracked for later reuse
or removal, and clearing the source releases all rows. Row indices still refer to positions
in the requested source list, including positions whose factory failed.

### `Compose.indexes`

`indexes(source, render) -> directive`

A collection keyed by position. The row at position 3 is always the same row; only its
value changes. Right for a window onto changing data, a log tail, a fixed set of slots,
and wrong when items have identity that must follow them around.

```luau
Compose.indexes(function(use)
    return use(logLines)
end, function(line, index)
    return Text { Text = function(use) return use(line) end }
end)
```

### `Compose.OrderedCollection`

`OrderedCollection { from, key, render, mode, viewport, layout, ... } -> directive`

Retains an ordered population in full or through a moving window. It computes row sizes,
grid wrapping and overscan. It can follow the newest message or preserve the reader's position
when earlier history loads.

```luau
OrderedCollection {
    from = messages,
    key = function(message)
        return message.id
    end,

    mode = "windowed",
    viewport = viewport,
    layout = { itemSize = 52 },
    overscan = 6,
    follow = "end",

    render = function(message, placement)
        return Row {
            Offset = function(use)
                return use(placement).offset
            end,
            Text = function(use)
                return use(message).body
            end,
        }
    end,
}
```

`mode` is explicit and has no threshold: `"all"` mounts everything, `"windowed"` mounts the
visible rows plus `overscan`. Population changes do not switch the retention policy.

`viewport` is a readable `{ offset, size }` in whatever unit your host measures in, and is
required by `"windowed"`. `render` receives the row's `placement`, a readable carrying its
`index`, `row`, `column`, `offset`, `size`, `crossOffset` and `crossSize`.

`layout` accepts a static options table, a cell/formula holding that table, or a body taking
`use` and returning it. Options are `kind` (`"list"` or `"grid"`), `columns`, `itemSize`, `gap`,
`crossSize` and `crossGap`. For example:

```luau
layout = function(use)
    local metrics = use(themeMetrics)
    return {
        kind = "grid",
        columns = math.max(1, math.floor(use(viewportWidth) / metrics.tileWidth)),
        itemSize = metrics.tileHeight,
        gap = metrics.spacing,
        crossSize = metrics.tileWidth,
        crossGap = metrics.spacing,
    }
end,
```

Changing resolved layout values updates placement, extent, controls and the retained window.
Keys present in both windows keep their nodes, owners and component state; keys leaving the
window dispose normally. In `"all"` mode every surviving key retains its state through reflow.
Static tables are construction-time options; publish changes through a readable or body.

`itemSize` is the fixed size for a fixed collection and the estimate for a
measured one; pass `measured`, a readable of key-to-size, to correct it as rows report their
real sizes. A grid row is as tall as its tallest item. Measurements remain authoritative by key
through reflow. If a width or theme change invalidates them, publish cleared or updated
measurements with the layout change in one batch.

**It does not scroll or measure the host.** It computes placement and publishes requested
scroll changes through `status.desiredOffset`. The adapter reads scroll position, measures rows
and moves the viewport. Supply `status`. Have the adapter apply its requested offset and publish
the actual offset through `viewport`.

Reflow anchors the first visible key, excluding overscan, preserving its offset relative to
the viewport start. The requested offset is clamped to the new scroll bounds. End-following
takes precedence; an explicit viewport offset change takes precedence over key anchoring.
If the anchor key disappears, the current offset is preserved subject to those bounds.
The mounted window immediately covers the requested offset. The request remains pending
while the reported offset is unchanged, so repeated reflows accumulate without losing the
anchor. Reporting the requested offset acknowledges it; reporting a different offset treats
that as an explicit scroll. No host scroll is performed by Compose.

`status` is a cell. The collection writes it **only when one of its fields differs**, not on every
pass. A scroll that keeps the retained range, the geometry and the measurements writes nothing.
An adapter that watches `status` therefore stays asleep on a frame with nothing to apply.
`controls` is a table the collection fills with `offsetOf(index, align, size)`, `indexOfKey(key)`
and `placementOf(index)`, to drive your own viewport.

`placementOf(index)` returns a frozen placement. It returns the same table for the same index
until the geometry or a measurement moves that index. A retained row's placement readable holds
the same table, so a repaint that changes nothing allocates nothing.

`controls` has no `slotAt(offset)` and no `boundaryBetween(a, b)`. Both values derive from
`placementOf`, so core does not carry them. The boundary before slot `index` is
`placementOf(index).offset`. The boundary after that slot is `.offset + .size`. To find the slot
at an offset, run a binary search over `placementOf`. The offset of a placement rises with the
index, and each probe costs one tree descent:

```luau
local function slotAt(controls, total, offset)
    local low, high = 1, total
    while low < high do
        local middle = (low + high) // 2
        local placement = controls.placementOf(middle)
        if offset < placement.offset + placement.size then
            high = middle
        else
            low = middle + 1
        end
    end
    return low
end
```

`follow = "end"` keeps the view at the newest item. It disengages when the reader scrolls
away, but stays active when new content arrives.

Scrolling costs the retained slice, not the population: the range is a division for uniform
rows and a tree descent otherwise. Work proportional to the whole list happens when the list
changes, which is detected by identity, or measured geometry is rebuilt for changed layout
values. Returning an equivalent layout table does not rebuild geometry.

A change to one row's measured size is incremental. Publishing a new `measured` table walks the
keys of that table to find what differs. Each size that did change costs one row maximum and one
prefix-tree update. That is a tree descent, not a rebuild. Compose rebuilds the geometry only when
the list identity or a layout value changes.

### `Compose.SpatialCollection`

`SpatialCollection { from, key, position, origin, tiers, render, ... } -> directive`

A world population retained by relevance rather than by count, for 2D or 3D.

```luau
SpatialCollection {
    from = combatants,
    key = function(unit)
        return unit.id
    end,
    position = function(unit)
        return unit.x, unit.y, unit.z
    end,

    origin = cameraPosition,
    cellSize = 64,
    hysteresis = 24,
    tiers = {
        { name = "full", radius = 80 },
        { name = "simplified", radius = 180 },
        { name = "marker", radius = 300 },
    },
    budget = { mountsPerFrame = 8 },

    render = function(unit, representation)
        return Combatant {
            unit = unit,
            tier = function(use)
                return use(representation).name
            end,
        }
    end,
}
```

It decides **which entities have a representation and at what detail**. It does not place
them: the mounted item owns its own transform, so a moving entity keeps its nodes and updates
its own bindings rather than being rebuilt.

`tiers` are listed nearest first by ascending radius; past the outermost radius an entity is
not retained. `render` receives a `representation` readable carrying `tier`, `name`,
`distance` and `pinned`. `position` returns two or three coordinates: a 2D world simply does
not return a third.

`hysteresis` widens a boundary **in the direction of leaving only**, so an entity oscillating
on a tier radius settles instead of mounting and disposing on alternate frames, while an
entity that has genuinely come closer is promoted immediately.

`budget.mountsPerFrame` admits newly relevant entities over successive frames, nearest and
most detailed first, so arriving in a dense area fills the scene in rather than stalling on
one frame. It needs the host `frames` capability, and it subscribes only while there is a
backlog. Departures are never budgeted: keeping something that should be gone is a
correctness problem, not a scheduling one.

`pinned` is a readable set of keys that are always retained, whatever the distance: their
tier is still what distance earns, so a pinned objective far away is a marker rather than a
full model. `importance` multiplies one entity's radii, so a boss stays relevant further out
without needing a tier of its own.

After every pass, it writes `total`, `retained`, `queried`, `pending`, `perTier` and `cells`
to the `status` cell. Compare `queried` with `total` to see how much of the population the
spatial index excluded from the query.

On Roblox this complements instance streaming and SLIM rather than restaging them. The engine
already decides what is replicated and how distant models are drawn; what it cannot infer is
which entities deserve a nameplate, audio or a party marker, and how much construction one
frame may do. Ordinary geometry should still be streamed geometry.

### `Compose.LayerStack`

`LayerStack(options) -> directive`

Retains stable keyed layers from bottom to top. Each receives a readable state with `index`,
`depthFromTop`, `top` and `covered`, so visibility and input policy update without rebuilding
the covered scene. `retention = "top"` mounts only the top layer; the default `"all"`
preserves covered state.

### `Compose.MountBudget`

`MountBudget(options) -> directive`

Admits newly present keyed items over frames, ordered by optional numeric `priority`, while
removing departures immediately. `mountsPerFrame` is required. A backlog takes one frame
subscription and releases it when drained; `status` reports `total`, `mounted` and `pending`.
`SpatialCollection` shares the same admission engine.

### `Compose.createFocusScope`

`createFocusScope(options) -> FocusScope`

Creates an owner-bound, host-neutral focus policy over stable enabled keys. The controller
exposes `current`, `focus`, `clear`, `first`, `last`, `next`, `previous`, `move` and
`isFocused`. Pass `position` for directional movement. An adapter watches `current` and
applies native focus, so noninteractive collections pay nothing.

### `Compose.createPool`

`createPool(options) -> Pool`

Creates an owner-bound opt-in pool for expensive resources. `acquire` returns
`{ value, release }`; release is idempotent, calls `reset`, and retains at most
the required finite `maxRetained`. Owner disposal destroys idle and checked-out resources
exactly once. Compose nodes are never pooled automatically because structural identity and
cleanup remain explicit.

Complete contracts and canonical combinations are in
[`ownership.md`](ownership.md).

### `Compose.createKeyedCache`

`createKeyedCache(options) -> Cache`

Creates an owner-bound cache with arbitrary keys and a finite `maxRetained` limit.
When full, it evicts the least-recently-used entry.

- `get(key)` builds on a miss. On a hit, it returns the retained value and marks it most-recently-used.
- `peek(key)` reads without building or changing recency.
- `evict(key)` destroys one retained entry. It does nothing if the key is absent.
- `size()` returns the retained count.
- `keys()` returns retained keys, least-recently-used first.
- Optional `touch(key, value)` observes every hit or miss without affecting retention.

Owner disposal destroys each retained value exactly once, newest-recency-first. Cache values
are not leases: callers hold references only while the cache retains them. Adding a newer
key can evict a value that a caller still references.

This is the primitive for expensive, identity-keyed builds a host must not repeat on every
use: e.g. one mesh per distinct gear piece, reused across every character that equips it,
instead of rebuilt per join.

### `Compose.fragment`

`fragment(builder) -> directive`

Several nodes where one child is expected, without wrapping them in a container the layout
did not ask for.

### `Compose.portal`

`portal(target, builder) -> directive`

A subtree that lives elsewhere in the host tree: tooltips, modals, world-space markers.
Its own slot stays empty; its nodes go into `target`. Its lifetime is unchanged: disposing
the component that wrote the portal removes exactly what the portal added, and leaves
`target` standing.

### `Compose.boundary`

`boundary(builder, fallback) -> directive`

A subtree that can fail without taking the screen with it. `fallback(failure, retry)`
renders the failure.

```luau
Compose.boundary(Inventory, function(failure, retry)
    return ErrorPanel {
        Text = "Inventory failed: " .. tostring(failure),
        [Compose.event("Activated")] = retry,
    }
end)
```

Catches failures in its builder and in watches beneath it. These include property bindings,
structural updates and user watches. It does not catch a failure in its own fallback.
See [failure cleanup](ownership.md#failure-unwinds-completely) for resource-unwind guarantees.

---

## Context

### `Compose.createSharedResource`

`createSharedResource(factory) -> acquire`

One expensive thing, many consumers, released when the last one goes.

```luau
local useCatalogue = Compose.createSharedResource(function()
    local catalogue = buildCatalogue()
    return catalogue, function()
        catalogue:destroy()
    end
end)

-- In a component:
local catalogue = useCatalogue()
```

Each call acquires a reference and registers its release with the active owner. Releasing
the last reference disposes the resource. A later acquisition builds a fresh resource.

**The factory runs under the resource's own owner, never the caller's.** If A's factory
acquires B, A retains that reference to B. The first departing consumer of A releases neither
resource. The last releases both, innermost last, exactly once. A failed factory releases
its partial acquisitions and caches nothing.

`acquire.detached()` returns the value **and** its release, for a caller with no owner and a
lifetime of its own to manage. Calling that release twice is safe; forgetting it holds the
resource for the life of the process, which is why it is the form you have to ask for.

### `Compose.easing`

A frozen table of easing functions: `linear`, and `in`/`out`/`inOut` variants of `Quad`,
`Cubic`, `Quart`, `Quint`, `Sine`, `Expo`, `Circ`, `Back`, `Elastic`, and `Bounce`. Each
takes normalized progress in `[0, 1]`. `Back` and `Elastic` variants can return values
outside that range to produce overshoot.

```luau
runtime.tween(opacity, { seconds = 0.25, ease = Compose.easing.outQuad })
```

### Reduced motion

`spring` and `tween` both accept `reducedMotion`. The policy is a cell, a formula or a body that
reads a boolean. It is a source, not a plain boolean, because the setting changes while the
application runs. A value that is neither raises `animation/bad-reduced-motion`.

```luau
local calm = Compose.cell(GuiService.ReducedMotionEnabled)
runtime.spring(health, { period = 0.3, reducedMotion = calm })
```

While the policy reads true, the animated value reaches each new target on the frame that
retargets it. Compose interpolates nothing, holds no frame listener, and writes once per change
instead of once per frame. If the policy turns true in mid-flight, the value lands on its current
target at once and the integrator settles. A policy that turns false again therefore starts from
rest, not from a stale velocity. An absent or false policy leaves the animation unchanged.

Compose reads the policy; it does not discover the setting. Core cannot read an accessibility
preference. Read the preference in your application and write it into a cell.

### `Compose.registerCodec`

`registerCodec(typeName, codec) -> ()`

Teaches Compose to animate a type without core ever naming it. A codec has `arity`,
`encode(value, out)`, `decode(components)`, and an optional `normalise(components)`.

```luau
Compose.registerCodec("Colour", {
    arity = 3,
    encode = function(value, out) out[1], out[2], out[3] = value.r, value.g, value.b end,
    decode = function(c) return Colour.new(c[1], c[2], c[3]) end,
    normalise = function(c)
        c[1], c[2], c[3] = math.clamp(c[1], 0, 1), math.clamp(c[2], 0, 1), math.clamp(c[3], 0, 1)
    end,
})
```

`encode` writes into a caller-owned buffer because an animation encodes on every frame, and
a per-frame allocation is a per-frame collection. Core registers exactly one codec:
`number`. `ComposeRoblox` registers the Roblox datatypes.

### `Compose.registeredCodecs`

`registeredCodecs() -> { string }`

Every registered type name, sorted.

### `Compose.createSpringState`

`createSpringState(position, arity) -> State`

A spring state at rest at `position`. The integrator is pure and public so you can drive it
yourself, or test against it.

### `Compose.stepSpring`

`stepSpring(state, target, delta, period, damping) -> simulatedSeconds`

Advances `state` towards `target`, in place. Integrates at a fixed 120 Hz internally, so the
same animation produces the same curve at 30fps and 240fps; a very large delta is clamped
rather than simulated. Returns the seconds actually simulated.

### `Compose.springAtRest`

`springAtRest(state, target, reference, tolerance) -> boolean`

Whether the spring has settled close enough to stop simulating. "Close enough" is relative
to the distance it set out to travel, so a spring moving a pixel and one moving a thousand
settle at the same perceived moment.

### `Compose.springCoefficients`

`springCoefficients(period, damping) -> (stiffness, drag)`

The coefficients behind the model, for anyone integrating it themselves.

---

## Diagnostics

### `Compose.formatDiagnostic`

`formatDiagnostic(code, summary, fields?) -> string`

Formats a Compose-shaped diagnostic without raising it. Adapters use it so their errors
read like the rest of the library's. See [`api.md`](api.md).

### `Compose.parseDiagnostic`

`parseDiagnostic(message) -> Diagnostic?`

Parses a Compose diagnostic into `{ code, summary, fields }`. Use this inverse of
`formatDiagnostic` instead of maintaining a separate parser for thrown messages.

```luau
local ok, err = pcall(build)
if not ok then
    local diagnostic = Compose.parseDiagnostic(tostring(err))
    if diagnostic ~= nil and diagnostic.code == "owner/no-active-owner" then
        -- diagnostic.fields.fix is the one-line remedy the message carried
    end
end
```

This pure function reads a string. It does not intercept, change or suppress the original
failure. Parsing adds no work to code that does not call it.

Returns nil for non-Compose diagnostics. It accepts a source-location prefix, including the
prefix produced by `error` at a non-zero level and often returned through `pcall`.

### `Compose.setWorkCounters`

`setWorkCounters(enabled) -> ()`

Turns work counting on. Off by default and costing one boolean read when off, so a timing
run measures the runtime rather than the instrumentation.

### `Compose.readWorkCounters`

`readWorkCounters() -> WorkCounters`

A snapshot: cell writes, writes suppressed, notifications, formula recomputations,
recomputations suppressed, watch runs, watch schedules, schedules coalesced, drains, and
continuation passes.

```luau
Compose.setWorkCounters(true)
Compose.resetWorkCounters()
runtime:batch(function()
    for value = 1, 10 do count:set(value) end
end)
Compose.readWorkCounters().watchRuns   --> 1
```

### `Compose.resetWorkCounters`

`resetWorkCounters() -> ()`

Zeroes every counter.

### `Compose.setYieldChecking`

`setYieldChecking(enabled) -> ()`

Runs every user function on a fresh coroutine so a yield inside reactive code is reported
at the point of the yield. Costs a coroutine per user call: for development and tests, not
for a shipped frame loop.

### `Compose.profile`

`profile.start(now, options?) -> ()`
`profile.stop() -> ProfileReport`
`profile.label(node, name) -> ()`
`profile.active() -> boolean`
`profile.format(report, limit?) -> string`
`profile.data(report) -> table`

Records the work caused by each reactive write: cell changes, formula recomputations,
watch runs and host property writes. The report uses the graph labels you provide.

The profiler is off until started. Its hooks share the work-counter branch and add no
fields to nodes. **Labels are recorded only while the profiler runs.** Start it before
building the screen to capture those labels. Earlier nodes still report work and fan-out
under synthetic names such as `cell#12`.

`start` takes the clock, because core does not read time on its own: pass whatever your
host uses to measure elapsed seconds. `options` bounds capture -- `maxNodes` (default
4096) and `maxDrains` (default 256). Capture is aggregate rather than a log, so nothing
grows with the number of writes, and **no application value is ever recorded**: the report
holds counts, ids, and the labels you supplied.

`stop` returns the report and drops everything the recorder held. `format` renders it
deterministically for a terminal; `data` returns the same thing as plain tables ready for
JSON. A failure inside the recorder cannot reach the application: it marks itself broken,
stops recording, and the report says the numbers are incomplete.

```luau
Compose.profile.start(elapsedSeconds)

local health = Compose.cell(100)
Compose.profile.label(health, "player.health")

local dispose = runtime.mount(App, root)
-- ... drive a few seconds of the thing you are debugging ...

print(Compose.profile.format(Compose.profile.stop()))
```

```
compose profile: 4.017 s, 63 node(s) tracked

  writes 480 (12 suppressed) | recomputations 480 (61 published) | watch runs 61 | host writes 61
  schedules 61 (0 coalesced)

hottest:
  player.health                      480 writes, 12 suppressed, fan-out 1
      -> healthPercent               x480
  healthPercent                      480 recomputes (61 published)
      -> Frame.Size                  x61
  Frame.Size                         61 runs, 61 host writes
```

The report lists total work and the busiest nodes. Arrows identify downstream work caused by each node.

### `Compose.inspect`

`inspect.start(options?) -> ()`
`inspect.stop() -> ()`
`inspect.active() -> boolean`
`inspect.label(owner, name) -> ()`
`inspect.snapshot() -> InspectReport`
`inspect.owner(owner) -> InspectOwner?`
`inspect.owned(owner) -> InspectOwnedCounts?`
`inspect.node(node) -> InspectNode`
`inspect.format(report) -> string`
`inspect.data(report) -> table`

Reports node custody, owners and their retained resources to explain why a resource remains alive.

```luau
Compose.inspect.start()
local dispose = runtime.mount(App, root)
-- ... the thing you expected to be gone is not ...
print(Compose.inspect.format(Compose.inspect.snapshot()))
print(Compose.inspect.node(suspiciousNode).because)
```

```
compose inspect: 1 outstanding mount(s), 402 node(s) with recorded custody, 0 pending

mounts:
  Battle  holding 1
    tree: 401 nodes owned, 1 adopted, 0 borrowed, 60 watches, 0 cleanups, 41 owners
    1 child owner
    owner#2  holding 42
      1 owned node, 40 child owners
```

`inspect.node(node).because` describes the ownership relationship in a sentence.

Off until started, and off means no field on any owner or node, no label, and no reference
held anywhere. The cost of that is the same rule [`Compose.profile`](#composeprofile) has:
**an owner built before `start` reports its total but not its breakdown**, and the report
says which it is rather than reporting zeroes as though they were measurements.

`options` bounds capture: `maxOwners` (default 4096) and `maxNodes` (default 16384). Every
table it keeps is weakly keyed, so inspecting something never keeps it alive, and `stop`
drops all of it. No application value is ever recorded.

**`report.trackedNodes` counts nodes across the process; do not assert per-test deltas on it.**
It counts a weak-keyed table of nodes whose custody Compose recorded. The count falls when
the collector reclaims entries, on its own schedule. It can include nodes from unrelated
tests that the collector has not yet reclaimed. Identical operations can therefore produce
different deltas. Use it only as a rough diagnostic count.

Use `inspect.owned(owner)` for exact owner-scoped deltas. It returns `{ ownedNodes, borrowedNodes }`.
`ownedNodes` counts nodes the owner created or adopted and will destroy on disposal.
`borrowedNodes` counts borrowed nodes while the owner holds them.

These counts decrease immediately when disposal calls `forget`; they do not wait for collection.
Other owners and allocation churn do not affect them:

```luau
Compose.inspect.start()
local owner = Compose.createOwner()
Compose.withOwner(owner, function()
	runtime.constructors.Frame { Name = "Kept" }
end)

Compose.inspect.owned(owner) --> { ownedNodes = 1, borrowedNodes = 0 }
```

Like `inspect.owner`, it returns `nil` while the inspector is not running.

See [ownership.md](ownership.md) for how to read the output and what it cannot tell you.

### `Compose.outstandingMounts`

`outstandingMounts() -> number`

How many top-level mounts have not been disposed. A test asserting this is zero is a leak
check.

---

## `compose-test-scene`

### `TestScene.create`

`create() -> TestScene`

An isolated, deterministic scene with a host adapter and inspection helpers. Its nodes are frozen
empty tables, so core code that reaches around the protocol fails immediately rather than working by accident.

```luau
local test = TestScene.create()
local runtime = Compose.createRuntime(test.adapter)

test.declareEvent("Button", "Activated")
test.dispatch(button, "Activated")
test.step(1 / 60)
test.failNext("insertChild")

test.counts().setProperty
test.liveNodes()
test.serialize(test.root)
```

Full surface: `adapter`, `root`, `makeNode`, `kindOf`, `propertyOf`, `attributeOf`,
`nameOf`, `childrenOf`, `parentOf`, `isAlive`, `handlerCount`, `declareEvent`, `dispatch`, `poke`,
`step`, `now`, `failNext`, `clearFailures`, `counts`, `resetCounts`, `liveNodes`,
`liveSubscriptions`, `leaked`, and `serialize`.

It stores attributes for `string`, `number`, `boolean` and `nil`, and refuses anything else
with a reason. `failNext("setAttribute")` is the exception to `failNext`'s usual meaning: it
makes the next `setAttribute` *report* a refusal rather than raise, because that is what the
protocol asks that verb to do.

### `RobloxEmulator.create`

`create() -> Emulator`

A headless emulation of the Roblox `Instance` model, required separately from
`src/test-scene/roblox`. Where `TestScene` gives opaque nodes, this gives **Instance-shaped**
ones: dot-accessible properties with per-class defaults, methods, signals and an inheritance
chain. This lets tests exercise components that access instance members through references.
It runs without the Roblox engine.

```luau
local RobloxEmulator = require(script.Parent.Parent["test-scene"].roblox)

local emulator = RobloxEmulator.create()
local runtime = Compose.createRuntime(emulator.adapter)

local rig = emulator.createInstance("Model", {
    Name = "Rig",
    emulator.createInstance("Humanoid", { emulator.createInstance("Animator") }),
    Parent = emulator.root,
})

rig:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
emulator.fire(button, "Activated")
emulator.step(1 / 60)
emulator.failNext("createNode")
emulator.log()
```

Full surface: `engine`, `adapter`, `render`, `root`, `createInstance`, `defineClass`,
`newSignal`, `step`, `now`, `childrenOf`, `parentOf`, `propertyOf`, `attributeOf`,
`isAlive`, `liveObjects`, `liveConnections`, `serialize`, `log`, `clearLog`, `poke`, `fire`,
`failNext`, and `clearFailures`.

`adapter` uses `ComposeRoblox.createHost(emulator.engine)`. Its `render` wraps that adapter's
renderer to count operations, log them and inject failures. Tests therefore exercise
`src/roblox/host.luau` itself. Like that adapter, the emulator has no `moveChild`.

On each node: `.Name`, `.Parent`, `.ClassName`, every property its class declares,
`:Destroy`, `:GetChildren`, `:GetDescendants`, `:FindFirstChild(name, recursive?)`,
`:FindFirstChildOfClass`, `:IsA`, `:IsDescendantOf`, `:IsAncestorOf`, `:SetAttribute`,
`:GetAttribute`, `:GetAttributes`, `:GetAttributeChangedSignal`,
`:GetPropertyChangedSignal`, the `ChildAdded`, `ChildRemoved` and `Destroying` signals, and
the class's own events. `defineClass(name, spec)` adds a class the fixture does not ship,
inheriting the defaults, events and methods of a `super` that is already defined.

`log()` returns the ordered render operations, `createNode`, `setProperty`, `setAttribute`,
`clearProperty`, `insertChild`, `removeChild`, `destroyNode`, `setName`, each with the node
and its class name. `failNext(operation, times?)` makes those verbs raise, except
`setAttribute`, which reports a refusal instead, exactly as `TestScene` does.

See [emulator limits](roblox.md#what-the-emulator-cannot-check) for behaviour it cannot test.
Those claims require checks in the actual engine.

---

## `compose-roblox`

### `ComposeRoblox.createRuntime`

`createRuntime(engine?) -> Runtime`

A runtime bound to the Roblox host. The usual entry point. Called with no argument inside
Roblox; pass an engine to run the adapter anywhere else.

```luau
local runtime = ComposeRoblox.createRuntime()
local dispose = runtime.mount(Hud, playerGui)
```

### `ComposeRoblox.createHost`

`createHost(engine?) -> Host`

The host itself, for passing to `Compose.createRuntime` directly, or for reaching a
capability, `host.observation.observeProperty`, say, without a runtime.

### `ComposeRoblox.animatableTypes`

`animatableTypes(engine?) -> { string }`

Every Roblox datatype this engine can animate, sorted. Currently `CFrame`, `Color3`,
`UDim`, `UDim2`, `Vector2`, `Vector3`: plus `number` from the core.

### `ComposeRoblox.cleanup`

`cleanup(value) -> dispose`

`Compose.cleanup`, extended for Roblox: an `RBXScriptConnection` is disconnected, a thread
is cancelled, an `Instance` is destroyed, and a table with `Disconnect` or `disconnect` is
disconnected. Everything else falls through to the core.

Passing an Instance is an ownership statement. For something you did not create,
`runtime.adopt` says it more clearly; for something you must *not* destroy, say nothing:
borrowed is the default.

### `ComposeRoblox.createCleanup`

`createCleanup(typeName?) -> cleanup`

A `cleanup` bound to a particular way of naming types. Inside Roblox the default is the
global `typeof`, which is what you want; a test engine supplies its own so the adapter's
real branches are the ones being exercised.

### `ComposeRoblox.createViewport`

`createViewport(camera, engine?, options?) -> (Compose.Readable<{ width, height }>, Compose.Readable<boolean>)`

A reactive `{ width, height }` kept current from
`camera.ViewportSize` via `GetPropertyChangedSignal`, released on owner disposal. Hand the
first result to a layout formula. `camera` is anything with
a `ViewportSize` property shaped like a Vector2: ordinarily `workspace.CurrentCamera`.

A camera can report a placeholder before the client viewport exists. A size below
`minimumSide` on either axis, or with non-finite dimensions, is treated as unknown.
The source ignores invalid updates and retains its last valid size. Readiness starts false
until the first valid size arrives, then stays true. Before any valid size arrives, the
source returns the fallback. Consumers never receive nil.

`options` is `{ minimumSide: number?, fallback: { width, height }? }`, defaulting to `100`
and `{ width = 1280, height = 720 }`. Read readiness when the difference matters, hold a
first layout, or a fade-in, and ignore it when it does not.

### `ComposeRoblox.usableViewportSize`

`usableViewportSize(size, minimumSide?) -> boolean`

The rule `createViewport` holds to, on its own, for an application that owns its own
observation wiring: true when `size` is a pair of finite numbers at or above `minimumSide`
on both axes, which defaults to `100`.

### `ComposeRoblox.preferredInput`

`preferredInput(inputService?, engine?) -> Cell<PreferredInputClass>`

The reactive input class for `UserInputService.PreferredInput`: `Touch`, `KeyboardAndMouse`, or
`Gamepad`. It follows property changes for the current owner lifetime. The optional arguments make
adapter tests explicit; ordinary Roblox use is simply `ComposeRoblox.preferredInput()`.

### `ComposeRoblox.preferredInputSpec`

`preferredInputSpec(preferred) -> PreferredInputSpec`

The pure counterpart for style selection. It maps a `PreferredInput` enum value to its input class
and stable token: `touch`, `keyboard-and-mouse`, or `gamepad`.

---

## Authoring project trees

`compose-authoring` runs at build and edit time, never inside a mount. The package guide is
[`../authoring/README.md`](../authoring/README.md); this section owns the project-tree generator.

### `Author.set`

`set(options) -> EntrySet`

Wraps an authored entry array as a semantic entry set named by `name`, keyed by `idKey`, and
optionally grouped by `roleKey`. The set answers `byId` and `byRole` deterministically.

```luau
local props = Author.set { name = "props", idKey = "id", entries = { { id = "torch" } } }
```

### `Author.validate`

`validate(set, rules) -> (boolean, { Violation })`

Checks a set against `idPattern`, `unique`, `required`, and `refs`, and returns the violations in
entry order and then rule order. Each violation is `{ setName, entryId, rule, detail }`.

```luau
local ok, violations = Author.validate(props, { idPattern = "^%l[%l%d%-]*$", unique = true })
```

### `Author.digest`

`digest(set) -> string`

Computes a content digest of a set: 16 lowercase hex characters, stable across key order and entry
order. The declaration name, `idKey`, and `roleKey` are part of it, so a rename changes the digest.
This is change detection, not cryptography.

### `Author.coverage`

`coverage(set, keys) -> Coverage`

Reports authored ids and roles missing from a registry key list. Use it to find entries
without handlers before runtime.

### `Author.bake`

`bake` holds the emitters: `attributePlan`, `layoutSheet`, `registryModule`, and `dataModule`. The package
guide [`../authoring/README.md`](../authoring/README.md) states what each one produces and what the
package refuses to do.

### `Author.projectTree`

`projectTree(plan) -> { documents, order, manifest }`

Turns one declarative mount plan into a project document per target, plus a manifest of the
mounted paths and a digest of that manifest. The function is pure. It reads no files, so a
caller supplies the source facts as data and gets the same result for the same plan.

```luau
local Author = require(path.to.compose.authoring)

local result = Author.projectTree {
    mounts = {
        { at = { "ReplicatedStorage" }, name = "Shared", path = "source/shared" },
        { at = { "ServerScriptService" }, name = "Boot", path = "source/server/boot.luau" },
    },
    variants = {
        { name = "release", excludePrefixes = { "source/fixtures/" } },
    },
    targets = {
        { name = "alpha", document = "build/alpha.project.json" },
        {
            name = "beta",
            document = "build/beta.project.json",
            variant = "release",
            identity = { at = { "ReplicatedStorage" }, name = "BuildIdentity", values = { commit = "abc123" } },
        },
    },
}
```

A `Mount` names its tree location as `at`, an array of ancestor names, then `name`, and then a
source `path`, a `className`, or both. It may also carry `properties`, `attributes`,
`ignoreUnknownInstances`, `siblings`, and `requires`. A missing ancestor becomes a `Folder`.

A `properties`, `attributes`, or `Identity.values` entry, and a `Variant.properties` entry, each
take a `RojoValue`: a string, a finite number, a boolean, an array of finite numbers, or a table
with exactly one string key whose value is itself a `RojoValue`. The tagged-table shape names a
Rojo type, so `{ Enum = 2 }`, `{ Color3 = { 1, 0, 0 } }`, and `{ CFrame = { 0, 0, 0 } }` are each
one `RojoValue`, and nesting composes them freely. A table with two or more keys, or a non-finite
number anywhere in the shape, is refused.

A `Target` names the document to write and may take a `variant` and an `identity`. Two targets
share one mount plan and still differ in their stamped identity, so a build identity is an
injected value rather than a second generator.

A `Variant` is data: `excludeExact`, `excludePrefixes`, and `excludeSuffixes` drop source paths,
`mounts` adds mounts, and `properties` merges properties into a named tree location. `excludeAt`
drops a mount by its tree location, `at` plus `name`, and every mount nested under that location,
which reaches a mount that carries a class and no path. A mount in `mounts` may set `replace` to
overwrite the base mount already at its `at` plus `name` location instead of raising a duplicate,
and refuses when no base mount stands there. The base plan is never changed, so one target taking
a variant leaves the others alone.

The generator refuses a plan rather than emitting a tree that breaks at runtime.

- **Sibling closure.** A mount that declares `siblings` needs every one of those source paths
  mounted under the same parent, because a mounted module reaches its script parent siblings at
  runtime.
- **Bare relative requires.** Under the default `requirePolicy` of `alias-only`, a declared
  request beginning with `./` or `../` is refused, because a relative request breaks when the tree
  places the module somewhere else. Set `requirePolicy` to `any` to allow them.
- **Collisions.** Two mounts at one tree location, two targets with one name, an identity that
  lands on an occupied location, an unknown variant, a mount with neither path nor className, and
  a value that cannot become a property are each refused.

`manifest.digest` is 16 lowercase hex characters over the manifest, which makes it change
detection rather than cryptography.
