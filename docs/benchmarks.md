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
| `--baseline file` | Compares timing and retained heap with a stored run. Timing uses a ratio of 1.5 and a floor of 5 microseconds. Heap uses a ratio of 1.05 and a floor of 64 KiB. Both use the median. |
| `--spread file file ...` | Prints the spread of the same benchmarks across stored runs. It runs no benchmark. |

Use `--filter` and `--scale` for focused diagnostics. Do not claim that a filtered run covers all cases.

## Published results

Each push to `main` publishes the candidate measurements of its paired performance shards to the `perf-results` branch, also when a shard fails its verdict. A manual run of the workflow on `main` publishes too.
`bench/publish.luau` keeps one file for each commit under `results/` and writes `README.md` with the latest median and p95 of every benchmark, the change from the previous commit and trend charts for the Compose timings.
The runner is the CI Ubuntu runner, so compare values from the same branch history only.

## Manual framework comparison

The latest published results are in [framework-comparison.md](framework-comparison.md).

The **Framework comparison** GitHub workflow runs only on `workflow_dispatch`.
It uses `ubuntu-latest`. It does not run on a pull request or a push.
It is separate from the required `Gate` check and paired performance.
The normal `bench/run.luau` command still selects only bare Luau and Compose.

Run the same comparison locally with these commands:

```bash
lute run tools/sync-dependencies.luau --benchmarks
lute run bench/compare.luau --verify --out build/framework-parity
lute run bench/compare.luau --out build/framework-comparison
```

Use `--filter text` to select workload ids. Use `--out directory` to select the output directory.
`--verify` runs only the comparison correctness cases.
This entry point covers the 24 runtime workloads. It does not add the screen and entity scenarios to this comparison.

The lock file is the source of exact versions, commits, trees, rights and license notice paths.
All added surfaces have the `benchmark` role. The default dependency sync and the required gate omit these surfaces.
The explicit `--benchmarks` sync checks each commit, tree, remote and clean checkout.
It uses sparse checkouts for benchmark dependencies. Blend uses only its 29 listed modules and its license notice.
These sources stay in the ignored `.lute/dependencies` directory. They are not part of `src` or the package.
The loader reads only the benchmark surfaces in the lock. It runs upstream source without edits.
It resolves Roblox module paths (including `WaitForChild`), Nevermore module names, React package names and upstream Roblox package layouts against those surfaces.
It gives each loaded framework a separate cost-model environment and module cache.

Fusion uses the latest GitHub release that GitHub marks as a non-prerelease.
Its upstream tag contains `beta`; the upstream version table marks it as a release.
Vide uses its release tag. React and ReactRoblox use the same release.
React also needs the reconciler, scheduler, shared utilities, Luau polyfills, symbols and promises.
Blend uses one exact NevermoreEngine revision. Its package version is in the lock.
Roact and Seam use their latest release tags. Charm uses its latest package release tag; Reflex uses its latest release tag.
The second React lane uses the upstream Roblox tag with its own polyfill, symbol and promise dependencies.
Reflex uses its declared Promise dependency separately.
Roblox signals has no upstream release or tag. Its pin uses an exact default-branch commit and the package version marked `unreleased`.
The summary prints the exact source identities for all these dependencies.

### Support

`Yes` means the lane has an implementation and must pass correctness before timing.
`U` means unsupported. Each unsupported lane has a reason in the workload and the output table.

| Workload ids | Bare | Compose | Fusion | Vide | React | Blend |
| --- | --- | --- | --- | --- | --- | --- |
| `cold-mount-100`, `cold-mount-1000`, `cold-mount-10000` | Yes | Yes | Yes | Yes | Yes | Yes |
| `mount-dispose` | Yes | Yes | Yes | Yes | Yes | Yes |
| `update-leaf`, `update-fanout`, `update-batched` | Yes | Yes | Yes | Yes | Yes | Yes |
| `update-repeated` | Yes | Yes | U | Yes | Yes | Yes |
| `branch-swap` | Yes | Yes | Yes | Yes | Yes | Yes |
| `ordered-window-scroll` | U | Yes | U | U | U | U |
| `keyed-append`, `keyed-prepend`, `keyed-insert`, `keyed-remove` | Yes | Yes | U | Yes | Yes | Yes |
| `keyed-replace`, `keyed-reverse`, `keyed-rotate`, `keyed-shuffle` | Yes | Yes | Yes | Yes | Yes | Yes |
| `events` | Yes | Yes | Yes | Yes | Yes | Yes |
| `animate-many` | Yes | Yes | Yes | Yes | U | Yes |
| `status-panel`, `mount-cycles`, `scene-3d` | Yes | Yes | Yes | Yes | Yes | Yes |
| `unwind` | Yes | Yes | Yes | Yes | U | U |

