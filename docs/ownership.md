# Ownership

This guide governs a component that creates, adopts, borrows, or cleans up a resource.

Compose uses ownership to decide which resources it disposes.

## The one rule

**Compose destroys nodes it creates or explicitly adopts. It preserves borrowed nodes.**

## Three custodies

| Custody | How a node gets it | Destroyed on disposal? |
| --- | --- | --- |
| `owned` | a runtime constructor made it | yes |
| `adopted` | you called `runtime.adopt(node)` | yes |
| `borrowed` | everything else, including anything Compose has never seen | **no** |

An unrecognised node is `borrowed` by default. This default prevents Compose from destroying a node owned by another system.
Examples include an external mount target, a player's character, a service and a shared layer.

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

`runtime.mount` and `runtime.mountFragment` take a target node. An external target is usually borrowed.
A component can also mount into a container that it creates or adopts.

Mounting preserves the target's custody. An `owned` or `adopted` container stays registered for destruction with its owner.
Changing it to `borrowed` would let the container outlive its tree.

Compose disposes the mounted block before it destroys the container.
Disposing only the block preserves the container and its other children.

Inside a mount, the active owner controls disposal order. Outside a mount, the target still belongs to the scope that created or adopted it.
Compose registers the mounted block against that target node.

Before destroying the target, Compose disposes its mounted blocks, newest first.
Calling a block's own disposer removes that block and preserves the target's custody.

### Subscriptions are always owned

Observing or connecting to a borrowed object owns only the resulting subscription. The
object survives; the subscription does not.

```luau
runtime.decorate(playerGui.Hud, {
    [Compose.event("Changed")] = onChanged,
    BackgroundTransparency = 0.5,
})
```

On disposal, Compose releases the connection and **clears the property to its default**. It does not destroy `playerGui.Hud`.
Compose clears properties it wrote on borrowed nodes. It skips this step for owned nodes because it destroys them instead.

## Owners

An owner is a list of disposers plus the guarantee that each runs exactly once.

```luau
local owner = Compose.createOwner()

local detach = owner.own(function() ... end)   -- register; returns a detach
owner.watch(function(use) ... end)    -- a watch held by this owner
local child = owner.createChild()              -- nests

owner.dispose()   -- releases everything, newest first, exactly once
```

Owners guarantee two behaviors.

**Exactly once.** Each resource is released once, even if disposal or detach is called again.
Disposing a child and then its parent does not release the child's resources twice.
The owner removes each entry before calling it.

**Reverse order.** The owner releases the newest registration first.
A subscription registered after its node is released before that node. This prevents events from reaching a destroyed node.

Disposal continues after an error. If a disposer raises, the owner runs the remaining disposers and reports all errors together.
If a disposer registers another disposer during that teardown, the owner runs the new disposer immediately. The owner
skips no disposer. If exactly one disposer fails, the owner raises that failure again with its original value and no
added position. If several disposers fail, the owner raises one summary that names each failure.

### Registering after disposal

An already disposed owner calls a newly registered disposer immediately.
This can happen when an asynchronous callback creates a resource after its tree has been disposed.

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

A failed `create` uses a checkpoint to release resources registered during that attempt.
The checkpoint avoids creating a separate child owner for each node construction.

## The ambient owner

`create`, `cleanup`, `watch` and structural primitives register with the active owner.
A mount activates its owner, so components do not pass an owner to every call.

`Compose.withOwner` explicitly activates an owner for a body.
It ends that activation whether the body returns or raises.

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

A suspended component keeps its owner when it resumes. Another mount can run during the suspension without changing that ownership.
Each thread has its own activation. Disposing one mount does not dispose another mount's nodes or connections.

