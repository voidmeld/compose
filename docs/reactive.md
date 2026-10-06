# Cells, formulas, watches and reactors

Cells, formulas and watches represent application values. Reactors schedule their updates.

`Cell<T>` can be passed directly to APIs that accept `Readable<T>`.
Its `peek` method uses the readable receiver type. `set` and `update` keep the writable cell contract.
The application supplies the scheduling triggers and decides how to organize state.

## The protocol

Two things hold a value, and one function reads them.

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
progress:peek()   --> 80
```

Each reactive body receives `use`. This includes formulas, watches, bound properties and structural sources.
A call to `use` records a dependency. For an intentional untracked read, use `:peek()`.

A `Source` is a cell, a formula or a body that computes a value.

- To bind a readable directly, use `Text = progress`.
- To transform its value, use `Text = function(use) return use(progress) .. "%" end`.

`Compose.sharedCell` declares intentionally shared state at module scope. It needs no owner and behaves like `cell` at runtime.

`Compose.accumulator` tracks one source and reduces each change into its own readable state.
It reads its previous state without tracking that read, so its own update cannot trigger it again.
The [API reference](api.md#composesharedcell) documents both constructors.
Consumer diagnostics recognize these forms and report equivalent manual constructions.

## Nodes, consumers and edges

The graph contains producers, consumers and dependency edges. See [`../src/core/reactive/graph.luau`](../src/core/reactive/graph.luau).

- A **producer** holds a value and a version. The version advances when the value changes.
- A **consumer** reads producers and receives change notifications.
- A formula has both roles. A cell is a producer. A watch is a consumer.
- An **edge** joins the doubly-linked subscriber list of the producer and the dependency array of the consumer. The array follows read order.

Removing an edge from the subscriber list costs O(1). New edges append to that list, so notifications follow first-read order.

### Subscription lifetime

Every edge is strong in both directions.

- A watch releases its subscriptions when it is disposed.
- Reads that continue in the same callback after disposal return current values. They do not attach dependencies.
- Direct and fused bindings detach their shared subscription when their last listener is removed.
- If a watch runs again, it also detaches the dependencies that its body no longer reads.

A watch does not need a retained handle. Its owner controls its lifetime.
To stop a watch early, call the disposer that `runtime:watch(...)` returns.
Owner disposal releases the watch without waiting for garbage collection.

- Formulas that you create inside an active owner share its lifetime.
- Formulas that you create outside an owner need an explicit `:dispose()` when their lifetime ends.
- Disposal permanently releases the upstream dependencies. A later read raises `reactive/disposed-formula`.
- Reading a formula does not transfer its ownership.

The optional second argument names an explicit watch in a running causal profile.
It turns a synthetic row such as `watch#101` into an operation name. It does not retain a watch handle and does not add a second lifetime mechanism.

### Re-reading the same shape allocates nothing

On each run, the consumer reads its dependency array in order.
`use(x)` reuses the edge at the current position if that edge already points to *x*.
At the first mismatch, Compose detaches and rebuilds the remaining edges.
An unchanged read sequence reuses every edge.

## Change propagation

A changed write advances the version of the cell and visits its subscribers.
It marks direct dependents `DIRTY` and indirect dependents `CHECK`.
Each affected watch enters the queue of its reactor. Evaluation occurs when a read or a queue drain requests it.

`CHECK` means that a dependency might have changed.
Compose refreshes each dependency and compares its version with the last observed version.
If no version changed, the consumer returns to `CLEAN` without running. This prevents redundant evaluation in diamond-shaped graphs.

A formula publishes a new `version` only when its computed value changes.
A recomputation that produces an equal value leaves the version alone, so downstream consumers return to `CLEAN` without running.
A filter that returns an equal list stops the cascade there.

## Reactors

A **reactor** has its own queue, batch depth and drain. Each runtime owns a separate reactor.
`Compose.createOwner(reactor)` assigns an owner to an existing reactor.
The batch of one runtime does not defer the watches of another runtime.
An error in one reactor does not prevent another reactor from draining.

```luau
runtime:batch(function() ... end)  -- watches deferred until it returns; nests
runtime:settle()                   -- run everything pending; a no-op inside a batch
runtime:pending()                  -- how many watches are waiting
```

Several reactors can read the same cell.
A write outside a batch settles every affected reactor, even if one raises. Compose reports the collected failures afterwards.

A **cell belongs to no reactor and no runtime**. A cell is a value with subscribers. A write to a cell settles every reader of that cell.
A shared model is the set of cells that an application reads from several trees.

