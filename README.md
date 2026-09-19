# Compose

Compose is a host-neutral Luau library that builds and owns application scene trees.

## Start

- Build a component: [`docs/quickstart.md`](docs/quickstart.md).
- Change or verify Compose: [`AGENTS.md`](AGENTS.md).
- Find a system guide: [`docs/index.md`](docs/index.md).
- Use Compose in another repository: [`.agents/skills/compose/SKILL.md`](.agents/skills/compose/SKILL.md).

The public packages are [`src/core`](src/core), [`src/test-host`](src/test-host), and
[`src/roblox`](src/roblox). Core speaks only the documented
[host protocol](docs/host-protocol.md). A host supplies the concrete nodes.

## Gate

```bash
lute run tools/gate.luau
```

Run this command before reporting the repository as passing. Run it with `--list` to see the
checks. [`docs/benchmarks.md`](docs/benchmarks.md) defines reproducible representative checks and their limits.

## License

Compose is Copyright (c) 2026 voidmeld and licensed under the [MIT License](LICENSE). The private
source repository carries no third-party source; the exact private Verify dependency is declared in
[`dependencies.lock.luau`](dependencies.lock.luau).
