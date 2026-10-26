# Ownership

Ownership determines which resources Compose releases.
Compose destroys nodes that it creates or adopts. It preserves borrowed nodes.

## Node custody

| Custody | Source | Destroyed on disposal? |
| --- | --- | --- |
| `owned` | A runtime constructor created the node. | Yes |
| `adopted` | The application called `runtime.adopt(node)`. | Yes |
| `borrowed` | All other nodes, including unknown nodes. | No |

`Compose.custodyOf(node)` returns the custody.
Compose stores custody with weak keys. The record does not keep the node alive.

Use `runtime.adopt(node)` to transfer responsibility for destruction to Compose.
Use `runtime.borrow(node)` to return custody to the external owner.
An unknown node is already borrowed. An explicit `borrow` call can make this decision clear.
`adopt` rejects a node that Compose already owns. Each node has one owner.

### A mount target keeps the custody it has

`runtime.mount` and `runtime.mountFragment` preserve target custody.
The owner of an owned or adopted target still destroys that target.

- Compose releases the mounted block before it destroys the target.
- Disposal of only the block preserves the target and its other children.
- Inside a mount, the active owner controls disposal order.
- Outside a mount, Compose registers the block against its target.
- Before target destruction, Compose releases those blocks, newest first.
- The block's disposer removes that registration and preserves target custody.

`Compose.portal` makes its target borrowed.
Use a portal for a layer that another system owns.
Mount directly into a container that your tree owns.
A portal would prevent Compose from destroying that container.
The [mount-target example](../examples/mount-target.luau) checks these rules.

### Subscriptions are always owned

Observation of a borrowed node owns the subscription, but keeps the node borrowed.
`runtime.decorate` binds properties and events to an existing node.
Disposal releases those subscriptions.
On a borrowed node, it also resets each written property to the class default.
It does not restore the previous value.
Compose destroys owned nodes instead of resetting their properties.

## Owners

An owner stores cleanup functions.
`Compose.createOwner(reactor?)` creates an owner.
`Compose.owner.own(owner, cleanup)` registers cleanup and returns a detach function.
`Compose.owner.createChild(owner)` creates a child owner.
`Compose.owner.watch(owner, body)` registers a watch.
`Compose.owner.dispose(owner)` releases all registrations, newest first.

Each cleanup function runs once, including after repeated disposal or detach calls.
Early disposal of a child removes its parent registration.
The owner removes a registration before it calls its cleanup function.
Thus a subscription registered after its node ends before node destruction.

Disposal continues after a failure.
If one cleanup fails, the owner raises that original failure without a new position.
If several fail, it raises one summary with all failures.
A cleanup registered during disposal runs immediately.
A cleanup registered after disposal also runs immediately.

### Checkpoints

`Compose.owner.checkpoint(owner)` records the current registrations.
`Compose.owner.rollbackTo(owner, mark)` releases registrations after that checkpoint, newest first.
A failed node construction uses this operation to release resources from that attempt.

## The ambient owner

Node construction, cleanup, watches and structural directives use the active owner.
A mount activates its owner while it builds content.
`Compose.withOwner(owner, body)` activates an explicit owner until the body returns or raises.
A watch activates a scope for each run.
Resources created during that run follow the [watch cleanup contract](api.md#composecleanup).

### Which owner is active, exactly

Each thread has its own activation.
Compose selects the owner in this order:

1. Use the innermost activation on the running thread.
2. Otherwise, use an unambiguous owner from the threads that resume it.
3. Otherwise, apply the missing-owner rules below.

Only the innermost activation of each resuming thread participates.
This includes user functions under `Compose.setYieldChecking(true)`.
Luau reports resuming threads as `normal`, but does not give their order.
Different owners on those threads cause `owner/no-active-owner`.
An explicit activation on the running thread resolves that ambiguity.

A suspended component keeps its owner after resumption.
Other mounts do not change that ownership.
The reactive evaluation context follows the same thread and resume chain.
An independent callback cannot inherit a suspended run's owner or dependency tracking.
A failure releases only the failing coroutine's evaluation context.

Use `Compose.bindOwner(callback)` inside the intended owner to bind a callback to it.
Alternatively, activate the owner inside the callback with `Compose.withOwner`.
A host callback started independently has no resume chain from which to select an owner.

Reactive functions must not yield.
Use `Compose.setYieldChecking(true)` to detect yields during development.

## Entry points, and what happens with no active owner

| Call without an active owner | Result | Diagnostic |
| --- | --- | --- |
| `Compose.watch`, `Compose.cleanup` | Rejects the call. | `owner/no-active-owner` |
| `Compose.accumulator` | Rejects the call. | `accumulator/no-active-owner` |
| `Compose.createPool` | Rejects the call. | `pool/no-active-owner` |
| `Compose.createKeyedCache` | Rejects the call. | `keyed-cache/no-active-owner` |
| `Compose.createFocusScope` | Rejects the call. | `focus-scope/no-active-owner` |
| Shared resource acquisition | Rejects the call. | `async/shared-no-owner` |
| Structural directives | Rejects the call. | `structure/no-active-owner` |
| Runtime constructors, `create`, `decorate`, `connect`, `adopt`, animation and scheduling without an explicit owner | Rejects the call. | `owner/no-active-owner` |
| A context's `provide(value, body)` | Creates a provider owner. | None |
| `Runtime:watch` | Uses the runtime root owner. | None |
| `mount`, `mountFragment` | Creates a mount owner. | None |

With an active owner, a context provider belongs to that owner.
Without one, the caller releases resources from a successful provider body.
A failed provider body disposes its provider owner.
The [context API](api.md#composecreatecontext) defines value inheritance.

`Runtime:watch` can register watches before the first mount.
`runtime:dispose()` releases the runtime root owner and its watches.
Later `mount` and `mountFragment` calls raise `runtime/disposed` before they start work.

A top-level mount creates and activates an owner.
Its disposer releases the block and owner, even if cleanup fails.
It then raises the first failure.
The process root retains top-level mount owners until disposal.
`Compose.outstandingMounts()` counts them.
A mount inside an active owner belongs to that owner.

### Making the root explicit

Use `Compose.withRootOwner(body, reactor?)` for a scope that ends when its body returns or raises.
Use `Compose.createRootOwner(boot, reactor?)` for a scope that ends at application shutdown.
The second call returns a handle with `dispose()`.
Both calls release resources if setup fails.
Nested mounts belong to that root scope.
See the [root API](api.md#composewithrootowner) and [root-scope example](../examples/root-scope.luau).

## Why a watch needs an owner

Dependency edges retain their producers and consumers.
A watch stays active until disposal, even without a retained disposer.
Call its disposer only to stop it before its owner ends.

## Failure unwinds completely

Creation, property writes, event connections, child insertion and component functions can fail.
After a failed construction:

- The parent keeps its previous children.
- The slot keeps its previous child count.
- No resource or subscription from the failed attempt remains.
- The scheduler can run the next mount.

[The unwind tests](../tests/lifecycle/unwind.verify.luau) inject failures at several depths and check these conditions.

## Checklist for new code

1. Register external cleanup with `Compose.cleanup`.
2. Keep external nodes borrowed unless you adopt them.
3. Test each mount operation that can fail.
4. Check cleanup registered after disposal.
