# Compose

A reactive UI and scene library for Roblox, written in strict Luau.

Compose lets you describe a screen or a 3D scene as plain functions. You put your game's
state in cells, bind instance properties to that state, and Compose updates only the
properties and children that depend on what changed. Nothing is rebuilt on every frame,
and nothing is diffed. When a component's owner ends, every instance, connection and
subscription it created is released, newest first. The same code runs in Roblox Studio and
in a plain Lute process with a test host, so components can be tested without the engine.

Compose is not a control library and not a framework. It has no buttons, themes or
navigation, no networking, storage or server logic, and it does not own your game loop.
A control library or a game builds those on top; your game supplies the rules and the
data.

First, build one component with the [quickstart](docs/quickstart.md).

## What is inside

| Area | What it provides | Reference |
| --- | --- | --- |
| Reactive state | Cells that hold a value, formulas that derive one, watches that react, batching and settling | [Reactive state](docs/api.md#reactive-state) |
| Ownership | Owners that release instances, connections and subscriptions together, in order | [Ownership](docs/api.md#ownership) |
| Composition | Constructors for any instance class, property binding, events, mounting into a target | [Composition](docs/api.md#composition) |
| Structure | Conditional children, keyed lists with reuse, ordered collections, portals, slots | [Structure](docs/api.md#structure) |
| Context and animation | Shared resources down the tree, springs and tweens driven by frames | [Context](docs/api.md#context) |
| Diagnostics | Named errors with a fix, retention and work counters, a scene inspector | [Diagnostics](docs/api.md#diagnostics) |
| Roblox host | Instances, datatypes, viewport and input bound to the engine | [Roblox](docs/api.md#srcroblox) |
| Test host | A scene host that runs with no engine, for tests and benchmarks | [Test hosts](docs/api.md#srctest-scene) |
| Design | Visual documents that compile to components, and a visual editor for them | [Design](docs/api.md#design), [Design editor](docs/api.md#design-editor) |
| Authoring | Build-time generation of content, layouts and project trees | [Authoring](docs/api.md#authoring-project-trees) |

## Example

A label that follows a counter, mounted on the test host so it needs no engine:

```luau
local Compose = require(path.to.compose.core)
local TestScene = require(path.to.compose["test-scene"])

local test = TestScene.create()
local runtime = Compose.createRuntime(test.adapter)
local Host = runtime.constructors

local count = Compose.cell(0)

local dispose, root = runtime.mount(function()
	return Host.Panel {
		Title = "Clicks",
		Label = function(use): string
			return ("clicked %d times"):format(use(count))
		end,
	}
end, test.root)

count:set(3)
runtime:settle()
assert(test.propertyOf(root, "Label") == "clicked 3 times")
dispose()
```

`use(count)` records that the label depends on the cell. Setting the cell updates that one
property. `dispose()` releases the panel, the binding and anything else the component
owned. On Roblox, `Host.Frame`, `Host.TextLabel` and every other class work the same way
with real instances. [examples](examples/README.md) has complete programs.

## How it fits together

| Surface | Purpose |
| --- | --- |
| [`src/core`](src/core) | State, ownership, scene construction, collections, animation and scheduling. No engine dependency. |
| [`src/roblox`](src/roblox) | The Roblox host: instances, datatypes, viewport and input. |
| [`src/test-scene`](src/test-scene) | Test hosts that run without an engine. Not for shipped places. |
| [`src/design`](src/design) | Design documents, sessions and source files. |
| [`src/design-editor`](src/design-editor) | The visual editor and its libraries for 2D and 3D scenes. |
| [`authoring`](authoring) | Content checks and file generation at build time. |

Core talks to a host through the [host protocol](docs/host-protocol.md); the Roblox host
is one implementation and the test host is another. Your application supplies its rules,
networking, storage and assets.

## Install

Compose is pinned by commit, not by version. Choose a commit of
`https://github.com/voidmeld/compose.git`, record its commit and tree hash in your
dependency lock, and require the public roots under `src`. The
[Compose skill](.agents/skills/compose/SKILL.md) describes adopting it in a repository.

## Documentation

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
| Check consumer ownership and names | [Consumer source checks](docs/checking.md) |
| Use the visual editor | [Design editor](docs/design-editor.md) |
| Plan repeated 3D parts with Pattern | [Geometric patterns](src/design/patterns.md) |
| Generate content, layouts and project trees | [Build-time authoring](authoring/README.md) |
| Measure time and memory | [Benchmarks](docs/benchmarks.md) |
| Run checks in Roblox Studio | [Engine verification](verification/roblox/README.md) |
| Change this repository | [Maintainer guide](AGENTS.md) and [contributing](CONTRIBUTING.md) |

## Performance

The [Luau library benchmarks](https://github.com/voidmeld/luau-library-benchmarks)
repository compares Compose with other libraries on the same workloads:
[results](https://github.com/voidmeld/luau-library-benchmarks/blob/main/docs/scene-composition/headless-results.md)
and [method](https://github.com/voidmeld/luau-library-benchmarks/blob/main/docs/scene-composition/method.md).
Every change to this repository is also compared with its base on the same runner for
time and retained memory; see [benchmarks](docs/benchmarks.md).

## Compatibility

The supported unit is an exact commit and tree; there is no semantic-version promise.
Exported declarations and documented error names are contracts, and a contract changes
together with its consumers. Modules under `src` that the API reference does not list are
internal. Source analysis uses Luau Solver V2, including read-only types.

## License

Copyright (c) 2026 voidmeld. [MIT License](LICENSE). The repository contains no
third-party source. [dependencies.lock.luau](dependencies.lock.luau) records the exact
development dependencies.
