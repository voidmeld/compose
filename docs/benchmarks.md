# Representative proof

Run correctness before timing.
The benchmarks use the Verify testing library. Each workload and each scenario has one parity case and one benchmark collection.
The runtime suite covers construction, reactive updates, identity, events, animation, unwind and teardown.
The scene suite combines UI, 2D and 3D content, virtualized collections and keyed-entity churn.
Both lanes run in the benchmark cost-model environment with deterministic input.
That environment is `bench/cost-model`. It is for benchmarks only. The tests use the simulated engine instead.
It models only the members that the benchmarks use. It counts property writes and reads, parent changes, connections, events and deferred tasks, and it supplies the global table that the plain-Luau lane runs against.
The simulated engine has neither those counters nor that global table, so the benchmarks do not run on it. See [the simulated engine](roblox.md#the-simulated-engine).

## Commands

One entry point runs every suite.

```bash
lute run bench/run.luau --verify --suite all
lute run bench/run.luau --suite workloads --out build/performance/runtime
lute run bench/run.luau --suite entities --filter entities-integrated --scale medium --out build/performance/entities
lute run bench/run.luau --suite screens --baseline build/performance/runtime/stored.json
lute run bench/run.luau --spread build/performance/first/stored.json build/performance/second/stored.json
```

| Option | Meaning |
| --- | --- |
| `--suite workloads\|screens\|entities\|all` | The suite. The default is `workloads`. |
| `--filter text` | Runs the workloads or scenarios whose id contains the text. |
| `--scale name` | Runs one scale of each scenario. |
| `--out directory` | Receives the results. The default is `bench/results/scratch`. |
| `--verify` | Runs only the parity cases. The gate runs this form as the producer `benchmark-parity`. |
| `--baseline file` | Compares the new run with a stored run. The rule is a ratio of 1.5 and a floor of 5 microseconds on the median. |
| `--spread file file ...` | Prints the spread of the same benchmarks across stored runs. It runs no benchmark. |

Use `--filter` and `--scale` for focused diagnostics. Do not claim that a filtered run covers all cases.

## What a run does

The command builds one Verify gate. For each workload or scenario scale it declares two producers.

1. `parity-<id>` runs one case on a Verify worker. The case builds the same scene in every framework and compares the tree snapshots.
2. `timing-<id>` runs one benchmark collection. It runs only after its parity case passes.

A collection has one member for each framework. The members run in an order that rotates by one position for each workload.
The collection measures a fixed CPU workload, the yardstick, before and after the members. A drifting yardstick marks the members unsupported.
Each member keeps these properties:

- Warmup runs whole samples (`warmupScope = "sample"`).
- `beforeSample` builds a fresh cost-model environment, loads the framework and prepares the scene. It is not timed.
- The timed region runs the workload for `iterations` runs. For a workload it then drains the environment (`finalize`).
- `afterSample` reads the counters, releases the scene, drains the environment and records leaks. It is not timed.
- The clock is a wall clock. The unit is microseconds.

A workload member times `iterations` runs plus one drain as one sample. A scenario member has the phases `cold`, `steady`, `burst`, `settle` and `teardown`.
Each phase is its own measurement named `<scenario>.<scale>/<framework>/<phase>`.
A scenario with a framework that has reactive work counters or a probe also has a member `.../counts`. It runs the whole scenario once with the work counters enabled.
Its time is not a measurement. The reactive work counters never run inside the timed samples of the other members. The cost-model counters always run, because they are part of the environment.

## Recorded quantities

Each sample records these series with `sampler.series`. Each series holds one array per sample.

| Series | Meaning |
| --- | --- |
| `counter.<name>` | The cost-model counters at the end of the run: `instancesCreated`, `instancesDestroyed`, `propertyWrites`, `propertyReads`, `parentChanges`, `connectionsMade`, `connectionsBroken`, `eventsFired` and `tasksDeferred`. |
| `leakedInstances`, `leakedConnections` | Live instances and connections after release, less the count before the scene. Both must be zero. |
| `diagnostics` | The number of diagnostics that the framework emitted. |
| `frame` | The duration of each steady frame, in microseconds. Scenarios only. |
| `round` | The duration of each burst round, in microseconds. Scenarios only. |
| `liveInstancesAfterBuild` | Live instances after the cold build. Scenarios only. |
| `reactive.<name>`, `probe.<name>` | The reactive work counters and the probe values of the `counts` member. |

A workload time is the time of one sample. Divide it by the `iterations` of the workload for a time per run.
The `steady` phase time is the time of all steady frames. Divide it by the frame count for a time per frame.
A scenario that declares a steady budget has that budget enforced at the scale `large`. The budget applies to the median of the `steady` phase.
Every other measurement is measured only. No framework is judged against another.

## Conditions

Before you compare timings, check these conditions:

- Observable trees match. The `parity-<id>` case checks this.
- Inputs are fixed.
- Each framework has warmup and runs in rotated order.
- The reactive work counters run in their own member, apart from timing.
- Disposal leaves no retained nodes or connections.

Report the absolute time and the noise. A stored run holds the raw samples, so `--spread` shows the noise across runs.

Record the source commit and tree, the dirty state, the runtime and environment, the command and the concurrency outside the active source tree.
The stored run is named with the commit. The environment label names the operating system, the architecture, the processor and the thread count.
Keep failed and noisy attempts too. Do not automatically use historical samples as baselines.
A baseline from another environment label fails the comparison.
Benchmark ids name the workload. A renamed workload is a different id, so an older baseline that uses an old id does not compare by name.

## Output

The run writes two files to the output directory.

- `stored.json` is the stored run that `--baseline` and `--spread` read. It holds the raw samples of every measurement.
- `report.json` is the full Verify report. It holds the series of every measurement.

CPU proof of core does not establish native rendering, physics, networking, device input or played quality.
Before you update the framework pin of a consumer, verify the affected consumers.
An engine claim needs its own authentic execution. See [engine verification](../verification/roblox/README.md).
Do not relabel an earlier receipt as evidence of new source.
