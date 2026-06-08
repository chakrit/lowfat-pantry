# lowfat-pantry — Distribution Design

Status: **decided** — this repo becomes a `lowfat` skill repo imported via `school.toml`;
plugins ride the skill-import rail and the **agent** symlinks them into the lowfat home under
SKILL.md instructions (no script). See `../decisions/2026-06-08-pantry-distribution.md` for
the ruling and `lowfat-skill.md` for the skill design. The Option A/B/C analysis below is the
reasoning that led there; B (symlink-into-home) is the realized mechanism, with the skill
repo as its carrier. Goal: a new machine/project gets the full pantry with zero per-project
reconfiguration.

## The governing constraint

lowfat resolves a **single** plugin/config home, override semantics, no additive path
(verified against the `v0.6.8` binary — env vars are `LOWFAT_HOME`, `XDG_CONFIG_HOME`,
`XDG_DATA_HOME`, `LOWFAT_DATA`, `LOWFAT_DISABLE`, `LOWFAT_LEVEL`; there is no
`LOWFAT_PLUGIN_PATH`). Resolution order:

    $LOWFAT_HOME  →  $XDG_CONFIG_HOME/lowfat  →  ~/.config/lowfat

External plugins live under `<home>/plugins/<category>/<plugin>/`. Trust state
(`trusted.toml`) lives in the same home.

Consequence: you cannot *add* a plugin directory to a search path. You either take over the
whole home (`LOWFAT_HOME`) or you populate the existing home.

## The alignment that makes this easy

| Layer            | Scope                  | Already distributed how                     |
| ---------------- | ---------------------- | ------------------------------------------- |
| lowfat plugins   | per-machine/user       | (nothing yet — this is the gap)             |
| `.lowfat` config | per-project            | committed in each repo (done for this repo) |
| ACE school clone | per-machine, all repos | single git clone, ACE-managed               |
| ACE skills       | per-project view       | **symlink** from `.claude/skills/` → clone  |

The school clone is already the per-machine, shared-across-projects artifact. Plugins are
per-machine. They belong on the same rail.

## Options (analysis)

The reasoning snapshot that led to the decision. The *realized* design — skill repo, agent
sync, plugins at `school/skills/lowfat/plugins/` — lives in the decision entry and
`lowfat-skill.md`. Below, the `<school-clone>/pantry` and `pantry install` references are the
original framing, since superseded.

### A — `LOWFAT_HOME` → school clone (ACE sets the env)

ACE exports `LOWFAT_HOME=<school-clone>/pantry`. Every project inherits all pantry plugins,
fully automatic, no install step.

- **+** Zero setup; trust state travels with the pantry (reproducible).
- **−** Takes over the *entire* home. A user's personal/non-school plugins must live inside
  the school tree or be abandoned. Hostile to anyone with their own lowfat setup.

### B — Symlink pantry into the real home (mirror the ACE skills model) — recommended

Keep the home personal (`~/.config/lowfat`). Symlink each pantry plugin from the school
clone into `~/.config/lowfat/plugins/`. This is exactly what ACE already does for skills,
one layer down.

- **+** Personal plugins coexist as real dirs alongside symlinked pantry ones. Trust file
  stays personal. Edits to a pantry plugin go to the school clone (same property as skills).
  Same mental model the user already runs for skills.
- **−** Needs a sync step to create/refresh symlinks. ACE doesn't know about plugins yet, so
  either a small `pantry install` script owns it now, or ACE grows a plugin-symlink feature
  later (upstream ACE ask).

### C — Standalone installer, school-independent

`chakrit/lowfat-pantry` repo + `make install` populating `~/.config/lowfat/plugins/`.

- **+** Portable beyond the school; usable by non-ACE users.
- **−** Loses the "school clone = everything" property; another thing to keep in sync.

## Outcome

**Option B's mechanism (symlink-into-home) was adopted — but carried by a standalone Claude
Code `lowfat` skill repo, usable by any Claude Code user, not just ACE.** ACE users receive it
via the skill-import rail (plugins materialize at `school/skills/lowfat/plugins/`); non-ACE
users install the skill directly. Either way the agent performs the symlink sync under
SKILL.md steps, resolving the skill's own install dir as the source — so Option C's
standalone reach is folded in without a separate installer. Full realized design:
`../decisions/2026-06-08-pantry-distribution.md` and `lowfat-skill.md`.

## Open upstream ask (zdk/lowfat)

An additive `LOWFAT_PLUGIN_PATH` (colon-separated extra plugin search dirs, layered over the
personal home) would make Option A safe and collapse B's symlink step entirely — point it at
`<school-clone>/pantry/plugins` and done, with the personal home untouched. Worth filing;
until then, B is the clean path.

## Trust implication (carry into design either way)

lowfat trusts plugins by **name**, not content hash. A distributed pantry that ships
executable `.lf`/shell/Python must treat `trusted.toml` as security-relevant: trusting a
pantry plugin once trusts all future mutations of it. Pin pantry plugin versions and review
trust grants as part of the sync's reconcile step, not silently.
