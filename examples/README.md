# Examples

These examples are small, runnable patterns for using Compose.

These programs appear in the order [`init.luau`](init.luau) lists them. Each program
runs, asserts its claim, and is checked by the gate.

```bash
lute run tools/run-examples.luau
```

| Example | What it shows |
| --- | --- |
| [`profiling.luau`](profiling.luau) | Finding the formula that recomputes constantly but publishes almost never, using `Compose.profile`. |
| [`lifetime.luau`](lifetime.luau) | Finding the subscription that outlived the screen that created it, using `Compose.inspect`. |
| [`accumulator.luau`](accumulator.luau) | The two stated-intent reactive forms. A `sharedCell` shows module-scope life is the point. An `accumulator` merges discrete events into running state without a peek/set dance. |
| [`arena.luau`](arena.luau) | The canonical module shape, whole: a root that owns external state, local component state, a keyed collection, and one mount. See [`../docs/api.md`](../docs/api.md). |
| [`collections.luau`](collections.luau) | A windowed chat and a relevance-retained battlefield. Both do work proportional to what is visible. |
| [`composition-primitives.luau`](composition-primitives.luau) | Layers, bounded admission, logical focus, and explicit resource reuse, all in one owned scene. |
| [`mount-target.luau`](mount-target.luau) | Mounting a second producer into a node the tree already owns, plus an adopted clone under it, without demoting the target to borrowed. |
| [`attributes.luau`](attributes.luau) | The reserved `Attributes` key. It covers static and reactive attributes, deduped writes, `nil` clearing one, and a value the host refuses by name rather than swallows. |
| [`root-scope.luau`](root-scope.luau) | An entry point with no ambient owner. One long-lived root serves the process, one scoped root serves a boot job, and both exist to enable the refusal shown here. |
| [`roblox-emulator.luau`](roblox-emulator.luau) | The Instance-shaped emulator. A component reaches an instance through a ref, calls methods on it, loads an animation track, and unwinds a failed mount, all with no Roblox present. |

All but the last run against [`../src/test-host`](../src/test-host), which is deliberately not
Roblox-shaped. Its nodes are frozen empty tables with no members at all. That is what makes
them runnable here, and it is also the demonstration: the same code targets
[`../src/roblox`](../src/roblox) by changing which host the runtime is built from.

`roblox-emulator.luau` is the exception, and it makes the same point from the other side. It
runs against [`../src/test-host/roblox.luau`](../src/test-host/roblox.luau), whose nodes *are*
Instance-shaped. The component in it reaches an instance through a ref and calls methods on it,
yet it still needs no Roblox.

```luau
local runtime = Compose.createRuntime(TestHost.create().host)   -- here
local runtime = ComposeRoblox.createRuntime()                    -- in Roblox
```

Start with the [quickstart](../docs/quickstart.md), then `arena.luau`.
