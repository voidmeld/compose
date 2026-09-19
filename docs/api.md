# API reference

Every public export appears here with a runnable example. `tools/check-public-surface.luau` checks
the exported APIs against this page, because an undocumented API is hard to use and a missing API is misleading.

Examples assume:

```luau
local Compose = require(path.to.compose.core)
local TestHost = require(path.to.compose["test-host"])

local host = TestHost.create()
local runtime = Compose.createRuntime(host.host)
local create = runtime.create
```

Working versions of most of them are under [`../examples`](../examples), and every
behaviour claimed here is asserted somewhere in [`../tests`](../tests).

---

## Reactive state

Two things hold a value, and one function reads them. `use` is handed to every reactive
body, a formula, a watch, a bound property, the source of a structural directive, and
reading through it is what records a dependency. Outside a body there is no `use` in
scope, so an untracked read is something you write on purpose with `:peek()` rather than
something you get by forgetting.

### `Compose.cell`

`cell(initial, equals?) -> Cell`

The only place a value enters the graph. `initial` may be a value or a thunk, which is not
called until the first read or write.

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

A cell whose module-scope life is stated in the constructor. A deliberate process-wide
singleton, an exported cross-module reactive API, a dev-time override, is a legitimate
shape, but written as `cell` it is indistinguishable from a leak. `sharedCell` says the
missing owner is the design: no owner is required, and disposal is explicitly not expected.

```luau
-- module scope is the point
local presses = Compose.sharedCell(0)

return { presses = presses }
```

At runtime it differs from `cell` in nothing but the constructor name and an identity flag
on its metatable: same behaviour, same memory, same fast paths, and diagnostics name it
what it is: a cell. `Compose.cell` also remains valid at module scope; `sharedCell` is
the stated-intent form the consumer lint recognises, not a new capability.

### `Compose.formula`

`formula(body, equals?) -> Formula`

A cached derivation. `body` receives `use` and must read every dependency through it.

```luau
local percent = Compose.formula(function(use)
    return use(health) / 100
end)

percent:peek()  --> 0.81
```

Lazy: the body does not run until something reads it. Cached: it reruns only when a
dependency actually moved. A formula that reruns to an equal value publishes no change,
so the cascade stops there rather than at every leaf.

### `Compose.watch`

`watch(body, label?) -> dispose`

Runs `body` now, and again when something it read changes. Belongs to whatever is
currently mounting, and refuses outside a mount: a watch's lifetime is its owner's, and
one with no owner has no defined end.

```luau
Compose.watch(function(use)
    print(use(percent))
end, "health readout")
```

The dispose is returned for the rare case you want to end it early. Ignoring it is safe
and usual: nothing needs to hold it for the watch to keep running, and disposing the owner
ends it deterministically.

