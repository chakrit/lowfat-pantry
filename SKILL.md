---
name: lowfat-pantry
description: >-
  Set up and sync the lowfat command-output compactor and its plugin pantry for
  a project. Use when the user wants to install/configure lowfat, enable token
  savings on shell command output, add or refresh pantry filter plugins, or wire
  the agent's transparent command-rewrite hook. Triggers: "set up lowfat", "/lowfat",
  "sync the pantry", "compact my command output", "reduce token usage from bash".
---

# lowfat — setup & pantry sync

`lowfat` is a token-aware command-output filter (successor to RTK): it wraps a command,
runs the real binary, and pipes the output through a `.lf` filter at three intensities
(`ultra`/`full`/`lite`). This repo is the **pantry** — community `.lf` plugins under
`plugins/<category>/<name>/`, where `<category>` is the command (e.g. `gh`) and `<name>` is
`<command>-compact` (e.g. `gh-compact`), matching lowfat's bundled convention. No
grouping/tier dir. This skill installs lowfat, seeds a project `.lowfat`, and **syncs**
selected pantry plugins into the user's lowfat home.

Sync is carried as agent steps, not a bundled script. Spell the filesystem mechanics
exactly; improvise only the judgment (which plugins fit the project, whether a changed
plugin is safe to re-link).

> **Safety boundary (hard):** NEVER install global tooling. NEVER run `lowfat plugin
> trust`. Both are user-run. The agent only proposes the exact commands and creates/removes
> symlinks under the resolved lowfat home with idempotent checks.

## 0. Resolve the pieces

- **Pantry source dir** = this skill's own `plugins/` directory. Resolve it from the skill's
  install location (any install method — ACE import, manual clone, skill manager). For ACE
  imports: `<school-clone>/skills/lowfat-pantry/plugins/`.
  - **Caveat — source inside an ACE-managed / gitignored tree** (e.g. `.claude/skills/`):
    the `<home>/plugins/*` symlinks point at uncommitted content, recreated only when `ace`
    re-syncs the skill. On a fresh machine the links dangle until `ace` runs; an `ace`
    re-sync that *deletes* the skill dir breaks every link. Flag this and prefer the most
    durable/portable clone as canonical.
- **lowfat home** (plugins + trust), highest precedence first:
  1. `$LOWFAT_HOME`
  2. `$XDG_CONFIG_HOME/lowfat` (if `XDG_CONFIG_HOME` is set)
  3. `~/.config/lowfat` (only if that dir already exists)
  4. `~/.lowfat` (fallback)

  Confirm with `lowfat info`, don't guess. Plugins at `<home>/plugins/`, trust at
  `<home>/trusted.toml`.

## 1. Detect state (run in parallel)

- `which lowfat` (+ `lowfat --version`) — binary present?
- `.lowfat` present at/above the project root? (`lowfat info` reports the active config)
- Integration hook wired? Check both scopes — user (Claude Code: a `PreToolUse` hook in
  `~/.claude/settings.json`) and project-local (`.claude/settings.local.json` at the repo
  root). Other agents: their equivalent pre-command hook config at either scope.
- Pantry sync status — diff the pantry source against `<home>/plugins/` (see step 4).

## 2. Install if absent — USER-RUN

If `lowfat` is not on PATH, STOP and give the user the exact command for their platform
(`cargo install lowfat`, or a brew/release install). Resume once they confirm it's present.

## 3. Seed `.lowfat`

If no `.lowfat` exists at the project root, copy `templates/lowfat` to `./.lowfat` and tune:

- **level** — default `full`; suggest `ultra` for very large repos / tight budgets.
- **filters/disable** — enable filters matching the detected toolchain. Signals:
  `Cargo.toml`→cargo, `package.json`→ the node tools present (tsc/eslint/prettier/jest/
  vitest/next), `go.mod`→go+golangci-lint, `*.csproj`→dotnet, `pyproject.toml`/
  `requirements.txt`→ pytest/ruff/mypy/black/pip, `*.tf`→terraform, `Chart.yaml`→helm.
  Never set both `filters` (whitelist) and `disable` (blacklist).

Never enable `redact-secrets` globally without first checking it won't corrupt this
project's structured output (JSON/env) — prefer per-pipeline opt-in.

## 4. Sync the pantry — the core step (idempotent)

### a. Scope
Ask **how much** pantry to install with `AskUserQuestion`: all · by tier · by category ·
hand-pick. Default the selection to plugins whose command matches the detected toolchain.

### b. Reconcile (three-way diff)
For each selected plugin, between the pantry source and `<home>/plugins/<cat>/<name>/`:
- **added** — in pantry, not in home → propose create.
- **removed** — in home, not in pantry → leave alone (it's the user's own), unless it's a
  stale symlink back into this pantry.
