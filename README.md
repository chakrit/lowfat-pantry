# lowfat-pantry

A standalone **`/lowfat` agent skill** plus a **pantry of [lowfat](https://github.com/zdk/lowfat)
filter plugins** — the token-aware command-output compactor that replaces RTK.

lowfat wraps a shell command, runs the real binary, and pipes its output through a `.lf`
filter that **keeps the signal and drops the bloat** at three intensities — `ultra` (~10
lines) · `full` (~30) · `lite` (~60). This repo ships the skill that installs/syncs it and
the community plugins that teach it how to compact each tool.

## What's here

    SKILL.md                     the /lowfat skill (setup + pantry sync as agent steps)
    plugins/<category>/<name>/   a pantry plugin: lowfat.toml · filter.lf · samples/ · tests.yml
    templates/lowfat             seed project config (copied to .lowfat)
    scripts/validate.sh          validate filters purely via `lowfat filter`
    docs/                        design + reference (see below)

## Plugins

**51 community filters** beyond lowfat's six bundled ones (git, docker, grep, find, ls,
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

- **ACE** — import via `school.toml` `[[imports]]`; it materializes at `school/skills/lowfat/`.
- **skills.sh** — the regular skills installer also works: `npx skills add chakrit/lowfat-pantry`.
- **Manual** — clone it where your skill tooling looks, or point your agent at it.

Then run **`/lowfat`** in a project. The skill detects/installs lowfat (user-run), seeds a
`.lowfat` config tuned to your toolchain, and syncs the pantry plugins you choose into your
lowfat home (`<LOWFAT_HOME>/plugins/`). lowfat itself: `cargo install lowfat`.

## Authoring a plugin

Read `docs/spec/lowfat-filter-dsl.md` (the full `.lf` reference + cookbook), mirror an
existing plugin (`plugins/rg` is the simplest, `plugins/gh` shows flag guards), then:

    scripts/validate.sh plugins/<your-plugin>

validates parse + per-level reduction via the pure `lowfat filter` runner (no install, no
trust, no global state). Samples are byte-faithful to real command output; mark synthesized
ones with `synthetic: true` in `tests.yml`.

## Docs

- `docs/spec/lowfat-filter-dsl.md` — `.lf` DSL authoring spec.
- `docs/notes/lowfat-internals.md` — how lowfat works (home/trust/levels/pipeline/CLI).
- `docs/spec/lowfat-skill.md` — the skill's design arc.
- `docs/spec/pantry-plugin-backlog.md` — remaining plugin candidates.
- `docs/decisions/` — distribution + design rulings.

## Status

Early — plugins are `v0.1.0`, samples are largely synthetic (validated via `lowfat filter`),
and the golden test harness (`chakrit/smoke`) wiring is pending. `tests.yml` is authored per
plugin in a provisional format ready for that harness.