Outside a mount, use `owner.watch(body, label?)` with an explicit owner, or
`runtime:watch(body, label?)`, which falls back to the runtime's own owner. The optional
label names this otherwise-handleless watch in a running [`Compose.profile`](#composeprofile)
capture; it is not retained when the profiler is off.

### `Compose.accumulator`

`accumulator { from, reduce, initial?, equals? } -> Readable`

Event-merge with the self-write inside: tracks one readable source, and on each of its
changes runs `reduce(previous, event)` to produce its own readable state: history the
event source does not carry.

```luau
local timings = Compose.accumulator {
    from = castFired,                       -- a cell or formula; each change is one event
    reduce = function(previous, event)      -- merge one event into the running state
        return withCast(previous, event)
    end,
    initial = {},                           -- the state before any event
}
```

Written by hand this is a cell plus a watch that peeks the cell it also sets. The
primitive closes that shape's hazards by construction: the read of its own previous value
is internal and untracked, so it can never re-trigger itself, and there is no peek to get
wrong.

Owner-scoped, like a watch: it subscribes, and the subscription ends with the owner that
created it. Eager, like a watch and deliberately unlike a formula: a lazy merge would
silently drop every event before its first read. `reduce` runs at construction with the
mount-time value of `from` as the first event, and again on every change. A cell is a
value, not a queue: two writes to `from` inside one batch present as one change, exactly
as they would to the hand-rolled watch.

A reduction that lands on an equal value (per `equals`, default `==`) marks nothing
downstream. A `reduce` that raises drops that one event and nothing else: the last reduced
state stands, the subscription survives, and the failure reports the way any watch failure
does.

### `Compose.reactor`

`reactor() -> Reactor`

A scheduling domain: one queue, one batch depth, one drain. Every runtime makes its own,
and `Compose.createOwner(reactor)` puts an owner in one. Two domains never share a queue,
never see each other's batches, and never wedge each other.

```luau
local reactor = Compose.reactor()

reactor:batch(function() ... end)  -- watches deferred until it returns; nests
reactor:settle()                   -- run everything pending; no-op inside a batch
reactor:pending()                  -- how many watches are waiting
```

A write outside a batch settles every domain it reached, before it returns.

### `Compose.sample`

`sample(source) -> value`

Reads a cell, a formula, or a body without depending on anything. Inside a reactive body
prefer `x:peek()`, which says the same thing about one value.

A body is called with a reader of its own, so `sample(function(use) return use(count) end)`
is the body's current value. Anything that is neither a node nor a body is refused at the
call as `reactive/not-a-source`, and a body that reads something which is not a node is
refused as `reactive/not-a-node` naming `Compose.sample`.

### `Compose.isReadable`

`isReadable(value) -> boolean`

True for a cell or a formula. Decided by metatable, which is why an ordinary table passed
as a property value is never mistaken for something reactive.

---

## Ownership

### `Compose.createOwner`

`createOwner() -> Owner`

A root owner. Whoever creates one is responsible for disposing it. Inside a mounted tree
you almost always want `owner.createChild()` instead.

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

Runs `body` with `owner` active, closing the activation even if `body` raises. The escape
hatch for imperative code that wants Compose's primitives outside a mount.

An activation belongs to the thread that opened it. A body that yields keeps its own owner
when it resumes, whatever other mounts ran meanwhile; a thread Compose is resuming inherits
the resumer's owner; a thread with neither has no active owner. See
[`ownership.md`](ownership.md#which-owner-is-active-exactly).

### `Compose.bindOwner`

`bindOwner(body) -> a closure with the same arguments and results`

Captures the owner active now and returns `body` wrapped so that every later call runs with
that owner active again. For a callback the host fires on its own thread, an event handler,
a deferred continuation, a completion, where nothing is active and the primitives would
otherwise refuse.

```luau
local onArrived = Compose.bindOwner(function(child)
    runtime.connect(child, "Changed", handle)   -- owned by the component that bound it
end)
runtime.connect(container, "ChildAdded", onArrived)
```

Raises `owner/no-active-owner` if there is no owner to capture, and
`owner/bind-body-not-a-function` if `body` is not a function. The bound closure passes its
arguments through and returns the body's results; a raise propagates unchanged. Binding does
not extend a lifetime, if the owner is disposed before the callback runs, whatever the
callback registers is released immediately, the same as any late registration.

### `Compose.withRootOwner`

`withRootOwner(body, reactor?) -> body's results`

Creates a root owner, makes it the active one for `body`, and disposes it, newest first,
exactly once, when `body` returns **or** raises. `body` is called with the owner, and its
results are returned. A raise propagates unchanged; if a disposer also raises while
unwinding, both are reported and the body's failure comes first.

This is the entry-point form. A server main, a boot module, a one-shot job: code with
no ambient owner, that would otherwise hand-roll `createOwner` + `withOwner` + a `dispose`
it can forget.

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

The same thing for a root that must **stay open**: `body` runs with the owner active, and the
scope survives `body` returning. If `body` raises, the partly built root is disposed newest
first and the failure re-raised: a failed boot leaves nothing standing.

Returns `{ owner, dispose }`. `dispose` is `owner.dispose`, named on the handle so shutdown
code reads as shutdown; `owner` is there so later work can re-enter the scope with
`Compose.withOwner`.

```luau
local app = Compose.createRootOwner(function(owner)
    local connection = connect()                    -- released at shutdown
    runtime.mount(Hud, host.root)                   -- belongs to this root, not to the process root
end, runtime.reactor)

-- ... the process runs ...

app.dispose()   -- releases everything above, newest first
```

Two forms rather than one option, because each has a single fixed return shape: a flag that
decided between "the body's results" and "a handle" would make the return type depend on an
argument's value, which is not typeable without a public `any`. They mirror the pair that
already exists: `withOwner` runs and leaves, `createOwner` hands you something to keep.

`examples/root-scope.luau` runs both.

### `Compose.currentOwner`

`currentOwner() -> Owner?`

The owner currently mounting, or nil. For library code that needs to behave differently
inside and outside a tree. To carry that owner into a callback that runs later, prefer
[`Compose.bindOwner`](#composebindowner) over pairing this with `Compose.withOwner`.

### `Compose.cleanup`

`cleanup(value) -> dispose`

Registers teardown with the active owner. Accepts a function, or a table with a `destroy`
or `dispose` method. Raises outside a mount.

```luau
runtime.mount(function()
    local subscription = someService:subscribe(handler)
    Compose.cleanup(function()
        subscription:cancel()
    end)
    return Frame {}
end, host.root)
```

Roblox connections, threads, and Instances are the adapter's business: see
[0](#composerobloxcleanup).

### `Compose.custodyOf`

`custodyOf(node) -> "owned" | "adopted" | "borrowed"`

Whether Compose will destroy this node. Anything Compose has not seen is `"borrowed"`, and
borrowed nodes are never destroyed.

---

## Composition

### `Compose.createRuntime`

`createRuntime(host) -> Runtime`

Binds Compose to a host. The host is validated once, here, so a host missing a method
fails next to the host rather than three frames into a render.

A `Runtime` has:

| Member | Meaning |
| --- | --- |
| `host` | the host it renders to |
| `connect(node, event, handler)` | subscribes to an event on an existing node; returns the unsubscribe |
| `create(kind)` | a constructor for that class; call it with props to build a node |
| `decorate(node, props)` | applies props to a node Compose did not create |
| `mount(component, target)` | mounts a one-node component; returns `(dispose, node)` |
| `mountFragment(fragment, target)` | mounts top-level sibling nodes and structural directives; returns `(dispose, staticRoots)` |
| `adopt(node)` | takes responsibility for destroying an existing node |
| `borrow(node)` | states that Compose must never destroy this node |
| `spring(source, options?)` | follows `source` with spring physics |
| `tween(source, options?)` | follows `source` along an easing curve; `seconds` is a number or a source of seconds sampled at each retarget |
| `timeline(options?)` | one owned clock many properties can read |

`create` is curried: it takes a class name and returns a constructor. Name the constructors
a file uses once, at the top, and build with them:

```luau
local create = runtime.create
local Frame = create "Frame"
local Text = create "Text"

local dispose, root = runtime.mount(function()
    return Frame {
        Title = "Inventory",
        Label = function(use)
            return tostring(use(count)) .. " items"
        end,
        [Compose.event("Activated")] = function() ... end,

        Text { Text = "a static child" },
        Compose.show(isOpen, Details),
    }
end, host.root)
```

`Frame { ... }` is ordinary Luau, not a Compose construct: Luau permits dropping the
parentheses around a single table argument, so it is exactly `Frame({ ... })`. Write
`create(className) { ... }` where the class is only known at run time.

Props: string keys are properties, function values bind reactively, and the array part is
children. Two wrappers cover the cases where a function is ambiguous: `Compose.event` and
`Compose.static`.

`decorate` is for something that already exists: a mount target, a character, a layer
someone else owns. Bindings and subscriptions belong to the active owner; the node does
not. Properties written onto a borrowed node are cleared on disposal.

`connect` is the one-line form of the most common thing an adapter is asked to do:

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

The first row is the usual one and is the whole story for a top-level `runtime.mount(App,
host.root)`. The others are for the case where a component owns a container, a group, a
world model, a layer it made, and something other than that container's own props decides
what goes inside it:

```luau
local group = Model { Name = "Entity" }

runtime.mountFragment(function()
    return { Label { Text = captionOf(entity) } }
end, group)

return group
```

`group` is still owned, so it is still destroyed with the tree, and the block mounted into
it is torn down first. Disposing only the block's own dispose removes its nodes and leaves
`group` standing. Without this, mounting into a container you made would quietly demote it
to `borrowed` and it would never be destroyed: a leak, not a safety measure.

The ordering is what makes it safe, and something always orders it. Inside a mount the
active owner does: the target and the block belong to it, and it releases newest first.
**Outside any mount**, a root bootstrap that builds long-lived nodes once and fills them in
afterwards, there is no active owner, but the target still has one, so the block is ordered
against the target *node* instead:

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
affects ordering, and `keyed` and `windowed` still identify rows by the key function they are
given.

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

**Group properties that move together.** The whole gain is that several narrow watches
become one wide one, so it is a win exactly when they share a source and a loss when they
do not: a change to any dependency recomputes every value in the group.
[0](benchmarks.md#focused-api-costs) measures both sides:
−40% where the properties share a source, +46% where they do not.

Nothing is written until the body has returned every value, so a body that raises part-way
leaves the node as it was. On a borrowed node, exactly the declared names are cleared on
disposal. A name the host classifies as an event raises `props/group-names-an-event`; a
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

All of these are **directives**: they go in the array part of a props table, they manage
their own run of children, and they never learn what a node is.

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

A subtree that is allowed to leave. With no `exit` this is `show`, and takes the same path.

```luau
Frame {
    presence(isOpen, Panel, {
        exit = function(nodes)
            return runtime.timeline { duration = 0.2 }
        end,
    }),
}
```

The builder is handed a `phase`, `phase.exiting` is a readable that is true while the
subtree is on its way out, and may return one node or an array of them.

`exit` is called once, with the nodes that are leaving, at the moment the condition goes
false. The subtree stays mounted and owned until the thing it returns reports `completed`,
and is then removed and disposed exactly once. Anything with a `completed` readable will do;
a timeline is the obvious one.

It does not animate. Turning the exit's progress into a host value is the job of the bindings
that read it, which is why the leaving subtree is still there to read them.

**Re-entry reclaims.** A condition that goes true again during an exit takes the same subtree
back and sets `phase.exiting` false again, so a departure authored against it reverses from
where it had got to rather than snapping. No second build, no second disposal, and the
abandoned exit cannot remove it later.
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

**The fields are named because the arguments are not distinguishable.** `key` and `render`
are both functions of a value, and getting them the wrong way round produces a list of one
row and no error at all. Naming them makes that mistake unwritable.

`from` takes a cell or a formula directly, as well as a body. `key` defaults to the value
itself: pass a real one whenever the values are structural copies rather than stable
objects, which is nearly always.

Reordering the source **moves** the existing nodes rather than destroying and rebuilding
them, which is what keeps a text field focused, an animation running and a scroll position
still.

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

An ordered population viewed through a moving window, with the geometry decided for you.
Where `windowed` gives you the seam and expects the range, this owns the arithmetic: row
sizes, grid wrapping, overscan, holding a chat at its newest message, and holding position
when history loads above the reader.

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
visible rows plus `overscan`. A collection never changes its retention policy underneath you
at some population it happened to reach.

`viewport` is a readable `{ offset, size }` in whatever unit your host measures in, and is
required by `"windowed"`. `render` receives the row's `placement`, a readable carrying its
`index`, `row`, `column`, `offset`, `size`, `crossOffset` and `crossSize`.

`layout` takes `kind` (`"list"` or `"grid"`), `columns`, `itemSize`, `gap`, `crossSize` and
`crossGap`. `itemSize` is the fixed size for a fixed collection and the estimate for a
measured one; pass `measured`, a readable of key-to-size, to correct it as rows report their
real sizes. A grid row is as tall as its tallest item.

**It never touches the host.** It computes where things are and publishes what it wants;
reading a scroll position, measuring a row and moving a viewport are the adapter's job. When
it wants the view moved, to follow the end, or to hold position while history loads above,
it says so in `status.desiredOffset`.

`status` is a cell it writes after every pass: `total`, `retained`, `first`, `last`,
`firstRow`, `lastRow`, `rowCount`, `extent`, `following`, `desiredOffset` and `measured`.
`controls` is a table it fills with `offsetOf(index, align, size)`, `indexOfKey(key)` and
`placementOf(index)`, for driving your own viewport.

`follow = "end"` keeps the view at the newest item. It disengages when the **reader** scrolls
away and not when content arrives beneath them, which is the difference between a chat that
follows and one that lets go every time a message lands.

Scrolling costs the retained slice, not the population: the range is a division for uniform
rows and a tree descent otherwise. Work proportional to the whole list happens when the list
changes, which is detected by identity.

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

`status` is a cell it writes after every pass: `total`, `retained`, `queried`, `pending`,
`perTier` and `cells`. The gap between `queried` and `total` is the spatial index doing its
job.

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

Creates an owner-bound cache keyed by an arbitrary value, with least-recently-used eviction
at an explicit finite `maxRetained`. `get(key)` builds on a miss, otherwise returns the
retained value and marks it most-recently-used; `peek(key)` reads without building and
without touching recency; `evict(key)` destroys one retained entry (a no-op if the key is
not retained); `size()` and `keys()` report the current retained set, `keys()` ordered
least-recently-used first. An optional `touch(key, value)` fires on every hit or miss purely
for observation and never affects retention. Owner disposal destroys every retained value,
newest-recency-first, exactly once. Unlike `createPool`, a cache value is not leased and
released: callers hold it by reference for as long as it stays retained, and eviction is
the cache's own decision once a newer key pushes it out.

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

Catches anything that runs as a watch beneath it: the builder, a property binding
recomputing, a `show` or `keyed` rebuilding, a watch of your own. Does not catch a failure in the
fallback itself. See [2](ownership.md#error-boundaries).

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

Each call takes a reference and registers its release with the active owner, so the count
follows the tree. The last subtree holding it going away tears it down; acquiring again
after that builds a fresh one.

**The factory runs under the resource's own owner, never the caller's.** That is what makes
nesting safe: when A's factory acquires B, B belongs to A's lifetime, so the first consumer
of A going away releases neither and the last releases both, innermost last, exactly once. A
factory that fails part-way releases whatever it had already taken and caches nothing.

`acquire.detached()` returns the value **and** its release, for a caller with no owner and a
lifetime of its own to manage. Calling that release twice is safe; forgetting it holds the
resource for the life of the process, which is why it is the form you have to ask for.

### `Compose.easing`

A frozen table of easing functions: `linear`, and `in`/`out`/`inOut` variants of `Quad`,
`Cubic`, `Quart`, `Quint`, `Sine`, `Expo`, `Circ`, `Back`, `Elastic`, and `Bounce`. Each
takes and returns a number in `[0, 1]`.

```luau
runtime.tween(opacity, { seconds = 0.25, ease = Compose.easing.outQuad })
```

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

Reads a Compose diagnostic back into `{ code, summary, fields }`. The inverse of
`formatDiagnostic`, and it exists for tools and agents: what they receive is the thrown
string, and asking each of them to parse it with its own regular expression is how a message
becomes an API nobody may ever improve.

```luau
local ok, err = pcall(build)
if not ok then
    local diagnostic = Compose.parseDiagnostic(tostring(err))
    if diagnostic ~= nil and diagnostic.code == "owner/no-active-owner" then
        -- diagnostic.fields.fix is the one-line remedy the message carried
    end
end
```

A pure function over a string. There is no sink to install, no hook on the raise path, and
nothing that could change or swallow the original failure. A caller that never parses pays
nothing, because there is nothing to pay.

Returns nil for anything that is not a Compose diagnostic. A message a runtime has prefixed
with a source location, which is what `error` at a non-zero level produces, and what a
`pcall` in user code usually hands back, is parsed rather than rejected.

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

The causal profiler. Answers *why did this frame do this work* by recording the chain a
write sets off -- cell, formula, watch, host property -- and printing it back under the
names you gave the graph.

It is a development tool and it is off until you start it. Every hook lives inside the
same branch the work counters use, so an application that never calls `start` pays nothing
for it and no node carries a single extra field. The cost of that is a rule about order:
**a label is only recorded while the profiler is running**, so start it before you build
the screen you want to read about. Anything built earlier is still measured and still
shows its fan-out; it just appears under a synthetic name like `cell#12`.

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

See [api.md](api.md) for how to read that output.

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

The lifetime inspector. Answers *why is this still alive* in the terms ownership is written
in: custody, owners, and what each owner is holding.

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

`inspect.node(node).because` is a sentence rather than a structure on purpose: the answer to
"why is this alive" is a relationship, and a relationship reads better than it tabulates.

Off until started, and off means no field on any owner or node, no label, and no reference
held anywhere. The cost of that is the same rule [`Compose.profile`](#composeprofile) has:
**an owner built before `start` reports its total but not its breakdown**, and the report
says which it is rather than reporting zeroes as though they were measurements.

`options` bounds capture: `maxOwners` (default 4096) and `maxNodes` (default 16384). Every
table it keeps is weakly keyed, so inspecting something never keeps it alive, and `stop`
drops all of it. No application value is ever recorded.

**`report.trackedNodes` is a process-global diagnostic census, not a per-test assertion
target.** It is a live count over every node any owner in the *entire process* has ever taken
custody of, kept in a weak-keyed table. That count falls only when the incremental collector
gets around to reclaiming an entry it dropped, on the collector's own schedule, never the
caller's, so it includes nodes a wholly unrelated test left stranded and not yet swept, and
the same operation can report a different delta from one run to the next. Treat it as "roughly
what I expect" or "is this non-negative"; never write a spec that asserts a delta on it.

For an owner-scoped count that *is* safe to assert deltas on, use `inspect.owned(owner)`. It
returns `{ ownedNodes, borrowedNodes }`, nodes the owner created or adopted (and will destroy
on its own disposal), and nodes it borrowed (and is charged with while it holds them), kept
exact by decrementing the moment `forget` runs on disposal, not by waiting for the collector.
It is untouched by what any other owner in the process is doing or leaving stranded, including
under allocation churn that would move `trackedNodes`:

```luau
Compose.inspect.start()
local owner = Compose.createOwner()
Compose.withOwner(owner, function()
	world.create "Frame" { Name = "Kept" }
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

## `compose-test-host`

### `TestHost.create`

`create() -> TestHost`

An isolated, opaque, deterministic host. Its nodes are frozen empty tables, so core code
that reaches around the protocol fails immediately rather than working by accident.

```luau
local host = TestHost.create()
local runtime = Compose.createRuntime(host.host)

host.declareEvent("Button", "Activated")
host.dispatch(button, "Activated")
host.step(1 / 60)
host.failNext("insertChild")

host.counts().setProperty
host.liveNodes()
host.serialize(host.root)
```

Full surface: `host`, `root`, `makeNode`, `kindOf`, `propertyOf`, `attributeOf`,
`childrenOf`, `parentOf`, `isAlive`, `handlerCount`, `declareEvent`, `dispatch`, `poke`,
`step`, `now`, `failNext`, `clearFailures`, `counts`, `resetCounts`, `liveNodes`,
`liveSubscriptions`, `leaked`, and `serialize`.

It stores attributes for `string`, `number`, `boolean` and `nil`, and refuses anything else
with a reason. `failNext("setAttribute")` is the exception to `failNext`'s usual meaning: it
makes the next `setAttribute` *report* a refusal rather than raise, because that is what the
protocol asks that verb to do.

### `RobloxEmulator.create`

`create() -> Emulator`

A headless emulation of the Roblox `Instance` model, required separately from
`src/test-host/roblox`. Where `TestHost` gives opaque nodes, this gives **Instance-shaped**
ones: dot-accessible properties with per-class defaults, real methods, signals, and an
inheritance chain. That is what a component reaching an instance through a ref needs in
order to be testable at all. No Roblox is required, ever.

```luau
local RobloxEmulator = require(script.Parent.Parent["test-host"].roblox)

local emulator = RobloxEmulator.create()
local runtime = Compose.createRuntime(emulator.host)

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

Full surface: `engine`, `host`, `render`, `root`, `createInstance`, `defineClass`,
`newSignal`, `step`, `now`, `childrenOf`, `parentOf`, `propertyOf`, `attributeOf`,
`isAlive`, `liveObjects`, `liveConnections`, `serialize`, `log`, `clearLog`, `poke`, `fire`,
`failNext`, and `clearFailures`.

`host` is built by `ComposeRoblox.createHost(emulator.engine)`, and `render` is that
adapter's own renderer wrapped only to count, log and inject failures. What a specification
exercises here is `src/roblox/host.luau`, not a second implementation of it, so `moveChild`
is absent here for the same reason it is absent there.

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
`setAttribute`, which reports a refusal instead, exactly as `TestHost` does.

What it does **not** emulate is listed in [`roblox.md`](roblox.md#what-the-emulator-cannot-check),
and that list is the point: this is a fixture, and only the engine decides.

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

A camera reports a placeholder size before the client's viewport exists, and layout decided
from a 1x1 viewport is wrong for the whole session. So a size below `minimumSide` on either
axis, or one that is not a finite pair of numbers, is unknown rather than small: the source
holds what it last knew and the second result, readiness, stays false until a real size
arrives. Until then the value is the fallback, so a consumer that only wants a number never
sees nil.

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

Reports which authored ids and roles fall through a registry key list, which is how an authored
entry with no handler is found before it silently does nothing at runtime.

### `Author.bake`

`bake` holds the emitters: `attributePlan`, `layoutSheet`, and `registryModule`. The package
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
