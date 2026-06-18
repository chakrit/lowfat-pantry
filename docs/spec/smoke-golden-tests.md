# Smoke golden-file tests

How the pantry's filters are tested for output drift. The harness is
[`chakrit/smoke`](https://github.com/chakrit/smoke) (>= v0.3.0) driving a
committed golden per plugin. smoke is a **drift detector**, not an assertion
engine: a clean run means the output still matches the locked golden, not that
the output is "correct" — correctness is established once, by a human, when the
golden is first reviewed and committed.

## Run it

```sh
scripts/test.sh          # whole suite; exit 0 = no drift
scripts/test.sh -c       # re-lock everything (review the diff, then commit)
smoke plugins/go/go-compact/tests.cue        # one plugin
smoke -c plugins/go/go-compact/tests.cue     # re-lock one plugin
```

smoke runs each spec's commands in the **invocation cwd**, so always invoke from
the repo root (`test.sh` enforces this). Exit codes: `0` UNCHANGED, `1` CHANGED
(drift — investigate or re-lock), `3` NEW (no lock yet), `65` malformed spec.

## What a spec looks like

One `tests.cue` per plugin, beside its `filter.lf`. The committed golden is
`tests.lock.yml` next to it. See `plugins/go/go-compact/tests.cue` for the
annotated reference. The shape:

- `_`-prefixed (CUE-hidden) fields hold the case matrix — `_dir`, `_cases`
  (sample/sub/args/exit/levels). CUE drops hidden fields on export, so smoke's
  **closed schema never sees them** (a typo'd schema field is a hard error,
  exit 65). This is why specs are CUE, not YAML: the matrix templates cleanly
  while the validated surface stays closed.
- A comprehension expands `_cases × levels` into one smoke test each.
- **Test names must be unique.** The default name is `"\(c.sample) \(l)"`. If two
  cases reuse the *same sample* (e.g. one filter invoked two ways over one
  fixture), that name collides → duplicate test → smoke **exit 65**, but *only
  when the spec runs standalone* — the full-suite run masks it (one case is
  silently deduped, a coverage gap). When a sample is reused, include sub+args:
  `name: "\(c.sample) \(c.sub) \(c.args) \(l)"`. (npx, redis-cli hit this.)
- Each test locks **two commands**:
  1. the raw `lowfat filter … < sample` — the literal golden, catches any
     content drift;
  2. the same piped through `scripts/measure.py` — emits `lines N` / `bytes N`,
     so an over-prune-to-empty or unexpected-growth regression surfaces as a
     changed number, i.e. as drift.
- `checks: [stdout, exitcode]` — stdout is the golden / metrics, exitcode is a
  "filter didn't crash" sentinel. `lowfat filter`'s stderr is always empty, so
  it is omitted to keep the lock lean.

`scripts/measure.py` is deliberately **judgment-free**: it measures and exits 0,
never gates. smoke is the sole judge — pass/fail lives entirely in the
golden/drift, not in the script. To add a metric, print another deterministic
line; never add a pass/fail branch.

## Adding / changing a filter

1. Edit `filter.lf`, add or adjust cases in `tests.cue`.
2. `smoke -c plugins/<cmd>/<plugin>/tests.cue` to lock.
3. **Review the lock diff** — this is the correctness gate. A NEW or CHANGED
   golden is only trustworthy because a human read it.
4. Commit `tests.cue` + `tests.lock.yml` together.

Determinism is required: smoke compares bytes. The filter must be a pure
function of (stdin, sub, args, exit, level). Samples are static fixtures, so
this holds for every current plugin; a filter that injected a timestamp, PID,
or other volatile content would drift on every run and not belong in the golden
suite.

## How it relates to `lowfat filter`

Each command shells out to `lowfat filter <f.lf> --sub= --args= --exit= --level=`
— a single-shot invocation with no install or trust step. For the flag
semantics and the `.lf` language itself, see lowfat's own docs, not just this
repo's:
[`zdk/lowfat` README](https://github.com/zdk/lowfat/blob/main/README.md) and
[`docs/PLUGINS.md`](https://github.com/zdk/lowfat/blob/main/docs/PLUGINS.md);
the repo-local authoring spec is `docs/spec/lowfat-filter-dsl.md`.

## Provenance

`tests.cue` is the source of truth. It replaced an earlier `tests.yml` +
`scripts/validate.py` setup, which was retired once the smoke suite covered
every plugin (2026-06-17).
