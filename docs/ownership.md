# Ownership

This guide governs a component that creates, adopts, borrows, or cleans up a resource.

Compose uses ownership to decide which resources it disposes.

## The one rule

**Compose destroys what it made. It never destroys what it was handed.**

Everything below is that sentence, made precise.

## Three custodies

| Custody | How a node gets it | Destroyed on disposal? |
| --- | --- | --- |
| `owned` | `runtime.create(...)` made it | yes |
| `adopted` | you called `runtime.adopt(node)` | yes |
| `borrowed` | everything else, including anything Compose has never seen | **no** |

`borrowed` is the default for an unrecognised node. Guessing wrong in the other direction
would destroy something that was not yours. A mount target, a player's character, a service,
a layer another system manages: all borrowed, all left standing.

```luau
Compose.custodyOf(node)   --> "owned" | "adopted" | "borrowed"
```

Custody lives in a weak-keyed table, so recording it never keeps a node alive.

### `adopt` and `borrow` are both explicit

```luau
runtime.adopt(existingNode)    -- "destroy this when I go"
runtime.borrow(existingNode)   -- "never destroy this"  (already the default; say it when
                               --  the intent matters to a reader)
```

`adopt` refuses a node Compose already owns. A node has exactly one owner, and adopting a
second time would destroy it twice.

### A mount target keeps the custody it has

`runtime.mount` and `runtime.mountFragment` take a target to mount into. Almost always that
target is a node Compose did not make, and it is borrowed. Not always, though: a component
may own a container, a group, a world model, a panel it built, whose contents are decided by
something other than that container's own props.

Mounting into such a node leaves it `owned` (or `adopted`). Demoting it to `borrowed`
would drop it from its owner's destruction set, so the container would outlive the tree that
made it. That is the leaking direction, not the safe one. The safe default applies to nodes
Compose was *handed*, and this is not one.

Two consequences follow, both from reverse order. The block mounted into the container is
torn down before the container is destroyed. Disposing only the block leaves the container
standing with its own children intact.

Inside a mount, the active owner is what puts the two in that order. **Outside any mount**
(a bootstrap that creates its long-lived nodes once and mounts into them afterwards) there
is no active owner, but the target is not ownerless: the scope that created or adopted it is
its owner. So the block is ordered against the target node itself. Destroying that node
disposes every block mounted into it first, newest first, and only then destroys it.
Unmounting a block through its own handle detaches it and leaves the target standing with
the custody it had.

That is the whole difference between the two cases: which thing holds the order. Nothing is
refused for want of an owner, because there is always one: the node's own.

### Subscriptions are always owned

Observing or connecting to a borrowed object owns only the resulting subscription. The
object survives; the subscription does not.

```luau
runtime.decorate(playerGui.Hud, {
    [Compose.event("Changed")] = onChanged,
    BackgroundTransparency = 0.5,
})
```

On disposal: the connection is released, the property is **cleared back to its default**,
and `playerGui.Hud` is untouched. Properties Compose writes onto a borrowed node are always
cleared again. Leaving a tint or a size behind on someone else's node is a leak with a
visual symptom. Owned nodes skip that work, because they are about to be destroyed.

## Owners

An owner is a list of disposers plus the guarantee that each runs exactly once.

```luau
local owner = Compose.createOwner()

local detach = owner.own(function() ... end)   -- register; returns a detach
owner.watch(function(use) ... end)    -- a watch held by this owner
local child = owner.createChild()              -- nests

owner.dispose()   -- releases everything, newest first, exactly once
```

Two properties are load-bearing.

**Exactly once.** Disposing twice, disposing a child and then its parent, or calling a
detach twice: each resource is released once. Entries are unlinked before running, so no
path can reach one again.

**Reverse order.** Newest first. A subscription registered after the node it listens to is
torn down before that node. That is the order that keeps a host from firing an event
against something already gone.

Disposal never stops early. If one disposer raises, the rest still run and the errors are
reported together, because a half-released tree is worse than a loud one.

### Registering after disposal

Running the disposer immediately is the only sane answer. The caller has just created a
resource whose lifetime was supposed to end before it began, usually because an async
callback landed after the tree it belonged to was torn down.

```luau
owner.dispose()
owner.own(function() print("released") end)   --> prints immediately
```

### Checkpoints

