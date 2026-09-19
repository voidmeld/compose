# Engine verification

`checks.luau` exercises native property refusal/unwind, class defaults, layout, animation,
whole-scene updates and disposal. These checks require an actual engine and are not run by the
CPU gate. Use the current authorization and surface owner for any Studio operation.

From a clean source checkout:

```bash
lute run tools/make-verification-plugin.luau --out build/ComposeVerify.rbxmx
```

The plugin bundles Compose, the checks and the exact source commit, tree and dirty state.
The command also writes `build/ComposeVerificationIdentity.luau` for the module-preserving route:

```bash
rojo serve verification/roblox.project.json
```

Run the checks in an unpublished scratch place. They remove their scratch tree without saving, publishing or uploading.
Keep every `COMPOSE-VERIFY|` line, artifact SHA-256, Studio version, platform, place and mode outside the active source tree.
A passing result requires:

- Matching clean source identity.
- A begin/end pair.
- Zero failed total.
- No FAIL or fatal line.

Missing or ambiguous output is not a pass.

A bundled plugin verifies only the engine behavior its checks cover.
Verify native codegen by observing module-preserving source in the engine profiler. A source directive or CPU timing cannot establish it. Native rendering, device input and application quality require consumer evidence.
