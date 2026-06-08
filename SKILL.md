---
name: lowfat
description: >-
  Set up and sync the lowfat command-output compactor and its plugin pantry for
  a project. Use when the user wants to install/configure lowfat, enable token
  savings on shell command output, add or refresh pantry filter plugins, or wire
  the transparent Claude Code rewrite hook. Triggers: "set up lowfat", "/lowfat",
  "sync the pantry", "compact my command output", "reduce token usage from bash".
---

# lowfat — setup & pantry sync

`lowfat` is a token-aware command-output filter (the successor to RTK). It wraps a
command, runs the real binary, and pipes the output through a `.lf` filter that keeps the
signal and drops the bloat, at three intensities (`ultra`/`full`/`lite`). This repo is the
**pantry**: a set of community `.lf` plugins under `plugins/<category>/<name>/`. This skill
gets lowfat installed, seeds a project `.lowfat` config, and **syncs** selected pantry
plugins into the user's lowfat home.

This skill carries the sync logic as **agent steps**, not a bundled script — scope and
reconcile are judgment calls (which plugins fit this project, whether a changed plugin is
safe to re-trust) that benefit from context a script can't see. Spell the filesystem
mechanics exactly; improvise only the judgment.

> **Safety boundary (hard):** the agent NEVER installs global tooling and NEVER runs
> `lowfat plugin trust`. Those are user-run. The agent only proposes the exact commands and
> creates/removes symlinks under the resolved lowfat home with explicit, idempotent checks.

## 0. Resolve the pieces

- **Pantry source dir** = this skill's own `plugins/` directory. Resolve it from the
  skill's install location (works for any install method — ACE import, manual clone, skill
  manager). For ACE imports this is `<school-clone>/skills/lowfat/plugins/`.
- **lowfat home** (where plugins + trust live), highest precedence first:
  1. `$LOWFAT_HOME`
  2. `$XDG_CONFIG_HOME/lowfat` (if `XDG_CONFIG_HOME` is set)
  3. `~/.config/lowfat` (only if that dir already exists)
  4. `~/.lowfat` (fallback)

  Confirm with `lowfat info` rather than guessing. Plugins live at `<home>/plugins/`,
  trust state at `<home>/trusted.toml`.

## 1. Detect state (run in parallel)

- `which lowfat` (+ `lowfat --version`) — is the binary present?
- `.lowfat` present at/above the project root? (`lowfat info` reports the active config)
- Integration hook wired? Check user-scope `~/.claude/settings.json` for a lowfat
  `PreToolUse` hook entry.
- Pantry sync status — diff the pantry source against `<home>/plugins/` (see step 4).

## 2. Install if absent — USER-RUN

If `lowfat` is not on PATH, STOP and give the user the exact command for their platform
(`cargo install lowfat`, or a brew/release install). The agent never installs global
tooling. Resume once the user confirms it's present. *(RTK safety principle, kept.)*

## 3. Seed `.lowfat`

If no `.lowfat` exists at the project root, copy `templates/lowfat` to `./.lowfat` and tune:

- **level** — default `full`; suggest `ultra` for very large repos / tight budgets.
- **filters/disable** — enable filters matching the detected toolchain. Signals:
  `Cargo.toml`→cargo, `package.json`→ the node tools present (tsc/eslint/prettier/jest/
  vitest/next), `go.mod`→go+golangci-lint, `*.csproj`→dotnet, `pyproject.toml`/
  `requirements.txt`→ pytest/ruff/mypy/black/pip, `*.tf`→terraform, `Chart.yaml`→helm.
  Never set both `filters` (whitelist) and `disable` (blacklist).

Never enable `redact-secrets` globally without checking it won't corrupt this project's
structured output (JSON/env); prefer per-pipeline opt-in.

## 4. Sync the pantry — the core step (agent-performed, idempotent)

### a. Scope
Ask the user **how much** pantry to install with `AskUserQuestion`: all · by tier · by
category · hand-pick. Default the selection to plugins whose command matches the detected
toolchain (from step 3).

### b. Reconcile (three-way diff)
For each selected plugin compute, between the pantry source and `<home>/plugins/<cat>/<name>/`:
- **added** — in pantry, not in home → propose create.
- **removed** — in home, not in pantry → propose nothing (leave the user's own plugins
  alone) unless it's a stale symlink back into this pantry.
- **changed** — both exist but content differs. This is the **trust drift guard**: lowfat
  trusts by plugin *name*, so it will NOT re-prompt when a trusted plugin's content
  changes. Surface every changed+already-trusted plugin here explicitly with
  `AskUserQuestion` before re-linking.

### c. Apply (filesystem mechanics — exact)
For each approved plugin, idempotently:
- Ensure `<home>/plugins/<cat>/` exists.
- Target = `<home>/plugins/<cat>/<name>`. If it's already a symlink to the pantry source,
  skip (no-op). If it's a **real file/dir** (not ours), do NOT clobber — report a conflict
  and ask. Otherwise create the symlink `<target> -> <pantry>/<cat>/<name>`.
- For removals the user approved, only `rm` the symlink (never a real dir).

### d. Trust — USER-RUN
For every new or changed plugin, print the exact `lowfat plugin trust <name>` commands and
ask the user to run them. The agent NEVER self-trusts, even for first-party pantry content —
the reconcile in (b) is what keeps this safe against silent drift.

## 5. Wire transparent rewrite — opt-in, default OFF

Offer (don't force) to register lowfat's `PreToolUse` hook at user scope
(`~/.claude/settings.json`) so command output is compacted machine-wide without manual
prefixing. Use `lowfat hook` / `lowfat shell-init` for the exact entry, and the
`update-config` skill to write it. Sequence this LAST, after coverage exists.

## 6. Report

Terse status: lowfat active (version), `.lowfat` level, N pantry plugins synced (and which
need trusting), hook wired or not. Mention `/lowfat` re-runs the sync.

## Reference
- `docs/spec/lowfat-filter-dsl.md` — authoring `.lf` filters (for adding/editing plugins).
- `docs/notes/lowfat-internals.md` — how lowfat resolves home/trust/levels/pipeline.
- `plugins/README.md` — pantry layout and conventions.
- `scripts/validate.sh` — validate a filter purely via `lowfat filter` (no install/trust).