```luau
local mark = owner.checkpoint()
-- ... register things ...
owner.rollbackTo(mark)   -- releases exactly those, newest first
```

This is how a failed `create` unwinds. A child owner would do the same job, but a child
owner is a table and seven closures, and node construction is the hottest path in the
library. A checkpoint is one value instead.

## The ambient owner

Declarative code should not thread an owner through every call, so `create`, `cleanup`,
`watch`, and the structural primitives all register against whichever owner is
currently active. Mounting is what makes one active.

Every activation is strictly balanced. `Compose.withOwner` is the only public way to open
one, and it closes whether the body returned or raised.

```luau
local owner = Compose.createOwner()
Compose.withOwner(owner, function()
    Compose.watch(function(use) ... end)
end)
owner.dispose()
```

### Which owner is active, exactly

An activation belongs to the thread that opened it, so "active" is answered per thread and
not per process.

1. The innermost activation opened **by the running thread**, if it has one.
2. Otherwise the innermost activation opened by a thread that is **resuming** this one: an
   ancestor in the resume chain. This is how a task body that Compose resumed
   (including user functions under `Compose.setYieldChecking(true)`)
   registers with the owner that resumed it.
3. Otherwise nothing is active, and every refusal in the table below applies.

The first rule is what makes a yielding body safe to interleave. A component that waits, a
host lookup, a round trip, anything that suspends the thread, keeps its own owner across
the suspension, even when another mount runs to completion in the meantime. The other
mount's activation is on another thread. It is not an ancestor of this one, and it is not
adopted here. Two mounts that yield through each other stay two trees, and disposing one
does not take the other's late nodes and connections with it.

