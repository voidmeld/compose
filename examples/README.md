# Examples

These examples are small, runnable patterns for using Compose. Each runtime exposes a constructor table that caches fields on first lookup: `local Host = runtime.constructors`, then `Host.Kind { ... }`.
`Compose` remains the core module supplying reactive and ownership helpers.

These programs appear in the order [`init.luau`](init.luau) lists them. Each program
runs, asserts its claim, and is checked by the gate.

```bash
lute run tools/run-examples.luau
```

| Example | What it shows |
| --- | --- |
| [`profiling.luau`](profiling.luau) | Finding the formula that recomputes constantly but publishes almost never, using `Compose.profile`. |
| [`lifetime.luau`](lifetime.luau) | Finding the subscription that outlived the screen that created it, using `Compose.inspect`. |
| [`accumulator.luau`](accumulator.luau) | A `sharedCell` declares shared module state. An `accumulator` reduces source events into state without manual read/write feedback. |
| [`arena.luau`](arena.luau) | A root with owned external state, local component state, a keyed collection and one mount. See [`../docs/api.md`](../docs/api.md). |
| [`collections.luau`](collections.luau) | A windowed chat and a relevance-retained battlefield. Both do work proportional to what is visible. |
| [`composition-primitives.luau`](composition-primitives.luau) | Layers, bounded admission, logical focus, and explicit resource reuse, all in one owned scene. |
| [`mount-target.luau`](mount-target.luau) | Mounting a second producer into a node the tree already owns, plus an adopted clone under it, without demoting the target to borrowed. |
| [`attributes.luau`](attributes.luau) | Static and reactive `Attributes`, duplicate-write suppression, clearing with `nil`, and explicit host value rejection. |
| [`root-scope.luau`](root-scope.luau) | Explicit ownership at an entry point: a long-lived process root and a scoped boot-job root. |
| [`roblox-emulator.luau`](roblox-emulator.luau) | The Instance-shaped emulator. A component reaches an instance through a ref, calls methods on it, loads an animation track, and unwinds a failed mount, all with no Roblox present. |

All examples except the last use [`../src/test-scene`](../src/test-scene). Its nodes are frozen empty tables without members.
These examples use only the host protocol. They can target [`../src/roblox`](../src/roblox) by changing the runtime's adapter.

`roblox-emulator.luau` uses [`../src/test-scene/roblox.luau`](../src/test-scene/roblox.luau).
Its nodes have Instance-style properties and methods. The component calls those methods through a ref without running Roblox.

```luau
local runtime = Compose.createRuntime(TestScene.create().adapter)   -- here
local runtime = ComposeRoblox.createRuntime()                    -- in Roblox
```

Start with the [quickstart](../docs/quickstart.md), then `arena.luau`.
