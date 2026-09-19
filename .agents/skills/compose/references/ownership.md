# Ownership and structure

This note governs a component that changes its structure or lifetime. Use `show`, `switch`, `keyed`,
or `OrderedCollection` for structural changes. Mount only finite roots, because components must not parent,
destroy, or retain nested mount disposers. Read the guide for the primitive you select:

- `docs/ownership.md`, `docs/ownership.md`, or `docs/reactive.md`
- `docs/api.md`, `docs/ownership.md`, `docs/api.md`, or `docs/ownership.md`