The unsupported reasons are:

- The ordered-window workload measures a Compose collection contract. The other libraries have no matching native primitive.
- Fusion has no public transaction that reduces 500 repeated source writes to one host property write.
- At the pinned Fusion release, native `ForPairs` can assign a removed key's scope to a retained key. The four keyed workloads that shrink a list fail the retained-node identity check.
- React and ReactRoblox have no native spring. This comparison does not add an animation library to that lane.
- At the pinned React release, a failed render leaves abandoned cost-model nodes after root unmount. An error boundary does not release those nodes. This fails the partial-build rollback contract.
- At the pinned Blend revision, an error during observable subscription can leave created cost-model nodes without a returned cleanup resource. This fails the partial-build rollback contract.

The additional lanes classify the same 24 workloads:

| Lane | Supported | Unsupported | Unsupported workload ids and reasons |
| --- | --- | --- | --- |
| Roact | 19 | 5 | `ordered-window-scroll`: no matching ordered window primitive. `update-repeated`: no public binding batch transaction. `animate-many`: no spring. `unwind`: failed-render rollback is not guaranteed by the public mount handle. `scene-3d`: Roact sets names from reconciliation keys; named dictionary children do not preserve the required mounting order. |
| Seam | 22 | 2 | `ordered-window-scroll`: no matching ordered window primitive. `status-panel`: the native computed-property type guard rejects the workload's synthetic `Frame.Text`, whose initial type is nil. |
| signals | 12 | 12 | All eight `keyed-*` workloads and `status-panel`: no native keyed Instance collection or row lifetime primitive. `branch-swap`: no conditional Instance ownership primitive. `animate-many`: no spring. `ordered-window-scroll`: no matching ordered window primitive. |
| React + Reflex | 21 | 3 | `ordered-window-scroll`, `animate-many`, `unwind`: the same rendering limitations as the existing React lane. |
| Fusion + Charm | 19 | 5 | `ordered-window-scroll` and the same four shrinking keyed workloads as Fusion. Charm batching supports `update-repeated`. |
| Roblox React | 21 | 3 | `ordered-window-scroll`, `animate-many`, `unwind`: the same rendering limitations as the existing React lane. |

### Measurement and fairness

The comparison first runs the existing observable-tree parity check.
It also compares the prepared tree and every update checkpoint, checks retained row identity, and checks disposal.
The leaf and repeated-write workloads must commit exactly one property write per run.
A missing implementation without an unsupported reason fails parity.
Unsupported lanes have no timing or heap measurement.

Timing uses the existing Verify workload collections, sample counts, warmup, CPU reference, rotated order and calibration retry.
The timed region includes every authored iteration and the final environment drain.
Setup, framework loading, snapshots and release are outside timing, as in the normal runtime suite.
Mount-and-release workloads include their own release inside the timed region.
The comparison does not apply performance thresholds between libraries.

Each supported lane also has a separate, exclusive heap worker.
It first runs one unreported full memory lifecycle. It then records three full memory lifecycles.
Each lifecycle loads the framework and creates the environment and borrowed container before the heap baseline.
It builds the scene, runs the authored iterations, measures mounted heap, releases the scene, and measures teardown heap.
The table uses the median of those three estimates. It uses the same bounded collection-witness method as paired performance.
The framework's loaded modules and permanent scheduler are outside the scene baseline.
The estimate includes the cost-model nodes, bindings, framework state and adapter closures retained by the scene.
It does not measure exact reachable bytes, RSS or native engine memory. Teardown heap can include framework caches and estimator noise even when scene nodes and connections are all released.

