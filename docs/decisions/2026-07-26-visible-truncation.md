# Truncation is visible; inventory listings are exempt

**Date:** 2026-07-26 · **Status:** accepted · **Trigger:**
[issue #1](https://github.com/chakrit/lowfat-pantry/issues/1)

## Ruling

1. A `*:` catch-all must never end in a bare `head` / `tail` / `truncate`. Truncation that
   reaches the reader carries a marker naming the dropped count — `head-auto-marked` in
   place of `head auto`.
2. Subcommands whose output is one load-bearing identifier per line are exempt from
   compaction entirely. They get an explicit rule returning `raw`, above the catch-all.

Recorded as invariants 6 and 7 in `docs/spec/output-philosophy.md`.

## Why this goes against the obvious default

The obvious default is what all 64 plugins shipped with: unknown subcommands fall to
`head auto` and get length-capped. That is the *correct instinct for a compactor* — cap what
you do not understand — and it is why every plugin does it. 40 of 64 catch-alls ended in a
silent truncator.

The instinct is wrong at the boundary, and wrong in a specific, non-obvious way. Compaction
trades completeness for tokens, and that trade is only sound when the reader can tell it
happened. `head` cuts without a trace, so a truncated list and a genuinely short list are
byte-identical. The reader does not get a degraded answer — they get a **confident wrong
answer**, with no signal to distrust it.

In the reported case `tofu state list` returned 15 of 36 resources. Nothing marked the cut.
The output implied an LKE cluster, a reserved edge IP, an edge firewall, 13 object-storage
buckets, and 7 Neon projects were absent from state, and the next reasonable step from that
reading is reconciling state to match — destroying tracked infrastructure on the strength of
a truncation.

Inventory listings deserve their own carve-out rather than just a marker because they are
the degenerate case for a lossy summarizer: every line is load-bearing, no line is
redundant, and the entire value is completeness. There is no honest 30-line summary of a
36-item list. Marking would make the loss visible; exemption makes it not happen.

## Cost accepted

Unknown subcommands with genuinely bloated output now cost one extra line (the marker), and
exempt subcommands cost their full length. Both are token regressions, taken deliberately:
the tokens saved by a silent cut are worthless if the output they produce is wrong.

## Alternatives rejected

**Blanket `raw` catch-alls.** Eliminates the class outright but gives up compaction on every
subcommand a filter does not explicitly name — surrendering the tool's purpose to fix a
subset of cases. Marked truncation keeps the savings and restores the reader's ability to
tell.

**Fix only the reported plugin.** Issue #1 named `terraform`, but the shape was in 40
filters. Fixing the instance and leaving the class is how the same bug gets reported 39 more
times. See `docs/guides/issue-triage.md`.

**Wait for an upstream fix.** The true root cause is that lowfat's builtin `head`/`tail`
cut without a marker; fixing it there would fix all plugins *and* the six bundled filters at
once, and belongs upstream. But `zdk/lowfat` is not ours to land, and the pantry cannot
ship a known silent-loss bug while waiting on someone else's release.

## Amendment — 2026-07-27: no exemption for named rules

The original sweep's radius was catch-alls, and `plugins/README.md` carried an exemption
for named-subcommand rules ("their author knew the output shape") that this doc's rule 2
never granted. chakrit ruled the invariant applies everywhere: **any** cut marks, including
extraction paths that keyword-filter first and cap after.

Radius: 69 bare `head`/`tail` ops across 17 filters, plus every budget-limited loop in a
`shell:` body (mypy, ruff, pytest, jest, vitest, terraform, kubectl, psql, helm, systemctl,
diff, aws, env, uv). Eleven goldens re-locked, all additive — no output line was removed
anywhere, only markers added.

## Consequences

- `.lf` had no include mechanism, so `head-auto-marked` was duplicated per filter.
  **Superseded 2026-07-26 (same day, v0.8.0):** `include` landed upstream and the marked
  macros now live once in `plugins/lib/truncation.lf`. Self-containment is still a
  distribution requirement — it is met by the sync linking `plugins/lib` into the lowfat
  home next to the plugins, so the `../../lib/` path resolves in both trees.
- The macro is `python:`, not `awk` — `awk` is banned repo-wide. Measured suite cost of the
  swap was ~0.4s across 703 tests.
- Every new plugin classifies each subcommand as inventory / structured / compactable before
  writing a rule. Added to the `SKILL.md` decision tree.
