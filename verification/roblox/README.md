# Engine verification

[`checks.luau`](checks.luau) lists runtime checks and adds the [scene checks](checks-scenes.luau) in order.
[`entry.luau`](entry.luau) converts each check into a Verify case.
Cases test native property rejection, failed construction, class defaults, layout, animation, scene updates and disposal.

Each case requires `roblox-engine`.
The entry declares that capability only on a native host.
Simulation reports these cases as unsupported.
The gate checks their types under both solvers with the official Roblox declarations pinned in `dependencies.lock.luau`.
Type checking does not run the engine.

## Run the checks

Studio must be installed, authenticated and configured for MCP tools.
The Verify documentation describes native Studio execution.
The command starts a disposable Studio with a generated place.
It does not save, publish or upload the place.

```bash
lute run .lute/dependencies/verify/tools/run.luau --entry verification/roblox/entry.luau --host studio --context Client --deadline 300
```
Use `--case instance-lifecycle` to select one check.
The case IDs are in the runtime and scene check files linked above.
`lute run tools/gate.luau --native` runs this command as `roblox-engine`.
It also runs `spring-heartbeat` with `--context Server` as `roblox-heartbeat`.
This keeps coverage of the server frame source.

Exit code zero means all selected cases passed.
Each run keeps `report.json`, `summary.txt` and Studio diagnostics in a unique directory under `.verify`.
Each case records its detail as a step.
The report records the Studio version, place, context and animatable types.
Keep the evidence, Studio version and source commit outside the active source tree.
Missing or partial output is not a pass.

### Client and server frames

Run `property-readables-before-render` on a native client.
It checks hidden layout measurement, shared property signals, settled sampling and the first visible frame.
It requires `roblox-client`. A server or simulator cannot prove this result.
Run client animation, timeline and scheduler checks with `PreRender`.
Retain server `Heartbeat` coverage.
Measure observation callback cost during animated layout with the engine profiler.
Headless timing cannot prove that cost.

Check mixed motion, timelines, scheduling, collection admission, clocks, settled sampling and sequences on both frame sources.
Check coherent frame publication.
Check isolation after callback failures.
Check that completion and disposal release all subscriptions.

## Limits

A passing run proves only behavior covered by its cases.
For native code generation, inspect modules with preserved source boundaries in the engine profiler.
A source directive or CPU timing cannot prove it.
Native rendering, device input and application quality require consumer evidence.
