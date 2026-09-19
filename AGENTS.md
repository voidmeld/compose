# Compose maintainer laws

Compose owns finite application scene trees through a host-neutral protocol. Keep that boundary
and fine-grained updates intact. Read [README.md](README.md), then [docs/index.md](docs/index.md).

- Only a host protocol creates, changes, parents or destroys nodes. Core has no engine or ambient clock.
- Dispose each owned resource once. Preserve borrowed resources. Release resources after a failed build. Test these behaviors.
- Public APIs come from package entry points. Inspect actual production, tooling, generated and test
  consumers before removing code. Remove mechanisms that have no consumer need. Exports and tests
  alone do not justify keeping them. Document the current public contract.
- Keep one current contract and runnable falsifier. Do not infer speedup or consumer experience
  from a passing CPU gate.
- Every code review checks for simpler names, control flow and boundaries without changing behavior.
  Remove proven redundancy. Keep useful abstractions. Prefer explicit code over fewer lines, and
  verify affected contracts before accepting a simplification.
- Maintain automation in Lute Luau. Exact dependencies live only in `dependencies.lock.luau`.
- Do not add explanatory source comments. Use names, types and public contracts to explain intent.
  Tool directives and required license notices are allowed.
- Keep the framework product-neutral: no adopter identity, private places, group ids or milestone names.
- Regenerate the test manifest after corpus changes with `lute run tools/check-test-manifest.luau --write`.
- Run focused checks while editing. Commit the candidate locally, then run `lute run tools/gate.luau`
  on the clean HEAD. The fresh-clone check must pass before integration. Do not change the candidate during verification.
- Set author and committer to `voidmeld <158495725+voidmeld@users.noreply.github.com>`.
  Use timeless commit messages without trailers.

Keep external end-user product names, adopter identities and competitive comparisons in research repositories.
Use neutral requirements and research links here. Preserve exact dependency, API, tool and license identifiers.
