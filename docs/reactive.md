# Reactive state

Cells hold state. Formulas calculate values from other state.
Reactors schedule updates. The application supplies the events that change state.

## The protocol

A reactive function receives `use`. Each `use(value)` call records a dependency.
Formulas, watches, property bindings and structural sources use this protocol.
Use `value:peek()` for a read that must not record a dependency.

```luau
local progress = Compose.cell(100)
local percent = Compose.formula(function(use)
    return use(progress) / 100
end)
runtime:watch(function(use)
    print(use(percent))
end, "progress readout")
progress:set(90)
progress:update(function(value) return value - 10 end)
```

A source is a readable or a function that calculates a value.
A cell satisfies the readable protocol. Its setter methods keep the writable cell contract.

- Bind a readable directly with `Text = progress`.
- Transform it with `Text = function(use) return use(progress) .. "%" end`.

`Compose.sharedCell` declares state that all users of a module share.
It needs no owner and has the same runtime behavior as `cell`.
`Compose.accumulator` reduces each observed source change into readable state.
Its previous-state read records no dependency, so its update cannot trigger itself.
The [API reference](api.md#composesharedcell) gives both contracts.
The consumer checker detects equivalent manual forms.

## Nodes, consumers and edges

The [reactive graph](../src/core/reactive/graph.luau) has producers, consumers and dependency edges.

- A producer holds a value and a version.
- A consumer reads producers and receives change notifications.
- A cell is a producer. A watch is a consumer. A formula has both roles.
- An edge joins a producer's subscriber list to a consumer's dependency array.

The subscriber list links each entry to its previous and next entry.
Removal costs O(1). New entries go at the end.
Notifications follow first-read order. The dependency array also follows read order.

### Subscription lifetime

An edge keeps both ends alive.
A watch releases its edges on disposal.
Later reads in the same callback return current values without recording dependencies.
A new watch run also removes dependencies that it no longer reads.
Direct and fused bindings share subscriptions until their last listener leaves.

An owner keeps its watch alive without a separate retained handle.
Call the returned disposer to stop a watch early.
Owner disposal releases it without waiting for garbage collection.

A formula created under an active owner belongs to that owner.
Outside an owner, call `formula:dispose()` when its lifetime ends.
Disposal releases upstream dependencies permanently.
Later reads raise `reactive/disposed-formula`.
A read of an existing formula does not transfer ownership.

An optional watch label names its row in a causal profile.
It does not create a separate lifetime or retain a watch handle.

### Re-reading the same shape allocates nothing

On each run, the consumer reads its dependency array in order.
`use(x)` reuses the current edge if it already points to `x`.
At the first mismatch, Compose removes and rebuilds the remaining edges.
An unchanged read order reuses all edges.

## Change propagation

A changed write updates the cell and invalidates its subscribers.
When a sole terminal binding is already queued, repeated writes retain the latest value without repeating graph work.
The binding restores normal notification before evaluation, subscription changes or disposal.
Enabling work counters or yield checking also restores it before the next write.
Other changed writes advance the cell version and visit its subscribers.
It marks direct dependents `DIRTY` and indirect dependents `CHECK`.
Each affected watch enters its reactor queue.
A read or queue drain requests evaluation.

For `CHECK`, Compose refreshes each dependency and compares versions.
If no version changed, the consumer returns to `CLEAN` without evaluation.
This avoids repeated evaluation in diamond graphs.

A formula advances its version only when its result changes.
An equal result lets downstream consumers return to `CLEAN` without evaluation.
Thus a filter that returns an equal list stops further propagation.

For many equality projections of one key, `Compose.selector(source)` shares one source subscription and returns a key-to-readable function. Routing looks up the previous and current keys before watches drain; only projections whose answer changes are invalidated. The creating owner releases the selector. See [the API reference](api.md#composeselector).

## Reactors

Each reactor has its own queue, batch depth and drain operation.
Each runtime owns a separate reactor.
`Compose.createOwner(reactor)` assigns an owner to an existing reactor.
A batch or failure in one reactor does not block another reactor.

```luau
runtime:batch(function() ... end)
runtime:settle()
runtime:pending()
```

`batch` defers queued watches until its outermost call ends.
`settle` runs pending work. It does nothing inside a batch.
`pending` counts queued watches.

A cell belongs to no reactor or runtime.
Several reactors can read it.
A write outside a batch settles all affected reactors, even if one fails.
Compose then reports the collected failures.
To batch several runtimes, call each runtime's `batch` operation.

For a shared model, create a root owner outside its scene trees.
Dispose that owner after the trees.
Otherwise, the trees can keep reading cells that no code updates.

### One clock for several runtimes

A host supplies `frames = { onFrame, now }`.
Animation and collection admission use that host clock.
Runtimes share a clock when they share a host.
Pass the same host to each `Compose.createRuntime` call to share it.

`ComposeRoblox.createRuntime()` reuses one cached ambient host.
An explicit engine argument creates a fresh host.
Use that argument when the hosts must stay independent.
The Roblox host selects its native frame source.

The host owns the frame signal.
Each consumer releases its listener when its owner ends.
The host keeps no listener after the last consumer leaves.
Listeners run in subscription order, which fixes runtime tick order.
[The shared-frame tests](../tests/lifecycle/shared-frames.verify.luau) check these rules.

### The contract

1. Queued watches observe coherent state after the outermost batch ends.
2. Several dependency changes share one queue entry until that watch runs.
3. A write during a watch can queue it again in the same drain.
4. A failure clears the queue and batch flag before Compose reports it.
5. A cascade above the run limit raises an error.
6. A failed formula raises again until a dependency changes.

Formulas and watches retain their dependency on a failed formula.
They recover when that dependency changes.

### A batch is not a transaction

If the batch body fails, completed writes remain.
Watches still observe them. A batch does not restore previous state.

## Versions come from a counter, not a clock

Versions use an increasing integer counter.
A formula advances its version only when its result changes.
[The boundary check](../tools/check-boundary.luau) rejects `os.clock` in core.

## Measuring work

Use [work counters](api.md#composesetworkcounters) to count completed and avoided work.
Use the [causal profiler](api.md#composeprofile) to follow writes through updates.
Use the [benchmark procedure](benchmarks.md) to measure time.
Counts alone cannot show a speed improvement.

## The guarantees, and where tests pin them

| Tests | Contract |
| --- | --- |
| [Reactive contract](../tests/reactive/contract.verify.luau) | Lazy evaluation, equality, caching, dependency tracking, ownership and batches. |
| [Shared cells](../tests/reactive/shared-cell.verify.luau) | Shared cells behave like cells. |
| [Accumulator](../tests/reactive/accumulator.verify.luau) | Reduction order, batches, equality, disposal and recovery. |
| [Failure cases](../tests/reactive/falsifiers.verify.luau) | Changing dependencies, independent runtimes, repeated writes, disposal during a drain and recovery. |

The failure cases also check graph memory after disposal and repeated reads.
