# Compose

Compose is a scene composition library for Luau. You build UI and world scenes from functions, bind properties to reactive state, and give nodes and subscriptions a defined lifetime.
An update changes only the affected properties or children. It does not rebuild the scene.

## Use cases

- Build a UI or world scene from component functions and mount it once.
- Bind a property to a cell or a formula. Compose recomputes only the dependents of a changed cell.
- Own nodes, subscriptions and external resources. Disposal runs once, newest first, and a failed build unwinds.
- Render large collections with keyed, ordered, windowed or relevance-retained children.
- Run on Roblox Instances through the Roblox host, viewport and input adapters.
- Test scenes and lifecycles with no engine, using the test scene and the Instance-shaped emulator.
- Validate content, compile layouts and generate source files and Rojo project trees at build time with the authoring package.
- Find hot formulas and leaked subscriptions with `Compose.profile` and `Compose.inspect`.

## Getting started

1. Install the pinned tools: `rokit install`.
2. Pin Compose. Use one exact commit of `https://github.com/voidmeld/compose.git`. Record its commit and tree hash in your repository. Require the packages under its `src` directory.
3. Mount one component. This is the complete file [examples/quickstart.luau](examples/quickstart.luau):

```luau
--!strict

local Compose = require "../src/core"
local TestScene = require "../src/test-scene"

local function run(): string
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

	local label = test.propertyOf(root, "Label") :: string
	dispose()
	return label
end

return {
	name = "quickstart",
	what = "building, updating and disposing one component",
	expected = "clicked 3 times",
	run = run,
}
```

Run it with `lute run tools/gate.luau --file tests/examples/examples.verify.luau`. The command runs every example as one case. The case `quickstart: building, updating and disposing one component` passes when the label reads `clicked 3 times`.
The [quickstart](docs/quickstart.md) explains each step and shows the Roblox host.

## Documentation

| Document | Owns |
| --- | --- |
| [Quickstart](docs/quickstart.md) | Build, update and dispose a component. |
| [Examples](examples/README.md) | Complete patterns that run on the test scene. |
| [Documentation index](docs/index.md) | The contracts: API, ownership, reactivity, hosts and scenes. |
| [Build-time authoring](authoring/README.md) | Content sets, semantic layouts and generated artifacts. |
| [Consumer skill](.agents/skills/compose/SKILL.md) | How an application adopts Compose. |
| [Contributor guide](AGENTS.md) | How to change and validate this repository. |

## Packages

| Public entry point | Use |
| --- | --- |
| [`src/core`](src/core) | Reactive state, scene construction, collections, animation, owner-bound scheduling and rectangle geometry. Host-neutral. |
| [`src/roblox`](src/roblox) | Roblox host, datatypes, viewport and input adapters. |
| [`src/test-scene`](src/test-scene) | Deterministic hosts for scene and lifecycle tests without an engine. |
| [`authoring`](authoring/README.md) | Build-time content validation, layout compilation, source generation and Rojo project tree generation. |

Core has no engine dependency. A host adapter creates and changes concrete nodes.
The application owns its rules, networking, persistence and asset loading.

Terms: a component is a function that returns composition. A cell holds state. A formula derives state. A node is one element of the scene. A host creates and changes nodes. An owner releases the resources that it holds. The consumer is the application that uses Compose.

## Validate

Run `lute run tools/gate.luau` on a clean committed HEAD. Every test, example, benchmark parity check and static check is a producer of that one gate.
Narrow a run with `--tier fast`, `--only producer`, `--file spec`, `--case id`, `--name text` or `--rerun`. Use `--explain id` for the reason of a result and `--list` to list the producers.
`--native` adds the engine checks. [AGENTS](AGENTS.md#validate) states when to run which.

## License

Copyright © 2026 voidmeld. [MIT License](LICENSE). The repository contains no third-party source.
The exact Verify dependency is in [dependencies.lock.luau](dependencies.lock.luau).
