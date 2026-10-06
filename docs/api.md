# API reference

This page owns the public signatures, the return values and the failure behavior.
`tools/check-public-surface.luau` checks that each public export has an entry here.

| Task | Reference |
| --- | --- |
| Store and derive state | [Reactive state](#reactive-state) |
| Control resource lifetimes | [Ownership](#ownership) |
| Build and mount nodes | [Composition](#composition) |
| Change scene structure | [Structure](#structure) |
| Share resources and animate values | [Context](#context) |
| Diagnose work and retention | [Diagnostics](#diagnostics) |
| Test without an engine | [Test hosts](#srctest-scene) |
| Use Roblox | [Roblox adapter](#srcroblox) |
| Generate build artifacts | [Authoring](#authoring-project-trees) |

The examples assume this setup:

```luau
local Compose = require(path.to.compose.core)
local TestScene = require(path.to.compose["test-scene"])

local test = TestScene.create()
local runtime = Compose.createRuntime(test.adapter)
local Host = runtime.constructors
```

The examples on this page are fragments, unless the text says otherwise.
[Executable examples](../examples/README.md) show complete setups. [Tests](../tests) exercise the contracts.
Neither a fragment nor an API inventory proves native rendering or application quality.

---

## Reactive state

Cells hold state. Formulas derive state.
Every reactive body receives `use`, including formulas, watches, bound properties and structural sources.
A read through `use` records a dependency. Outside a body, use `:peek()` for an explicit untracked read.

### A value, or a source of one

`Compose.Value<T>` is the type of an argument that accepts one of four things:

- a plain `T`
- a cell that reads as `T`
- a formula that reads as `T`
- a body that returns `T`

An option field uses `Value` when the field does not depend on which of the four the consumer has.

```luau
type Options = {
    seconds: Compose.Value<number>?,
}

runtime.tween(opacity, { seconds = 0.25 })
runtime.tween(opacity, { seconds = configuredSeconds })
```

`Source<T>` is the narrower union. It accepts a cell, a formula or a body, but not a plain value.
If a constant is a mistake for the field, use `Source`. If a constant is correct, use `Value`.

### Type checking

Every maintained Luau source begins with `--!strict` and uses no explicit `any` type, including casts, type packs, tests and tooling.
The gate parses types and checks both Luau solvers.
Dynamic host properties and decoded input remain `unknown` until their protocol or an existing validation supplies a concrete shape.
Generic callbacks keep their argument and result types.

Three habits keep consumer code checking under both solvers:

- Annotate `use` in a body that you pass where a `Source` or `Value` is expected. The new solver does not infer a function parameter from a union that also holds a readable.
- Assert the type of a cell whose initial value is a function. A function argument also matches a function-valued `T`.
- Annotate a table literal whose type the call cannot infer, such as an empty `initial` or a `layout` that you pass to a union-typed option.

```luau
Compose.show(function(use: Compose.Use)
    return use(progress) > 0
end, Overlay)

local settings = Compose.cell(loadSettings) :: Compose.Cell<Settings>

Compose.OrderedCollection {
    from = rows,
    layout = { itemSize = 24 } :: Compose.OrderedCollectionLayout,
    render = Row,
}
```

The old solver widens the singleton string union of a formula body before instantiation.
The literal-union compiler fixture projects the resulting formula back to its explicitly declared body return type. The same fixture also checks under the new solver.
Production readable receivers keep their concrete contracts.

### `Compose.cell`

`cell(initial, equals?) -> Cell`

Stores a writable value in the reactive graph. `initial` can be a value or a function.
Compose calls an initial-value function only on the first read or write.

```luau
local progress = Compose.cell(100)

progress:peek()                     --> 100   read, no dependency
progress:set(90)
progress:update(function(previous) --> 81
    return previous - 9
end)
```

`equals` decides what counts as a change. The default is `==`.
Compose suppresses a write that `equals` calls equal. Nothing downstream is marked, and no watch runs.

### `Compose.sharedCell`

`sharedCell(initial, equals?) -> Cell`

Declares a cell with a module-scope lifetime.
Use it for deliberate process-wide state, an exported reactive API or a development override.
It needs no owner, and disposal is not expected. The constructor makes that lifetime explicit to readers and to consumer lint.

```luau
-- module scope is the point
local presses = Compose.sharedCell(0)

return { presses = presses }
```

It uses the same runtime behavior and execution paths as `cell`, with an additional metatable identity flag.
Diagnostics identify it as a cell. `Compose.cell` remains valid at module scope.
`sharedCell` declares intent for consumer lint. It adds no reactive capability.

### `Compose.formula`

`formula(body, equals?) -> Formula`

A cached derivation. `body` receives `use` and must read every dependency through it.

```luau
local percent = Compose.formula(function(use)
    return use(progress) / 100
end)

percent:peek()  --> 0.81
```

The body runs on its first read. Compose caches the result and recomputes it only when a dependency changes.
An equal result publishes no change, so downstream consumers do not run again.

- A formula that you create under an active owner belongs to that owner. It releases its upstream dependencies on teardown or on failed-build unwind.
- If you read an existing formula from another owner, you borrow it. The read does not transfer ownership.
- Outside an active owner, the consumer controls its lifetime with `formula:dispose()`.
- Explicit disposal also works for owned formulas. It removes their cleanup registration immediately.

Disposal is idempotent. It releases the dependencies, the body, the comparator and the cached value.
Later `:peek()` and `use(formula)` reads raise `reactive/disposed-formula`.
Disposal neither evaluates the body nor schedules downstream callbacks.
Dispose downstream consumers before their formula, or give the formula an owner that outlives those consumers.

### `Compose.watch`

`watch(body, label?) -> dispose`

Runs `body` immediately, and again when a dependency changes.
The active owner controls its lifetime. The call refuses when there is no active owner.

```luau
Compose.watch(function(use)
    print(use(percent))
end, "progress readout")
```

To stop the watch early, call the returned disposer. You do not need to retain it to keep the watch running.
Disposing the owner stops the watch.
Resources that you create inside the body follow the [per-run cleanup contract](#composecleanup).

Outside a mount, use `owner.watch(body, label?)` with an explicit owner, or `runtime:watch(body, label?)`, which falls back to the own owner of the runtime.
The optional label names this otherwise handleless watch in a running [`Compose.profile`](#composeprofile) capture.
Compose does not retain it when the profiler is off.

#### Reacting to changes only

No option suppresses the first run. The first run registers the dependencies, so it must happen.
To act only on later changes, give the watch one flag:

```luau
local delivered = false
Compose.watch(function(use)
    local current = use(progress)
    if not delivered then
        delivered = true
        return
    end
    flash(current)
end, "progress flash")
```

The first run is synchronous. It happens inside the `watch` call itself, before an enclosing batch closes.
A write that you make later in that same batch is therefore a change.
The watch runs again when the batch settles. The body then reads the value that the batch left behind, not the value that it started with.

### `Compose.accumulator`

`accumulator { from, reduce, initial?, equals? } -> Readable`

Tracks one readable source. On each change, it calls `reduce(previous, event)` to update its own readable state.
This state can retain information that the event source does not carry.

```luau
local seen = Compose.accumulator {
    from = signalFired,                     -- a cell or formula; each change is one event
    reduce = function(previous, event)      -- merge one event into the running state
        return withSignal(previous, event)
    end,
    initial = {} :: Seen,                   -- the state before any event
}
```

This combines a cell with a watch that reads and updates the cell.
The internal read of the previous state is untracked, so the accumulator cannot trigger itself through that read.

- The subscription belongs to the active owner and ends when that owner disposes.
- `reduce` runs immediately with the construction-time value of `from`, and then on every change. It does not wait for the first read, because that would miss earlier events.
- A cell stores a value, not a queue. Two writes to `from` inside one batch produce one observed change.
- An equal reduction result (`equals`, default `==`) does not mark downstream consumers.
- If `reduce` raises, the accumulator drops that event and keeps the previous state and subscription. It reports the error as a watch failure.

### `Compose.reactor`

`reactor() -> Reactor`

Creates a scheduling domain with its own queue, batch depth and drain. Every runtime creates one.
To place an owner in that domain, pass the reactor to `Compose.createOwner(reactor)`.
Domains do not share queues or batch state, so one domain cannot block the drain of another.

```luau
local reactor = Compose.reactor()

reactor:batch(function() ... end)  -- watches deferred until it returns; nests
reactor:settle()                   -- run everything pending; no-op inside a batch
reactor:pending()                  -- how many watches are waiting
```

A write outside a batch settles every domain that it reached, before it returns.

A reactor needs no host. Cells, formulas and watches are the whole reactive layer, and none of them touches a host.
`Compose.createRuntime(host)` creates a reactor because a runtime also builds nodes.
Some models have no tree: a server-side store, a simulation or a test.
For such a model, create a reactor, create an owner on that reactor, and do not create a runtime.

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

Reads a cell, a formula or a body without depending on anything.
Inside a reactive body, prefer `x:peek()`, which says the same thing about one value.

Compose calls a body with an untracked reader. Thus `sample(function(use) return use(count) end)` returns the current value of the body.

- An argument that is neither a reactive node nor a body raises `reactive/not-a-source`.
- A body that reads a non-reactive value raises `reactive/not-a-node`, naming `Compose.sample`.

### `Compose.isReadable`

`isReadable(value) -> boolean`

True for a cell or a formula. Compose decides by metatable. An ordinary table that you pass as a property value is therefore never mistaken for something reactive.

---

## Ownership

### `Compose.createOwner`

`createOwner(reactor?) -> Owner`

Creates a root owner. The consumer must dispose it. Inside a mounted tree, usually use `owner.createChild()` instead.

```luau
local owner = Compose.createOwner()
Compose.withOwner(owner, function()
    Compose.watch(function(use) ... end)
end)
owner.dispose()   -- releases everything registered above, newest first, exactly once
```

An `Owner` has `own`, `watch`, `createChild`, `dispose`, `isDisposed`, `size`, `reactor`, `checkpoint`, `rollbackTo` and `guardWith`.
See [`ownership.md`](ownership.md).

In an entry point, prefer [`Compose.withRootOwner`](#composewithrootowner) or [`Compose.createRootOwner`](#composecreaterootowner).
They follow the same ownership rules, with setup unwind and an explicit shutdown boundary.

### `Compose.withOwner`

`withOwner(owner, body) -> body's results`

Runs `body` with `owner` active. It ends that activation even if `body` raises.
Use it to call owner-bound primitives from imperative code outside a mount.

- An activation belongs to the thread that opened it.
- A yielding body keeps its owner when it resumes, regardless of intervening mounts.
- A thread without its own activation inherits only an unambiguous owner from a resumer.
- Competing owners on distinct resumer threads raise `owner/no-active-owner`. To resolve this, bind the child with `Compose.bindOwner` or activate its owner with `Compose.withOwner`.
- A thread with neither has no active owner.

See [`ownership.md`](ownership.md#which-owner-is-active-exactly).

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

- It raises `owner/no-active-owner` if there is no owner to capture.
- It raises `owner/bind-body-not-a-function` if `body` is not a function.
- The bound closure passes its arguments through and returns the results of the body. A raise propagates unchanged.
- Binding does not extend a lifetime. If the owner is already disposed, the closure immediately releases anything that the callback registers, as with any late registration.

### `Compose.withRootOwner`

`withRootOwner(body, reactor?) -> body's results`

Creates a root owner and makes it the active owner for `body`.
It disposes the owner, newest first, exactly once, when `body` returns **or** raises.
It calls `body` with the owner and returns the results of `body`.
A raise propagates unchanged. If a disposer also raises during the unwind, Compose reports both failures. The failure of the body comes first.

Use this form for an entry point with no ambient owner, such as a server main, a boot module or a one-shot job.
It combines owner creation, activation and guaranteed disposal.

```luau
local report = Compose.withRootOwner(function(owner)
    local pool = Compose.createPool { ... }   -- accepted: the root owner is active
    return measure(pool)
end)
-- the pool is destroyed here, whether `measure` returned or raised
```

To put the root in an existing scheduling domain, pass `reactor`. Usually pass `runtime.reactor`, so that the root batches with the trees that you mount under it.
If you omit it, the owner gets its own reactor.

### `Compose.createRootOwner`

`createRootOwner(body, reactor?) -> RootScope`

Creates a root that stays open after `body` returns. The body runs with the owner active.
If it raises, Compose disposes the partly built root newest first and propagates the failure.

It returns `{ owner, dispose }`. The `dispose` field is `owner.dispose`.
To activate the scope for later work, use `owner` with `Compose.withOwner`.

```luau
local app = Compose.createRootOwner(function(owner)
    local connection = connect()
    Compose.cleanup(connection)
    runtime.mount(Overlay, test.root)
end, runtime.reactor)

-- ... the process runs ...

app.dispose()   -- releases everything above, newest first
```

The two root APIs have fixed return types.
`withRootOwner` returns the results of the body and closes the root.
`createRootOwner` returns a scope that the consumer must dispose.

`examples/root-scope.luau` runs both.

### `Compose.currentOwner`

`currentOwner() -> Owner?`

Returns the active owner, or nil. Library code uses it to behave differently inside and outside a tree.
To carry that owner into a callback that runs later, prefer [`Compose.bindOwner`](#composebindowner) over a pair of this call and `Compose.withOwner`.

### `Compose.cleanup`

`cleanup(value) -> dispose`

Registers teardown with the active owner. It accepts a function, or a table with a `destroy` or `dispose` method.
It raises when there is no active owner.
Inside a watch body, from `Compose.watch`, `owner.watch` or `runtime:watch`, the active owner is that run.
Its cleanups and resources are released before the next run and when the watch ends.

```luau
runtime.mount(function()
    local subscription = someService:subscribe(handler)
    Compose.cleanup(function()
        subscription:cancel()
    end)
    return Host.Frame {}
end, test.root)
```

For Roblox connections, threads and Instances, use [ComposeRoblox.cleanup](#composerobloxcleanup).

### Owner scheduler

`scheduler(owner?) -> Scheduler`

Binds delayed work to an owner. If you omit `owner`, it uses the active owner. It raises `owner/no-active-owner` when there is none.
The scheduler holds one paused timeline, so it holds no frame listener while nothing is pending.

| Call | Meaning |
| --- | --- |
| `after(seconds, body) -> cancel` | Runs `body` once after `seconds`. `cancel()` returns true if the task was still pending. |
| `replace(key, seconds, body) -> cancel` | Works like `after`, but first cancels any pending task under the same key. |
| `cancel(key) -> boolean` | Cancels the pending task under `key`. |
| `clear()` | Cancels every pending task and keeps the scheduler. |
| `pending() -> number` | Returns the count of pending tasks. |
| `dispose()` | Cancels everything and ends the scheduler. Owner disposal does the same. |

- `seconds` is finite and zero or more. A zero delay runs on the next frame, never inside the call.
- A bad delay, body or key raises `scheduler/invalid-delay`, `scheduler/invalid-body` or `scheduler/invalid-key` and schedules nothing.
- A key is any value except nil or NaN.
- Tasks that fall due on one frame run in due-time order, and then in scheduling order.
- Compose retires a task before its body runs, so the body can schedule more work, including under its own key. New work waits for a later frame.
- The body runs with the scope of the scheduler active. Resources that it creates end with the owner.
- A body that raises does not stop its siblings. After every due task has run, the scheduler raises the failure. Several failures raise one summary, like an owner disposal.
- Scheduling on a disposed scheduler returns a cancel that does nothing.

```luau
local timers = runtime.scheduler(owner)
timers.replace("notice", 2.5, function()
    notice:set(nil)
end)
timers.cancel("notice")
```

### Ramp

`ramp(initial, options?) -> { value, retarget }`

A tween whose target and duration change together.

- `value` is a readable that starts at `initial`.
- `retarget(target, seconds)` moves it from its current value to `target` along `options.ease` (default linear).
- A `seconds` of zero or less jumps at once and holds no frame listener.
- Any other non-finite `seconds` raises `ramp/invalid-seconds`.
- It needs an active owner.

### `Compose.createSlot`

`createSlot(owner?) -> Slot`

Holds the attachment for one current key and replaces it atomically.
If you omit `owner`, it uses the active owner. It raises `slot/no-active-owner` when there is none.

- `bind(key, attach) -> boolean` runs `attach(owner, release)` under a fresh child owner. When it succeeds, that owner becomes current and Compose disposes the previous attachment. It returns false for the key that is already current, or after disposal, without running `attach`.
- If `attach` raises, Compose releases its partial resources, the current attachment stays and Compose raises the failure unchanged.
- `release(key) -> boolean` disposes the attachment if `key` is current. The `release` callback that `attach` receives does the same. It does nothing while that attachment is still being attached.
- `current() -> unknown` reads the current key (nil when empty). Narrow it before you use key members.
- `dispose()` ends the slot. Owner disposal does the same.
- A key is any value except nil or NaN. Bad arguments raise `slot/invalid-key`, `slot/invalid-attach` or `slot/invalid-owner`.

### `Compose.custodyOf`

`custodyOf(node) -> "owned" | "adopted" | "borrowed"`

Reports whether Compose destroys this node. Anything that Compose has not seen is `"borrowed"`, and Compose never destroys borrowed nodes.

---

## Composition

### `Compose.createRuntime`

`createRuntime(host) -> Runtime`

Binds Compose to a host. It validates the host once at construction, so missing methods fail before rendering starts.

A `Runtime` exposes the composition members below. Its controls use method syntax:
`runtime:batch(body)`, `runtime:settle()`, `runtime:pending()`, `runtime:watch(body, label?)` and `runtime:dispose()`.
For scheduling, see [reactors](reactive.md#reactors).
For root lifetimes, see [ownership](ownership.md#entry-points-and-what-happens-with-no-active-owner).

| Member | Meaning |
| --- | --- |
| `host` | The host that the runtime renders to. |
| `connect(node, event, handler)` | Subscribes to an event on an existing node. Returns the unsubscribe. |
| `constructors` | A string-keyed table of lazily cached constructors that are bound to this runtime. Use `Host.Frame { ... }`. |
| `create(kind)` | Selects a constructor for a dynamic host kind. Call it with props to build a node. |
| `decorate(node, props)` | Applies props to a node that Compose did not create. |
| `mount(component, target)` | Mounts a one-node component. Returns `(dispose, node)`. |
| `mountFragment(fragment, target)` | Mounts top-level sibling nodes and structural directives. Returns `(dispose, staticRoots)`. |
| `adopt(node)` | Takes responsibility for destroying an existing node. |
| `borrow(node)` | States that Compose must never destroy this node. |
| `spring(source, options?)` | Follows `source` with spring physics. |
| `tween(source, options?)` | Follows `source` along an easing curve. `seconds` is a number or a source of seconds that Compose samples at each retarget. |
| `timeline(options?)` | Creates one owned clock that many properties can read. |
| `ramp(initial, options?)` | Creates a value that moves to each new target over a duration that you choose for each retarget. See [Ramp](#ramp). |
| `scheduler(owner?)` | Creates owner-bound delayed work with cancellation and keyed replacement. See [Owner scheduler](#owner-scheduler). |

The `spring` and `tween` option tables both accept `reducedMotion`, a [reduced motion policy](#reduced-motion).

Bind `local Host = runtime.constructors` once and use the host-kind fields directly.
Reading a field lazily caches its constructor. Calling it builds through the host and the ownership rules of this runtime:

```luau
local Host = runtime.constructors

local dispose, root = runtime.mount(function()
    return Host.Frame {
        Title = "Summary",
        Label = function(use)
            return tostring(use(count)) .. " items"
        end,
        [Compose.event("Activated")] = function() ... end,

        Host.Text { Text = "a static child" },
        Compose.show(isOpen, Details),
    }
end, test.root)
```

`Host.Frame { ... }` is ordinary Luau. The single table argument permits omitting parentheses, so it is exactly `Host.Frame({ ... })`.
For a dynamic kind, use `runtime.create(className) { ... }`.

The core `Compose` module supplies reactive and ownership helpers. It has no host constructors.
An application can export the `constructors` table of its runtime as its own `Compose` module and write `Compose.Text { ... }` where that host supports `Text`.
If the component also needs core helpers, require core separately as `ComposeCore`.
Each constructor table belongs to one runtime.

Props: string keys are properties, function values bind reactively, and the array part is children.
Two wrappers cover the cases where a function is ambiguous: `Compose.event` and `Compose.static`.

`decorate` is for something that already exists: a mount target, a model, or a layer that someone else owns.
Bindings and subscriptions belong to the active owner. The node does not.

- Each mentioned property replaces its previous binding after the first successful host write, even when the replacement starts with the same value. The previous source stops writing that property.
- Unmentioned properties and event subscriptions remain active.
- Attributes replace bindings by attribute name, separately from properties.
- Only the current binding clears the value of a borrowed property when its owner disposes. Disposing an older owner cannot clear a newer value. Disposing the replacement does not restore an older binding.
- If the first write of the replacement fails, the previous binding remains active.
- Applying several props is not a transaction. A later failure does not restore bindings that Compose already replaced.

`connect` subscribes to an event on an existing node:

```luau
runtime.connect(part, "Touched", onTouched)
```

The subscription belongs to the active owner, so Compose releases it when the subtree is released.
Calling the returned unsubscribe is optional. It is safe to call twice.

#### The custody of a mount target

Mounting preserves the custody of the target.
[Ownership](ownership.md#a-mount-target-keeps-the-custody-it-has) owns the destruction order, multiple mounted blocks and the distinction from portals.
A target that is neither a table nor userdata raises `mount/target-not-a-node`.
See the [mount-target example](../examples/mount-target.luau) for a complete lifecycle.

### `Compose.labelOf`

`labelOf(node) -> string?`

Returns the label under which a node was built, `Part "Ground" { }`, or nil if it was built anonymously.

A label belongs to Compose. Compose records it whether or not the host has any notion of a name.
It is the name that a node uses in a diagnostic, in the profiler and in [`Compose.inspect.node`](#composeinspect).
It is **not a key**. Duplicates are legal, it never affects ordering, and keyed collections still identify rows by their key function.

### `Compose.event`

`event(name) -> key`

Marks a props key as an event subscription. It is unambiguous on every host. It is required on hosts that cannot tell events from properties at runtime.

```luau
Button { [Compose.event("Activated")] = function() ... end }
```

### `Compose.property`

`property(name) -> key`

Marks a props key as a property write and overrides the host classification.
Use it for a member that looks connectable but that you want to *write*.

### `Compose.group`

`group(names) -> key`

Binds several named properties from one body.
The body returns one value for each name, in order. Compose writes each value only when it differs from what this group last wrote there.

```luau
Part {
    [Compose.group { "Position", "Transparency", "Color" }] = function(use)
        local unit = use(state)
        return unit.position, unit.fade, unit.tint
    end,
}
```

One watch, one dependency set and one queue entry replace one of each for every property.

**Group properties that change together.**
One watch replaces several, but a change to any dependency recomputes every value in the group.
Shared dependencies can reduce scheduling work. Independent dependencies can cause unnecessary recomputation.
Measure the actual workload with the [benchmark protocol](benchmarks.md). CPU results of core do not establish native rendering or device performance.

- Compose writes nothing until the body has returned every value, so a body that raises part-way leaves the node as it was.
- On a borrowed node, Compose clears exactly the declared names on disposal, unless a later binding replaced that name.
- If you replace one group member, the other members stay reactive. If you replace the last member, Compose releases the group watch.
- A name that the host classifies as an event raises `props/group-names-an-event`.
- A body that returns the wrong number of values raises `props/group-arity`.

### `Attributes`

`Attributes = { name = value | source | use -> value }`

The one **reserved string key**. Its value is a table of attribute names and values. Compose writes each one through `render.setAttribute` of the host, not as a property.

```luau
Part {
    Attributes = {
        Level = 3,
        Category = category,                  -- a cell: rewritten when it changes
        Label = function(use)
            return ("level %d"):format(use(level))
        end,
    },
}
```

Attributes follow the same rules as properties, through the same `bind` and `write-once` split.
A cell or a function binds reactively. Compose writes anything else once. `Compose.static(value)` writes a function value literally.
Three differences apply:

- **`nil` clears.** Setting an attribute to nil removes it. This is also how Compose undoes a binding on a borrowed node when its owner disposes.
- **Writes deduplicate.** A recompute that produces the value that Compose already wrote reaches no host. `Compose.group` does this for properties. A plain property binding does not.
- **Names are checked first.** Compose validates every name in the table before it writes any of them, so a bad name leaves the node exactly as it was. The write order is the sorted name order, not the iteration order of the table.

These failures apply:

- A name that is not a non-empty string raises `props/attribute-name`.
- A value that the host does not store raises `props/attribute-value`, with the reason of the host in `detail`.
- An owned node raises `props/child-under-attribute`.
- A non-table raises `props/attributes-not-a-table`.
- A host whose renderer omits `setAttribute` raises `host/no-attributes`.

`Attributes` is reserved only as a *bare* string key.
On a host that has a property of that name, `[Compose.property "Attributes"]` writes the property and is never reserved.

### `Compose.static`

`static(value) -> wrapped`

Marks a value as literal, so Compose writes a function value to the property and does not call it.

```luau
Widget { OnRequest = Compose.static(handler) }
```

---

## Structure

The structural builders return **directives** for the array part of a props table.
Each directive manages its own range of children through the host-neutral protocol.
This section also describes the focus, pool and cache helpers.

### `Compose.show`

`show(condition, builder, fallback?) -> directive`

One subtree, present while `condition` is truthy.

```luau
Screen {
    Compose.show(isLoading, Spinner),
    Compose.show(hasError, ErrorPanel, EmptyState),
}
```

Compose rebuilds the subtree only when the *truthiness* of the condition changes.
A counter inside a `show` survives when its condition goes 1, 2, 3.

A branch can return a node or another directive directly. This keeps nested structure flat:

```luau
Compose.show(isOpen, function()
    return Compose.keyed { from = rows, key = keyOf, render = Row }
end)
```

When one branch contributes several sibling nodes, return `Compose.fragment(...)`.

### `Compose.presence`

`presence(condition, builder, options?) -> directive`

Retains a departing subtree until its exit completes. Without `exit`, it follows the same execution path as `show`.

```luau
Frame {
    presence(isOpen, Panel, {
        exit = function(nodes)
            return runtime.timeline { duration = 0.2 }
        end,
    }),
}
```

The builder receives `phase` and can return one node or an array of nodes.
`phase.exiting` is a readable that stays true while the subtree is leaving.

`exit` is called once, with the nodes that are leaving, at the moment the condition goes false.
The subtree stays mounted and owned until the object that `exit` returns reports `completed`. Compose then removes and disposes the subtree exactly once.
Anything with a `completed` readable works. A timeline is the obvious choice.

`presence` does not animate. Bindings in the retained subtree must read the exit progress and convert it into host values.

**Re-entry reclaims.** If the condition becomes true during exit, Compose keeps the same subtree and sets `phase.exiting` to false.
An animation that is bound to that value can reverse from its current position.
Compose neither rebuilds nor disposes the subtree. The abandoned exit cannot remove it later.

**Disposal wins.** An owner that is disposed during an exit releases the leaving subtree immediately.
A subtree on its way out never outlives the tree that made it.
An `exit` that raises, or that returns something with no `completed`, releases the subtree and reports the failure.
A broken exit must not become a leak.

### `Compose.switch`

`switch(source, branches, fallback?) -> directive`

One of several subtrees, chosen by key. A key with no branch mounts `fallback`, or nothing.
This is deliberately not an error. A key space that grows at runtime must degrade to empty and must not crash a frame.

```luau
Compose.switch(screen, {
    list = ListScreen,
    detail = DetailScreen,
    error = ErrorScreen,
}, Loading)
```

Like `show`, each branch can return either a node or another directive.

### `Compose.keyed`

`keyed { from, key?, render } -> directive`

A collection whose rows survive reordering.
`render(value, index, key)` receives the value and the index as **readables**, so a row renders again in place when its data or its position changes.

```luau
keyed {
    from = items,
    key = function(item)
        return item.id
    end,
    render = function(item, index)
        return Row {
            Name = function(use) return use(item).name end,
            LayoutOrder = index,
        }
    end,
}
```

The named `key` and `render` fields distinguish two callbacks that both accept a value.
Use the field names to keep identity selection separate from row construction.

`from` accepts a cell, a formula or a body. `key` defaults to the value itself.
If values are structural copies and not stable objects, supply a key function.

If the source is reordered, Compose **moves** the existing nodes. It does not destroy and rebuild them.
This keeps a text field focused, an animation running and a scroll position still.

If a row factory raises, that row unwinds while reconciliation continues with independent rows.
Compose mounts or reorders the successful rows, and then reports all factory failures together.

- The update is not a transaction. Successful rows remain tracked for later reuse or removal.
- Clearing the source releases all rows.
- Row indices still refer to positions in the requested source list, including positions whose factory failed.

### `Compose.indexes`

`indexes(source, render) -> directive`

A collection keyed by position. The row at position 3 is always the same row. Only its value changes.
It is right for a window onto changing data, a log tail or a fixed set of slots.
It is wrong when items have an identity that must follow them around.

```luau
Compose.indexes(function(use)
    return use(logLines)
end, function(line, index)
    return Text { Text = function(use) return use(line) end }
end)
```

### `Compose.OrderedCollection`

`OrderedCollection { from, key, render, mode, viewport, layout, ... } -> directive`

Retains an ordered population in full or through a moving window.
It computes row sizes, grid wrapping and overscan.
It can follow the newest message, or preserve the position of the reader when earlier history loads.

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

`mode` is explicit and has no threshold. `"all"` mounts everything. `"windowed"` mounts the visible rows plus `overscan`.
Population changes do not switch the retention policy.

`viewport` is a readable `{ offset, size }` in the unit that your host measures. `"windowed"` requires it.
`render` receives the `placement` of the row, a readable that carries its `index`, `row`, `column`, `offset`, `size`, `crossOffset` and `crossSize`.

`layout` accepts a static options table, a cell or formula that holds that table, or a body that takes `use` and returns it.
The options are `kind` (`"list"` or `"grid"`), `columns`, `itemSize`, `gap`, `crossSize` and `crossGap`. For example:

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

- If resolved layout values change, Compose updates the placement, the extent, the controls and the retained window.
- Keys that are present in both windows keep their nodes, owners and component state. Keys that leave the window dispose normally.
- In `"all"` mode, every surviving key keeps its state through reflow.
- Static tables are construction-time options. To publish changes, use a readable or a body.

`itemSize` is the fixed size for a fixed collection and the estimate for a measured collection.
To correct the estimate as rows report their real sizes, pass `measured`, a readable of key-to-size.
A grid row is as tall as its tallest item. Measurements remain authoritative by key through reflow.
If a width or theme change invalidates them, publish cleared or updated measurements with the layout change in one batch.

**It does not scroll or measure the host.**
It computes placement and publishes requested scroll changes through `status.desiredOffset`.
The adapter reads the scroll position, measures rows and moves the viewport.
Supply `status`. Have the adapter apply its requested offset and publish the actual offset through `viewport`.

Reflow works as follows:

- It anchors the first visible key, excluding overscan, and preserves its offset relative to the viewport start.
- Compose clamps the requested offset to the new scroll bounds.
- End-following takes precedence. An explicit viewport offset change takes precedence over key anchoring.
- If the anchor key disappears, Compose preserves the current offset, within those bounds.
- The mounted window immediately covers the requested offset.
- The request remains pending while the reported offset is unchanged, so repeated reflows accumulate without losing the anchor.
- If the adapter reports the requested offset, it acknowledges the request. If it reports a different offset, Compose treats that as an explicit scroll.
- Compose performs no host scroll.

`status` is a cell. The collection writes it **only when one of its fields differs**, not on every pass.
A scroll that keeps the retained range, the geometry and the measurements writes nothing.
An adapter that watches `status` therefore stays asleep on a frame with nothing to apply.
`controls` is a table that the collection fills with `offsetOf(index, align, size)`, `indexOfKey(key)` and `placementOf(index)`, to drive your own viewport.

`placementOf(index)` returns a frozen placement.
It returns the same table for the same index until the geometry or a measurement moves that index.
The placement readable of a retained row holds the same table, so a repaint that changes nothing allocates nothing.

`controls` has no `slotAt(offset)` and no `boundaryBetween(a, b)`. Both values derive from `placementOf`, so core does not carry them.

- The boundary before slot `index` is `placementOf(index).offset`.
- The boundary after that slot is `.offset + .size`.
- To find the slot at an offset, run a binary search over `placementOf`. The offset of a placement rises with the index, and each probe costs one tree descent:

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

`follow = "end"` keeps the view at the newest item. It disengages when the reader scrolls away. It stays active when new content arrives.

Scrolling costs the retained slice, not the population. The range is a division for uniform rows and a tree descent otherwise.
Work that is proportional to the whole list happens when the list changes, which Compose detects by identity, or when it rebuilds measured geometry for changed layout values.
An equivalent layout table does not rebuild geometry.

A change to the measured size of one row is incremental.
If you publish a new `measured` table, Compose walks the keys of that table to find what differs.
Each size that did change costs one row maximum and one prefix-tree update. That is a tree descent, not a rebuild.
Compose rebuilds the geometry only when the list identity or a layout value changes.

### `Compose.SpatialCollection`

`SpatialCollection { from, key, position, origin, tiers, render, ... } -> directive`

A world population that Compose retains by relevance, not by count, for 2D or 3D.

```luau
SpatialCollection {
    from = entities,
    key = function(entity)
        return entity.id
    end,
    position = function(entity)
        return entity.x, entity.y, entity.z
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

    render = function(entity, representation)
        return Marker {
            entity = entity,
            tier = function(use)
                return use(representation).name
            end,
        }
    end,
}
```

It decides **which entities have a representation and at what detail**. It does not place them.
The mounted item owns its own transform, so a moving entity keeps its nodes and updates its own bindings. Compose does not rebuild it.

- `tiers` are listed nearest first, by ascending radius. Past the outermost radius, an entity is not retained.
- `render` receives a `representation` readable that carries `tier`, `name`, `distance` and `pinned`.
- `position` returns two or three coordinates. A 2D world does not return a third.
- `hysteresis` widens a boundary **in the direction of leaving only**. An entity that oscillates on a tier radius settles and does not mount and dispose on alternate frames. An entity that has genuinely come closer is promoted immediately.
- `budget.mountsPerFrame` admits newly relevant entities over successive frames, nearest and most detailed first. Arriving in a dense area then fills the scene in and does not stall one frame. It needs the host `frames` capability. It subscribes only while there is a backlog.
- Departures are never budgeted. Keeping something that must be gone is a correctness problem, not a scheduling problem.
- `pinned` is a readable set of keys that Compose always retains, whatever the distance. Their tier is still what distance earns, so a pinned entity far away is a marker and not a full model.
- `importance` multiplies the radii of one entity, so a landmark stays relevant further out without a tier of its own.

After every pass, the collection writes `total`, `retained`, `queried`, `pending`, `perTier` and `cells` to the `status` cell.
Compare `queried` with `total` to see how much of the population the spatial index excluded from the query.

On Roblox, this collection complements instance streaming and SLIM. It does not restage them.
The engine already decides what it replicates and how it draws distant models.
The engine cannot infer which entities deserve a label, audio or a group marker, and how much construction one frame can do.
Ordinary geometry must still be streamed geometry.

### `Compose.TileCollection`

`TileCollection { viewport, tileSize, read, render, overscan? } -> directive`

Owns the nonempty tiles that intersect a rectangular camera view.
Coordinates are zero-based integers, including negative coordinates.
Each `(column, row)` is a stable identity within one collection. Use one collection for each map layer.

```luau
Compose.TileCollection {
    viewport = camera,
    tileSize = { width = 32, height = 32 },
    overscan = 1,
    read = function(use: Compose.Use, column: number, row: number): string?
        local rowCells = map[row]
        local tile = if rowCells ~= nil then rowCells[column] else nil
        return if tile ~= nil then use(tile) else nil
    end,
    render = function(tile: Compose.Readable<string>, placement: Compose.TileCollectionPlacement)
        return Host.Tile {
            Image = tile,
            X = placement.x,
            Y = placement.y,
        }
    end,
}
```

`viewport` is a cell, a formula or a body that returns `TileCollectionViewport = { x, y, width, height }` in the same units as `tileSize`.

- The grid origin is `(0, 0)`.
- Dimensions must be finite. Tile dimensions must be positive. Viewport dimensions must be non-negative.
- A zero-area viewport retains nothing, including overscan.
- The right and bottom edges are exclusive. A tile that partially intersects is included.
- Optional `overscan` is a non-negative integer number of extra rows and columns on every side. The default is zero.
- `tileSize` and `overscan` are construction-time options.
- Apply camera translation and zoom through the host. Publish the corresponding rectangle in grid-world units.
- Derived coordinate bounds must be safely representable integers.

`read(use, column, row)` supplies application data for each covered coordinate.

- Return `nil` for an empty or out-of-map coordinate. `false` is valid tile data.
- Read reactive inputs through `use`, including a cell that holds `nil` while an empty coordinate can become occupied.
- If the application replaces the map structure, read a reactive map or revision before you look up its cells. A plain table mutation alone does not publish a change.
- `read` must only read data. Create owned resources in `render`.

`render(value, placement)` builds one host node.

- `value` is readable and changes in place.
- `placement` is a frozen `TileCollectionPlacement` that contains `column`, `row`, `x`, `y`, `width` and `height`. It stays fixed for the mounted lifetime of that coordinate.
- Bind host properties to the readable value. Publish replacement values for changed records. The default equality is `==`.
- If `read` returns `nil`, or if the tile leaves the retained rectangle, Compose disposes the tile. If `read` later returns data, Compose builds the tile again. Persistent application state belongs in the map of the application.

A camera change or an observed data change reads the covered rectangle, including empty coordinates, and then reconciles its occupied tiles.
The cost depends on that rectangle, not on the full map.
A single visible edit still reads that rectangle again. Only changed bindings write to the host.
Per-coordinate reactive inputs outside the rectangle have no collection subscription.
When one node for each tile would be too expensive for the host, use chunk coordinates and a chunk renderer.

The collection delegates creation, placement and destruction to its host.
Storage, loading, atlas interpretation, terrain matching and collision remain concerns of the application or the adapter.
Build failures use the cleanup and partial-success contract of `keyed`.
The runnable [`tile-map` example](../examples/tile-map.luau) checks bounded reads, edits, camera churn and teardown with the test host.
It does not establish native rendering performance.

### `Compose.LayerStack`

`LayerStack(options) -> directive`

Retains stable keyed layers from bottom to top.
Each layer receives a readable state with `index`, `depthFromTop`, `top` and `covered`, so visibility and input policy update without a rebuild of the covered scene.
`retention = "top"` mounts only the top layer. The default `"all"` preserves covered state.

### `Compose.MountBudget`

`MountBudget(options) -> directive`

Admits newly present keyed items over frames, ordered by the optional numeric `priority`. It removes departures immediately.
`mountsPerFrame` is required.
A backlog takes one frame subscription and releases it when drained. `status` reports `total`, `mounted` and `pending`.
`SpatialCollection` shares the same admission engine.

### `Compose.createFocusScope`

`createFocusScope(options) -> FocusScope`

Creates an owner-bound, host-neutral focus policy over stable enabled keys.
The controller exposes `current`, `focus`, `clear`, `first`, `last`, `next`, `previous`, `move` and `isFocused`.
For directional movement, pass `position`.
An adapter watches `current` and applies native focus, so noninteractive collections pay nothing.

### `Compose.focusNeighbor`

`focusNeighbor(from, candidates, direction) -> number?`

Returns the index that the rectangle ranking policy of Compose selects for a move from `from`, or `nil` when no candidate lies ahead.
Rectangles are `FocusRect = { x, y, width, height }`. `direction` is a `FocusDirection`.

- A candidate is ahead when its near edge is past the center of `from` and, unless it overlaps `from` on the cross axis, it ends past the leading edge of `from`.
- Candidates that overlap `from` on the cross axis rank first, by gap and then by center offset.
- Next come the candidates whose center lies within 45 degrees of the move, measured from the middle of the leading edge of `from`. They rank by center offset plus 0.028 times their distance along the move.
- The rest rank last, by center offset divided by `max(distanceAlongMove, 1)^0.15`.
- Equal scores prefer the smaller center offset, and then the first candidate in the array.
- Supply finite coordinates and positive widths and heights in the same units.
- An unknown direction raises `focus-neighbor/unknown-direction`.

This is a pure function. An adapter that owns focus geometry calls it with host rectangles.
Native focus parity needs a separate comparison on that host. This policy does not guarantee it.
It does not change the point-based navigation policy of `createFocusScope`.

```luau
local nextIndex = Compose.focusNeighbor(
    { x = 0, y = 0, width = 40, height = 40 },
    { { x = 60, y = 0, width = 40, height = 40 } },
    "right"
) -- 1
```

### `Compose.createPool`

`createPool(options) -> Pool`

Creates an owner-bound, opt-in pool for expensive resources.

- `acquire` returns `{ value, release }`.
- `release` is idempotent. It calls `reset`, and it retains at most the required finite `maxRetained`.
- Owner disposal destroys idle and checked-out resources exactly once.
- Compose never pools nodes automatically, because structural identity and cleanup remain explicit.

For owner lifetimes, see [ownership](ownership.md). For a complete example, see [composition-primitives.luau](../examples/composition-primitives.luau).

### `Compose.createKeyedCache`

`createKeyedCache(options) -> Cache`

Creates an owner-bound cache with arbitrary keys and a finite `maxRetained` limit.
When the cache is full, it evicts the least-recently-used entry.

- `get(key)` builds on a miss. On a hit, it returns the retained value and marks it most-recently-used.
- `peek(key)` reads without building or changing recency.
- `evict(key)` destroys one retained entry. It does nothing if the key is absent.
- `size()` returns the retained count.
- `keys()` returns the retained keys, least-recently-used first.
- Optional `touch(key, value)` observes every hit or miss without affecting retention.

Owner disposal destroys each retained value exactly once, newest-recency-first.
Cache values are not leases. A consumer holds references only while the cache retains them.
If you add a newer key, the cache can evict a value that a consumer still references.

This is the primitive for expensive, identity-keyed builds that a host must not repeat on every use.
For example, build one mesh for each distinct item and reuse it for every instance of that item, instead of building it again for each use.

### `Compose.geometry`

Pure rectangle arithmetic with no host and no state.
A frame is `{ left, top, right, bottom, width, height }`. Inputs need only `left`, `top`, `right` and `bottom`.
Applications supply the layout choices (sizes, margins, preference order). Compose does not choose them.

| Call | Meaning |
| --- | --- |
| `safeArea(viewport, insets?, margin?) -> frame` | Returns the viewport `{ width, height }` minus `insets { left?, top?, right?, bottom? }` and `margin` on every side. An overflowing inset gives a zero extent, never a negative one. |
| `fit(available, desired, options?) -> frame` | Places a `desired { width, height }` panel inside `available`. It caps the panel by `options.max`, raises it to `options.min`, and then limits it to the room. `options.anchor { x, y }` in `[0, 1]` places it (default centered). |
| `overlaps(a, b) -> boolean` | True only for shared area. Touching edges are clear. |
| `contains(outer, inner) -> boolean` | True when `inner` lies inside `outer`, edges included. |
| `firstClear(candidates, options?) -> (rect?, index?)` | Returns the first candidate that is inside `options.within` and clear of every `options.reserved` rect. It returns nil when all are blocked, so the consumer chooses the fallback. |

`firstClear` preserves extra candidate fields in its return type.
It validates `within`, the candidates and the reserved records as bounds at runtime.

Calls refuse bad input with these diagnostics:

- `geometry/invalid-number`: non-finite, or negative where a size or inset is expected
- `geometry/invalid-rect`: missing, or right before left, or bottom before top
- `geometry/invalid-size`
- `geometry/invalid-insets`
- `geometry/invalid-limits`: minimum above maximum
- `geometry/invalid-anchor`
- `geometry/invalid-candidates`

```luau
local area = Compose.geometry.safeArea(viewport, insets, 12)
local panel = Compose.geometry.fit(area, { width = 420, height = 600 }, { max = { width = 480, height = 640 } })
```

### `Compose.fragment`

`fragment(builder) -> directive`

Places several nodes where one child is expected, without a container that the layout did not ask for.

### `Compose.portal`

`portal(target, builder) -> directive`

A subtree that lives elsewhere in the host tree, such as tooltips, modals and world-space markers.
Its own slot stays empty. Its nodes go into `target`.
Its lifetime is unchanged. If you dispose the component that wrote the portal, Compose removes exactly what the portal added and leaves `target` standing.

### `Compose.boundary`

`boundary(builder, fallback) -> directive`

A subtree that can fail without taking the screen with it.
`fallback(failure, retry)` renders the failure.
A failure is anything that the subtree raises while it builds, while its watches run, or while its bound properties read a formula.

```luau
Compose.boundary(Summary, function(failure, retry)
    return ErrorPanel {
        Text = "Summary failed: " .. tostring(failure),
        [Compose.event("Activated")] = retry,
    }
end)
```

The boundary catches failures in its builder and in the watches beneath it.
These include property bindings, structural updates and user watches.
It does not catch a failure in its own fallback.
For the resource-unwind guarantees, see [failure cleanup](ownership.md#failure-unwinds-completely).

---

## Context

### `Compose.createSharedResource`

`createSharedResource(factory) -> acquire`

One expensive thing for many consumers. Compose releases it when the last consumer goes.

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

Each call acquires a reference and registers its release with the active owner.
When the last reference is released, Compose disposes the resource. A later acquisition builds a fresh resource.

**The factory runs under the own owner of the resource, never the owner of the consumer.**
If the factory of A acquires B, A keeps that reference to B.
The first departing consumer of A releases neither resource. The last consumer releases both, innermost last, exactly once.
A failed factory releases its partial acquisitions and caches nothing.

`acquire.detached()` returns the value **and** its release, for a consumer with no owner and a lifetime of its own to manage.
Calling that release twice is safe. If you forget it, the resource stays held for the life of the process. That is why you must ask for this form.

### `Compose.easing`

A frozen table of easing functions: `linear`, and the `in`, `out` and `inOut` variants of `Quad`, `Cubic`, `Quart`, `Quint`, `Sine`, `Expo`, `Circ`, `Back`, `Elastic` and `Bounce`.
Each takes normalized progress in `[0, 1]`.
The `Back` and `Elastic` variants can return values outside that range to produce overshoot.

```luau
runtime.tween(opacity, { seconds = 0.25, ease = Compose.easing.outQuad })
```

### Reduced motion

`spring` and `tween` both accept `reducedMotion`.
The policy is a cell, a formula or a body that reads a boolean.
It is a source, not a plain boolean, because the setting changes while the application runs.
A value that is neither raises `animation/bad-reduced-motion`.

```luau
local calm = Compose.cell(GuiService.ReducedMotionEnabled)
runtime.spring(progress, { period = 0.3, reducedMotion = calm })
```

- While the policy reads true, the animated value reaches each new target on the frame that retargets it. Compose interpolates nothing, holds no frame listener, and writes once for each change instead of once for each frame.
- If the policy turns true in mid-flight, the value lands on its current target at once and the integrator settles.
- A policy that turns false again therefore starts from rest, not from a stale velocity.
- An absent or false policy leaves the animation unchanged.

Compose reads the policy. It does not discover the setting, because core cannot read an accessibility preference.
Read the preference in your application and write it into a cell.

### `Compose.registerCodec`

`registerCodec(typeName, codec) -> ()`

Teaches Compose to animate a type without core ever naming it.
A codec has `arity`, `encode(value, out)`, `decode(components)` and an optional `normalise(components)`.

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

`encode` writes into a buffer that the consumer owns, because an animation encodes on every frame, and a per-frame allocation is a per-frame collection.
Core registers exactly one codec: `number`. `ComposeRoblox` registers the Roblox datatypes.

### `Compose.registeredCodecs`

`registeredCodecs() -> { string }`

Returns every registered type name, sorted.

### `Compose.createSpringState`

`createSpringState(position, arity) -> State`

Creates a spring state at rest at `position`.
The integrator is pure and public, so you can drive it yourself or test against it.

### `Compose.stepSpring`

`stepSpring(state, target, delta, period, damping) -> simulatedSeconds`

Advances `state` towards `target`, in place.
It integrates at a fixed 120 Hz internally, so the same animation produces the same curve at 30 fps and 240 fps.
It clamps a very large delta and does not simulate it. It returns the seconds that it actually simulated.

### `Compose.springAtRest`

`springAtRest(state, target, reference, tolerance) -> boolean`

Reports whether the spring has settled close enough to stop simulating.
"Close enough" is relative to the distance that the spring set out to travel, so a spring that moves a pixel and a spring that moves a thousand settle at the same perceived moment.

### `Compose.springCoefficients`

`springCoefficients(period, damping) -> (stiffness, drag)`

Returns the coefficients behind the model, for anyone who integrates it.

---

## Diagnostics

### `Compose.formatDiagnostic`

`formatDiagnostic(code, summary, fields?) -> string`

Formats a diagnostic without raising it. Adapters use it to report errors in the same format as core.

### `Compose.parseDiagnostic`

`parseDiagnostic(message) -> Diagnostic?`

Parses a Compose diagnostic into `{ code, summary, fields }`.
Use this inverse of `formatDiagnostic` instead of a separate parser for thrown messages.

```luau
local ok, err = pcall(build)
if not ok then
    local diagnostic = Compose.parseDiagnostic(tostring(err))
    if diagnostic ~= nil and diagnostic.code == "owner/no-active-owner" then
        -- diagnostic.fields.fix is the one-line remedy the message carried
    end
end
```

This pure function reads a string. It does not intercept, change or suppress the original failure.
Parsing adds no work to code that does not call it.

It returns nil for non-Compose diagnostics.
It accepts a source-location prefix, including the prefix that `error` produces at a non-zero level and that `pcall` often returns.

### `Compose.setWorkCounters`

`setWorkCounters(enabled) -> ()`

Turns work counting on. It is off by default. When it is off, it costs one boolean read, so a timing run measures the runtime and not the instrumentation.

### `Compose.readWorkCounters`

`readWorkCounters() -> WorkCounters`

Returns a snapshot of these counts: cell writes, writes suppressed, notifications, formula recomputations, recomputations suppressed, watch runs, watch schedules, schedules coalesced, drains and continuation passes.

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

Runs every user function on a fresh coroutine, so that Compose reports a yield inside reactive code at the point of the yield.
It costs a coroutine for each user call. Use it for development and tests, not for a shipped frame loop.

### `Compose.profile`

`profile.start(now, options?) -> ()`
`profile.stop() -> ProfileReport`
`profile.label(node, name) -> ()`
`profile.active() -> boolean`
`profile.format(report, limit?) -> string`
`profile.data(report) -> ProfileData`

Records the work that each reactive write causes: cell changes, formula recomputations, watch runs and host property writes.
The report uses the graph labels that you provide.

The profiler is off until you start it. Its hooks share the work-counter branch and add no fields to nodes.
**Compose records labels only while the profiler runs.**
Start it before you build the screen, to capture those labels.
Earlier nodes still report work and fan-out under synthetic names such as `cell#12`.

- `start` takes the clock, because core does not read time on its own. Pass whatever your host uses to measure elapsed seconds.
- `options` bounds capture: `maxNodes` (default 4096) and `maxDrains` (default 256).
- Capture is aggregate and not a log, so nothing grows with the number of writes. **Compose records no application value.** The report holds counts, IDs and the labels that you supplied.
- `stop` returns the report and drops everything that the recorder held.
- `format` renders the report deterministically for a terminal. `data` returns the same content as plain tables that are ready for JSON.
- A failure inside the recorder cannot reach the application. The recorder marks itself broken, stops recording, and the report says that the numbers are incomplete.

```luau
Compose.profile.start(elapsedSeconds)

local level = Compose.cell(100)
Compose.profile.label(level, "item.level")

local dispose = runtime.mount(App, root)
-- ... drive a few seconds of the thing you are debugging ...

print(Compose.profile.format(Compose.profile.stop()))
```

```
compose profile: 4.017 s, 63 node(s) tracked

  writes 480 (12 suppressed) | recomputations 480 (61 published) | watch runs 61 | host writes 61
  schedules 61 (0 coalesced)

hottest:
  item.level                         480 writes, 12 suppressed, fan-out 1
      -> levelPercent                x480
  levelPercent                       480 recomputes (61 published)
      -> Frame.Size                  x61
  Frame.Size                         61 runs, 61 host writes
```

The report lists total work and the busiest nodes. Arrows identify the downstream work that each node causes.

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
`inspect.data(report) -> InspectData`

Reports node custody, owners and their retained resources, to explain why a resource remains alive.

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
  Dashboard  holding 1
    tree: 401 nodes owned, 1 adopted, 0 borrowed, 60 watches, 0 cleanups, 41 owners
    1 child owner
    owner#2  holding 42
      1 owned node, 40 child owners
```

`inspect.node(node).because` describes the ownership relationship in a sentence.

The inspector is off until you start it. When it is off, no field exists on any owner or node, no label exists, and nothing holds a reference.
The cost follows the same rule as [`Compose.profile`](#composeprofile):
**an owner that you build before `start` reports its total but not its breakdown.**
The report says which case applies. It does not report zeroes as though they were measurements.

`options` bounds capture: `maxOwners` (default 4096) and `maxNodes` (default 16384).
Every table that the inspector keeps is weakly keyed, so inspecting something never keeps it alive, and `stop` drops all of it.
Compose records no application value.

**`report.trackedNodes` counts nodes across the process. Do not assert per-test deltas on it.**
It counts a weak-keyed table of nodes whose custody Compose recorded.
The count falls when the collector reclaims entries, on its own schedule.
It can include nodes from unrelated tests that the collector has not yet reclaimed.
Identical operations can therefore produce different deltas. Use it only as a rough diagnostic count.

For exact owner-scoped deltas, use `inspect.owned(owner)`. It returns `{ ownedNodes, borrowedNodes }`.
`ownedNodes` counts the nodes that the owner created or adopted and will destroy on disposal.
`borrowedNodes` counts borrowed nodes while the owner holds them.

These counts decrease immediately when disposal calls `forget`. They do not wait for collection.
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

For custody and disposal rules, see [ownership](ownership.md).

### `Compose.outstandingMounts`

`outstandingMounts() -> number`

Returns how many top-level mounts are not yet disposed. A test that asserts this is zero is a leak check.

---

## `src/test-scene`

### `TestScene.create`

`create() -> TestScene`

Creates an isolated, deterministic scene with a host adapter and inspection helpers.
Its nodes are frozen empty tables, so core code that reaches around the protocol fails immediately and does not work by accident.

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

The full surface is `adapter`, `root`, `makeNode`, `kindOf`, `propertyOf`, `attributeOf`, `nameOf`, `childrenOf`, `parentOf`, `isAlive`, `handlerCount`, `declareEvent`, `dispatch`, `poke`, `step`, `now`, `failNext`, `clearFailures`, `counts`, `resetCounts`, `liveNodes`, `liveSubscriptions`, `leaked` and `serialize`.

It stores attributes for `string`, `number`, `boolean` and `nil`. It refuses anything else with a reason.
`failNext("setAttribute")` is the exception to the usual meaning of `failNext`.
It makes the next `setAttribute` *report* a refusal and not raise, because that is what the protocol asks that verb to do.

### `RobloxEmulator.create`

`create(environment, engine) -> Emulator`

Connects a [Verify Roblox test environment](https://github.com/voidmeld/verify/blob/main/docs/api.md) to the real Roblox adapter, from `src/test-scene/roblox`.
Verify owns the simulated engine: Instances, classes, signals, virtual time, disposal accounting and unsupported-member errors.
Compose adds operation logging and failure injection.
Pass the environment and `Verify.environmentEngine(environment)`. Verify supplies datatype conversion without wrapping objects or signals.
Compose does not require Verify at runtime.
The [runnable emulator example](../examples/roblox-emulator.luau) shows the complete setup.

The surface is `engine`, `adapter`, `render`, `environment`, `root`, `createInstance`, `log`, `clearLog`, `failNext` and `clearFailures`.
Use `environment` for time (`step`, `now`), engine-side changes (`poke`, `fire`), inspection (`childrenOf`, `propertyOf`, `liveObjects`, `liveConnections`) and `defineClass`.

- `adapter` uses `ComposeRoblox.createHost(emulator.engine)`.
- `render` wraps the renderer of that adapter, to log operations and inject failures. Tests therefore exercise `src/roblox/host.luau` itself. Like that adapter, it has no `moveChild`.
- `createInstance(className, props)` also takes children in the array part and sets them before the parent.
- `log()` returns the ordered render operations `createNode`, `setProperty`, `setAttribute`, `clearProperty`, `insertChild`, `removeChild`, `destroyNode` and `setName`, each with the node and its class name.
- `failNext(operation, times?)` makes those verbs raise, except `setAttribute`, which reports a refusal instead, exactly as `TestScene` does.

See [simulation limits](roblox.md#what-the-simulation-cannot-check).

---

## `src/roblox`

### `ComposeRoblox.createRuntime`

`createRuntime(engine?) -> Runtime`

Returns a runtime that is bound to the Roblox host. This is the usual entry point.
Inside Roblox, call it with no argument. To run the adapter anywhere else, pass an engine.

```luau
local runtime = ComposeRoblox.createRuntime()
local dispose = runtime.mount(Overlay, playerGui)
```

### `ComposeRoblox.createHost`

`createHost(engine?) -> Host`

Returns the host itself. Pass it to `Compose.createRuntime` directly, or use it to reach a capability without a runtime, for example `host.observation.observeProperty`.

### `ComposeRoblox.animatableTypes`

`animatableTypes(engine?) -> { string }`

Returns every Roblox datatype that this engine can animate, sorted.
Currently these are `CFrame`, `Color3`, `UDim`, `UDim2`, `Vector2` and `Vector3`, plus `number` from the core.

### `ComposeRoblox.cleanup`

`cleanup(value) -> dispose`

`Compose.cleanup`, extended for Roblox:

- It disconnects an `RBXScriptConnection`.
- It cancels a thread.
- It destroys an `Instance`.
- It disconnects a table with `Disconnect` or `disconnect`.
- It passes everything else to the core.

Passing an Instance is an ownership statement.
For something that you did not create, `runtime.adopt` says it more clearly.
For something that you must *not* destroy, say nothing. Borrowed is the default.

### `ComposeRoblox.createCleanup`

`createCleanup(typeName?) -> cleanup`

Returns a `cleanup` that is bound to a particular way of naming types.
Inside Roblox, the default is the global `typeof`, which is what you want.
A test engine supplies its own, so that the real branches of the adapter are the ones under test.

### `ComposeRoblox.createViewport`

`createViewport(camera, engine?, options?) -> (Compose.Readable<{ width, height }>, Compose.Readable<boolean>)`

Returns a reactive `{ width, height }` that stays current from `camera.ViewportSize` through `GetPropertyChangedSignal`. Compose releases it on owner disposal.
Give the first result to a layout formula.
`camera` is anything with a `ViewportSize` property that has the shape of a Vector2. Ordinarily it is `workspace.CurrentCamera`.

A camera can report a placeholder before the client viewport exists.

- A size below `minimumSide` on either axis, or with non-finite dimensions, is unknown.
- The source ignores invalid updates and keeps its last valid size.
- Readiness starts false until the first valid size arrives, and then stays true.
- Before any valid size arrives, the source returns the fallback. Consumers never receive nil.

`options` is `{ minimumSide: number?, fallback: { width, height }? }`, with the defaults `100` and `{ width = 1280, height = 720 }`.
Read readiness when the difference matters, to hold a first layout or a fade-in. Ignore it when it does not matter.

### `ComposeRoblox.usableViewportSize`

`usableViewportSize(size, minimumSide?) -> boolean`

The rule that `createViewport` holds to, on its own, for an application that owns its own observation wiring.
It is true when `size` is a pair of finite numbers at or above `minimumSide` on both axes. The default is `100`.

### `ComposeRoblox.preferredInput`

`preferredInput(inputService?, engine?) -> Cell<PreferredInputClass>`

Returns the reactive input class for `UserInputService.PreferredInput`: `Touch`, `KeyboardAndMouse` or `Gamepad`.
It follows property changes for the lifetime of the current owner.
The optional arguments make adapter tests explicit. For ordinary Roblox use, call `ComposeRoblox.preferredInput()`.

### `ComposeRoblox.preferredInputSpec`

`preferredInputSpec(preferred) -> PreferredInputSpec`

The pure counterpart for style selection.
It maps a `PreferredInput` enum value to its input class and its stable token: `touch`, `keyboard-and-mouse` or `gamepad`.

---

## Authoring project trees

`authoring` runs at build and edit time, never inside a mount.
The package guide is [`../authoring/README.md`](../authoring/README.md). This section owns the project-tree generator.

### `Author.set`

`set(options) -> EntrySet`

Wraps an authored entry array as a semantic entry set that `name` names, keyed by `idKey`, and optionally grouped by `roleKey`.
The set answers `byId` and `byRole` deterministically.

```luau
local props = Author.set { name = "props", idKey = "id", entries = { { id = "lamp" } } }
```

### `Author.validate`

`validate(set, rules) -> (boolean, { Violation })`

Checks a set against `idPattern`, `unique`, `required` and `refs`.
Violations return in entry order, and then in the rule order that this paragraph lists. Each is `{ setName, entryId, rule, detail }`.
`refs` skips absent fields. To reject them, use `required`.
A reference names either a target set with `into` or allowed values with `oneOf`.

```luau
local ok, violations = Author.validate(props, { idPattern = "^%l[%l%d%-]*$", unique = true })
```

### `Author.digest`

`digest(set) -> string`

Computes a content digest of a set: 16 lowercase hex characters, stable across key order and entry order.
The declaration name, `idKey` and `roleKey` are part of it, so a rename changes the digest.
This is change detection, not cryptography.

### `Author.coverage`

`coverage(set, keys) -> Coverage`

Reports authored IDs and roles that are missing from a registry key list. Use it to find entries without handlers before runtime.

### `Author.bake`

`bake` holds the emitters: `attributePlan`, `layoutSheet`, `registryModule` and `dataModule`.
The package guide [`../authoring/README.md`](../authoring/README.md) states what each one produces and what the package refuses to do.

### `Author.placement`

Build-time geometry and semantic placement resolution over positions `{ x, y, z }`.
The consumer supplies content, anchor positions, routes and thresholds.
Compose resolves generic rules and checks the result without application policy or engine state.

| Call | Result |
| --- | --- |
| `distance(a, b, space?)` | Distance in xz (default) or xyz. |
| `distanceToPath(point, path, space?)` | Distance to the nearest segment in xz. |
| `alongLateral(point, from, to, space?)` | Signed `(along, lateral, length)` for one segment in xz. |
| `nearest(point, items, positionOf)` | Nearest item and xz distance. Ties keep the first item. An empty list returns `(nil, math.huge)`. |
| `ring(count, radius)` | Evenly spaced `{ x, z }` offsets, starting on the positive x axis. |
| `spread(ordinal, step)` | Golden-angle `(dx, dz)` offset with radius `step * sqrt(ordinal - 1)`. Ordinal 1 is the origin. |
| `pathPoint(path, along, lateral, y)` | Position along a path. It extends the end segments when needed. Positive lateral uses the segment normal `(-uz, ux)` in xz. The result uses the supplied height. |
| `resolve(spec)` | Positions keyed by entry ID. |
| `check(points, constraints)` | Violations in constraint order. |

#### Resolve rules

`resolve` takes `{ anchors?, routes?, spreadDistance?, entries }`.
Anchors map IDs to positions. Routes map IDs to paths of at least two positions.
Each entry is `{ id, kind, ... }`:

| Kind | Fields | Position |
| --- | --- | --- |
| `absolute` | `x`, `y?`, `z` | The stated position. |
| `offset` | `from`, `dx`, `dy?`, `dz` | The referenced position plus the offset. |
| `route` | `route`, `along`, `lateral`, `y?` | `pathPoint` on the named route. |
| `spread` | `from`, `ordinal` | The referenced position plus `spread(ordinal, spreadDistance)`, keeping its height. |

- `from` names an anchor or another entry.
- Entries can appear in any order. Cycles and missing references refuse.
- The result contains one new position for each entry. It does not echo anchors and does not change inputs.
- The rule fields `y` and `dy` default to zero.
- Anchor, route-vertex and check-point positions require `y`.
- A spread rule requires a finite, non-negative `spreadDistance` and a positive integer ordinal.

```luau
local positions = Author.placement.resolve {
    anchors = { origin = { x = 0, y = 0, z = 0 } },
    entries = {
        { id = "lamp", kind = "offset", from = "building", dx = 4, dz = 0 },
        { id = "building", kind = "offset", from = "origin", dx = 20, dz = 10 },
    },
}
```

#### Check constraints

Pass resolved positions directly to `check`, or supply your own table keyed by ID.
Each constraint declares a `kind` and its required fields:

| Kind | Fields | Requirement |
| --- | --- | --- |
| `separation` | `ids`, `minimum` | At least two IDs. Every pair is at least `minimum` apart. |
| `clearance` | `subject`, `from`, `minimum` | `from` is nonempty. Its nearest point is at least `minimum` from the subject. |
| `within` | `subject`, `anchor`, `radius` | The subject is within `radius` of the anchor. |
| `path` | `subject`, `path`, `halfWidth` | The subject is within `halfWidth` of the path. |

- `separation` and `clearance` accept a non-negative `tolerance`. The default is zero.
- `clearance` with `strict = true` rejects a distance that equals `minimum` and does not apply tolerance.
- Each violation is `{ index, kind, subject, other?, actual, required }`. `index` names the constraint.

```luau
local violations = Author.placement.check(positions, {
    { kind = "clearance", subject = "lamp", from = { "building" }, minimum = 8 },
})
```

#### Spaces and refusals

`nil` means `"xz"`. `distance`, `separation`, `clearance` and `within` also accept `"xyz"`.
`path`, `distanceToPath` and `alongLateral` accept only `nil` or `"xz"` and refuse `"xyz"`.

- Coordinates and numeric inputs must be finite.
- Thresholds, tolerance, ring radius and spread step must be non-negative.
- Ring count and spread ordinal must be positive integers.
- `pathPoint` rejects a zero-length segment anywhere in its path. `alongLateral` requires distinct endpoints in xz.

Refusals use `placement/` codes: `non-finite-number`, `negative-number`, `unknown-space`, `unsupported-space`, `short-path`, `degenerate-segment`, `bad-ring`, `bad-ordinal`, `bad-rule`, `duplicate-id`, `unknown-anchor`, `unknown-route`, `unknown-rule`, `cyclic-reference`, `bad-constraint`, `unknown-point` and `unknown-constraint`.
Missing required constraint fields and undersized ID lists raise `placement/bad-constraint` with the constraint index and field.

### `Author.projectTree`

`projectTree(plan) -> { documents, order, manifest }`

Turns one declarative mount plan into a Rojo project tree document for each target, plus a manifest of the mounted paths and a digest of that manifest.
The function is pure. It reads no files, so the consumer supplies the source facts as data and gets the same result for the same plan.

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

A `Mount` names its tree location as `at`, an array of ancestor names, then `name`, and then a source `path`, a `className`, or both.
It can also carry `properties`, `attributes`, `ignoreUnknownInstances`, `siblings` and `requires`.
A missing ancestor becomes a `Folder`.

A `properties`, `attributes` or `Identity.values` entry, and a `Variant.properties` entry, each take a `RojoValue`:

- a string
- a finite number
- a boolean
- an array of finite numbers
- a table with exactly one string key whose value is itself a `RojoValue`

The tagged-table shape names a Rojo type, so `{ Enum = 2 }`, `{ Color3 = { 1, 0, 0 } }` and `{ CFrame = { 0, 0, 0 } }` are each one `RojoValue`, and nesting composes them freely.
A table with two or more keys, or a non-finite number anywhere in the shape, is refused.

A `Target` names the document to write and can take a `variant` and an `identity`.
Two targets share one mount plan and still differ in their stamped identity, so a build identity is an injected value and not a second generator.

A `Variant` is data:

- `excludeExact`, `excludePrefixes` and `excludeSuffixes` drop source paths.
- `mounts` adds mounts.
- `properties` merges properties into a named tree location.
- `excludeAt` drops a mount by its tree location, `at` plus `name`, and every mount nested under that location. This reaches a mount that carries a class and no path.
- A mount in `mounts` can set `replace` to overwrite the base mount that already stands at its `at` plus `name` location, instead of raising a duplicate. It refuses when no base mount stands there.
- The base plan never changes, so one target that takes a variant leaves the others alone.

The generator refuses a plan and does not emit a tree that breaks at runtime.

- **Sibling closure.** A mount that declares `siblings` needs every one of those source paths mounted under the same parent, because a mounted module reaches the siblings of its script parent at runtime.
- **Bare relative requires.** Under the default `requirePolicy` of `alias-only`, the generator refuses a declared request that begins with `./` or `../`, because a relative request breaks when the tree places the module somewhere else. To allow them, set `requirePolicy` to `any`.
- **Collisions.** The generator refuses each of these cases: two mounts at one tree location, two targets with one name, an identity that lands on an occupied location, an unknown variant, a mount with neither path nor className, and a value that cannot become a property.

`manifest.digest` is 16 lowercase hex characters over the manifest. It is change detection, not cryptography.
