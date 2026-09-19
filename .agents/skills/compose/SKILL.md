---
name: compose
description: Invoke only while consuming Compose's public scene-composition and ownership API in a Luau application. Do not invoke it to change Compose itself, or for game logic, scheduling, networking, physics, persistence, or asset loading.
---

# Compose consumer

This skill helps a Luau application consume Compose's public scene-composition and ownership API.

1. Find the pinned public package and reuse the application's runtime and nearby component. For a first component, follow [the bootstrap route](references/api.md) to create a runtime. Resolve a missing pin through the application's dependency procedure; never substitute internal imports.
2. Create composition with `runtime.create`. Keep instance state inside the component, return composition, and use stable keys for structural changes.
3. Use `borrow` for nodes Compose must not destroy. Use `adopt` for a whole node it must destroy. Bind external handles to an owner. Stop with `HOLD: ownership or lifetime undecided` when you cannot decide ownership.
4. Run `lute run tools/compose-check.luau --root <source>` when pinned tools exist. Exercise the changed behavior and ownership with focused consumer checks. Run its full gate at the frozen integration boundary. Record the dependency pin, candidate, check result, and evidence path.

The skill is finished when every created node has a decided owner and the application's own gate
passes at integration, or when an unresolved dependency or ownership boundary is reported.

Read one reference for the contract you need:

- [Public API and first component](references/api.md)
- [Ownership and reactive structure](references/ownership.md)
- [Roblox, profiling, or authoring](references/consumer-guides.md)