The adapters use each library's public construction and state APIs.
Fusion uses scopes and `ForPairs`. Vide uses sources, `values` and explicit scoped cleanup.
Vide's public `strict` runtime flag is false so its development check does not evaluate each effect twice.
All maintained adapter code still uses strict Luau checking.
React uses production settings, ReactRoblox legacy roots, property bindings and keyed function components.
React's repeated-write lane uses batched React state; binding writes do not provide that coalescing contract.
The repeated-write lanes use numeric sources. They convert the final value to text after coalescing.
Blend uses states, computed properties and `ComputedPairs` with native subscriptions and Maids.
Its row-position map uses the public `Shared` operator so it is computed once per list update.
Blend's repeated-write lane uses its public `Throttled` operator to emit the last value at the end of the defer lane.
Fusion and Blend apply independent writes eagerly. The batched workload has one independent source per node, so it does not require those libraries to merge writes to the same sink.
Roact uses public bindings, class components, fragments and mount handles. Its structural subscriptions update component state.
Seam uses public scopes, values, computeds, `ForPairs`, `Batch` and springs. Its property bindings flush on a native frame callback, so each batch includes a zero-delta cost-model frame.
The cost-model host provides ancestry notifications, native vector defaults and the pre-render callback needed by these bindings.
Signals uses its public signals, computeds, effects and batch scheduler. Its small host bridge assigns properties and owns node and effect cleanup; it adds no scene reconciler or keyed collection.
React + Reflex subscribes React bindings to native producers and flushes the producers within the React batch. Its repeated-write workload converts the flushed numeric state to text once.
Fusion + Charm subscribes Fusion values to native atoms, releases each subscription with its Fusion scope, and uses Charm's public batch transaction.
These combined lanes retain their rendering library's native collection and animation behavior. Their measurements include the bridge and subscription costs.

The animation workload checks tree structure only. Its existing snapshot omits numeric animation properties.
Fusion and Blend use their native analytic springs. Vide uses its native solver. The target, damping and nominal period match the workload.
The solvers can produce different intermediate numbers. This lane does not prove equal trajectories, equal numerical error or equal animation quality.

Default properties and native cleanup costs remain in each lane.
All lanes use the same cost-model host, which adds dispatch and counter costs.
The adapters add small Luau call and table costs. The results include those costs.
These results describe this workload, host, runtime and machine. They do not establish native rendering, played quality or a general speedup.
Hosted-runner noise and garbage collection can affect the results. Read the raw samples and calibration records before drawing a conclusion.

The workflow writes `comparison.md` to the job summary and retains the output directory as the `framework-comparison` artifact for seven days.
The table gives median time in microseconds, mounted retained heap in KiB, and each value divided by Compose.
Lower ratios mean smaller measurements. A zero Compose heap baseline has no ratio.
Time is per complete workload sample; divide by the table's iteration count for a time per run.
The artifact also contains `stored.json`, `report.json`, `context.json` and the gate evidence.
The context records source identity, dirty state, runtime, machine, command and dependency identities.
Only passed cases supply measurements to `stored.json` and the table. A rejected calibration cannot supply a comparison value.
Missing supported measurements fail the command. Failed and noisy attempts remain in the raw report and gate artifact.

## Required CI comparison

The required `Gate` check waits for two independent jobs: `Repository suite` and `Paired performance`. They run at the same time on separate Ubuntu runners. The suite shares a CPU process budget between commands and isolated test workers. Workers fill free slots as checks finish, with a limit of eight workers and one worker per 2 GiB after a 2 GiB reserve. Timing stays serial on its own runner.

The paired job measures three complete `--suite all` rounds on one runner. Arm order alternates base/candidate, candidate/base, base/candidate. The timing samples and CPU-reference budgets are split across these rounds. A persistent regression continues through six rounds with the same alternating order. Calibration and execution failures stop the comparison. The baseline is the pull request's exact base commit; a main push compares against its previous commit, and a manual run compares against its parent. Both revisions use the candidate's pinned tools, Verify dependency, benchmarks, test fixtures and maintainer tooling. The measurement archive and its hash are retained. Production `src` and `authoring` remain specific to each revision.

Every pull request runs both jobs, including documentation-only changes.

The Verify comparison checks each timed measurement's median, requiring the same name, unit and environment. Growth must exceed both 50 percent and 5 microseconds in every paired round and in the pooled samples to flag a persistent regression. The instrumented `/counts` passes remain in the raw reports but are excluded from timing comparison, as their duration is not a performance measurement. Missing or renamed measurements fail rather than silently reducing coverage. Every individual run must finish completely passed; failed, skipped or unsupported producers cannot qualify the candidate. Benchmark changes that make the runs incomparable need an explicit review and a compatible comparison, not an omitted CI step.

Each entry also measures Compose's retained Luau heap while mounted and after teardown in a fresh worker, outside timing. It first warms the lifecycle until two consecutive teardown readings agree within 1 KiB, at most four times, so one-time process growth does not count as retention. Then it records one memory lifecycle per paired round with Verify's bounded `gc-witness-low-water/2` estimator and eight collection witness cycles per endpoint. Temporary 8 KiB buffers drive collection progress. Raw heap readings and collection progress stay in the report attachments. Growth must exceed both 5 percent and 64 KiB in every paired round and in the pooled median to flag a persistent regression. Missing mounted or teardown measurements fail. This estimates retained Luau heap; it does not measure exact reachable bytes, process RSS or Roblox engine memory. An unchanged workload and a retained 4 MiB allocation test the comparison through the real lifecycle adapter in separate workers.

