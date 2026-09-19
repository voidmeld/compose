# Cells, formulas, watches, and reactors

These primitives represent and settle application values, defining a reactive graph contract, not
ambient scheduling or application state policy.

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

Every reactive body, a formula, a watch, a bound property, the source of a structural
directive, is handed `use`. Reading through it is what records a dependency. There is
no `use` in scope anywhere else, so a tracked read is visible at the call site, and an
untracked read is something you write on purpose with `:peek()`.

A `Source` is a cell, a formula, or a body that computes one. Anywhere the library takes a
value that may change, it takes a `Source`, so `Text = health` and
`Text = function(use) return use(health) .. "%" end` both work and mean what they look
like.

Two constructors state an intent the base forms leave implicit. `Compose.sharedCell` is a
cell whose module-scope life is the point: a deliberate process-wide singleton, no owner
expected, identical to `cell` at runtime. `Compose.accumulator` is the event merge: one
tracked source, each change reduced into the accumulator's own readable state. It reads its
own previous value untracked internally, so the shape cannot re-trigger itself. Both are in
[`api.md`](api.md#composesharedcell), and both are the forms the consumer lint recognises;
a hand-rolled equivalent draws a finding.

## Nodes, consumers, and edges

Inside, the graph is two roles and one object joining them. See
[`../src/core/reactive/graph.luau`](../src/core/reactive/graph.luau).

A **producer** has a value and a version that advances when the value changes. A
**consumer** reads producers and has to be told when one moves. A formula is both; a cell
is only a producer; a watch is only a consumer.

An **edge** sits in two lists at once: the producer's doubly-linked subscriber list, so
detaching is O(1) from either end, and the consumer's own array of dependencies, in read
order. New edges go on the subscriber list's tail, so consumers are marked in the order
they first read. That is a deterministic order rather than whatever a hash set yields.

The edge occupies five slots in a table's array part, addressed by named index constants
in `graph.luau`.

### Nothing is weak, and nothing needs holding

Every edge is strong in both directions. A watch releases its subscriptions when it is
disposed. Rerunning a watch also detaches dependencies its body no longer reads.

This is why a watch needs no handle. `runtime:watch(...)` returns a dispose for the rare
case you want to end it early, and throwing it away is safe and usual: the watch lives
exactly as long as the owner that created it. A subtree's teardown is a fact about the
tree, not about when a collector last ran.

The optional second argument names an explicit watch in a running causal profile. It turns
a synthetic row such as `watch#101` into an operation name, without retaining a watch
handle or adding a second lifetime mechanism.

### Re-reading the same shape allocates nothing

A consumer's dependency array is in read order, and a re-run walks it with a cursor.
`use(x)` at position *i* against an edge already pointing at *x* reuses that edge. That
covers every read of a body whose branches did not change. The first position where the
shape differs is where rebuilding starts: everything from there is detached and the tail
is built fresh. Dynamic dependencies cost exactly what changed.

## Marking pushes, evaluation pulls

A write does not recompute anything. It advances the cell's version and walks the
subscriber lists, marking direct dependents `DIRTY` and everything behind them `CHECK`,
and queuing any watch it reaches on that watch's own reactor. Nothing is evaluated until
something asks.

`CHECK` is the state that makes a diamond come out right. It means "a dependency may have
moved." Resolving it walks the dependency edges, brings each producer up to date, and
compares the version the edge last observed against the producer's version now. If none
moved, the consumer returns to `CLEAN` without running.

A formula keeps two versions, and the difference is the whole of transitive suppression.

- `ranAt`: when the body last executed. Not published.
- `version`: when the *value* last differed. What consumers compare against.

A formula that reruns and lands on an equal value advances `ranAt` and leaves `version`
alone, so everything reading it goes back to `CLEAN` without running. `filter(items)`
returning an equal list stops the cascade dead.

## Reactors

A **reactor** is one scheduling domain: one queue, one batch depth, one drain. Every
runtime owns one and never shares it, and `Compose.createOwner(reactor)` puts an owner in
one. Two runtimes in a process therefore cannot interleave each other's watches, cannot
see each other's batches, and cannot be wedged by each other's errors.

```luau
runtime:batch(function() ... end)  -- watches deferred until it returns; nests
runtime:settle()                   -- run everything pending; a no-op inside a batch
runtime:pending()                  -- how many watches are waiting
```

A cell may be read from more than one domain. A write outside a batch settles **every**
domain it reached, and settles all of them even if one raises, because two runtimes are
either independent or they are not. The failures are reported together afterwards.

The contract, in the order it matters:

1. Watches observe coherent state. Inside a batch, nothing runs until the body returns.
2. A watch runs at most once per drain however many dependencies moved.
3. Batches nest. Only the outermost drains.
4. A user error does not wedge the reactor. The queue is cleared and the batch flag
   released before the error propagates.
5. Draining settles. A watch may write, and what that wakes runs in the same drain; a
   cascade that will not settle raises rather than hanging.

### A batch is not a transaction

If the body raises halfway through, the writes it already made stand, and the watches that
observe them still run. Compose says so rather than implying an atomicity it does not
provide.

## Versions come from a counter, not a clock

Every write and every recomputation stamps a strictly increasing integer. Two writes in the
same instant are two versions, so the tightest write-read loop is still correct, which a
wall clock cannot promise. It is also what makes versions assertable in a test, and why
`tools/check-boundary.luau` forbids `os.clock` in the core at all.

## Counting the work

The work counters record avoided work as well as performed work: writes suppressed,
recomputations suppressed, schedules coalesced. "We made it faster" is only believable next
to a count of what stopped happening.

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
pins a shared cell to a cell behaviour for behaviour, and
[`../tests/reactive/accumulator.verify.luau`](../tests/reactive/accumulator.verify.luau) states
the accumulator's contract: eagerness, per-event ordering, batch coalescing, output
suppression, no self-retrigger, disposal, and what a raising reduce does and does not
corrupt.

[`../tests/reactive/falsifiers.verify.luau`](../tests/reactive/falsifiers.verify.luau) covers
what is easy to break while all of that still passes. Each check fails on a plausible
implementation, and two of them caught this one.

- **Dynamic dependency churn.** A branch no longer taken is a source no longer heard from,
  and a dependency list that grows, shrinks, and reorders keeps working.
- **Lifetime without a retained handle.** The dispose is thrown away and the collector
  provoked hard; the watch still runs. It stops exactly when its owner is disposed.
- **Independent runtimes.** One domain batching does not defer another, and one domain's
  watch raising does not stop another from settling.
- **Re-entrant writes.** A watch that writes to something it reads re-runs, including from
  inside its own first run. This is the case that fails if the stale flag is cleared after
  the body rather than before it.
- **Dispose during a drain.** A watch torn down by an earlier watch in the same drain does
  not run.
- **Recovery after an abandoned drain.** The cascade bound clears the queue while leaving
  its watches stale; the next write must still mark them.
- **Standing graph memory.** Every edge comes back when a subtree is released, and a body
  re-reading the same shape does not accumulate edges.
