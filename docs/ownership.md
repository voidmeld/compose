# Ownership

This guide governs a component that creates, adopts, borrows or cleans up a resource.
Compose uses ownership to decide which resources it disposes.

## Disposal rule

**Compose destroys nodes that it creates or explicitly adopts. It preserves borrowed nodes.**

## Node custody

| Custody | How a node gets it | Destroyed on disposal? |
| --- | --- | --- |
| `owned` | A runtime constructor made it. | yes |
| `adopted` | You called `runtime.adopt(node)`. | yes |
| `borrowed` | Every other case, including anything that Compose has never seen. | **no** |

An unrecognized node is `borrowed` by default.
This default prevents Compose from destroying a node that another system owns.
Examples are an external mount target, a model, a service and a shared layer.

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

`adopt` refuses a node that Compose already owns. A node has exactly one owner, and a second adoption would destroy the node twice.

### A mount target keeps the custody it has

`runtime.mount` and `runtime.mountFragment` take a target node. An external target is usually borrowed.
A component can also mount into a container that it creates or adopts.

Mounting preserves the custody of the target.
An `owned` or `adopted` container stays registered for destruction with its owner.
If Compose changed it to `borrowed`, the container would outlive its tree.

- Compose disposes the mounted block before it destroys the container.
- If you dispose only the block, the container and its other children stay.
- Inside a mount, the active owner controls the disposal order.
- Outside a mount, the target still belongs to the scope that created or adopted it. Compose registers the mounted block against that target node.
- Before Compose destroys the target, it disposes the mounted blocks of the target, newest first.
- If you call the own disposer of a block, Compose removes that block and preserves the custody of the target.

A portal has different custody. `Compose.portal` marks its target borrowed.
Use a portal for a layer that another system owns.
To mount into a container that your tree owns, mount directly. A portal would demote the container to borrowed and prevent its destruction.
The [mount-target example](../examples/mount-target.luau) exercises owned and adopted targets.

### Subscriptions are always owned

If you observe or connect to a borrowed object, you own only the resulting subscription.
The object survives. The subscription does not.

```luau
runtime.decorate(playerGui.Overlay, {
    [Compose.event("Changed")] = onChanged,
    BackgroundTransparency = 0.5,
})
```

On disposal, Compose releases the connection and **clears the property to its default**. It does not destroy `playerGui.Overlay`.
Compose clears the properties that it wrote on borrowed nodes. It skips this step for owned nodes, because it destroys them instead.

## Owners

An owner is a list of disposers, with the guarantee that each disposer runs exactly once.

```luau
local owner = Compose.createOwner()

local detach = owner.own(function() ... end)   -- register; returns a detach
owner.watch(function(use) ... end)    -- a watch held by this owner
local child = owner.createChild()              -- nests

owner.dispose()   -- releases everything, newest first, exactly once
```

Owners guarantee two behaviors.

**Exactly once.** Each resource is released once, even if you call disposal or detach again.
If you dispose a child and then its parent, the parent does not release the resources of the child twice.
The owner removes each entry before it calls the entry.

**Reverse order.** The owner releases the newest registration first.
A subscription that you register after its node is released before that node. This prevents events from reaching a destroyed node.

Disposal continues after an error.

- If a disposer raises, the owner runs the remaining disposers and reports all errors together.
- If a disposer registers another disposer during that teardown, the owner runs the new disposer immediately. The owner skips no disposer.
- If exactly one disposer fails, the owner raises that failure again with its original value and no added position.
- If several disposers fail, the owner raises one summary that names each failure.

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

A failed `create` uses a checkpoint to release the resources that it registered during that attempt.
The checkpoint avoids a separate child owner for each node construction.

## The ambient owner

`create`, `cleanup`, `watch` and the structural primitives register with the active owner.
A mount activates its owner, so components do not pass an owner to every call.

