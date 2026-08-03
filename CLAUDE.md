# lowfat-pantry

This repo is **`chakrit/lowfat-pantry`** — a standalone Claude Code `/lowfat-pantry` skill plus a
pantry of lowfat plugins/filters for compacting command-output tokens.
`SKILL.md` (the `/lowfat-pantry` entrypoint) and **65 community plugins** under `plugins/` are
built.

## Source of truth

- `SKILL.md` + `docs/spec/lowfat-skill.md` — skill design
- `docs/vendor/lowfat-filter-dsl.md` — `.lf` authoring spec; read before editing any filter
- `docs/spec/output-philosophy.md` — keep-vs-cut philosophy; the *why* behind filter design
- `docs/vendor/lowfat-internals.md` — how lowfat works
- `docs/decisions/` — rulings
- `docs/guides/issue-triage.md` — turn a bug report into a bug *class*; fix it across every
  plugin at once
- `plugins/README.md` — pantry layout + the truncation conventions every filter must hold
- `docs/spec/pantry-plugin-backlog.md` — what's built + what's left

Test filters with `scripts/test.sh` — the smoke golden suite plus five gates goldens can't
provide (`lint`, `drift`, `overprune`, `passthrough`, `levels`; none re-lockable, all
skipped under `-c`) — or `scripts/smoke.sh plugins/<cmd>/<plugin>/tests.cue` for one
plugin. Bare is the check; **`-c` re-locks** — read the CHANGED diff before passing it.
See `docs/guides/smoke-golden-tests.md`. Filters are **POSIX sh only** — no
`python:`, no `awk`, ERE not BRE; `plugins/README.md` says why. Real failure output comes
from `capture/` — for every tool, including ones installed on this machine, so a sample's
provenance is a Dockerfile and a fixture rather than someone's laptop. Reach for it before
settling a keep-vs-cut question from a sample: a hand-written one cannot answer where a
tool puts its verdict, and will imply a wrong answer.
Session resume trail: `.ace/save.md` (+ `.ace/save.ledger.md`), gitignored.

## Durable artifacts

`docs/` — file by the routing gate in `docs/README.md`: a ruling → `decisions/`;
third-party lookup → `vendor/`; a how-to → `guides/`; our own design/surface → `spec/`;
unsettled exploration → `scratch/` (last resort, opened with a "not spec/decision
because ___" line). Nothing defaults to `scratch/`.

## Coding environment (PRODIGY9 Coding School)

This project's AI coding environment is managed by
[ACE](https://github.com/ace-rs/ace). Run `ace` to start a coding session. Run
`ace setup` if not yet configured.

Skills and conventions are provided by the **PRODIGY9 Coding School** school and are
symlinked into `.claude/skills/`. Skill edits go through symlinks into the school clone —
propose changes back to the school repo when ready. Run `ace config` or `ace paths` to
debug configuration issues.
