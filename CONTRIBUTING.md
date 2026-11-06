# Contributing to Compose

Thank you for your interest in Compose. This guide explains how to set up a
checkout, how to check a change and how to send it.

## Setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit).
2. Run `rokit install` in the repository root. This installs the pinned tools
   from `rokit.toml`: Lute, luau-lsp, Rojo, StyLua and Luau.
3. Run `lute setup` to install the Luau SDK type definitions.

## Rules

Read [AGENTS.md](AGENTS.md) before you change the repository. It states the
rules that every change must follow, including the type policy, the
specification style and the evidence that a change needs. The
[API reference](docs/api.md) states the public contracts.

## Check a change

- While you edit, run one specification through the gate:
  `lute run tools/gate.luau --file tests/path/name.verify.luau`. Add
  `--name text` to select cases.
- After you add or remove a specification, run
  `lute run tools/check-test-manifest.luau --write`.
- Commit the change. Then run `lute run tools/gate.luau` once on the clean
  commit. The full gate includes a fresh-clone check, so it must run on a
  committed tree.

## Pull requests

- Open a pull request against `main`. Do not push to `main` directly.
- The required `Gate` check must pass before a pull request can merge. The other
  CI jobs, such as paired performance, must also pass.
- Describe what the change does, why, and the evidence: the specifications you
  added and the gate result.
- Keep one change in one pull request.

## License

Compose is licensed under the [MIT License](LICENSE). By contributing, you agree
that your contributions are licensed under the same license.
