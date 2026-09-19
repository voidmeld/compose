# Engine verification

`checks.luau` exercises native property refusal/unwind, class defaults, layout, animation,
whole-scene updates and disposal. These checks require an actual engine and are not run by the
CPU gate. Use the current authorization and surface owner for any Studio operation.

From a clean source checkout:

```bash
lute run tools/make-verification-plugin.luau --out build/ComposeVerify.rbxmx
```

The plugin bundles Compose, the checks and exact commit/tree/dirty identity. The same command
writes `build/ComposeVerificationIdentity.luau` for the module-preserving route:

```bash
rojo serve verification/roblox.project.json
```

Run on an unpublished scratch place. The check owns and removes its scratch tree; it does not
save, publish or upload. Preserve every `COMPOSE-VERIFY|` line, artifact SHA-256, Studio version,
platform, place and mode outside the active source tree. Require matching clean source identity,
a begin/end pair, zero failed total and no FAIL/fatal line. Missing or ambiguous output is not a pass.

A bundled plugin proves only the covered engine behavior. Native codegen requires an observation
of module-preserving source in the engine profiler; neither a source directive nor CPU timing
establishes it. Native rendering, device input and application quality require consumer evidence.
