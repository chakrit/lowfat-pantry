# lowfat-pantry

This repo is **`chakrit/lowfat-pantry`** — a standalone Claude Code `/lowfat-pantry` skill plus a
pantry of lowfat plugins/filters for compacting command-output tokens.
`SKILL.md` (the `/lowfat-pantry` entrypoint) and **64 community plugins** under `plugins/` are
built.

## Source of truth

- `SKILL.md` + `docs/spec/lowfat-skill.md` — skill design
- `docs/vendor/lowfat-filter-dsl.md` — `.lf` authoring spec; read before editing any filter
- `docs/spec/output-philosophy.md` — keep-vs-cut philosophy; the *why* behind filter design
- `docs/vendor/lowfat-internals.md` — how lowfat works
- `docs/decisions/` — rulings
- `docs/spec/pantry-plugin-backlog.md` — what's built + what's left

Test filters with `scripts/test.sh` (smoke golden suite) or `scripts/smoke.sh -c
plugins/<cmd>/<plugin>/tests.cue` for one plugin; see `docs/guides/smoke-golden-tests.md`.
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