A watch body activates a scope for that run.
Before you allocate resources in a reactive body, read the [watch cleanup contract](api.md#composecleanup). Those resources have a shorter lifetime than the watch itself.

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

An activation belongs to the thread that opened it. "Active" is therefore answered for each thread, not for the process.

1. The innermost activation that the **running thread** opened, if it has one.
2. Otherwise, an unambiguous owner from the threads that **resume** this one. Only the innermost activation of each thread participates. This is how a task body that Compose resumed registers with the owner that resumed it. User functions under `Compose.setYieldChecking(true)` are included.
3. Otherwise, nothing is active, and every refusal in the table below applies.

A suspended component keeps its owner when it resumes.
Another mount can run during the suspension without changing that ownership.
Each thread has its own activation. If you dispose one mount, you do not dispose the nodes or connections of another mount.

The reactive evaluation context also belongs to its coroutine and resume chain.
An independent callback cannot borrow the owner or the dependency tracking of a suspended run.
An explicit owner that you activate inside a run takes precedence until that activation ends.
Activations on unrelated suspended threads do not affect that choice.
A failure unwinds only the evaluation context of the failing coroutine.

Rule 2 applies only within a resume chain. A thread inherits when the owner of the resumer is unambiguous.
Luau reports resumer threads as `normal` and does not expose their order.
Competing owners on distinct resumer threads raise `owner/no-active-owner`, because the activation order cannot identify the nearest resumer.

- To resolve this ambiguity, bind the child callback with `Compose.bindOwner` inside its intended owner, or use `Compose.withOwner` inside the child.
- An explicit activation on the current thread also resolves it.
- An independently started host callback has no resume chain and cannot infer an owner. To give that callback an explicit owner, use [`Compose.bindOwner`](api.md#composebindowner):

```luau
local onArrived = Compose.bindOwner(function(child)
    runtime.connect(child, "Changed", handle)     -- registered with this component's owner
end)
runtime.connect(container, "ChildAdded", onArrived)
```

Reactive code still must not yield.
A formula that yields has no coherent version. A watch that yields observes a world that has moved.
`Compose.setYieldChecking(true)` enforces this rule in development.

## Entry points, and what happens with no active owner

An entry point can run before any owner is active. Each primitive handles that condition as follows:

| Called with no active owner | Behavior | Diagnostic | Reason |
| --- | --- | --- | --- |
| `Compose.watch` | refuses | `owner/no-active-owner` | A watch with no owner has no defined end. |
| `Compose.cleanup` | refuses | `owner/no-active-owner` | The teardown would never run. |
| `Compose.accumulator` | refuses | `accumulator/no-active-owner` | It subscribes to its source, and the subscription needs an end. |
| `Compose.createPool` | refuses | `pool/no-active-owner` | A pool cannot outlive the party that is responsible for its resources. |
| `Compose.createKeyedCache` | refuses | `keyed-cache/no-active-owner` | A cache cannot outlive the party that is responsible for its retained values. |
| `Compose.createFocusScope` | refuses | `focus-scope/no-active-owner` | It holds a subscription to its source. |
| an acquire from `Compose.createSharedResource` | refuses | `async/shared-no-owner` | The reference is released when its holder is disposed. |
| every structural primitive (`show`, `switch`, `keyed`, `indexes`, `presence`, `portal`, the collections) | refuses | `structure/no-active-owner` | The subtree belongs to whatever contains it. |
| `runtime.constructors.Kind(...)`, `runtime.create(kind)(...)`, `runtime.decorate`, `runtime.connect`, `runtime.adopt`, `runtime.spring`, `runtime.tween`, `runtime.timeline`, `runtime.ramp`, `runtime.scheduler` without an owner argument | refuses | `owner/no-active-owner` | Nodes and bindings must belong to something that can release them. |
| a context's `provide(value, body)` | **proceeds unowned** | none | The `provide` call itself pops the push. The owner registration is only a safety net for a body that raises past it. |
| `Runtime:watch` | **falls back to the root owner of the runtime** | none | See below. |
| `runtime.mount`, `runtime.mountFragment` | **mint a fresh owner for each call** | none | See below. |

Three rows are exceptions. Each is deliberate.

**A context's `provide` proceeds.** The call removes its own stack entry.
An active owner supplies additional cleanup if the body raises, but the operation does not need an owner.

**`Runtime:watch` falls back.** If no owner is active, the runtime supplies its root owner.
`runtime:dispose()` releases that owner and its watches. This supports subscriptions that you create before the first mount.
After `runtime:dispose()`, `mount` and `mountFragment` raise `runtime/disposed` and start no work.

**`mount` and `mountFragment` create an owner.** A top-level mount creates and activates its own owner.
Its disposer releases the mounted block and then that owner, even when a cleanup raises. Compose raises the first failure after it releases both.
The process root retains the owner, and the returned disposer releases it. `Compose.outstandingMounts()` counts these mounts.
A mount inside an active owner belongs to that owner and is released with it.

### Making the root explicit

If an entry point needs owner-dependent primitives, use a root owner.
Manual setup also needs cleanup when the body raises:

```luau
local owner = Compose.createOwner()
Compose.withOwner(owner, boot)
-- ... and somebody has to remember owner.dispose(), including when `boot` raised
```

`Compose.withRootOwner` and `Compose.createRootOwner` do that, with guaranteed disposal.

```luau
-- scoped: released when the body returns or raises
local result = Compose.withRootOwner(function(owner)
    return runOnce()
end)

-- long-lived: released at shutdown, and unwound if the boot itself raises
local app = Compose.createRootOwner(function(owner)
    startServices()
    runtime.mount(Overlay, test.root)
end, runtime.reactor)

app.dispose()
```

Inside either one, every refusal above becomes an ordinary call.
A top-level `mount` stops being top-level. It belongs to the root scope, so shutting the scope down takes the tree with it.
See [`api.md`](api.md#composewithrootowner) and `examples/root-scope.luau`.

## Why a watch needs an owner

Dependency edges retain both producers and consumers. A watch remains active until its owner disposes it.

`Compose.watch` requires an active owner. Without one, the watch would have no defined lifetime.

```luau
Compose.watch(function(use) ... end)   -- raises: no owner to hold the lifetime
```

**You do not need to retain the disposer.** Call the returned disposer only if you need to stop a watch early. Otherwise the owner releases it.
To check for undisposed top-level mounts, use `Compose.outstandingMounts()`.

## Failure unwinds completely

Node construction can fail during creation, property writes, event subscriptions, child insertion or the component body. After a failure:

- The parent holds exactly the children that it held before.
- The child count of the slot is unchanged.
- Nothing that the attempt created survives.
- No subscription that the attempt made survives.
- The scheduler remains usable, and the next mount works.

`tests/lifecycle/unwind.verify.luau` injects a failure at each of these points, at several depths, and asserts all five conditions every time.

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
            return Label { Text = "tip" }
        end),
    }
end
```

Disposing the tree that contains `Tooltip` releases the two connections, the `show` branch if it is mounted, and the `Frame`.
It does not touch `target`. It clears nothing from `target`, because nothing was written to it.

## Checklist for new code

1. Register non-node resources with `Compose.cleanup`.
2. Treat external nodes as borrowed, unless you explicitly adopt them.
3. Add a failure-injection test for each new step of a mount that can fail.
4. Check late registrations. An already disposed owner calls a newly registered disposer immediately.