- **changed** — both exist, content differs. **Trust-drift guard:** lowfat trusts by plugin
  *name*, so it will not re-prompt when a trusted plugin's content changes. Surface every
  changed + already-trusted plugin here with `AskUserQuestion` before re-linking.

### c. Apply (filesystem mechanics — exact)
For each approved plugin, idempotently:
- Ensure `<home>/plugins/<cat>/` exists.
- Target = `<home>/plugins/<cat>/<name>`. If already a symlink to the pantry source, skip.
  If it points at a *different* clone of this same pantry (dev clone + ACE/school clone)
  with byte-identical content, also a no-op — do NOT flag it "changed" in 4b (that fires the
  trust-drift guard spuriously). Re-point only if the user wants one clone canonical (favor
  the in-repo/committed one). If it's a real file/dir (not ours), do NOT clobber — report a
  conflict and ask. Else create the symlink `<target> -> <pantry>/<cat>/<name>`.
- For approved removals, `rm` the symlink only (never a real dir).

### d. Trust — USER-RUN
Trust gates only the builtin-override case: an untrusted external plugin applies freely when
no bundled plugin shadows its command (`info` shows it active and the hook rewrites through
it regardless of `trusted.toml`). Print `lowfat plugin trust <name>` only for plugins that
override a builtin **or** that the user wants to take precedence; for the rest, note they're
already active untrusted. NEVER self-trust, even first-party content.

## 5. Wire transparent rewrite — opt-in, default OFF

Offer (don't force) to register lowfat's command-rewrite hook. Get the exact entry from
`lowfat hook` / `lowfat shell-init`, then pick a **scope** with the user:

- **User scope** — compaction machine-wide, every project (Claude Code:
  `~/.claude/settings.json`).
- **Project-local scope** — this-repo-only, not committed/shared (Claude Code:
  `.claude/settings.local.json`, gitignored). Default here when unsure — narrower,
  reversible.

Write the entry through whatever the host agent provides for safe settings edits so existing
hooks aren't clobbered — Claude Code: the `update-config` skill (it owns the `settings.json`
merge); other agents edit their config file directly. Name the target file explicitly so the
chosen scope is the one edited. Sequence LAST, after coverage exists.

> **⚠️ Permission-surface warning (tell the user before wiring):** `lowfat hook` returns
> `permissionDecision: "allow"` alongside the rewritten command — so every command lowfat
> has a filter for (git, gh, curl, docker, …) is auto-approved and skips the agent's
> permission prompt. Harmless for `dontAsk`/YOLO users; for a user on default (ask) mode it
> silently widens the permission surface — `git push`, `curl` POSTs, `docker` runs get
> auto-approved purely because a compaction filter exists. Get a deliberate opt-in. (Upstream
> fix tracked: the hook should emit `updatedInput` *without* `permissionDecision` so the
> normal prompt runs on the rewritten command — `zdk/lowfat` hook.rs:31-42.)

> **Note:** if the agent's settings file is a stow/dotfiles symlink, the Edit tool may refuse
> to write through it — edit the real target path instead.

## 6. Report

Terse status: lowfat active (version), `.lowfat` level, N pantry plugins synced (and which
need trusting), hook wired or not. Mention `/lowfat-pantry` re-runs the sync.

## Authoring a pantry plugin — fast path

