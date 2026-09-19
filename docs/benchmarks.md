# Representative proof

Run correctness before timing. The runtime suite covers construction, reactive updates, identity,
events, animation, unwind and teardown. The scene suite combines UI, 2D/3D content, virtualized
collections and battle churn. Both lanes use the same emulated host and deterministic input.

```bash
lute run tools/gate.luau
lute run bench/run.luau --verify
lute run bench/scenarios-run.luau --suite all --verify
lute run bench/run.luau --out build/performance/runtime
lute run bench/report.luau --from build/performance/runtime
lute run bench/scenarios-run.luau --suite battle --filter battle-integrated --scale medium --out build/performance/battle
lute run bench/scenarios-report.luau --from build/performance/battle
```

Use `--filter` and `--scale` for a bounded diagnostic; never claim a filtered run covers all cases.
Admit timing only with matched observable trees, fixed inputs, warmup, rotated lanes, separate
untimed counters and zero retained nodes/connections. Report absolute time and noise, not ratios alone.

Record source commit/tree, dirty state, runtime/environment, command and concurrency outside the
active source tree. Preserve failed/noisy attempts there too. Historical samples are not automatic
baselines. The explicit `tools/check-benchmark-regressions.luau BASELINE.json CURRENT.json` comparison
never runs timings itself; compatible source/input/environment remains the reviewer’s responsibility.

Core CPU proof does not establish native rendering, physics, networking, device input or played quality.
Framework changes require affected actual consumers before repinning. An engine or fresh-agent claim
requires its own authentic execution. Do not relabel an earlier receipt as evidence of new source.
