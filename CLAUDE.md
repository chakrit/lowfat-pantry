# PRODIGY9 Coding School

This project's AI coding environment is managed by
[ACE](https://github.com/ace-rs/ace). Run `ace` to start a coding session.
Run `ace setup` if not yet configured.

Skills and conventions are provided by the **PRODIGY9 Coding School** school and
are symlinked into `.claude/skills/`. Skill edits go through
symlinks into the school clone — propose changes back to the school repo
when ready. Run `ace config` or `ace paths` to debug configuration issues.

## What this repo is

This repo is becoming **`chakrit/lowfat-pantry`** — a standalone Claude Code `/lowfat` skill
plus a pantry of lowfat plugins/filters, replacing RTK as the command-output token compactor.
Source of truth: `docs/spec/lowfat-skill.md` (skill design),
`docs/decisions/` (distribution + design rulings), `docs/spec/pantry-plugin-backlog.md`
(plugin backlog). Session resume breadcrumb: `.tasks.md`.

## Durable artifacts

`docs/{notes,decisions,spec}/` — sorted by permanence (impermanent /
point-in-time / current). Default to `notes/`. See `docs/README.md`
and per-dir READMEs for picker details.
