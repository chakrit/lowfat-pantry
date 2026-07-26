# Pantry — lowfat plugins

Community `.lf` filter plugins for [lowfat](https://github.com/zdk/lowfat), the
token-aware command-output compactor. The `/lowfat-pantry` skill symlinks selected plugins
from here into the resolved lowfat home (`<LOWFAT_HOME>/plugins/<category>/<name>/`, default
`~/.config/lowfat/plugins/` — `~/.lowfat/plugins/` when `$LOWFAT_HOME=~/.lowfat`), plus
`plugins/lib` alongside them so filter includes resolve there too.

## Layout

    plugins/lib/       shared macros, pulled in with `include ../../lib/<file>.lf`
      truncation.lf    head-marked / head-auto-marked / tail-marked / cap
      columns.lf       squeeze-columns

    plugins/<category>/<name>/
      lowfat.toml    plugin manifest ([plugin] name/commands/subcommands/…)
      filter.lf      the filter rules (the DSL; spec: https://github.com/chakrit/lowfat-pantry/blob/main/docs/vendor/lowfat-filter-dsl.md)
      samples/       real or representative command output, one file per case
      tests.cue      smoke golden spec: case matrix over (sample × level)
      tests.lock.yml committed golden output (written by the source repo's `scripts/smoke.sh -c`)

`<category>` is the primary command (e.g. `rg`); `<name>` is `<command>-compact`,
matching lowfat's bundled convention (`git/git-compact`). Disk plugins shadow bundled
ones of the same name.

## Truncation conventions (hard rules)

A compactor that drops lines must never be indistinguishable from a genuinely short
listing — that is the one failure mode producing a *confident wrong answer* rather than a
degraded one. Two rules, from
[`docs/decisions/2026-07-26-visible-truncation.md`](../docs/decisions/2026-07-26-visible-truncation.md):

1. **Inventory listings are exempt from compaction.** One load-bearing identifier per line
   with nothing redundant (`terraform state list`, `kubectl get`, `helm list`,
   `gh issue list`, `npm ls`) — the whole value is completeness. Give them their own rule
   returning `raw`, or squeeze columns only; never drop rows. There is no honest 30-line
   summary of a 200-item list.
2. **Truncation is always visible.** Any rule that drops lines says so, at every level,
   with the count. The `.lf` ops `head`/`tail` cut *without* a marker, so they must not
   terminate a `*:` catch-all — pull in a marked macro instead:

        include ../../lib/truncation.lf

        *:
            head-auto-marked

   `head-auto-marked` / `tail-auto-marked` mirror `head auto`'s level limits (ultra 15 /
   full 30 / lite 60); `head-marked <n>` / `tail-marked <n>` / `cap <n>` take an explicit
   cap. `or-shell:` recovery fallbacks cap the raw dump too and mark it the same way.

   **One marker form, everywhere** (2026-07-27):

        [lowfat] +<n> <unit> dropped (level=<lvl>) -- output truncated, re-run raw for the full list

   `<unit>` is `lines` unless the filter counts something more specific (tar `entries`,
   rubocop `offenses`). The count is what the reader *lost*, not what the stream held — a
   total tells you nothing you can act on when you can also see what survived.

   Never re-copy a library macro into a filter. The include path is relative to the
   including filter and holds in both trees — pantry source and
   `<LOWFAT_HOME>/plugins/<category>/<name>/` — because `/lowfat-pantry` symlinks
   `plugins/lib` into the lowfat home alongside the plugins (SKILL.md § 4c). A local
   `define` of the same name still shadows the library one when a plugin genuinely needs
   its own variant.

This holds for **every** rule, not just the catch-all (ruling 2026-07-27, superseding the
earlier "named-subcommand rules knew their output shape" exemption). Extraction paths are
the subtle case: a reader can tell that a keyword-extracted view isn't the whole stream,
but not whether the part that survived is complete — `mypy-compact` was showing 15 of 34
errors at ultra and saying nothing. Bare `head`/`tail` ops are therefore gone from the
pantry; a budget-limited loop counts what it discarded and prints the same marker as a
trailer.

Use `shell:` for extraction the ops can't express — POSIX sh, and **never `awk`**, which
is banned repo-wide. `python:` is banned in filters too, for a different reason: a filter
that needs an interpreter the user doesn't have doesn't degrade, it dies. Two portability
rules follow from BSD/GNU divergence, and both fail *silently* when broken:

- **ERE only** (`grep -E`, `sed -nE`). BSD sed has no `\|` alternation — it matches
  nothing, without an error, so a BRE alternation ships a filter that works on Linux and
  blanks the output on macOS.
- **POSIX classes only** — `[[:blank:]]`, not `\t`; spell case folding out per letter
  (`[Ss][Ee]…`), since BSD has no `(?i)`.

When a shape genuinely needs a parser — reshaping JSON — shell out to the real tool (`jq`)
and pass the stream through untouched when it's absent.

## Sample naming

    <command>-<subcommand>-<level>.txt    e.g. cargo-build-full.txt
    <command>-<subcommand>.txt            level-agnostic raw capture

Prefer **real** captured output (`<cmd> … > sample.txt 2>&1`); synthesize only when the
tool/environment isn't available here. Sample files must be **byte-faithful** to real
command output — no inline annotations (they would leak into filtered output and distort
line counts).

## tests.cue

The smoke golden spec for a plugin. Each case names a sample and the contexts to run it
through; smoke snapshots `lowfat filter filter.lf --sub=<sub> --args=<args> --exit=<exit>
--level=<level> < sample` per level and locks the output as the golden. The case×level
matrix scaffold lives in the shared `testkit` cue.mod package; a spec supplies only:

```cue
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/cargo/cargo-compact"
	name: "cargo-compact"
	cases: [
		{sample: "samples/cargo-build-full.txt", sub: "build", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}
```

See `go-compact/tests.cue` for the annotated reference and the smoke-golden-tests spec
(https://github.com/chakrit/lowfat-pantry/blob/main/docs/guides/smoke-golden-tests.md)
for the full harness.

## Authoring & testing

Author (in the pantry source repo, `chakrit/lowfat-pantry`) against the filter DSL spec
linked above. Test with smoke (no global state, no trust, no install — each case wraps
`lowfat filter <filter.lf> --sub … --exit … --level … < sample`, honoring the case's
real `exit` so failure samples are tested as failures):

    scripts/smoke.sh -c plugins/<cmd>/<plugin>/tests.cue   # lock the golden, REVIEW the diff
    scripts/test.sh                                        # whole suite, exit 0 = no drift
    scripts/drift.py                                       # wrapper/original agreement
    scripts/overprune.py                                   # nothing swallows a stream whole
    capture/capture.sh <stack>                             # real failure samples, in a container

`scripts/test.sh` runs four specs at a time (`JOBS=1` to serialize), then two gates that
goldens structurally can't replace. Neither is re-lockable — a failure in either is a bug:

- **`drift.py`** — the wrappers (`uv-compact`, `npx-compact`) delegate to their wrapped
  tools' filters by re-invoking `lowfat filter`, so a broken dispatch (wrong args mapping,
  a probe that stops finding the sibling) shows up nowhere in their own locks. It runs the
  wrapped tool's own samples through wrapper and original and requires identical output.
- **`overprune.py`** — a filter is a keep-list built from shapes its author had seen; when
  a tool rewords its output the list can match *nothing* and the page becomes silence,
  which reads as "the command printed nothing". Goldens can never catch this: a sample the
  filter recognizes is by definition not the case that breaks it. So it drives deliberately
  unrecognizable input through every filter × subcommand × level × exit and asserts
  something came back. Every rule needs a fallback — an `or "<tool>: ok"` verdict, an
  `or-shell:` marked tail, or an in-body `emitted` check.

Real failure output for tools that aren't installed comes from `capture/` — one container
image per stack, samples reviewed by hand before they're committed. See `capture/README.md`.

The lock diff is the correctness gate. A regression like over-prune-to-empty surfaces as
drift on the `measure.py` `lines`/`bytes` metric locked alongside each golden.

## Design principles

- **Filters are data, not code.** Logic lives in `.lf` rules + small POSIX `shell:` escape
  hatches, never a compiled binary and never an interpreter the user may not have.
- **Three levels, every plugin.** `ultra` (~10 lines) · `full` (~30) · `lite` (~60).
  Default `full`. Every plugin degrades gracefully across all three.
- **Preserve the signal, drop the bloat.** Keep errors, failures, summaries, and
  structural headers; drop progress bars, cache-hit noise, ASCII art, and unchanged
  context. On non-zero exit, prefer `raw` so failures are never hidden.
- **Never corrupt machine-readable output.** JSON/env/porcelain modes pass through or
  compact structurally, never lossily.