The `performance-evidence` artifact retains both raw stored runs and full reports, including failed attempts, for seven days. The job log records the comparison and each source identity. This checks the existing construction, update, identity, event, animation, unwind and teardown workloads, plus every UI, 2D, 3D, virtualization and entity scenario at its authored scales. It measures headless cost-model CPU behavior, including its dispatch overhead. It does not establish native rendering, physics, networking, input latency or played quality, and it does not detect regressions smaller than the comparison thresholds. Paired execution avoids a historical-machine baseline; it cannot eliminate hosted-runner noise.

`lute run bench/calibration.luau` optionally captures three diagnostic collections for each of two workloads. It records raw CPU endpoint samples and invalidation reasons. These diagnostics are outside normal CI. They do not replace a check or change its verdict. The heap estimator permits at most 2.5 million pressure allocations and 10 seconds per endpoint for the large fixtures.

## What a run does

The command builds one Verify gate. For each workload or scenario scale it declares three producers.

1. `parity-<id>` runs one case on a Verify worker. The case builds the same scene in every framework and compares the tree snapshots.
2. `timing-<id>` runs one benchmark collection in a fresh Verify worker process. It runs exclusively,
   only after its parity case passes. Allocation and collection inside that workload remain timed;
   prior unrelated collections cannot leave their allocation debt in its process.
3. `memory-<id>` runs the Compose lifecycle in a fresh worker after parity. It records mounted and teardown heap measurements outside timing. A CPU calibration failure does not block it. It does not run in `--verify` mode.

A collection has one member for each framework. The members run in an order that rotates by one position for each workload.
Before calibration, the worker primes each member with one unmeasured complete sample through Verify. This prepares the fixture and its lifecycle before the first CPU reference. The collection then keeps all declared warmup and measured samples. It measures a fixed CPU workload, the yardstick, before and after the members. Each endpoint warms up for 16 batches, then records 32 samples of 64 calls each, expressed as time per call. Median drift above 25 percent marks the members unsupported. A paired round (`--paired-round`) allows 100 percent: base and candidate alternate within each round, so machine drift affects both arms, and the ceiling only rejects a broken machine.

Paired execution splits those 32 CPU samples and 16 warmup batches across the first three rounds. It also splits each member's timing sample count across those rounds. A 31-sample scene uses 11, 10 and 10 samples. The six-round confirmation repeats that budget. Diagnostic count passes and fixture priming run in every round, so process startup and priming add some overhead.

Each timing collection permits two calibration-only retries through Verify. A yardstick drift or spread rejection can retry only when its workloads completed without failures or other invalid measurements. Every attempt remains in `calibration-attempts.tsv`. A third calibration rejection still fails. Valid measurements, workload failures and paired regressions do not trigger a retry. The ceiling is unchanged by the retries.

Scene and entity members use 31 complete measured samples. The shared suite owns that budget;
individual scenarios own their inputs and warmup. This spans multiple allocation/collection cycles
instead of allowing a seven-sample median to depend on one short allocation phase. It reduces
sampling variability, but does not eliminate hosted-runner noise or establish native performance.

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

`lute run bench/primitives.luau` measures the runtime primitives through Verify benchmarks, with 10 warmup samples and 40 measured samples of 200 operations. Setup and disposal are outside timing.
One Windows Lute headless run measured these p50/p95 microseconds per property notification or fake-host frame: observation with 100 holders of one property, 0.203/0.337; changing settled snapshot, 0.480/0.687; one-second clock with one subscriber, 0.447/0.605; sequence with one active tween track, 1.763/2.401.
These are absolute microbenchmarks, including fake-host dispatch, with no native rendering or speedup claim. Re-run for the current machine and revision.
The command stores raw Verify samples and source/environment context in `bench/results/primitives`; an optional first argument chooses another evidence directory.
The runtime primitive Verify cases separately count subscriptions and publications: 100 observation holders use one property connection; mixed active frame work uses one native frame listener; settled, completed, cancelled and unobserved work uses none. The one-second clock test observes one publication across four quarter-second frames, with no reactive writes between intervals.
Before you update the framework pin of a consumer, verify the affected consumers.
An engine claim needs its own authentic execution. See [engine verification](../verification/roblox/README.md).
Do not relabel an earlier receipt as evidence of new source.