Rule 2 is inheritance down a resume chain, not across it. A thread that Compose is
resuming right now sees the resumer's owner. A thread nobody is resuming, an engine
callback, a deferred handler, anything the host starts on its own, has no chain to
inherit, and refuses. That refusal is the point: a callback that fires after the mount
finished has no way to guess which owner it meant. Say which, with
[`Compose.bindOwner`](api.md#composebindowner):

```luau
local onArrived = Compose.bindOwner(function(child)
    runtime.connect(child, "Changed", handle)     -- registered with this component's owner
end)
runtime.connect(container, "ChildAdded", onArrived)
```

Reactive code still may not yield. A formula that yields has no coherent version, and a
watch that yields observes a world that has moved. `Compose.setYieldChecking(true)`
enforces that in development.

## Entry points, and what happens with no active owner

Mounting makes an owner active. An entry point, a server main, a boot module, a one-shot
job, has not mounted anything yet, so nothing is active. That is the one place where
the primitives above disagree with each other. **This table is the whole contract.**

| Called with no active owner | Behaviour | Diagnostic | Why |
| --- | --- | --- | --- |
| `Compose.watch` | refuses | `owner/no-active-owner` | a watch with no owner has no defined end |
| `Compose.cleanup` | refuses | `owner/no-active-owner` | the teardown would never run |
| `Compose.accumulator` | refuses | `accumulator/no-active-owner` | it subscribes to its source, and the subscription needs an end |
| `Compose.createPool` | refuses | `pool/no-active-owner` | a pool cannot outlive whoever is responsible for its resources |
| `Compose.createKeyedCache` | refuses | `keyed-cache/no-active-owner` | a cache cannot outlive whoever is responsible for its retained values |
| `Compose.createFocusScope` | refuses | `focus-scope/no-active-owner` | it holds a subscription to its source |
| an acquire from `Compose.createSharedResource` | refuses | `async/shared-no-owner` | the reference is released when its holder is disposed |
| every structural primitive (`show`, `switch`, `keyed`, `indexes`, `windowed`, `presence`, `portal`, the collections) | refuses | `structure/no-active-owner` | the subtree belongs to whatever contains it |
| `runtime.create(...)`, `runtime.decorate`, `runtime.connect`, `runtime.adopt`, `runtime.spring`, `runtime.tween`, `runtime.timeline` | refuses | `owner/no-active-owner` | nodes and bindings must belong to something that can release them |
| a context's `provide(value, body)` | **proceeds unowned** | none | the push is popped by the `provide` call itself; the owner registration is only a safety net for a body that raises past it |
| `Runtime:watch` | **falls back to the runtime's root owner** | none | see below |
| `runtime.mount`, `runtime.mountFragment` | **mint a fresh owner per call** | none | see below |

Three rows are exceptions, and each is deliberate.

**A context's `provide` proceeds.** Its stack push is balanced by the `provide` call itself, not
by an owner. Registering with the active owner is a belt-and-braces unwind for a body that
raises. With no owner there is nothing to leak, so refusing would buy nothing.

**`Runtime:watch` falls back.** A runtime already has a root owner, created with the runtime
and released by `runtime:dispose()`. A watch registered there has a defined end, the
runtime's, so the reason `Compose.watch` refuses does not apply. Consumers depend on this
for runtime-lifetime subscriptions set up before anything is mounted.

**`mount` and `mountFragment` mint.** A top-level mount is the thing that *makes* an owner
active; it cannot require one. The minted owner is held by the process root, which is what
`Compose.outstandingMounts()` counts, and the returned handle disposes it. Mounting *inside*
an active owner does not mint: the mount belongs to that owner instead, and is released with
it.

### Making the root explicit

Everything in the first block of that table has the same fix, and writing it out by hand in
every entry point is how it gets forgotten in one of them.

```luau
local owner = Compose.createOwner()
Compose.withOwner(owner, boot)
-- ... and somebody has to remember owner.dispose(), including when `boot` raised
```

`Compose.withRootOwner` and `Compose.createRootOwner` do that, with the disposal guaranteed.

```luau
-- scoped: released when the body returns or raises
local result = Compose.withRootOwner(function(owner)
    return runOnce()
end)

-- long-lived: released at shutdown, and unwound if the boot itself raises
local app = Compose.createRootOwner(function(owner)
    startServices()
    runtime.mount(Hud, host.root)
end, runtime.reactor)

app.dispose()
```

Inside either one, every refusal above becomes an ordinary call, and a top-level `mount`
stops being top-level: it belongs to the root scope, so shutting the scope down takes the
tree with it. See [`api.md`](api.md#composewithrootowner) and `examples/root-scope.luau`.

## Why a watch needs an owner

Nothing in the reactive graph is weak. A dependency edge is a strong object held from both
ends, so a watch keeps running until something disposes it, and the thing that disposes it
is its owner.

That is why a watch outside a mount is refused rather than tolerated. It would have no
defined end, and would keep running for the life of the process.

```luau
Compose.watch(function(use) ... end)   -- raises: no owner to hold the lifetime
```

**Nothing needs to hold the dispose.** `runtime:watch(...)` returns one for the rare case
you want to end a watch early, and throwing it away is safe and usual. Inside a component
the owner holds the lifetime. At the very top a `mount` registers with a process root, and
`Compose.outstandingMounts()` is how a test proves none were left behind.

## Failure unwinds completely

Building a node can fail at the host's `createNode`, at any property write, at any event
subscription, at any child insert, or in the component body itself. After any of them:

- the parent holds exactly the children it held before;
- the slot's child count is unchanged;
- nothing the attempt created survives;
- no subscription the attempt made survives;
- the scheduler is not wedged, and the next mount works.

`tests/lifecycle/unwind.verify.luau` injects a failure at each of these, at several depths,
and asserts all five every time.

## A worked example

```luau
local function Tooltip(target)
    local visible = Compose.cell(false)

    -- Borrowed: someone else's node. The subscription is ours; the node is not.
    runtime.decorate(target, {
        [Compose.event("MouseEnter")] = function() visible:set(true) end,
        [Compose.event("MouseLeave")] = function() visible:set(false) end,
    })

    -- Owned: we made it, we destroy it.
    return Frame {
        Compose.show(visible, function()
            -- Portalled elsewhere, still owned by us.
            return Label { Text = "tip" }
        end),
    }
end
```

Disposing the tree that contains `Tooltip` releases the two connections, the `show`
branch if it is mounted, and the `Frame`. It does not touch `target`, and it clears nothing
from `target`, because nothing was written to it.

## Checklist for new code

1. Did you create a resource that is not a node? It needs a `Compose.cleanup`.
2. Did you take a node from somewhere else? It is borrowed unless you say `adopt`.
3. Did you add a fallible step to mounting? Add a failure-injection test beside it.
4. Did you register something on an owner that could already be disposed? It will run
   immediately, which is correct. Make sure that is what you want.
