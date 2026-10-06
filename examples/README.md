# Examples

These programs demonstrate Compose through its public packages.
For constructor syntax and the first component, start with the [quickstart](../docs/quickstart.md).

The programs appear in the order that [`init.luau`](init.luau) lists them.
Each program runs and asserts its claim. The producer `tests` of the gate runs each program as one case.

```bash
lute run tools/gate.luau --file tests/examples/examples.verify.luau
```

| Example | What it shows |
| --- | --- |
| [`quickstart.luau`](quickstart.luau) | Building, updating and disposing one component. |
| [`profiling.luau`](profiling.luau) | Finding the formula that recomputes constantly but publishes almost never, with `Compose.profile`. |
| [`lifetime.luau`](lifetime.luau) | Finding the subscription that outlived the screen that created it, with `Compose.inspect`. |
| [`accumulator.luau`](accumulator.luau) | A `sharedCell` declares shared module state. An `accumulator` reduces source events into state without manual read and write feedback. |
| [`store-scene.luau`](store-scene.luau) | A root with owned external state, local component state, a keyed collection and one mount. See [`../docs/api.md`](../docs/api.md). |
| [`collections.luau`](collections.luau) | A windowed log and a relevance-retained field. Both do work that is proportional to what is visible. |
| [`tile-map.luau`](tile-map.luau) | A rectangular camera window over a map of a million coordinates, tile edits, edge admission and rectangle focus. |
| [`composition-primitives.luau`](composition-primitives.luau) | Layers, bounded admission, logical focus and explicit resource reuse, all in one owned scene. |
| [`mount-target.luau`](mount-target.luau) | Mounting a second producer into a node that the tree already owns, plus an adopted clone under it, without demoting the target to borrowed. |
| [`attributes.luau`](attributes.luau) | Static and reactive `Attributes`, duplicate-write suppression, clearing with `nil` and explicit host value rejection. |
| [`root-scope.luau`](root-scope.luau) | Explicit ownership at an entry point: a long-lived process root and a scoped boot-job root. |
| [`roblox-emulator.luau`](roblox-emulator.luau) | The Instance-shaped emulator. A component reaches an instance through a ref, calls methods on it, loads an animation track and unwinds a failed mount, all with no Roblox present. |

All examples except the last use [`../src/test-scene`](../src/test-scene). Its nodes are frozen empty tables without members.
These examples use only the host protocol. They can target [`../src/roblox`](../src/roblox) if you change the adapter of the runtime.

`roblox-emulator.luau` uses [`../src/test-scene/roblox.luau`](../src/test-scene/roblox.luau).
Its nodes have Instance-style properties and methods. The component calls those methods through a ref without running Roblox.

```luau
local runtime = Compose.createRuntime(TestScene.create().adapter)   -- here
local runtime = ComposeRoblox.createRuntime()                    -- in Roblox
```

Start with the [quickstart](../docs/quickstart.md), and then `store-scene.luau`.
