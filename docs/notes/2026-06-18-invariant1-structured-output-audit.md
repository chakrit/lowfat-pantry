# Invariant-1 (structured-output byte-exact) audit — 2026-06-18

Read-only audit of how pantry plugins handle machine-readable output
(`-o json`/`-o yaml`/`--json`/`-json`/`--format json`). Triggered while auditing
the Ruby/dotnet work this session; the rspec/rubocop format guard fix exposed the
question "which *other* plugins corrupt structured output?". Answer: several, and
on heavily-used tools.

Invariant 1 (`docs/spec/output-philosophy.md`): *a subset of JSON is corrupt JSON*.
Structured output must pass `raw`, never `keep`/`head`/`tail`/awk-reshape. It's
named there as "the highest-leverage rule; the most damaging bug class."

## Reference pattern (already correct)

`aws` and `az` do it right — copy these when fixing the rest:

- **aws** — `*: if exit failed: raw / elif --output table: <compact> / elif
  --output text: <compact> / else: raw`. Default (JSON) and any non-table/text
  output fall to `raw`. Header literally says "byte-preserve JSON/default output".
- **az** — default success output is JSON → `else: raw`; only `-o table`/`-o tsv`
  and `--help` are compacted.

Also already-guarded (per `plugins/CATALOG.md`): `gh`/`glab` (`--json`/`-F json`),
`cargo` (`--message-format`), `eslint`/`prettier`/`tsc` (`-f json`/`--format`).

## Confirmed violations (empirical repro, exit 0)

Each reproduced by piping a synthetic structured blob through `lowfat filter` at
the noted level. "Effect" is what the agent receives instead of the bytes.

| plugin         | flag                | effect                                          | status        |
| -------------- | ------------------- | ----------------------------------------------- | ------------- |
| kubectl        | `-o json` / `-o yaml` | `get`/`describe` awk shreds to ~3 lines         | **FIXED** (this session) |
| terraform      | `-json`             | `compact-plan` matches nothing → **empty output** | open          |
| pip            | `--format json` @ultra | `keep`+`or` → replaced with `pip: ok`         | open          |
| helm           | `-o json` / `-o yaml` | `helm-table` awk collapses whitespace (byte-mangle) | open          |
| golangci-lint  | `--out-format json` | `head 3` (clean) / `head N` truncates the JSON   | open          |
| npm            | `--json`            | small survives via `or-shell: tail`; large truncates | open          |
| pulumi         | `--json`            | `*`→`head auto` / up-rules tail-cap → truncates large | open          |
| dotnet         | `list ... --format json` | `*`→`head auto` truncates large list JSON     | open (pre-existing) |

mvn/gradlew have no common JSON stdout mode (build logs only) — not affected.

## Fix pattern

Add value-specific guards **before** the compaction, in every rule that
compacts (`.lf` has no top-level pre-filter, and macros can't wrap a cascade —
so the guard repeats per rule). Branch on the flag+value, not presence, so
`-o wide`/`--output table` still compact:

```
get:
    if exit failed:
        raw
    elif -o json:
        raw
    elif -o yaml:
        raw
    else:
        <existing compaction>
```

Per-plugin flag to guard: kubectl/helm `-o json`,`-o yaml` (+ `--output json/yaml`
residual); terraform `-json`; pip/golangci-lint `--format json`/`--out-format json`;
npm/pulumi `--json`; dotnet `--format json` in the `*` arm. Where a tool only ever
emits the compactable shape on the *default* (no-format) path, the cleaner form is
`if --format: raw / elif -f: raw / else: <compact>` (what rspec/rubocop now use).

Residual not covered by value guards: kubectl `-o jsonpath=`/`go-template=`/
`custom-columns=` (caller-formatted text — arbitrary, arguably should `raw` too).

## Why only kubectl was fixed unattended

kubectl is the most severe (shred) and most-used, the guard is trivial and
**zero-drift** (no existing sample uses `-o json`, so all locks stay UNCHANGED),
and it's verified by synthetic repro. The other six are each a *bespoke* guard in
a differently-shaped filter — too much unreviewed cross-cutting change to land
overnight — and none can be properly **goldened** without a real structured
sample, which needs live infra (a cluster for kubectl/helm, a tf project for
terraform, cloud creds for pulumi) or a toolchain capture (npm/pip/golangci-lint
via node/python/go images). The kubectl fix itself still wants a real
`kubectl get -o json|yaml` golden captured against a cluster.

**Recommended next (attended):** apply the fix pattern to the six open plugins as
one reviewed batch, capturing a real structured sample per plugin to lock the
raw-path golden (so a future edit narrowing the guard is caught as drift).
