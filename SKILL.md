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
- **shadows a bundled filter** — a disk plugin wins over lowfat's own of the same name, so
  installing one silently changes how an already-working command is compacted. `ls` is the
  only pantry plugin that does this (ruling `docs/decisions/2026-08-03-ls-override.md`);
  name the replacement when offering it, don't fold it into an "all" selection unremarked.
- **changed** — both exist, content differs. **Trust-drift guard:** lowfat trusts by plugin
  *name*, so it will not re-prompt when a trusted plugin's content changes. Surface every
  changed + already-trusted plugin here with `AskUserQuestion` before re-linking.

### c. Apply (filesystem mechanics — exact)
**First, always:** symlink `<home>/plugins/lib -> <pantry>/lib` (skip if already correct;
never clobber a real dir — report and ask). Filters `include ../../lib/truncation.lf`,
resolved two levels up from the plugin dir. A *symlinked* plugin resolves it either way —
`..` walks back out through the symlink into the pantry — but a plugin that was ever
copied instead has no pantry to walk back to, and a missing include is a hard parse error
that kills the whole filter (`lowfat: parsing …`, rc 1). The link makes the home tree
self-sufficient. It carries no `lowfat.toml`, so lowfat never treats it as a plugin.

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

> **⚠️ The rewrite is a string prefix, so it captures redirects and pipes (tell the user
> before wiring):** `rewrite_command` returns `format!("lowfat {command}")` with no shell
> parsing (`zdk/lowfat` rewrite.rs). A redirect therefore binds to *lowfat's* stdout, not
> the tool's — `pnpm test > /tmp/t.txt 2>&1` becomes `lowfat pnpm test > /tmp/t.txt 2>&1`
> and writes the **compacted** stream to the file, marker and all. Capture-then-read, the
> one workflow that exists to keep full output around for repeated reading, is exactly what
> it defeats; a trailing `| grep` is silently filtered the same way. Nothing downstream can
> recover the lost lines, and rerunning the command without the hook is the only way back.
> Treat this as permanent, not pending: only a rewrite-time parse could tell a redirect
> from a capture — stdout is a regular file either way, so there is nothing to detect at run
> time — and `shell-init`'s wrapper functions never see the redirect at all. Work with it
> instead: make the first word something no filter claims, and the command is left alone.
> `command pnpm test > /tmp/t.txt 2>&1` writes the full output, because the rewrite keys on
> `command`. (`LOWFAT_DISABLE` is not that lever: it is a comma-separated list of *command
> names*, read by lowfat at run time, and an inline `VAR=x` assignment only dodges the
> rewrite by the same first-word accident.)

> **Note:** if the agent's settings file is a stow/dotfiles symlink, the Edit tool may refuse
> to write through it — edit the real target path instead.

## 6. Report

Terse status: lowfat active (version), `.lowfat` level, N pantry plugins synced (and which
need trusting), hook wired or not. Mention `/lowfat-pantry` re-runs the sync.

When the hook was wired, close with the one thing that changes how commands get written
from now on: **a redirect captures lowfat's output, not the tool's.** `pnpm test >
/tmp/t.txt 2>&1` leaves a compacted file, so anything meant to hold full output takes a
first word no filter claims — `command pnpm test > /tmp/t.txt 2>&1`. It belongs in the
report because it is invisible otherwise: the capture succeeds, the file looks whole, and
only the `[lowfat]` marker inside it says the lines are gone.

## Authoring a pantry plugin — fast path

