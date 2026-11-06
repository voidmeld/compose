# Contributing to Compose

This guide owns checkout setup and the procedure for checking and submitting a change.

## Setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit).
2. Run `rokit install` in the repository root. This installs the pinned tools
   from `rokit.toml`: Lute, luau-lsp, Rojo, StyLua and Luau.
3. Run `lute setup` to install the Luau SDK type definitions.

## Rules

Read [AGENTS.md](AGENTS.md) before you change the repository. It states the
rules that every change must follow, including the type policy, the
specification style and the evidence that a change needs.
Use the [README task table](README.md#documentation) to find the contract and source for your task.
The [API reference](docs/api.md) owns public signatures, return values and failures.

## Check a change

1. While you edit, run one specification through the gate:
   `lute run tools/gate.luau --file tests/path/name.verify.luau`. Add
   `--name text` to select cases. Use `--tier fast` for the fast tier.
   The `spec-style` producer runs `tools/check-spec-style.luau`.
   `tools/checks-config.luau` selects the specifications for that check.
2. If you add or remove a specification, run
   `lute run tools/check-test-manifest.luau --write`.
3. Commit the change.
4. Run `lute run tools/gate.luau` once on the clean commit.
   The full gate includes a fresh-clone check. That check must pass before integration.

## Pull requests

- Follow the [repository integration rules](AGENTS.md#repository).
- The required `Gate` check includes the repository suite and paired performance.
  See [CI comparison](docs/benchmarks.md#required-ci-comparison) for its evidence and limits.
- Describe what the change does, why, and the evidence: the specifications you
  added and the gate result.
- Keep one change in one pull request.

## License

Compose is licensed under the [MIT License](LICENSE). By contributing, you agree
that your contributions are licensed under the same license.
