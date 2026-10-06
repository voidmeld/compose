# Compose maintainer guide

Compose is a scene composition library for Luau. It owns finite scene trees through a host-neutral protocol.
The [README](README.md) maps the tasks. Load the relevant [contract](docs/index.md), not every guide.

This file owns the contribution rules. Each fact has one owning document.

## Rules

- Only the host protocol creates, changes, parents or destroys nodes. Core has no engine and no ambient clock. Preserve fine-grained updates.
- Dispose each owned resource once. Preserve borrowed resources. Unwind failed builds. Test those boundaries.
- Use public package entry points. Before you cut a surface, inspect its production, dynamic, generated, CLI and test consumers. Exports and tests alone do not justify unused machinery.
- Keep one current contract and one runnable falsifier. Headless checks prove no engine experience and no unmeasured speedup.
- Use existing tools. Add process only for a concrete consumer benefit.
- Write automation in Lute Luau. Put exact dependencies only in `dependencies.lock.luau`.
- Add no explanatory source comments. Keep tool directives and required license notices.
- Keep adopter identity, destinations, policy and milestones out of the framework. Keep comparisons with other products out of this repository. Keep exact dependency, API and license identifiers.

## Validate

- While you edit, run focused checks through the gate: `lute run tools/gate.luau --file tests/path/name.verify.luau` for one specification, `--name text` for the cases whose name contains the text, `--tier fast` for the fast tier.
- Write every test as a Verify case. Write every benchmark as a Verify benchmark and every engine check as a Verify case.
- After you add or remove a specification, run `lute run tools/check-test-manifest.luau --write`.
- Commit the candidate. Then run `lute run tools/gate.luau` once on the clean HEAD. Its fresh-clone check must pass before integration.
- Do not change verified bytes after the gate.
- Reuse evidence while its inputs stay unchanged.

## Repository

Use author and committer `voidmeld <158495725+voidmeld@users.noreply.github.com>`. Add no attribution trailers.
Preserve license notices and exact consumer behavior when you simplify.
