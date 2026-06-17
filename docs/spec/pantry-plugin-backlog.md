# lowfat-pantry — Built Inventory & Build Posture

What's built, and the posture governing what gets built next. Per-plugin detail (behavior +
gotchas) lives in `../../plugins/CATALOG.md`; this file is the high-level inventory and the
demand-driven build rule. Bundled lowfat plugins (`git` `docker` `grep` `find` `ls` `tree`)
are not pantry plugins — a pantry override *replaces* a bundled filter wholesale (lowfat
merges nothing) and needs trust.

## Testing posture

All 52 plugins have a smoke golden-file spec (`tests.cue` + committed `tests.lock.yml`);
`scripts/test.sh` runs the suite. smoke is the sole judge; `scripts/measure.py` emits size
metrics it locks. Harness detail: `smoke-golden-tests.md`.

The legacy test path was retired (2026-06-17): the 52 `tests.yml` and `scripts/validate.py`
are gone; `scripts/gen-smoke-spec.py` is kept as historical migration tooling.

## Built (52 community plugins)

VCS/CI: `rg` `gh` `glab` · Rust: `cargo` · TS/JS: `tsc` `eslint` `prettier` `npm` `pnpm`
`yarn` `bun` · Python: `pytest` `ruff` `mypy` `black` `pip` · Go: `go` `golangci-lint` ·
.NET: `dotnet` · JVM: `mvn` `gradlew` · Infra/ops: `kubectl` `helm` `terraform`
`ansible-playbook` `systemctl` `journalctl` `docker-compose` `ssh` `rsync` · Cloud/data:
`aws` `gcloud` `psql` `sqlite3` `env` · Runtimes/build: `make` `npx` `deno` `uv` · Net/data:
`curl` `wget` `jq` `json` `tar` · Toolchain: `diff` `prisma` `next` `playwright` ·
Deploy/data (docker-captured real samples, 2026-06-10): `redis-cli` `pulumi` `wrangler` `az`.

lowfat has **no command router** — it intercepts real binaries by name. So
`eslint`/`prettier`/`pytest`/`vitest` are their own plugins, never folded into abstract
`lint`/`format`/`test`. A bare `lint`/`format`/`test`/`smart`/`summary`/`deps`/`err` never
fires (nothing invokes those binaries) — build one only if a wrapper convention emerges.

### Wrapper commands (`uv run` / `npx` / `poetry run` …) — selection keys on the outer word

A consequence of "no command router": filter selection keys on the **first token**, so
`uv run pytest`, `uvx ruff`, `npx eslint`, `poetry run mypy` select on the *wrapper*
(`uv`/`npx`/…), never the inner tool. The wrapped tool's own plugin (`pytest`/`ruff`/…)
never fires. Both wrapper plugins in the pantry work around this with **args-driven
dispatch** (a python body parses `$args` to find the inner tool), each duplicating its
wrapped tools' bodies — disjoint sets, so they share nothing (npx wraps Node tools, uv
wraps Python tools):

- **`npx-compact`** (2026-06-16) — full dispatch: strips the npm install/fetch preamble,
  detects the wrapped tool from `$args` (handling `-y`/`-p typescript`), and applies
  eslint/prettier/tsc compaction **ported** from the standalone filters. Bare
  `npx prettier <file>` and `-f json` pass raw; unknown tools get a conservative cap.
- **`uv-compact`** (2026-06-16) — full dispatch: parses `$args`, detects the wrapped tool
  (`uv run <t>`, `uv tool run <t>`, `uvx <t>`, `python -m <t>`, skipping value-flags like
  `--with X`), and applies that tool's compaction (pytest, ruff) inline, **copied** from
  the standalone filters. Also compacts uv's own `sync`/`lock`/`pip`/`add` output; caps
  arbitrary `uv run <prog>`. The copies carry a drift contract — see the filter header.

The dispatch approach **duplicates** each wrapped tool's body (no cross-filter dispatch in
`.lf`; macros are file-local), so it drifts from the originals on every edit. The **proper
fix is wrapper-unwrap in lowfat-core**: recognize a known runner prefix, strip it, and
re-resolve the filter against the inner command word with re-derived `$sub`/`$args`. That
covers the whole class (`uv run`/`uvx`/`npx`/`bunx`/`poetry run`/`pnpm exec`/`pdm run`/
`hatch run`) once, with zero pantry duplication, and would let `npx`/`uv` drop their
dispatch entirely. Not actionable in this repo — lowfat-core source lives upstream. Tracked
with the other engine asks (include/import, `$cmd` exposure) in `lf-wishlist.md`.

## Build posture (2026-06-12): the pantry is effectively done

Build or enhance only when a **real session shows specific bloat** worth fixing — then
capture that exact output and fix precisely it. A backlog rank (even "Top enhance") is
headroom, not a need; chasing it speculatively invites synthetic-sample drift (filters
matching invented output rather than real).

- **Bundled `git`/`docker` enhancement** — don't fork one without a concrete observed
  reason: the override replaces the bundled filter wholesale and needs trust. Wait for a real
  subcommand to blow the budget, capture that exact output, fix it precisely.
- **More plugins** — only with real captured samples. `vercel`/`netlify`/`flyctl`/`gt`
  deferred: their signal output (deploys, stack ops) is auth-gated, so no real capture
  without accounts. `gt` is also niche for a trunk-based solo workflow.
- **Real-sample backfill** — replace synthetic samples where a tool + fixture exist (real so
  far: rg, redis-cli, pulumi, wrangler, az, kubectl-noserver, go-test-pass). Docker
  containers are the proven cheap capture path.

## Not pantry plugins — RTK meta/infra

RTK's own management surface, not command filters. Lowfat covers the equivalents differently,
or they don't apply: `init`, `config`, `gain`, `cc-economics`, `discover`, `session`,
`telemetry`, `learn`, `run`, `proxy`, `pipe`, `trust`, `untrust`, `verify`, `hook`,
`hook-audit`, `rewrite`, `help`.

- `trust`/`untrust`/`verify` → lowfat `trusted.toml` (per-plugin name, **not** content hash).
- `gain`/`discover`/`session`/`cc-economics` → lowfat `stats`/`history`.
- `hook`/`hook-audit`/`rewrite`/`init` → lowfat shell/agent integration setup.
- `run`/`proxy`/`pipe` → lowfat passthrough + `lowfat pipe`.
