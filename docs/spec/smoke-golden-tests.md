# Smoke golden-file tests

How the pantry's filters are tested for output drift. The harness is
[`chakrit/smoke`](https://github.com/chakrit/smoke) (>= v0.5.0) driving a
committed golden per plugin. smoke is a **drift detector**, not an assertion
engine: a clean run means the output still matches the locked golden, not that
the output is "correct" — correctness is established once, by a human, when the
golden is first reviewed and committed.

## Run it

```sh
scripts/test.sh          # whole suite; exit 0 = no drift
scripts/test.sh -c       # re-lock everything (review the diff, then commit)
scripts/smoke.sh plugins/go/go-compact/tests.cue        # one plugin
scripts/smoke.sh -c plugins/go/go-compact/tests.cue     # re-lock one plugin
```

Both wrap `scripts/smoke.sh`, which provisions a pinned `chakrit/smoke` into a
gitignored `.bin/` via `go install` (needs Go on PATH) — never a bare `smoke` off
PATH, which may be an older version that mis-keys every lock (see Lock keys
below). smoke runs each spec's commands in the **invocation cwd**, so always
invoke from the repo root (the scripts enforce this). Exit codes: `0` UNCHANGED,
`1` CHANGED (drift — investigate or re-lock), `3` NEW (no lock yet), `64` usage
error, `65` malformed spec / duplicate test name.

**`test.sh` runs one spec per invocation.** Each plugin gets its own verdict line
and the suite aggregates the worst exit. Earlier smoke exited after the first
spec of a multi-spec compare, which *forced* this loop; v0.4 fixed it — a single
multi-spec call now checks every spec and aggregates exit — but the loop stays
for obvious per-plugin attribution and uniform behaviour under `-c`.

## What a spec looks like

One `tests.cue` per plugin, beside its `filter.lf`; the committed golden is
`tests.lock.yml` next to it. Each spec imports the shared `testkit` package
(`testkit/`, under the repo's `cue.mod`) and supplies just its data:

```cue
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/go/go-compact"
	name: "go-compact"
	cases: [
		{sample: "samples/go-build.txt", sub: "build", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		// …
	]
}
config: _suite.config
tests:  _suite.tests
```

`testkit.#Suite` owns the shape once for all 64 specs: it expands cases × levels
into the two-commands-per-case matrix, sets `config` (`/bin/sh`, `10s`) and
`checks: [stdout, exitcode]`, and names each test `"\(sample) \(level)"` under a
group named `name`. The per-spec diff is just `dir`, `name`, `cases` (and rarely
`nameParts`). See `plugins/go/go-compact/tests.cue`.

- **`#Case` validates every case.** `testkit.#Case` is closed and all-required
  (`sample!/sub!/args!/exit!/levels!`), so a typo'd or wrong-typed field fails at
  cue eval, not silently as a broken command. Needs smoke **≥ v0.5.0**, whose
  `cue/load` loader resolves the `cue.mod` import — older smoke can't load these.
- **Inputs stay off the closed surface.** `_suite` is hidden (`_`-prefixed), so
  smoke's closed `#Test` sees only the exposed `config`/`tests`; `dir`/`name`/
  `cases` never collide with it.
- **Lock keys use the spec BASENAME (smoke v0.4).** A test's full key is
  `<basename> \ <name> \ …`, so every lock here roots at `tests.cue \ …`, not
  the path. An older `smoke` keyed by the path as typed and mis-keys (re-NEWs)
  these locks — always run via `scripts/smoke.sh`.
- **`nameParts` for reused samples.** The leaf name defaults to
  `"\(sample) \(level)"`. A spec that reuses one sample across cases (npx,
  redis-cli) sets `nameParts: ["sample", "sub", "args"]` (any case fields,
  space-joined) to keep names unique — otherwise the duplicate is smoke **exit 65**.
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
2. `scripts/smoke.sh -c plugins/<cmd>/<plugin>/tests.cue` to lock.
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
