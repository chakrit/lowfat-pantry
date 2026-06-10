# `/lowfat` Skill — Design

Status: **draft**. The standalone agent skill this repo (`chakrit/lowfat-pantry`)
ships — usable from any skills-compatible agent (Claude Code being the primary target);
ACE users import it via `school.toml` `[[imports]]` as one install channel. Derived from lowfat's own mechanics, not transposed from the
author-written `rtk` skill (see `../decisions/2026-06-08-pantry-distribution.md`).

## Repo-as-skill

A standard agent-skill repo. ACE users import it like `kien-thai`/`visualise` (it
materializes at `school/skills/lowfat/`); non-ACE users install it via their own skill
tooling. Carries:

**Non-goal:** getting the skill *onto* a machine. That's the skill-manager's job (ACE import,
a skill installer, or a manual clone — the user's pick), not this repo's. The repo's only
install-adjacent responsibility is runtime self-location — resolving its own dir as the
symlink source — already covered below.

Layout:

    SKILL.md             the /lowfat skill (carries the sync logic as agent steps)
    plugins/<cat>/<p>/   pantry — lowfat.toml · filter.lf · samples/ · tests.yml
    templates/lowfat     seed project config (NO dot — it's a template, not active config)
    docs/                durable docs

No `bin/sync` script. The sync is performed by the agent under explicit SKILL.md
instructions — the scope and reconcile steps are judgment calls (which plugins fit this
project, whether a changed plugin is okay to re-trust) that benefit from context a script
can't see: user memory, project toolchain signals, the conversation. A script would re-ask
everything; the agent pre-fills sane defaults and surfaces only real decisions. SKILL.md must
still spell the fs mechanics exactly (idempotent check-then-symlink, never clobber a real
file/dir) so the agent improvises only the judgment, not the operations.

## Skill arc

1. **Detect state** (parallel): `which lowfat` · `.lowfat` present · integration hook wired
   (user-scope `~/.claude/settings.json`) · pantry sync status.

2. **Install if absent** — user-run (`cargo install lowfat` / brew). Agent never installs
   global tooling. Stop until present. *(rtk principle kept — safety boundary.)*

3. **Seed `.lowfat`** from `templates/lowfat`: level + enabled filters per toolchain signals
   (Cargo.toml → cargo, package.json → node tools, go.mod → go, etc.).

4. **Sync pantry** — the core step, performed by the agent directly (no bundled script):
   - **a. Scope** — harness asks the user *how much* pantry to install (all / by tier / by
     category / hand-pick). `AskUserQuestion`.
   - **b. Reconcile** — three-way diff between the selected pantry set and what's already in
     `~/.config/lowfat/plugins/`. Classify **added** (new in repo), **removed** (gone from
     repo, still local), **changed** (content differs). Harness asks the user to adjudicate
     each. `AskUserQuestion`. Also the **name-based-trust drift guard**: a *changed* plugin
     that's already trusted is re-surfaced here, since lowfat won't re-prompt on content
     change on its own.
   - **c. Apply** — create/remove symlinks per the user's decisions.
   - **d. Trust** — prompt the **user** to run `lowfat plugin trust <plugin>` for new/changed
     plugins. Agent never self-trusts, even first-party pantry content.

5. **Wire integration** *(opt-in, default off)* — register lowfat's PreToolUse hook at
   **user scope** (`~/.claude/settings.json`) for machine-wide transparent command rewrite.
   Use the `update-config` skill to write the hook entry. The migration plan sequences
   transparent rewriting last (after coverage exists); the skill offers it, doesn't force it.

6. **Standalone invocation** (already set up) → terse status: lowfat active, N pantry plugins
   synced, `/lowfat` to re-sync.

> Dropped vs the rtk skill: the "backfill in-flight commands to prefixed form" step. rtk
> needs it because it requires manual `rtk ` prefixing; once step 5's hook rewrites
> transparently there is nothing to backfill. Also dropped: the CLAUDE.md→RTK.md block
> relocation (lowfat injects no block).

## Trust boundary

Strict, user-run only. The agent surfaces what needs trusting and the exact command; the
user runs `lowfat plugin trust`. Holds even though pantry plugins are first-party — the
reconcile step (4b) is what makes this safe against silent content drift.

## Open

- `update-config` integration for the user-scope hook entry (step 5).
- Sync resolves the skill's **own** install dir as the symlink source (works for any install
  method); for ACE imports, confirm that resolves to `school/skills/lowfat/plugins/`.
