# Compose maintainer guide

Compose is a scene composition library for Luau. It owns finite scene trees through a host-neutral protocol.
First, run `git status --short` to inspect current work.
Read [CONTRIBUTING.md](CONTRIBUTING.md) for setup and checks.
Then use the [README task table](README.md#documentation) to select the contract for your task.
Read only the reference sections that the task needs.

This file owns the contribution rules. Each fact has one owning document.

## Rules

- Only the host protocol creates, changes, parents or destroys nodes. Core has no engine and no ambient clock. Preserve fine-grained updates.
- Dispose each owned resource once. Preserve borrowed resources. Unwind failed builds. Test those boundaries.
- Use public package entry points. Before you cut a surface, inspect its production, dynamic, generated, CLI and test consumers. Exports and tests alone do not justify unused machinery.
- Keep one current contract and one runnable check that can disprove it. Headless checks do not prove engine behavior or unmeasured speed improvements.
- Use existing tools. Add process only for a concrete consumer benefit.
- Write automation in Lute Luau. Put exact dependencies only in `dependencies.lock.luau`.
- Add no explanatory source comments. Keep tool directives and required license notices.
- Keep adopter identity, destinations, policy and milestones out of the framework. Keep comparisons with other products out of this repository. Keep exact dependency, API and license identifiers.

- Write every test and engine check as a Verify case. Write every benchmark as a Verify benchmark.
- Use the test harness and declare `local describe, it, expect = Test.describe, Test.it, Test.expect` once per specification. Only specifications about Verify's raw harness API are excluded from this style check.
- Every maintained Luau file requires `--!strict`, zero explicit `any` and zero type assertions (`::`), including concrete casts. The required gate rejects violations without a baseline or exemptions.
- Follow the [validation procedure](CONTRIBUTING.md#check-a-change). Do not change verified bytes after the gate. Reuse evidence while its inputs stay unchanged.

## Repository

Changes to this library use a pull request to `main` and the required `Gate` check. Do not push directly to `main` or bypass a failing check.

Preserve license notices and exact consumer behavior when you simplify.
