# Pantry — lowfat plugins

Community `.lf` filter plugins for [lowfat](https://github.com/zdk/lowfat), the
token-aware command-output compactor. The `/lowfat` skill symlinks selected plugins from
here into the resolved lowfat home (`<LOWFAT_HOME>/plugins/<category>/<name>/`, default
`~/.config/lowfat/plugins/` — `~/.lowfat/plugins/` when `$LOWFAT_HOME=~/.lowfat`).

## Layout

    plugins/<category>/<name>/
      lowfat.toml    plugin manifest ([plugin] name/commands/subcommands/…)
      filter.lf      the filter rules (the DSL; see docs/spec/lowfat-filter-dsl.md)
      samples/       real or representative command output, one file per case
      tests.yml      golden/invariant cases over (sample × level)

`<category>` is the primary command (e.g. `rg`); `<name>` is `<command>-compact`,
matching lowfat's bundled convention (`git/git-compact`). Disk plugins shadow bundled
ones of the same name.

## Sample naming

    <command>-<subcommand>-<level>.txt    e.g. cargo-build-full.txt
    <command>-<subcommand>.txt            level-agnostic raw capture

Prefer **real** captured output (`<cmd> … > sample.txt 2>&1`); synthesize only when the
tool/environment isn't available here. Mark synthetic samples with a leading
`# synthetic:` comment line.

## tests.yml (provisional)

The format below is provisional pending the `chakrit/smoke` golden harness upgrade. Each
case names a sample and the contexts to run it through; the harness will snapshot
`lowfat filter filter.lf --sub=<sub> --args=<args> --level=<level> < sample` per level.

```yaml
command: cargo
cases:
  - sample: samples/cargo-build-full.txt
    sub: build
    args: ""
    levels: [lite, full, ultra]
```

## Authoring & validating

Author against `docs/spec/lowfat-filter-dsl.md`. Validate purely (no global state, no
trust, no install) with the standalone filter runner:

    scripts/validate.sh                 # all plugins
    scripts/validate.sh plugins/rg      # one plugin

which wraps `lowfat filter <filter.lf> --sub … --level … < sample` and reports
line-reduction per (sample × level).

## Design principles (vs RTK)

- **Filters are data, not code.** Logic lives in `.lf` rules + small `shell:`/`python:`
  escape hatches, never a compiled binary.
- **Three levels, every plugin.** `ultra` (~10 lines) · `full` (~30) · `lite` (~60).
  Default `full`. Every plugin degrades gracefully across all three.
- **Preserve the signal, drop the bloat.** Keep errors, failures, summaries, and
  structural headers; drop progress bars, cache-hit noise, ASCII art, and unchanged
  context. On non-zero exit, prefer `raw` so failures are never hidden.
- **Never corrupt machine-readable output.** JSON/env/porcelain modes pass through or
  compact structurally, never lossily.
