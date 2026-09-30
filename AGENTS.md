# Compose maintainer laws

Compose owns finite application scene trees through a host-neutral protocol. [README](README.md) maps
tasks; load the relevant [contract](docs/index.md), not every guide.

- Only the host protocol creates, changes, parents or destroys nodes. Core has no engine or ambient clock. Preserve fine-grained updates.
- Dispose owned resources once, preserve borrowed resources and unwind failed builds. Exercise those boundaries.
- Use public package entry points. Inspect production, dynamic, generated, CLI and test consumers before cutting a surface. Exports and tests alone do not justify unused machinery.
- Keep one current contract and runnable falsifier. Headless checks prove no engine experience or unmeasured speedup.
- This file owns authority. Apply [Execute's agentic standard](https://github.com/voidmeld/execute/blob/main/docs/AGENTIC-STANDARD.md) to workflow changes and code review. Extra process needs a concrete consumer benefit.
- Maintain automation in Lute Luau; exact dependencies belong only in `dependencies.lock.luau`.
- Add no explanatory source comments; retain tool directives and required license notices.
- Keep adopter identity, destinations, policy and milestones out of the framework. Commercial comparisons belong in research; exact dependency/API/license identifiers remain.

Run focused checks while editing. After corpus changes, run `lute run tools/check-test-manifest.luau
--write`. Commit the candidate, then run `lute run tools/gate.luau` once on clean HEAD; its fresh-clone
check must pass before integration. Do not change verified bytes.

Use author and committer `voidmeld <158495725+voidmeld@users.noreply.github.com>` without attribution
trailers. Preserve license notices and exact consumer behavior when simplifying.
