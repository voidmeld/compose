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

The [framework comparison](docs/framework-comparison.md) times Compose against Fusion, Vide, React, Roact, Blend, Seam and other Roblox UI libraries on 23 runtime workloads. Each library passes the same parity checks before timing. These are headless cost-model measurements from CI (`eabe9cc`). They do not measure engine rendering.

Compose is faster than the fastest other library in 12 workloads, equal in 1 and slower in 10. Its retained heap is at most 1.58x that of hand-written Instances, and within 1.1x in 10 workloads.

| Workload | Time vs fastest other library | Time vs hand-written | Heap vs hand-written |
| --- | ---: | ---: | ---: |
| cold-mount-100 | 0.79x (Seam) | 0.84x | 1.01x |
| update-leaf | 0.74x (Roact) | 2.22x | 1.00x |
| update-batched | 0.83x (React) | 3.29x | 1.12x |
| keyed-append | 0.89x (Vide) | 1.32x | 1.27x |
| animate-many | 0.86x (Vide) | 5.88x | 1.58x |
| cold-mount-10000 | 1.27x (Signals) | 1.39x | 1.01x |
| mount-dispose | 1.20x (Signals) | 1.05x | 1.01x |
| keyed-reverse | 1.64x (Blend) | 3.49x | 1.33x |

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