When the user wants a *new* filter, you don't need to read the full DSL spec or lowfat
source — both were already distilled. Follow this. (Deep cases — `split`, macros, awk
state machines — are in `docs/spec/lowfat-filter-dsl.md`; reach for it only when the
skeleton below isn't enough.)

### Plugin layout (exact)
A pantry plugin is a directory `plugins/<command>/<command>-compact/` holding:

    lowfat.toml    # [plugin] name=<command>-compact, version, description, category=<command>, commands=["<command>"]
    filter.lf      # the filter (below)
    tests.cue      # smoke golden spec: case matrix (source of truth)
    tests.lock.yml # committed golden output (smoke -c writes it)
    tests.yml      # legacy case list (pending retirement; still read by validate.py)
    samples/       # byte-faithful captured output, one file per case

Mirror `plugins/rg/rg-compact/` (simplest) or `plugins/gh/` (flag guards). Copy its
`lowfat.toml` and swap the command.

### `.lf` mental model (the 20% you need)
- A filter is a list of **rules**: `<sub>[, <level>]:` then an indented op body.
  First rule whose `(subcommand, level)` matches wins; **only that one runs**. Put the
  catch-all `*:` LAST. No subcommands (ls/grep/rg)? One `*:` rule.
- Env in `shell:`/`python:` ops: `$sub` `$level` (ultra/full/lite) `$exit` `$args`.
  Current text arrives on **stdin**.
- The everyday ops: `keep /re/` · `drop /re/` · `head N` · `tail N` · `head auto`
  (=15/30/60 by level) · `or "text"` (fallback when stream went blank) ·
  `or-shell: <cmd>` (run cmd on the RAW input when blank) · `raw` (pass unchanged) ·
  `shell: <cmd>`. Regex is the Rust `regex` crate: **no backreferences/lookaround**.
- Branch with `match level:` (arms `ultra:`/`full:`/`lite:`/`else:`) or
  `if exit failed: … else: …` (guards: `exit ok|failed`, `level <lvl>`, `--flag`).

### The decision tree (this is what actually makes a filter correct)
1. **Does the command emit machine-readable output?** (`--json`, `-o yaml`, env dumps,
   bare `prettier <file>`, `<tool> run`/`exec` printing program stdout.) If so, that path
   must pass **byte-exact** — branch it out and `raw` it. `if --json: raw` /
   `elif -o json: raw`. Never `keep`/`head` structured or passthrough output: it
   corrupts JSON or hides results.
2. **On failure, is the failure short or IS the failure the bloat?**
   - Short errors (grep/find/rg/ls): `if exit failed: raw` (carry the error verbatim),
     with `or "no matches"` for the empty-but-ok case.
   - Noisy builds (tsc/mvn/gradle/dotnet): a failed build is *exactly* when you want
     `[ERROR]` lines pulled from hundreds of progress lines — run your extraction on
     failure too, with `or-shell: tail 50` as the over-prune safety net.
3. **Otherwise, scale by level.** `match level:` with `head auto`, or explicit
   `ultra/full/lite` head/tail caps. Drop progress/spinner noise with `drop /re/` first.

### Skeleton to adapt (covers most tools)
```
*:
    if exit failed:
        raw
        or "<tool>: nothing to report"
    else:
        match level:
            ultra: head 20
            lite:  head 200
            else:  head 60
```
Add a structured-output guard arm above it when step 1 applies; split into per-subcommand
rules (`status:`, `diff:`, …) when subcommands need different treatment.

### Test (always, before declaring done)
Golden-file drift is the primary gate — `chakrit/smoke` (>= v0.3.0) over `tests.cue`:

    smoke -c plugins/<command>/<plugin>/tests.cue   # lock; REVIEW the diff
    scripts/test.sh                                  # whole suite, exit 0 = no drift

The lock diff is the correctness gate: a NEW/CHANGED golden is only trustworthy because a
human read it. Full harness: `docs/spec/smoke-golden-tests.md`. The quick reduction sanity
check still works too:

    ./scripts/validate.py plugins/<command>

Checks parse + per-level reduction against each `tests.yml` case, purely via `lowfat filter`.
Samples must be **byte-faithful** to real command output; never add inline `# synthetic`
annotations (they leak into filtered output and skew line counts) — mark synthesized samples
`synthetic: true`. Filters must be deterministic (smoke compares bytes).

### Prompting another model to build one
Hand it: this section + the target plugin dir + 2-3 real captured samples (`<command> … |
tee samples/<case>.txt`). Tell it to (1) classify each subcommand via the decision tree
above, (2) write `filter.lf` + `lowfat.toml` + `tests.cue` (cases; `tests.yml` is legacy),
(3) lock with `smoke -c …` and review the golden, plus `./scripts/validate.py` for reduction,
and iterate until green. The single highest-leverage instruction: **"structured and
passthrough output must survive byte-exact — branch and `raw` it, never filter it."** That
one rule prevents the most damaging class of bug (silently corrupted JSON / hidden results).

## Reference
- `docs/spec/lowfat-filter-dsl.md` — authoring `.lf` filters (for adding/editing plugins).
  For the engine and `.lf` language upstream, see lowfat's own docs:
  [`zdk/lowfat`](https://github.com/zdk/lowfat) README + `docs/PLUGINS.md` / `docs/CONFIG.md`.
- `docs/notes/lowfat-internals.md` — how lowfat resolves home/trust/levels/pipeline.
- `docs/spec/smoke-golden-tests.md` — the smoke golden-test harness (`tests.cue`, locks,
  `measure.py`).
- `plugins/README.md` — pantry layout and conventions; `plugins/CATALOG.md` — per-plugin
  inventory + gotchas.
- `scripts/test.sh` — run the whole smoke golden suite. `scripts/gen-smoke-spec.py` —
  one-time `tests.yml`→`tests.cue` migration. `scripts/validate.py` — reduction sanity
  check (run as an executable).
