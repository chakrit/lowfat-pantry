# Pantry Distribution: a `lowfat` Skill Repo via ACE Imports

- **Date:** 2026-06-08
- **PR:** manual
- **Status:** accepted

## Decision

This repo becomes a **standalone Claude Code `lowfat` skill repo** (`chakrit/lowfat-pantry`),
usable by any Claude Code user independent of ACE. ACE users install it via `school.toml`
`[[imports]]` (one delivery channel, like `chakrit/kien-thai`); non-ACE users clone or install
it directly as a skill. It carries, in one tree:

- `SKILL.md` — the `/lowfat` setup/operation skill, carrying the sync as agent steps
- `plugins/<category>/<plugin>/` — the pantry (lowfat.toml, filter.lf, samples/, tests.yml)
- a `.lowfat` template — seed project settings

The sync (symlink the materialized `plugins/*` into `~/.config/lowfat/plugins/`, surface
`lowfat plugin trust`) is performed by the **agent under SKILL.md instructions**, not a
bundled script.

Distribution rides the **existing skill-import rail**. No bespoke `school/pantry/` directory;
no separate sync skill — both collapse into this repo.

## Rationale

- **Single override-only home.** lowfat resolves one plugin/config home, no additive
  `LOWFAT_PLUGIN_PATH` (verified against `v0.6.8`). So plugins must be *placed into* the
  existing home — a symlink sync, not a search-path addition.
- **Imports carry the whole subtree, not just SKILL.md.** Verified: `kien-thai` ships
  `references/`, `shell` ships `assets/` + `metadata.json`, `frontend-design` ships
  `LICENSE.txt`. So a `plugins/` tree rides along; for ACE users it materializes at
  `school/skills/lowfat/plugins/`. The sync resolves the skill's **own** install location as
  the symlink source — not a hardcoded ACE path — so it works wherever the skill lives
  (ACE import, direct clone, or any other install).
- **Reuses a rail that already exists (for ACE users).** The school already imports skill
  repos, so ACE users get the pantry with zero new machinery; non-ACE users install the skill
  directly. Supersedes this doc's earlier same-day framing (a dedicated `school/pantry/` dir +
  standalone sync skill), which added a second rail for no gain *and* assumed ACE.
- **Agent-driven sync, no script.** The sync (scope → reconcile → symlink → trust) is
  performed by the agent under explicit SKILL.md instructions, not a bundled script. The
  scope and reconcile steps are *judgment* — which plugins fit this project, whether a
  changed plugin is okay to re-trust — and the agent has context a script can't see (user
  memory, project signals, the conversation); a script would re-ask everything. SKILL.md
  specifies the fs mechanics exactly (idempotent check-then-symlink, never clobber a real
  file) so the agent improvises only the judgment, not the operations. The sync is occasional
  and interactive, so context-awareness beats a script's repeatability. Invoking the skill
  scopes the out-of-tree authorization (`~/.config/lowfat`) to the sync; trust stays
  user-run — the reconcile step is the checkpoint for lowfat's **name-based (not hash-based)
  trust**, re-surfacing any changed-but-trusted plugin.

## Not a transposition of the `rtk` skill

The `rtk` skill is author-written, not an authoritative blueprint. The `lowfat` skill is
**derived from lowfat's own mechanics** (shell-init eval, project `.lowfat`, plugin-home
sync, name-based trust, pantry seed). Reused from rtk only as *principle*: detect-state-first
idempotency, and the boundary that install + trust are user-run (agent never self-mutates
global env or self-trusts). Dropped: the CLAUDE.md→RTK.md block-relocation dance (lowfat
injects no block — it's `shell-init` + `.lowfat`), and the fixed 7-step arc.

## Open follow-ups

- Wire `school.toml` `[[imports]]` and settle exact repo/skill naming (skill triggers as
  `/lowfat`; repo likely `chakrit/lowfat-pantry`).
- File the upstream ask to zdk/lowfat for an additive `LOWFAT_PLUGIN_PATH`. If accepted, the
  symlink step disappears (point it at `school/skills/lowfat/plugins`), personal home
  untouched — strictly better. Until then, symlink sync stands.
