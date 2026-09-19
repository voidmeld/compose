# Compose maintainer laws

Compose owns finite application scene trees through a host-neutral protocol. Keep that boundary
and fine-grained updates intact. Read [README.md](README.md), then [docs/index.md](docs/index.md).

- Only a host protocol creates, changes, parents or destroys nodes. Core has no engine or ambient clock.
- Owned resources dispose once; borrowed resources survive; failed builds unwind. Test those behaviors.
- Public APIs come from package entry points. Inspect actual production, tooling, generated and test
  consumers before cutting code. Missing demand is a reason to remove machinery; exports and tests
  alone are not a reason to preserve it. Document the current public contract.
- Keep one current contract and runnable falsifier. Do not infer speedup or consumer experience
  from a passing CPU gate.
- Maintain automation in Lute Luau. Exact dependencies live only in `dependencies.lock.luau`.
- No explanatory source comments; names, types and public contracts carry intent. Tool directives and
  required license notices are allowed.
- Keep the framework product-neutral: no adopter identity, private places, group ids or milestone names.
- Regenerate the test manifest after corpus changes with `lute run tools/check-test-manifest.luau --write`.
- Run focused checks while editing. Commit the candidate locally, then run `lute run tools/gate.luau`
  on the clean HEAD; its fresh-clone check must pass before integration. Do not mutate the candidate during proof.
- Set author and committer to `voidmeld <158495725+voidmeld@users.noreply.github.com>`; timeless messages, no trailers.
