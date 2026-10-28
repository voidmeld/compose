# Compose

Compose is a scene composition library for Luau. It builds UI and world scenes from functions.
It binds properties to state. A state change updates only the affected properties and children.
Each scene has an owner that releases its nodes and subscriptions.

First, follow the [quickstart](docs/quickstart.md) to build, update and release one component.

## Documentation

Use this page to find a task. Each linked page gives the details for that task.

| Task | Document |
| --- | --- |
| Build your first component | [Quickstart](docs/quickstart.md) |
| Run complete examples | [Examples](examples/README.md) |
| Find public calls, types and errors | [API reference](docs/api.md) |
| Control resource lifetimes | [Ownership](docs/ownership.md) |
| Read state and schedule updates | [Reactive state](docs/reactive.md) |
| Implement a host | [Host protocol](docs/host-protocol.md) |
| Use the Roblox host | [Roblox](docs/roblox.md) |
| Build or test a scene | [Scenes](docs/scenes.md) |
| Use the visual editor | [Design editor](docs/design-editor.md) |
| Generate content, layouts and project trees | [Build-time authoring](authoring/README.md) |
| Measure time and memory | [Benchmarks](docs/benchmarks.md) |
| Read the recorded comparison | [Comparison results](docs/framework-comparison.md) |
| Store local measurements | [Local output](bench/results/README.md) |
| Run checks in Roblox Studio | [Engine verification](verification/roblox/README.md) |
| Use the consumer skill | [Compose skill](.agents/skills/compose/SKILL.md) |
| Find skill API links | [Skill API route](.agents/skills/compose/references/api.md) |
| Find skill lifetime links | [Skill ownership route](.agents/skills/compose/references/ownership.md) |
| Find skill host and build links | [Skill guide routes](.agents/skills/compose/references/consumer-guides.md) |
| Edit a design source module | [Design source](.agents/skills/compose/references/design.md) |
| Change this repository | [Maintainer guide](AGENTS.md) |
| Review this simplification | [Change report](ready.md) |

## Performance

The [framework comparison](docs/framework-comparison.md) times Compose against Fusion, Vide, React, Roact, Blend, Seam and other Roblox UI libraries on 24 runtime workloads. Each library is measured as it ships, warm, through the same comparison driver, and passes the same parity checks before timing. Compose runs native code because it ships `--!native`. These are headless cost-model measurements from CI (`99df90e`). They do not measure engine rendering.

On the 20 workloads that do not measure a Compose-specific contract, Compose is faster than the fastest other library in 6, within 5% in 4 and slower in 10. Its retained heap is within 1.1x of hand-written Instances in 7 of the 19 workloads with a heap baseline and at most 1.60x. See [Workloads with Compose contracts](docs/benchmarks.md#workloads-with-compose-contracts) for the four excluded workloads.

| Workload | Time vs fastest other library | Time vs hand-written | Heap vs hand-written |
| --- | ---: | ---: | ---: |
| animate-many | 0.69x (Vide) | 3.90x | 1.51x |
| cold-mount-100 | 0.79x (Signals) | 1.16x | 1.01x |
| cold-mount-1000 | 0.79x (Vide) | 0.86x | 1.00x |
| keyed-append | 0.89x (Vide) | 1.27x | 1.30x |
| update-fanout | 0.90x (React) | 1.65x | 1.09x |
| update-batched | 0.92x (React) | 3.29x | 1.19x |
| keyed-remove | 0.98x (Vide) | 2.24x | 1.31x |
| keyed-insert | 0.99x (Vide) | 2.23x | 1.32x |
| branch-swap | 1.03x (Vide) | 1.28x | 1.60x |
| keyed-prepend | 1.04x (Blend) | 3.15x | 1.33x |
| keyed-replace | 1.13x (Roact) | 1.81x | 1.29x |
| cold-mount-10000 | 1.15x (Signals) | 1.23x | 1.00x |
| mount-dispose | 1.17x (Signals) | 1.07x | 1.00x |
| scene-3d | 1.31x (React Reflex) | 1.51x | 1.21x |
| update-leaf | 1.34x (Roact) | 2.90x | 1.00x |
| keyed-reverse | 1.58x (Blend) | 3.06x | 1.34x |
| events | 1.72x (Signals) | 1.29x | 1.00x |
| keyed-shuffle | 1.76x (Blend) | 3.25x | 1.34x |
| keyed-rotate | 1.91x (Blend) | 3.70x | 1.34x |
| mount-cycles | 2.13x (Signals) | 1.38x | — |

A ratio below 1.00x is smaller. See [benchmarks](docs/benchmarks.md) for the method and the commands.

## Packages

| Entry point | Purpose |
| --- | --- |
| [`src/core`](src/core) | State, scene construction, collections, animation, scheduling and geometry. |
| [`src/roblox`](src/roblox) | Roblox host, datatypes, viewport and input. |
| [`src/design`](src/design) | Design documents, sessions, source files and source links. |
| [`src/design-editor`](src/design-editor) | Visual editor and libraries for 2D and 3D scenes. |
| [`src/test-scene`](src/test-scene) | Test hosts that run without an engine. |
| [`authoring`](authoring) | Content checks and file generation at build time. |

Core has no engine dependency. The host creates and changes nodes.
The application supplies its rules, networking, storage and assets.

## License

Copyright (c) 2026 voidmeld. [MIT License](LICENSE).
The repository contains no third-party source.
[dependencies.lock.luau](dependencies.lock.luau) records the exact dependencies.
