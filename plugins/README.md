# Pantry — lowfat plugins

Community `.lf` filter plugins for [lowfat](https://github.com/zdk/lowfat), the
token-aware command-output compactor. The `/lowfat-pantry` skill symlinks selected plugins from
here into the resolved lowfat home (`<LOWFAT_HOME>/plugins/<category>/<name>/`, default
`~/.config/lowfat/plugins/` — `~/.lowfat/plugins/` when `$LOWFAT_HOME=~/.lowfat`).

## Layout

    plugins/<category>/<name>/
      lowfat.toml    plugin manifest ([plugin] name/commands/subcommands/…)
      filter.lf      the filter rules (the DSL; spec: https://github.com/chakrit/lowfat-pantry/blob/main/docs/vendor/lowfat-filter-dsl.md)
      samples/       real or representative command output, one file per case
      tests.cue      smoke golden spec: case matrix over (sample × level)
      tests.lock.yml committed golden output (written by the source repo's `scripts/smoke.sh -c`)

`<category>` is the primary command (e.g. `rg`); `<name>` is `<command>-compact`,
matching lowfat's bundled convention (`git/git-compact`). Disk plugins shadow bundled
ones of the same name.

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

The lock diff is the correctness gate. A regression like over-prune-to-empty surfaces as
drift on the `measure.py` `lines`/`bytes` metric locked alongside each golden.

## Design principles

- **Filters are data, not code.** Logic lives in `.lf` rules + small `shell:`/`python:`
  escape hatches, never a compiled binary.
- **Three levels, every plugin.** `ultra` (~10 lines) · `full` (~30) · `lite` (~60).
  Default `full`. Every plugin degrades gracefully across all three.
- **Preserve the signal, drop the bloat.** Keep errors, failures, summaries, and
  structural headers; drop progress bars, cache-hit noise, ASCII art, and unchanged
  context. On non-zero exit, prefer `raw` so failures are never hidden.
- **Never corrupt machine-readable output.** JSON/env/porcelain modes pass through or
  compact structurally, never lossily.