Rule 2 applies only within a resume chain. A thread that Compose resumes inherits the resumer's owner.
An independently started host callback has no such chain and cannot infer an owner.
Use [`Compose.bindOwner`](api.md#composebindowner) to give that callback an explicit owner:

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

An entry point can run before any owner is active. Each primitive handles that condition as follows:

| Called with no active owner | Behaviour | Diagnostic | Why |
| --- | --- | --- | --- |
| `Compose.watch` | refuses | `owner/no-active-owner` | a watch with no owner has no defined end |
| `Compose.cleanup` | refuses | `owner/no-active-owner` | the teardown would never run |
| `Compose.accumulator` | refuses | `accumulator/no-active-owner` | it subscribes to its source, and the subscription needs an end |
| `Compose.createPool` | refuses | `pool/no-active-owner` | a pool cannot outlive whoever is responsible for its resources |
| `Compose.createKeyedCache` | refuses | `keyed-cache/no-active-owner` | a cache cannot outlive whoever is responsible for its retained values |
| `Compose.createFocusScope` | refuses | `focus-scope/no-active-owner` | it holds a subscription to its source |
| an acquire from `Compose.createSharedResource` | refuses | `async/shared-no-owner` | the reference is released when its holder is disposed |
| every structural primitive (`show`, `switch`, `keyed`, `indexes`, `presence`, `portal`, the collections) | refuses | `structure/no-active-owner` | the subtree belongs to whatever contains it |
| `runtime.constructors.Kind(...)`, `runtime.create(kind)(...)`, `runtime.decorate`, `runtime.connect`, `runtime.adopt`, `runtime.spring`, `runtime.tween`, `runtime.timeline` | refuses | `owner/no-active-owner` | nodes and bindings must belong to something that can release them |
| a context's `provide(value, body)` | **proceeds unowned** | none | the push is popped by the `provide` call itself; the owner registration is only a safety net for a body that raises past it |
| `Runtime:watch` | **falls back to the runtime's root owner** | none | see below |
| `runtime.mount`, `runtime.mountFragment` | **mint a fresh owner per call** | none | see below |

Three rows are exceptions, and each is deliberate.

**A context's `provide` proceeds.** The call removes its own stack entry.
An active owner supplies additional cleanup if the body raises, but the operation does not require an owner.

**`Runtime:watch` falls back.** The runtime supplies its root owner when no owner is active.
`runtime:dispose()` releases that owner and its watches. This supports subscriptions created before the first mount.
After `runtime:dispose()`, `mount` and `mountFragment` raise `runtime/disposed` and start no work.

**`mount` and `mountFragment` create an owner.** A top-level mount creates and activates its own owner.
Its disposer releases the mounted block and then that owner, even when a cleanup raises; the first
failure is raised after both are released.
The process root retains it, and the returned disposer releases it. `Compose.outstandingMounts()` counts these mounts.
A mount inside an active owner belongs to that owner and is released with it.

### Making the root explicit

Use a root owner when an entry point needs owner-dependent primitives.
Manual setup also requires cleanup when the body raises:

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
    runtime.mount(Hud, test.root)
end, runtime.reactor)

app.dispose()
```

Inside either one, every refusal above becomes an ordinary call, and a top-level `mount`
stops being top-level: it belongs to the root scope, so shutting the scope down takes the
tree with it. See [`api.md`](api.md#composewithrootowner) and `examples/root-scope.luau`.

## Why a watch needs an owner

Dependency edges retain both producers and consumers. A watch remains active until its owner disposes it.

`Compose.watch` requires an active owner. Without one, the watch would have no defined lifetime.

```luau
Compose.watch(function(use) ... end)   -- raises: no owner to hold the lifetime
```

**You do not need to retain the disposer.** Call the returned disposer only if you need to stop a watch early.
The owner releases it otherwise. Use `Compose.outstandingMounts()` to check for undisposed top-level mounts.

## Failure unwinds completely

Node construction can fail during creation, property writes, event subscriptions, child insertion or the component body. After a failure:

- the parent holds exactly the children it held before;
- the slot's child count is unchanged;
- nothing the attempt created survives;
- no subscription the attempt made survives;
- the scheduler remains usable, and the next mount works.

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

1. Register non-node resources with `Compose.cleanup`.
2. Treat external nodes as borrowed unless you explicitly adopt them.
3. Add a failure-injection test for each new fallible mount step.
4. Check late registrations. An already disposed owner calls a newly registered disposer immediately.