When the user wants a *new* filter, you don't need to read the full DSL spec or lowfat
source — both were already distilled. Follow this. (Deep cases — `split`, macros, multi-line
`shell:` blocks — are in `docs/vendor/lowfat-filter-dsl.md`; reach for it only when the
skeleton below isn't enough, and read its cookbook against the bans in step 4: the
examples there are upstream's, and upstream uses `awk`.) The *why* behind these rules —
the keep-vs-cut philosophy inherited from RTK and lowfat — is
`docs/spec/output-philosophy.md`; read it when a call isn't obvious from the tree below.

### Plugin layout (exact)
A pantry plugin is a directory `plugins/<command>/<command>-compact/` holding:

    lowfat.toml    # [plugin] name=<command>-compact, version, description, category=<command>, commands=["<command>"]
    filter.lf      # the filter (below)
    tests.cue      # smoke golden spec: case matrix (source of truth)
    tests.lock.yml # committed golden output (scripts/smoke.sh -c writes it)
    samples/       # byte-faithful captured output, one file per case

Shared macros live one level above the categories, in `plugins/lib/*.lf`, pulled in with
`include ../../lib/<file>.lf` — never copied into a filter.

Mirror `plugins/rg/rg-compact/` (simplest) or `plugins/gh/` (flag guards). Copy its
`lowfat.toml` and swap the command.

### `.lf` mental model (the 20% you need)
- A filter is a list of **rules**: `<sub>[, <level>]:` then an indented op body.
  First rule whose `(subcommand, level)` matches wins; **only that one runs**. Put the
  catch-all `*:` LAST. No subcommands (ls/grep/rg)? One `*:` rule.
- Env in `shell:` ops: `$sub` `$level` (ultra/full/lite) `$exit` `$args`.
  Current text arrives on **stdin**.
- The everyday ops: `keep /re/` · `drop /re/` · `head-auto-marked` (the library's marked
  stand-in for `head auto`'s 15/30/60 by level) · `head-marked N` · `tail-marked N` ·
  `or "text"` (fallback when stream went blank) ·
  `or-shell: <cmd>` (run cmd on the RAW input when blank) · `raw` (pass unchanged) ·
  `shell: <cmd>`. Regex is the Rust `regex` crate: **no backreferences/lookaround**.
  lowfat's own `head N` / `tail N` / `head auto` still exist, but no pantry filter uses one:
  they cut with no trace (step 4), and `scripts/lint.py` rejects them.
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
     failure too, with an `or-shell:` marked tail as the over-prune safety net (it caps the
     raw dump and prints the same dropped-count marker).
   - Caveat: exit code is a *signal*, not a failure proxy. `rg`/`diff`/`black` exit
     non-zero as information (no match / files differ / unformatted); `redis-cli`/`sqlite3`
     errors exit zero. Branch on output shape (error-line patterns), not `$exit` alone.
3. **Is it an inventory listing?** One load-bearing identifier per line, nothing redundant
   (`terraform state list`, `kubectl get`, `helm list`, `gh issue list`, `npm ls`). Then the
   whole value is completeness and nothing is safe to cut — give it its own rule returning
   `raw`, above the catch-all. There is no honest 30-line summary of a 200-item list.
4. **Otherwise, scale by level** — but never with a bare `head`/`tail`, in any rule, not
   just the catch-all. `head` cuts without a trace, so a truncated stream and a genuinely
   short one are byte-identical and the reader acts on a confident wrong answer. Use the
   `head-auto-marked` macro from `plugins/lib/truncation.lf` (below); it mirrors `head
   auto`'s limits and appends the dropped count. Never re-copy a library macro into a
   filter. Drop progress/spinner noise with `drop /re/` first.

### Skeleton to adapt (covers most tools)
```
# Truncation must be visible: bare `head`/`tail` cut without a trace, so a cut stream
# reads as a short one. The library's marked macros say what they dropped —
# head-auto-marked (mirrors `head auto`: ultra 15 / full 30 / lite 60),
# head-marked <n> / tail-marked <n> (explicit cap), cap <n>.
include ../../lib/truncation.lf

# Inventory: every line load-bearing, nothing redundant. Exempt from compaction.
list:
    raw

*:
    if exit failed:
        raw
        or "<tool>: nothing to report"
    else:
        head-auto-marked
```
Add a structured-output guard arm above it when step 1 applies; split into per-subcommand
rules (`status:`, `diff:`, …) when subcommands need different treatment. Use `shell:` for
extraction that ops can't express — POSIX sh, ERE only (`grep -E`/`sed -nE`; BSD sed
silently matches nothing for `\|`), **never `awk`, and never `python:`** — see
`plugins/README.md § Truncation conventions` for why both are banned.

### Test (always, before declaring done)
Golden-file drift is the gate — `chakrit/smoke` (>= v0.5.0) over `tests.cue`:

    scripts/smoke.sh -c plugins/<command>/<plugin>/tests.cue   # lock; REVIEW the diff
    scripts/test.sh                                            # whole suite, exit 0 = no drift

The lock diff is the correctness gate: a NEW/CHANGED golden is only trustworthy because a
human read it. Each case locks the compacted output plus `measure.py` size metrics, so an
over-prune or growth regression surfaces as drift. Full harness:
`docs/guides/smoke-golden-tests.md`.

Samples must be **byte-faithful** to real command output; never add inline `# synthetic`
annotations (they leak into filtered output and skew line counts). Filters must be
deterministic (smoke compares bytes). Failure output for a tool that isn't installed comes
from `capture/` — a stack Dockerfile plus a fixture directory, one command per sample — not
from a hand-written guess at what the tool prints (`capture/README.md`).

### Prompting another model to build one
Hand it: this section + the target plugin dir + 2-3 real captured samples (`<command> … |
tee samples/<case>.txt`). Tell it to (1) classify each subcommand via the decision tree
above, (2) write `filter.lf` + `lowfat.toml` + `tests.cue` (cases), (3) lock with
`scripts/smoke.sh -c …`, review the golden diff, and iterate until green. The two
highest-leverage instructions, which between them prevent the most damaging bug classes:

1. **"Structured and passthrough output must survive byte-exact — branch and `raw` it,
   never filter it."** Prevents silently corrupted JSON / hidden results.
2. **"Never cut without saying so, and never cut an inventory listing at all."** A cut list
   is byte-identical to a short one, so silent truncation yields a *confident wrong
   answer* — the class behind issue #1.

## Reference
- `docs/spec/output-philosophy.md` — keep-vs-cut philosophy (RTK + lowfat lineage, pantry
  invariants); the *why* behind the decision tree above.
- `docs/vendor/lowfat-filter-dsl.md` — authoring `.lf` filters (for adding/editing plugins).
  For the engine and `.lf` language upstream, see lowfat's own docs:
  [`zdk/lowfat`](https://github.com/zdk/lowfat) README + `docs/PLUGINS.md` / `docs/CONFIG.md`.
- `docs/vendor/lowfat-internals.md` — how lowfat resolves home/trust/levels/pipeline.
- `docs/guides/smoke-golden-tests.md` — the smoke golden-test harness (`tests.cue`, locks,
  `measure.py`).
- `docs/guides/issue-triage.md` — turning a bug report into a bug *class* and fixing it
  across every plugin at once.
- `plugins/README.md` — pantry layout and conventions; `plugins/CATALOG.md` — per-plugin
  inventory + gotchas.
- `scripts/test.sh` — run the whole smoke golden suite. `scripts/measure.py` — size-metric
  emitter locked alongside each golden.