- Give that model an owner that you create outside all of those trees, with `Compose.createRootOwner`.
- Dispose the owner after the trees.
- If you dispose the model first, the trees keep reading cells that nothing writes again.

Batching is not process-wide. Each reactor tracks its own batch state, so `runtime:batch` defers the watches of that runtime only.
To batch several runtimes together, call the `batch` of each one. Otherwise a write settles each affected reactor in turn.

### One clock for several runtimes

A frame clock is a host capability, not a runtime argument. A host can carry `frames = { onFrame, now }`.
Everything that moves reads the clock from the host that it was built on:

- springs
- tweens
- timelines
- collection admission

Several runtimes therefore share one clock when they **share one host**.
To share a host, pass the same host value to each `Compose.createRuntime`.
On Roblox, call `ComposeRoblox.createRuntime()` with no engine. Each such call reuses one memoized ambient host, which holds one Heartbeat connection.

The host owns the signal. Each consumer that needs frames takes its own listener on the host.
The consumer releases that listener when its owner is disposed, so the host holds no listener after the last consumer goes.
The host calls the listeners in the order in which it took them.
That order fixes the tick order of the runtimes that share the clock. The runtime that subscribed first moves first, on every frame.
`tests/lifecycle/shared-frames.verify.luau` pins all three behaviors.

`ComposeRoblox.createRuntime(engine)` with an explicit engine builds a fresh host, and therefore a second Heartbeat connection.
Pass an explicit engine only when the two trees must stay independent.

### The contract

The contract, in order of importance:

1. Watches observe coherent state. Inside a batch, nothing runs until the body returns.
2. Multiple dependency changes coalesce while a watch is queued. A write during execution can queue the watch again in the same drain.
3. Batches nest. Only the outermost batch drains.
4. A user error does not block future work. Compose clears the queue and releases the batch flag before it reports the error.
5. A watch can write. The watches that it wakes run in the same drain. A cascade that exceeds the run limit raises an error.
6. A formula whose body raises raises again on every read until a dependency changes, and then recomputes. Formulas and watches that read it keep that dependency, so they recover with it.

### A batch is not a transaction

If a batch body raises, its completed writes remain. Watches that observe those writes still run.
A batch does not roll back state.

## Versions come from a counter, not a clock

Version changes use a strictly increasing integer counter. They do not depend on elapsed time.
A formula advances its version only when its computed value changes.
`tools/check-boundary.luau` rejects `os.clock` in core.

## Measuring work

- To count completed and avoided work, use [work counters](api.md#composesetworkcounters).
- To trace a write through formulas, watches and host updates, use [the causal profiler](api.md#composeprofile).
- For timing, follow [the benchmark procedure](benchmarks.md).

Counts alone do not establish an improvement in speed.

## The guarantees, and where tests pin them

[`../tests/reactive/contract.verify.luau`](../tests/reactive/contract.verify.luau) states the everyday shape of each primitive:
laziness, equality suppression, supplied comparisons, formula caching, diamond deduplication, chain settling, untracked reads, ownership and nested batching.
[`../tests/reactive/shared-cell.verify.luau`](../tests/reactive/shared-cell.verify.luau) checks that shared cells behave like cells.

[`../tests/reactive/accumulator.verify.luau`](../tests/reactive/accumulator.verify.luau) states the contract of the accumulator:
eager reduction, event order, batch coalescing, output suppression, disposal and recovery after a reducer raises.
It also checks that the accumulator cannot trigger itself.

[`../tests/reactive/falsifiers.verify.luau`](../tests/reactive/falsifiers.verify.luau) covers additional failure cases.
Each check can detect a specific implementation defect.

- **Dynamic dependency churn.** Reads from abandoned branches stop receiving notifications. Dependencies can grow, shrink and change order.
- **Lifetime without a retained handle.** The watch survives garbage collection without a retained disposer. Owner disposal stops it.
- **Independent runtimes.** A batch or watch failure in one reactor does not prevent another reactor from settling.
- **Re-entrant writes.** A watch that writes to something that it reads runs again, including from inside its own first run. This case fails if Compose clears the stale flag after the body instead of before it.
- **Dispose during a drain.** A watch that an earlier watch tears down in the same drain does not run.
- **Recovery after an abandoned drain.** The cascade bound clears the queue and leaves its watches stale. The next write must still mark them.
- **Standing graph memory.** Every edge comes back when a subtree is released. A body that reads the same shape again does not accumulate edges.
