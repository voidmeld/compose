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
`bench/publish.luau` keeps one file per commit under `results/`. It writes `README.md` with each benchmark's latest median and p95. The page also shows changes from the previous commit and trend charts for Compose timings.
The runner is the CI Ubuntu runner, so compare values from the same branch history only.

## Library comparison

The comparison with other Roblox scene composition libraries is in the [Luau library benchmarks](https://github.com/voidmeld/luau-library-benchmarks) repository.

## Required CI comparison
The required `Gate` check waits for `Repository suite` and `Paired performance`. These jobs run concurrently on separate Ubuntu runners. The suite shares a process budget between commands and isolated test workers. Each completed check frees a worker slot. The limit is eight workers, with one per 2 GiB after a 2 GiB reserve. Timing runs serially on its own runner.
The required `Gate` check waits for two independent jobs: `Repository suite` and `Paired performance`. They run at the same time on separate Ubuntu runners. The suite shares a CPU process budget between commands and isolated test workers. Workers fill free slots as checks finish, with a limit of eight workers and one worker per 2 GiB after a 2 GiB reserve. Timing stays serial on its own runner.
The paired job measures three complete `--suite all` rounds on one runner. Order alternates base/candidate, candidate/base, base/candidate. The timing and CPU-reference sample budgets span those rounds. A persistent regression continues through six rounds with the same alternating order. Calibration or execution failure stops comparison. A pull request uses its exact base commit. A main push uses the previous commit. A manual run uses its parent. Both revisions use the candidate's pinned tools, Verify dependency, benchmarks, fixtures and maintainer tools. The evidence includes the measurement archive and its hash. Each revision uses its own production `src` and `authoring`.
The paired job measures three complete `--suite all` rounds on one runner. Arm order alternates base/candidate, candidate/base, base/candidate. The timing samples and CPU-reference budgets are split across these rounds. A persistent regression continues through six rounds with the same alternating order. Calibration and execution failures stop the comparison. The baseline is the pull request's exact base commit; a main push compares against its previous commit, and a manual run compares against its parent. Both revisions use the candidate's pinned tools, Verify dependency, benchmarks, test fixtures and maintainer tooling. The measurement archive and its hash are retained. Production `src` and `authoring` remain specific to each revision.

Every pull request runs both jobs, including documentation-only changes.
Verify compares timed medians with matching names, units and environments. A persistent regression must exceed both 50 percent and 5 microseconds in every paired round and the pooled samples. Raw reports retain `/counts` passes, but their durations do not enter timing comparison. Missing or renamed measurements fail the check. Every individual run must pass completely. Failed, skipped or unsupported producers cannot qualify the candidate. If benchmark changes prevent comparison, review those changes and provide a compatible comparison. Do not omit the CI step.
The Verify comparison checks each timed measurement's median, requiring the same name, unit and environment. Growth must exceed both 50 percent and 5 microseconds in every paired round and in the pooled samples to flag a persistent regression. The instrumented `/counts` passes remain in the raw reports but are excluded from timing comparison, as their duration is not a performance measurement. Missing or renamed measurements fail rather than silently reducing coverage. Every individual run must finish completely passed; failed, skipped or unsupported producers cannot qualify the candidate. Benchmark changes that make the runs incomparable need an explicit review and a compatible comparison, not an omitted CI step.

Each entry measures retained Compose Luau heap while mounted and after disposal in a fresh worker, outside timing. Warmup repeats at most four lifecycles. It stops when two consecutive teardown readings agree within 1 KiB. This excludes initial process growth from retention. Each paired round then records one memory lifecycle with Verify's bounded `gc-witness-low-water/2` estimator. Each endpoint uses eight collection witness cycles. Temporary 8 KiB buffers advance collection. Reports retain raw heap readings and collection progress. A persistent regression must exceed both 5 percent and 64 KiB in every round and the pooled median. Missing mounted or teardown measurements fail the check. These are retained Luau heap estimates. They do not measure exact reachable bytes, RSS or engine memory. Separate workers test the comparison with an unchanged workload and a retained 4 MiB allocation through the real lifecycle adapter.

The `performance-evidence` artifact keeps raw runs, full reports and failed attempts for seven days. The log records the comparison and source identities. Coverage includes construction, updates, identity, events, animation, failed construction and disposal. It also includes all UI, 2D, 3D, virtualized collection and entity scenarios at their declared scales. Measurements include headless host dispatch costs. They do not prove native rendering, physics, networking, input latency or application quality. Changes below the thresholds can pass. Paired runs avoid a historical-machine baseline but cannot remove hosted-runner noise.

`lute run bench/calibration.luau` optionally captures three diagnostic collections for each of two workloads. It records raw CPU endpoint samples and invalidation reasons. These diagnostics are outside normal CI. They do not replace a check or change its verdict. The heap estimator permits at most 2.5 million pressure allocations and 10 seconds per endpoint for the large fixtures.

## What a run does

The command builds one Verify gate. For each workload or scenario scale it declares three producers.

1. `parity-<id>` runs one case on a Verify worker. The case builds the same scene in every framework and compares the tree snapshots.
2. `timing-<id>` runs one benchmark collection in a fresh Verify worker process. It runs exclusively,
   only after its parity case passes. Allocation and collection inside that workload remain timed;
   prior unrelated collections cannot leave their allocation debt in its process.
3. `memory-<id>` runs the Compose lifecycle in a fresh worker after parity. It records mounted and teardown heap measurements outside timing. A CPU calibration failure does not block it. It does not run in `--verify` mode.

A collection has one member per framework. Member order rotates by one position for each workload. The comparison timing workers apply the same rotation. Before calibration, Verify runs one unmeasured complete sample per member to prepare its fixture and lifecycle. It retains all declared warmup and measured samples. It measures the CPU reference before and after the members. Each endpoint warms up for 16 batches. It then records 32 samples of 64 calls each as time per call. Median drift above 25 percent makes members unsupported. A paired round with `--paired-round` permits 100 percent drift. Both arms alternate within each round. This ceiling rejects a broken machine rather than ordinary drift.

Paired execution divides the 32 CPU samples and 16 warmup batches across the first three rounds. It also divides each member's timing samples. A 31-sample scene uses 11, 10 and 10 samples. Six-round confirmation repeats that budget. Each round includes diagnostic count passes and fixture preparation. Process startup and preparation add overhead.

Each timing collection permits two retries for calibration failures through Verify. Drift or spread rejection can retry only if workloads completed without failures or other invalid measurements. `calibration-attempts.tsv` retains every attempt. A third calibration rejection fails. Valid measurements, workload failures and paired regressions do not retry. Retries do not change the ceiling.

Scene and entity members use 31 complete measured samples. The shared suite sets that budget. Each scenario sets its inputs and warmup. Samples span several allocation and collection cycles. This reduces dependence on one short allocation phase. It does not remove hosted-runner noise or prove native performance.

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
One Windows Lute run recorded p50/p95 microseconds per notification or test-host frame. Observation with 100 holders of one property measured 0.203/0.337. A changing settled snapshot measured 0.480/0.687. A one-second clock with one subscriber measured 0.447/0.605. A sequence with one active tween track measured 1.763/2.401.
These are absolute microbenchmarks, including fake-host dispatch, with no native rendering or speedup claim. Re-run for the current machine and revision.
The command stores raw Verify samples and source/environment context in `bench/results/primitives`; an optional first argument chooses another evidence directory.
Separate Verify cases count subscriptions and publications. One hundred observation holders share one property connection. Mixed active frame work shares one native listener. Settled, completed, cancelled and unobserved work keeps no listener. The one-second clock test observes one publication across four quarter-second frames. It performs no reactive writes between intervals.
Before you update the framework pin of a consumer, verify the affected consumers.
An engine claim needs its own authentic execution. See [engine verification](../verification/roblox/README.md).
Do not relabel an earlier receipt as evidence of new source.
