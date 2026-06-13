# lowfat-pantry — Built Inventory & Build Posture

What's built, and the posture governing what gets built next. Per-plugin detail (behavior +
gotchas) lives in `../../plugins/CATALOG.md`; this file is the high-level inventory and the
demand-driven build rule. Bundled lowfat plugins (`git` `docker` `grep` `find` `ls` `tree`)
are not pantry plugins — a pantry override *replaces* a bundled filter wholesale (lowfat
merges nothing) and needs trust.

## Built (51 community plugins)

VCS/CI: `rg` `gh` `glab` · Rust: `cargo` · TS/JS: `tsc` `eslint` `prettier` `npm` `pnpm`
`yarn` `bun` · Python: `pytest` `ruff` `mypy` `black` `pip` · Go: `go` `golangci-lint` ·
.NET: `dotnet` · JVM: `mvn` `gradlew` · Infra/ops: `kubectl` `helm` `terraform`
`ansible-playbook` `systemctl` `journalctl` `docker-compose` `ssh` `rsync` · Cloud/data:
`aws` `gcloud` `psql` `sqlite3` `env` · Runtimes/build: `make` `npx` `deno` · Net/data:
`curl` `wget` `jq` `json` `tar` · Toolchain: `diff` `prisma` `next` `playwright` ·
Deploy/data (docker-captured real samples, 2026-06-10): `redis-cli` `pulumi` `wrangler` `az`.

lowfat has **no command router** — it intercepts real binaries by name. So
`eslint`/`prettier`/`pytest`/`vitest` are their own plugins, never folded into abstract
`lint`/`format`/`test`. A bare `lint`/`format`/`test`/`smart`/`summary`/`deps`/`err` never
fires (nothing invokes those binaries) — build one only if a wrapper convention emerges.

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
