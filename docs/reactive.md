# Cells, formulas, watches, and reactors

Cells, formulas and watches represent application values. Reactors schedule their updates.
The application supplies scheduling triggers and decides how to organize state.

## The protocol

Two things hold a value, and one function reads them.

```luau
local health  = Compose.cell(100)
local percent = Compose.formula(function(use)
    return use(health) / 100
end)

runtime:watch(function(use)
    print(use(percent))
end, "health readout")

health:set(90)
health:update(function(value) return value - 10 end)
health:peek()   --> 80
```

Each reactive body receives `use`. This includes formulas, watches, bound properties and structural sources.
A call to `use` records a dependency. Use `:peek()` for an intentional untracked read.

A `Source` is a cell, a formula or a body that computes a value.
Use `Text = health` to bind a readable directly.
Use `Text = function(use) return use(health) .. "%" end` to transform its value.

`Compose.sharedCell` declares intentionally shared state at module scope. It needs no owner and behaves like `cell` at runtime.

`Compose.accumulator` tracks one source and reduces each change into its own readable state.
It reads its previous state without tracking that read, so its own update cannot trigger it again.
The [API reference](api.md#composesharedcell) documents both constructors. Consumer diagnostics recognize these forms and report equivalent manual constructions.

## Nodes, consumers, and edges

The graph contains producers, consumers and dependency edges. See
[`../src/core/reactive/graph.luau`](../src/core/reactive/graph.luau).

A **producer** holds a value and a version. The version advances when the value changes.
A **consumer** reads producers and receives change notifications. A formula is both roles. A cell is a producer; a watch is a consumer.

An **edge** joins the producer's doubly-linked subscriber list and the consumer's dependency array. The array follows read order.
Removing an edge from the subscriber list costs O(1). New edges append to that list, so notifications follow first-read order.

The edge occupies five slots in a table's array part, addressed by named index constants
in `graph.luau`.

### Nothing is weak, and nothing needs holding

Every edge is strong in both directions. A watch releases its subscriptions when it is
disposed. Reads that continue in the same callback after disposal return current values
without attaching dependencies. Direct and fused bindings detach their shared subscription
when their last listener is removed. Rerunning a watch also detaches dependencies its body
no longer reads.

A watch does not require a retained handle. Its owner controls its lifetime.
Call the disposer returned by `runtime:watch(...)` if you need to stop it early.
Owner disposal releases the watch without waiting for garbage collection.

Formulas created inside an active owner share its lifetime. Formulas created outside an
owner require explicit `:dispose()` when their lifetime ends. Disposal permanently releases
upstream dependencies; subsequent reads raise `reactive/disposed-formula`. Reading a formula
does not transfer its ownership.

The optional second argument names an explicit watch in a running causal profile. It turns
a synthetic row such as `watch#101` into an operation name, without retaining a watch
handle or adding a second lifetime mechanism.

### Re-reading the same shape allocates nothing

On each run, the consumer reads its dependency array in order.
`use(x)` reuses the edge at the current position if that edge already points to *x*.
At the first mismatch, Compose detaches and rebuilds the remaining edges.
An unchanged read sequence reuses every edge.

## Marking pushes, evaluation pulls

A changed write advances the cell's version and visits its subscribers.
It marks direct dependents `DIRTY` and indirect dependents `CHECK`.
Each affected watch enters its reactor's queue. Evaluation occurs when a read or queue drain requests it.

`CHECK` means a dependency might have changed. Compose refreshes each dependency and compares its version with the last observed version.
If no version changed, the consumer returns to `CLEAN` without running. This prevents redundant evaluation in diamond-shaped graphs.

A formula publishes a new `version` only when its computed value changes. A recomputation
that produces an equal value leaves the version alone, so downstream consumers return to
`CLEAN` without running. A filter returning an equal list stops the cascade there.

## Reactors

A **reactor** has its own queue, batch depth and drain. Each runtime owns a separate reactor.
`Compose.createOwner(reactor)` assigns an owner to an existing reactor.
A runtime's batch does not defer another runtime's watches. An error in one reactor does not prevent another from draining.

```luau
runtime:batch(function() ... end)  -- watches deferred until it returns; nests
runtime:settle()                   -- run everything pending; a no-op inside a batch
runtime:pending()                  -- how many watches are waiting
```

Several reactors can read the same cell. A write outside a batch settles every affected reactor, even if one raises.
Compose reports the collected failures afterwards.

The contract, in the order it matters:

1. Watches observe coherent state. Inside a batch, nothing runs until the body returns.
2. Multiple dependency changes coalesce while a watch is queued. A write during execution can queue it again in the same drain.
3. Batches nest. Only the outermost drains.
4. A user error does not block future work. Compose clears the queue and releases the batch flag before reporting the error.
5. A watch can write. The watches it wakes run in the same drain. A cascade that exceeds the run limit raises an error.

### A batch is not a transaction

If a batch body raises, its completed writes remain. Watches that observe those writes still run.
A batch does not roll back state.

## Versions come from a counter, not a clock

Version changes use a strictly increasing integer counter. They do not depend on elapsed time.
A formula advances its version only when its computed value changes.
`tools/check-boundary.luau` rejects `os.clock` in core.

## Counting the work

Work counters record completed and avoided work, including suppressed writes, suppressed recomputations and coalesced schedules.
Use them to explain timing results. Counts alone do not establish a speedup.

```luau
Compose.setWorkCounters(true)
Compose.resetWorkCounters()
runtime:batch(function()
    for value = 1, 10 do count:set(value) end
end)
Compose.readWorkCounters().watchRuns   --> 1
```

They are off by default and cost one table read when off.

## The guarantees, and where they are pinned

[`../tests/reactive/contract.verify.luau`](../tests/reactive/contract.verify.luau) states the
everyday shape of each primitive: laziness, equality suppression, supplied comparisons,
formula caching, diamond deduplication, chain settling, untracked reads, ownership, and
nested batching. [`../tests/reactive/shared-cell.verify.luau`](../tests/reactive/shared-cell.verify.luau)
checks that shared cells behave like cells.

[`../tests/reactive/accumulator.verify.luau`](../tests/reactive/accumulator.verify.luau) states
the accumulator's contract: eager reduction, event order, batch coalescing, output suppression, disposal and recovery after a reducer raises.
It also checks that the accumulator cannot trigger itself.

[`../tests/reactive/falsifiers.verify.luau`](../tests/reactive/falsifiers.verify.luau) covers
additional failure cases. Each check can detect a specific implementation defect.

- **Dynamic dependency churn.** Reads from abandoned branches stop receiving notifications. Dependencies can grow, shrink and change order.
- **Lifetime without a retained handle.** The watch survives garbage collection without a retained disposer. Owner disposal stops it.
- **Independent runtimes.** A batch or watch failure in one reactor does not prevent another reactor from settling.
- **Re-entrant writes.** A watch that writes to something it reads re-runs, including from
  inside its own first run. This is the case that fails if the stale flag is cleared after
  the body rather than before it.
- **Dispose during a drain.** A watch torn down by an earlier watch in the same drain does
  not run.
- **Recovery after an abandoned drain.** The cascade bound clears the queue while leaving
  its watches stale; the next write must still mark them.
- **Standing graph memory.** Every edge comes back when a subtree is released, and a body
  re-reading the same shape does not accumulate edges.
