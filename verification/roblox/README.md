# Engine verification

[`checks.luau`](checks.luau) lists the engine checks. [`entry.luau`](entry.luau) turns each check into one Verify case.
The checks cover native property refusal and unwind, class defaults, layout, animation, whole-scene updates and disposal.
They need an actual engine. Every case requires the capability `roblox-engine`. The entry declares it only on a native host.
The simulator host reports each case as unsupported. It never reports a pass.

The gate type-checks this directory under both Luau solvers against the official Roblox declarations that `dependencies.lock.luau` pins.
That check does not run the engine.

## Run the checks

Run the checks in a launched Studio. The command starts a disposable Studio on a generated place, so nothing is saved, published or uploaded.

```bash
lute run .lute/dependencies/verify/tools/run.luau --entry verification/roblox/entry.luau --host studio --deadline 300
```

Use `--case instance-lifecycle` to run one check. The case ids are in [`checks.luau`](checks.luau).
`lute run tools/gate.luau --native` runs the same command as the producer `roblox-engine`.
Studio must be installed, authenticated and configured for its MCP tools. The Verify documentation describes native Studio execution.

Exit code zero means that every selected case passed.
The run keeps `report.json`, `summary.txt` and the Studio diagnostics in a unique directory below `.verify`.
Each case records its detail as a step. The report environment records the Studio version, place, context and animatable types.
Keep the evidence directory, the Studio version and the source commit outside the active source tree.
Missing or partial output is not a pass.

Runtime primitives need native client validation of `property-readables-before-render`: hidden text/layout measurement, shared per-property signals, settled sampling and the first visible frame. This case also requires `roblox-client`; a server or simulator cannot establish that result. Run client animation, timeline and scheduler checks with the new default `PreRender` frame source, and retain server `Heartbeat` coverage. Measure property-observation callback cost during animated layout in the engine profiler. No headless timing establishes that cost.
Check mixed motion, timeline, scheduler, collection admission, clock, settled and sequence work for coherent frame publication, callback failure isolation and complete subscription release after completion or disposal on both frame sources.

## Limits

A passing run verifies only the engine behavior that its cases cover.
To verify native codegen, observe module-preserving source in the engine profiler. A source directive or a CPU timing cannot establish it.
Native rendering, device input and application quality need evidence from the consumer.
