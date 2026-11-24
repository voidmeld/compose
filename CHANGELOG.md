# Changelog

Compose follows [semantic versioning](https://semver.org). While the version is `0.x`, a minor
release may change a public contract.

## Unreleased

- Follow-up: publish the Compose skill. Add `/.agents/skills/compose/**` to the `files` in
  `pkg.luau` so consumers that mirror the skill read it from the installed package.

## 0.1.0

- First versioned release. Compose is a `lute pkg` package: `pkg.luau` declares it, and
  consumers install it with `lute pkg install --vendor`.
- Verify is a development dependency pinned in `pkg.luau`; the custom dependency lock and sync
  script are gone. The pinned Roblox declarations for native type checks live in
  `tools/roblox-types.luau`.
- Requires Lute `1.0.1-nightly.20261120` or newer.
