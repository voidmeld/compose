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

Use `--filter` and `--scale` for focused diagnostics. Do not claim that a filtered run covers all cases.
Before comparing timings, check these conditions:

- Observable trees match.
- Inputs are fixed.
- Each lane has warmup and runs in rotated order.
- Counters run separately from timing.
- Disposal leaves no retained nodes or connections.

Report absolute time and noise as well as ratios.

Record the source commit/tree, dirty state, runtime/environment, command and concurrency outside the active source tree.
Keep failed and noisy attempts there too. Do not automatically use historical samples as baselines.
`tools/check-benchmark-regressions.luau BASELINE.json CURRENT.json` compares existing samples; it does not run timings.
The reviewer must check that source, inputs and environment are compatible.

Core CPU proof does not establish native rendering, physics, networking, device input or played quality.
Verify affected consumers before updating their framework pins. An engine or fresh-agent claim
requires its own authentic execution. Do not relabel an earlier receipt as evidence of new source.
