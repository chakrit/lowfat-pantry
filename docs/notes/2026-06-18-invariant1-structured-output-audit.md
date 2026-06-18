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
| pip            | `--format json` @ultra | `keep`+`or` → replaced with `pip: ok`         | **FIXED** (this session, real golden) |
| npm            | `--json`            | small survives via `or-shell: tail`; large truncates | **FIXED** (this session, real golden) |
| terraform      | `-json`             | `compact-plan` matches nothing → **empty output** | **FIXED** (real golden) |
| helm           | `-o json` / `-o yaml` | `helm-table` awk collapses whitespace (byte-mangle) | **FIXED** (real golden) |
| golangci-lint  | `--output.json.path` (v2) | latent: routed through keep/head, survives by or-shell fallback (see below) | **FIXED** (real golden) |
| pulumi         | `--json`            | `*`→`head auto` / up-rules tail-cap → truncates large | **FIXED** (real golden) |
| dotnet         | `list ... --format json` | `*`→`head auto` truncates large list JSON     | **FIXED** (real golden) |

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

## What was fixed unattended, and what wasn't

Fixed this session (each zero-drift — no existing sample uses the guarded flag,
so all locks stay UNCHANGED — and verified):
- **kubectl** `-o json`/`-o yaml` (most severe + most-used; guard verified by
  synthetic repro). Still wants a real `kubectl get -o json|yaml` golden captured
  against a cluster — the fix shipped without one.
- **pip** `--format json` and **npm** `--json` — captured **real goldens** using
  the already-present `python:3.12-slim` / `node:22` images (no new pulls), so
  the raw path is locked and a future narrowing of the guard surfaces as drift.

**The five open plugins were all fixed attended (2026-06-18, AFK), each with a
real golden** — no guard shipped without a test:

- **terraform** `-json` — `hashicorp/terraform`, provider-free outputs config:
  `plan -json` (ndjson) + `output -json`. Guarded plan/apply/init/*.
- **helm** `-o json`/`-o yaml` (+ `--output` long form) — `alpine/helm` via
  `install --dry-run=client` (no cluster), minimal chart. Guarded
  install|upgrade|status, list, *. The list rule's guard is mechanical (its
  `-o json` needs a live cluster) — zero-drift, same posture as kubectl.
- **dotnet** `list --format json` — `mcr.microsoft.com/dotnet/sdk:8.0`, console
  project + NuGet packages. Guarded the `*` arm.
- **golangci-lint** — the original premise (line-based JSON truncation) was a v1
  mental model. v2.12 emits **single-line** compact JSON via
  `--output.json.path`; line caps never truncate it and at ultra the or-shell
  fallback restores it, so there's no *active* corruption. But the filter still
  routed structured output *through* keep/head — surviving only by that
  accidental fallback, which invariant 1 forbids ("must pass raw, never
  keep/head"). Guarded `--output.json.path` (v2) + legacy `--out-format` (v1) to
  the raw path **by design**. Real golden from `golangci-lint:latest` (v2.12.2).
  Residual machine formats (`--output.{sarif,checkstyle,code-climate,junit-xml,
  html,teamcity}.path`) noted in the filter header — raw too, when demanded.
- **pulumi** `--json` — `pulumi/pulumi-base`, local backend + yaml-runtime
  program (no cloud creds): `preview --json` (60-line step stream) +
  `stack output --json`. Guarded both up|preview|destroy|refresh rules and *.

All 57 plugins' smoke goldens stay UNCHANGED (`scripts/test.sh` green); every new
case locks the raw path, so a future narrowing of any guard surfaces as drift.

## Round 2 (2026-06-18, AFK) — the audit was NOT exhaustive

Round 1 was triggered mid-work and only covered cloud/infra/CI tools. A full
sweep of all 57 filters found that an **entire category was never checked** —
build tools, package managers, and search tools — and several corrupt structured
output **severely** (the data is replaced by an "ok" verdict, not just
truncated). Empirically reproduced (synthetic structured input through `lowfat
filter`):

| plugin | flag | effect | status |
| ------ | ---- | ------ | ------ |
| go | `-json` (`go test -json`, `go list -json`, `go mod … -json`) | test@ultra exit0 → keep-miss → `or "go test: ok"` (**JSON destroyed**); list→`*` head; mod→head — truncate | open |
| cargo | `--message-format json` | build@ultra → keep-miss → `or "cargo: ok"` (**JSON destroyed**) | open |
| ruff | `--output-format json` / `--format json` | clean run (`[]`, exit 0) → `or "ruff: clean"` (**`[]` destroyed**); issues (exit≠0) survive via the raw-fallback END arm | open |
| rg | `--json` | exit 0 → `head N` truncates the ndjson match stream | open |
| pnpm | `--json` (`ls`/`audit`/`outdated --json`) | `*` → `head auto` truncates | open |
| bun | `--json` (`bun pm … --json`) | install/pm@ultra keep-miss → `or "bun: ok"`; `*` head | open |
| deno | `--json` (`deno info --json`, `deno lint --json`) | info→`*` head; lint→check/lint head — truncate | open |
| docker-compose | `--format json` (`ps`/`config --format json`) | ps→`compact-ps` awk reshape; config→`*` drop-blank+head — corrupt | open |
| playwright | `--reporter=json` / `--reporter json` | test rule keyword-filter/tail → corrupt JSON | open (see design note) |
| uv | `--format json` (`uv pip list`), inherited ruff `--output-format json` | native keep-miss → `or "uv pip: ok"`; ruff branch inherits the ruff bug via the drift-copy | open (see design note) |

**Doc-vs-filter discrepancy found:** Round 1 listed cargo as *already-guarded*
(`--message-format`, "per CATALOG.md"). False — CATALOG never said that and the
filter has no such guard. cargo was never guarded; corrected below.

**Already-correct (verified this round):** curl raws on the body path? No — see
design note. The Round-1 already-guarded set (gh/glab, aws/az, eslint/prettier/
tsc, jq/json, journalctl, gcloud) re-confirmed.

### Fix posture — mechanical vs design-call

Mechanical (direct terraform `-json` / rspec `--format` precedent — guard the
flag → raw, capture a real golden): **go, cargo, ruff, rg, pnpm, bun, deno,
docker-compose**.

Design-calls (logged for chakrit, NOT fixed unilaterally):
- **curl** — there is **no flag to key on**. The body is whatever the server
  returns (JSON/HTML/binary/text), and the filter deliberately caps it
  ("passthrough body, cap only"). Guarding would mean *sniffing* the body
  (starts with `{`/`[`) and raw-ing it — a real design decision, not a
  mechanical guard. A `curl -s api | jq` of a multi-line JSON body IS truncated
  today; whether that's a bug or accepted passthrough-cap behavior is chakrit's
  call.
- **playwright** — `--reporter=json`/`junit` are flag-guardable, but the reporter
  is just as often set in `playwright.config.ts`, which the filter can't see.
  Guarding the flag is correct-but-partial; worth a note in the header.
- **uv** — the dispatcher's ruff branch is a deliberate drift-copy of
  ruff-compact, so the ruff fix must be **mirrored** here; plus `uv pip list
  --format json` hits the native arm. Mechanical but couples to the ruff fix.
