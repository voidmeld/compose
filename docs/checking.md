# Consumer source checks

Use `tools/compose-check.luau` for Compose API diagnostics:

```sh
lute run path/to/compose/tools/compose-check.luau --root roblox
```

Use `tools/check-compose-ownership.luau` for application ownership and naming rules.
Require this module from a Lute check in the consumer repository.
The module does not run a check when it is required.
It does not change source files or baseline files.

```luau
local Check = require "../path/to/compose/tools/check-compose-ownership"
local process = require "@std/process"

local result = Check.check {
    roots = { "roblox", "shared" },
    options = {
        naming = {
            hosts = { "Host", "constructors" },
            forbidName = true,
            namedMounts = true,
            rootLabel = true,
        },
        enabled = function(path: string, rule: string): boolean
            return not (path == "roblox/Runtime.luau" and rule == "runtime-create")
        end,
    },
    exemptions = {
        { path = "shared/External.luau", rule = "destroy", reason = "This module releases external resources" },
    },
}
for _, finding in result.findings do
    print(("%s:%d [%s] %s"):format(finding.path, finding.line, finding.rule, finding.message))
end
for _, note in result.notes do
    print(note)
end
if #result.findings > 0 then
    process.exit(1)
end
```

Keep source roots, entry files, exemptions and naming rules in the consumer repository.
Use the same paths in the configuration and source roots. Relative paths start at the
working directory. A leading `./` and a trailing slash on a root are removed.
Overlapping roots scan each file once. A root can also be one file.
A missing root or invalid Luau source raises an error. Do not suppress that error in a gate.

## Calls and results

- `Check.check(config) -> Result` reads `.lua` and `.luau` files under `config.roots`.
- `Check.evaluate(files, config) -> Result` checks a map from path to source text.
  Use this call when a consumer already has a source manifest.
- `Check.scan(path, source, options) -> { Finding }` checks one source without exemptions or baselines.

A `Result` has `findings` and `notes`. Each finding has `path`, `line`, `rule`,
`message` and `snippet`. Lines start at 1. Findings are sorted by path, line and rule.
An empty `findings` array means that the selected rules passed.
Notes report unused exemptions and baseline reductions. They do not fail the check.

`config.include(path) -> boolean` selects source files. Use it to omit tests or generated
files when the application policy permits this. By default, the check includes all source
files, including tests. No dependency or application directory has an automatic exemption.

`config.options.enabled(path, rule) -> boolean` selects rules for each file.
Use it to permit runtime creation in one module or mounts in entry modules.

## Ownership rules

Ownership checks are on by default. Set `options.ownership = false` to use only naming
or custom rules.

| Rule | Source operation |
| --- | --- |
| `instance-new` | `Instance.new(...)` |
| `clone` | A `Clone` call |
| `destroy` | A `Destroy` call |
| `parent-assignment` | Assignment to `Parent`, including a string index |
| `from-existing` | `Instance.fromExisting` |
| `runtime-create` | A `createRuntime` call |
| `mount` | A `mount`, `mountFragment` or `app` call |

These are source checks, not a proof of runtime ownership. They do not resolve aliases
or dynamic member names. Member calls on other libraries can have the same names.
Use the rule selector or an exemption for those cases.
Comments and string text do not produce findings. Expressions inside interpolated strings
are checked.

## Naming rules

Set `options.naming` to a table with `hosts`, an array of constructor namespace names.
For example, `{ "Host", "UI", "constructors" }` selects those namespaces, including
`runtime.constructors`. All other naming fields are optional and off by default.

| Field | Rule |
| --- | --- |
| `forbidName = true` | Reject `Name` assignments and table fields. Use constructor labels. |
| `namedMounts = true` | Reject an anonymous function as the first argument of a `mount` call. |
| `namedRender = true` | Reject an anonymous function in a `render` field. |
| `namedReturns = true` | Reject returned anonymous functions. Select entry files with `enabled`. |
| `rootLabel = true` | Reject a returned host constructor called with only a props table. |
| `component = { typeName, field, definitionPath }` | Require a shared props type and a label from the first parameter. |

For example, `component = { typeName = "Identity.Named", field = "label",
definitionPath = "shared/Identity.luau" }` requires component props to include
`Identity.Named`. It accepts local type aliases and intersections. An optional shared type
does not meet the requirement. The component must use `Host.Frame(props.label) { ... }`.
Only `definitionPath` can declare a type alias with the final name from `typeName`.

The component check selects named functions whose first parameter is annotated, whose
body uses a configured host, and whose first parameter is called `props`, has `Props` in
its type text, has a table type, or includes the shared type. This is a source convention.
It does not resolve imported types or prove type equivalence.

## Additional application rules

`options.patterns` accepts `{ rule, pattern }` entries. Each Luau pattern match produces a
finding. The input has comments and string text replaced with spaces. Line offsets stay
unchanged. Use this for application calls that the built-in ownership rules do not cover.

`options.counts` accepts `{ path, rule, pattern, count }` entries. Each selected file must
have exactly `count` pattern matches. A missing file fails with `configuration`.
Use this for one runtime creation, one entry mount, or a required shared type definition.

`options.nestedCalls` accepts Luau patterns for complete call target text. For example,
`{ "^Scene%.add$", "^Scene%.addFragment$" }` rejects one selected call inside another
with `nested-mount`. This includes nested callbacks and calls on different lines.

## Exemptions and baselines

`config.exemptions` is an array of `{ path, reason, rule?, snippet? }` entries.
Each entry needs a selected source file and a nonempty reason.
Set `config.minimumReasonLength` to require more non-whitespace characters.
An entry without `rule` permits every rule in that file.
An entry with `snippet` permits only that exact source line, including whitespace.
A stale entry produces a note. A missing file or an invalid reason fails with `configuration`.

`config.baseline` is a map from path to a map from rule to allowed count:

```luau
baseline = {
    ["roblox/Legacy.luau"] = { ["name-field"] = 2 },
}
```

Only findings above an allowed count fail. A reduced count produces a note with the new
count. The check never raises or writes a baseline. Review baseline changes in the consumer.
