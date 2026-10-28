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
| Read the library comparison | [Luau library benchmarks](https://github.com/voidmeld/luau-library-benchmarks/blob/main/docs/results.md) |
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

The [Luau library benchmarks](https://github.com/voidmeld/luau-library-benchmarks) repository compares Compose with other Roblox scene composition libraries. It measures each library as the library ships and checks that all libraries produce the same result before it measures time. See its [results](https://github.com/voidmeld/luau-library-benchmarks/blob/main/docs/results.md) and its [method](https://github.com/voidmeld/luau-library-benchmarks/blob/main/docs/method.md).

This repository keeps the paired performance check. It compares each change with its base on the same runner. See [benchmarks](docs/benchmarks.md).

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
