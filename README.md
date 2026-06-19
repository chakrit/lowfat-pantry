# lowfat-pantry

A standalone **`/lowfat-pantry` agent skill** plus a **pantry of [lowfat](https://github.com/zdk/lowfat)
filter plugins** — the token-aware command-output compactor that replaces RTK.

lowfat wraps a shell command, runs the real binary, and pipes its output through a `.lf`
filter that **keeps the signal and drops the bloat** at three intensities — `ultra` (~10
lines) · `full` (~30) · `lite` (~60). This repo ships the skill that installs/syncs it and
the community plugins that teach it how to compact each tool.

> ### 🥡 The easy way: install lowfat *as a skill*
>
> **This whole repo is an agent skill.** You don't set lowfat up by hand — you hand the
> repo to your coding agent and let it do the work. Install it once (see
> [Install ↓](#install)), then run **`/lowfat-pantry`** inside any project. The agent
> checks for lowfat (handing you the one install command to run if it's missing — the
> binary install is yours, never the agent's), seeds a `.lowfat` config tuned to your
> toolchain, picks the filters that match your stack, and *offers* to wire the
> command-rewrite hook (opt-in, off by default). Re-run it anytime to re-sync.
>
> Building your own filter? The skill carries a [fast-path authoring
> guide](SKILL.md#authoring-a-pantry-plugin--fast-path) so your agent can write a correct
> plugin without reading the full DSL spec.

## What's here

    SKILL.md                     the /lowfat-pantry skill (setup + pantry sync as agent steps)
    plugins/<category>/<name>/   a pantry plugin: lowfat.toml · filter.lf · samples/ · tests.cue · tests.lock.yml
    templates/lowfat             seed project config (copied to .lowfat)
    scripts/test.sh              run the smoke golden-test suite over every plugin
    docs/                        design + reference (see below)

## Plugins

**64 community filters** beyond lowfat's six bundled ones (git, docker, grep, find, ls,
tree) — the full audited list with per-plugin notes and gotchas lives in
**[`plugins/CATALOG.md`](plugins/CATALOG.md)**. A taste:

- `cargo` `tsc` `pytest` `go` `mvn` `dotnet` — build/test: keep diagnostics + verdicts,
  drop progress chatter.
- `kubectl` `terraform` `pulumi` `ansible-playbook` — infra: verdict-anchored (recaps and
  summaries sit at the END of the stream).
- `gh` `aws` `az` `jq` — structured-output aware: `--json` and friends pass byte-exact.
- `env` — masks secret-looking values before anything else sees them.

Every plugin degrades across all three levels, preserves errors on non-zero exit,
and never corrupts machine-readable output (JSON/env/formatted code pass through byte-exact).

## Install

This repo is an agent skill (Claude Code, or any skills-compatible agent). Install it
however you manage skills:

- **[ACE](https://ace-rs.dev/)** — import via `school.toml` `[[imports]]`; it materializes at `school/skills/lowfat-pantry/`.
- **skills.sh** — the regular skills installer also works: `npx skills add chakrit/lowfat-pantry`.
- **Manual** — clone it where your skill tooling looks, or point your agent at it.

Then run **`/lowfat-pantry`** in a project. The skill detects/installs lowfat (user-run), seeds a
`.lowfat` config tuned to your toolchain, and syncs the pantry plugins you choose into your
lowfat home (`<LOWFAT_HOME>/plugins/`). lowfat itself: `cargo install lowfat`.

## Authoring a plugin

Letting an agent do it? Point it at the [fast-path
guide](SKILL.md#authoring-a-pantry-plugin--fast-path) in the skill — enough to write a
correct filter without the full spec. Doing it by hand: read
`docs/spec/lowfat-filter-dsl.md` (the full `.lf` reference + cookbook), mirror an existing
plugin (`plugins/rg` is the simplest, `plugins/gh` shows flag guards), then:

    smoke -c plugins/<your-plugin>/tests.cue   # lock the golden, REVIEW the diff
    scripts/test.sh                            # whole suite, exit 0 = no drift

The golden lock is the correctness gate — a NEW/CHANGED golden is only trustworthy because a
human read the diff. Each case runs the pure `lowfat filter` runner (no install, no trust, no
global state) and locks the compacted output plus `measure.py` size metrics. Filters must be
deterministic; samples are byte-faithful to real command output. Full harness:
`docs/spec/smoke-golden-tests.md`.

## Docs

- `docs/spec/lowfat-filter-dsl.md` — `.lf` DSL authoring spec.
- `docs/notes/lowfat-internals.md` — how lowfat works (home/trust/levels/pipeline/CLI).
- `docs/spec/smoke-golden-tests.md` — the smoke golden-test harness.
- `docs/spec/lowfat-skill.md` — the skill's design arc.
- `docs/spec/pantry-plugin-backlog.md` — remaining plugin candidates.
- `docs/decisions/` — distribution + design rulings.

## Status

Early — plugins are `v0.1.0` and samples are largely synthetic. Every plugin has a
`chakrit/smoke` golden-file test (`tests.cue` + committed `tests.lock.yml`); `scripts/test.sh`
runs the 487-test suite. Real-sample backfill is ongoing (see the backlog).
