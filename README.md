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

The [framework comparison](docs/framework-comparison.md) times Compose against Fusion, Vide, React, Roact, Blend, Seam and other Roblox UI libraries on 23 runtime workloads. Each library passes the same parity checks before timing. These are headless cost-model measurements from CI (`00a663b`). They do not measure engine rendering.

Compose is faster than the fastest other library in 11 workloads, equal in 1 and slower in 11. Its retained heap is within 1.1x of hand-written Instances in 10 workloads and at most 1.88x.

| Workload | Time vs fastest other library | Time vs hand-written | Heap vs hand-written |
| --- | ---: | ---: | ---: |
| update-repeated | 0.57x (React Reflex) | 6.72x | 0.79x |
| update-leaf | 0.66x (Roact) | 2.22x | 1.00x |
| branch-swap | 0.67x (Vide) | 1.17x | 0.99x |
| update-batched | 0.77x (React) | 2.86x | 1.13x |
| animate-many | 0.76x (Vide) | 5.01x | 1.56x |
| cold-mount-10000 | 1.00x (Signals) | 1.33x | 1.00x |
| mount-dispose | 1.01x (Signals) | 1.04x | 0.95x |
| cold-mount-100 | 1.24x (Signals) | 1.13x | 1.01x |
| keyed-reverse | 1.45x (Blend) | 2.85x | 1.28x |
| keyed-replace | 1.51x (Roact) | 2.27x | 1.11x |

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
