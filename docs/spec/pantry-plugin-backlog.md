# lowfat-pantry — Plugin Backlog

Source: RTK `0.42.0` command surface (`rtk --help`), sorted into pantry plugin
candidates. Priority is a rough first pass on frequency × school-stack fit × filtering
payoff. **You drive final prioritization** — these tiers are a starting proposal, not a
commitment.

Legend:

- **bundled** — lowfat `v0.6.8` already ships a plugin; work is *enhance/verify*, not build.
- **build** — no lowfat coverage; net-new plugin.
- **fold** — likely collapses into another plugin rather than standing alone.
- ✅ **built** — net-new plugin now exists under `plugins/` (this session).

## Built (51 community plugins)

VCS/CI: `rg` `gh` `glab` · Rust: `cargo` · TS/JS: `tsc` `eslint` `prettier` `npm` `pnpm`
`yarn` `bun` · Python: `pytest` `ruff` `mypy` `black` `pip` · Go: `go` `golangci-lint` ·
.NET: `dotnet` · JVM: `mvn` `gradlew` · Infra/ops: `kubectl` `helm` `terraform`
`ansible-playbook` `systemctl` `journalctl` `docker-compose` `ssh` `rsync` · Cloud/data:
`aws` `gcloud` `psql` `sqlite3` `env` · Runtimes/build: `make` `npx` `deno` · Net/data:
`curl` `wget` `jq` `json` `tar` · Toolchain: `diff` `prisma` `next` `playwright` ·
Deploy/data (docker-captured real samples, 2026-06-10): `redis-cli` `pulumi` `wrangler` `az`.

Note on the "fold" calls: lowfat has **no RTK-style command router** — it intercepts real
binaries by name. So `eslint`/`prettier`/`pytest`/`vitest` are built as their own plugins
(not folded into abstract `lint`/`format`/`test`). The generic `lint`/`format`/`test`/`smart`/
`summary`/`deps`/`err` entries below are **deprioritized**: nothing invokes a bare `lint`
binary, so they'd never fire. Build them only if a wrapper convention emerges.

Remaining candidates (lower value / lower format-confidence — synthetic samples risk drifting
from real output): `log`/`read`/`wc` (need a real intercepted command), `gt` (Graphite, niche
for a trunk-based solo workflow), deploy CLIs `vercel`/`flyctl`/`netlify`. Plus enhancement
passes on the bundled `git`/`docker`. Build these only with **real captured samples** so the
filters match actual output.

**Posture (2026-06-12): the pantry is effectively done; remaining work is demand-driven, not
backlog-ordered.** Build or enhance only when a *real session shows specific bloat* worth
fixing — then capture that exact output and fix precisely it. A backlog rank (even "Top
enhance") is headroom, not a need; chasing it speculatively is the synthetic-sample drift
this section warns against. For bundled commands (`git`/`docker`) there's an extra cost: a
pantry override *replaces* the bundled filter wholesale (lowfat merges nothing) and needs
trust — so don't fork one without a concrete, observed reason. 2026-06-10: `redis-cli`/`pulumi`/`wrangler`/`az` graduated to
built via docker-captured real samples; `vercel`/`netlify`/`flyctl`/`gt` stay deferred — their
signal output (deploys, stack ops) is auth-gated, so no real capture is possible without
accounts.

## Tier 0 — Universal, every session, high bloat

| Command | Status   | Notes                                                                 |
| ------- | -------- | --------------------------------------------------------------------- |
| `git`   | bundled  | 4 subcommands specialized; rest hit 30-line cap. Headroom, not a need — enhance only on observed bloat (see Posture). |
| `rg`    | build    | School prefers ripgrep; lowfat grep claims only `grep`. P0 gap.       |
| `gh`    | build    | PRs/issues/reviews — constant in this school. High value.             |
| `test`  | build    | Generic test runner, show-failures-only. Cross-stack, huge payoff.    |
| `grep`  | bundled  | Verify; may fold under a shared grep/rg filter.                       |
| `find`  | bundled  | Verify defaults suffice.                                              |
| `ls`    | bundled  | Verify defaults suffice.                                              |
| `tree`  | bundled  | Verify defaults suffice.                                              |

## Tier 1 — Common, directly on the school stack

| Command    | Status | Notes                                                          |
| ---------- | ------ | -------------------------------------------------------------- |
| `cargo`    | build  | Rust — core stack.                                             |
| `go`       | build  | Go — core stack (prod9/fx, ACE).                               |
| `dotnet`   | build  | C#/.NET — core stack.                                          |
| `tsc`      | build  | TS errors are extremely noisy; grouped output is high payoff.  |
| `npm`      | build  | Node — Payload/Astro.                                          |
| `pnpm`     | build  | Node — Payload/Astro.                                          |
| `npx`      | build  | Routes to tsc/eslint/prisma in RTK; useful router.            |
| `lint`     | build  | ESLint grouped-by-rule. Generic lint entry.                   |
| `format`   | build  | Universal format check (prettier/black/ruff). Cross-stack.    |
| `pytest`   | build  | Python tests.                                                  |
| `ruff`     | build  | Python lint/format.                                            |
| `mypy`     | build  | Python types, grouped errors.                                 |
| `kubectl`  | build  | K8s/infra (p9-infra).                                         |
| `curl`     | build  | HTTP + auto-JSON schema.                                      |
| `json`     | build  | JSON inspection / key extraction.                            |
| `env`      | build  | Secret-masked env dump — security-relevant.                  |

## Tier 2 — Useful, narrower or less frequent

| Command     | Status  | Notes                                                  |
| ----------- | ------- | ------------------------------------------------------ |
| `docker`    | bundled | Verify/enhance.                                        |
| `diff`      | build   | Changed-lines-only.                                    |
| `log`       | build   | Log dedup/filter.                                      |
| `read`      | build   | Intelligent file read / signature extraction.         |
| `wc`        | build   | Strip padding/paths.                                   |
| `wget`      | fold    | Strip progress bars; pairs with `curl`.               |
| `prettier`  | fold    | Likely folds into `format`.                            |
| `eslint`    | fold    | Likely folds into `lint`.                              |
| `vitest`    | fold    | Likely folds into `test`.                              |
| `jest`      | fold    | Likely folds into `test`.                              |
| `pip`       | build   | Auto-detects uv.                                       |
| `psql`      | build   | DB client — strip borders, compress tables.            |
| `aws`       | build   | Cloud client — force JSON, compress.                   |
| `glab`      | build   | GitLab CLI — you use both gh + gl.                     |
| `prisma`    | build   | Strip ASCII art.                                       |
| `next`      | build   | Next.js build.                                         |
| `playwright`| build   | E2E.                                                   |
| `golangci-lint` | build | Go lint.                                          |

## Tier 3 — Niche for this school

| Command    | Status | Notes                                              |
| ---------- | ------ | -------------------------------------------------- |
| `rake`     | build  | Ruby — no Ruby in current school skills.           |
| `rubocop`  | build  | Ruby.                                              |
| `rspec`    | build  | Ruby.                                             |
| `gradlew`  | build  | Android Gradle.                                    |
| `gt`       | build  | Graphite stacked PRs.                              |
| `smart`    | build  | Heuristic 2-line summary — generic.                |
| `summary`  | build  | Heuristic command summary — generic.               |
| `deps`     | build  | Dependency summary.                                |
| `err`      | build  | Generic errors/warnings-only runner.               |

## Not pantry plugins — RTK meta/infra (lowfat-native or N/A)

These are RTK's own management surface, not command filters. Lowfat covers the equivalents
differently (config, trust, history, hooks) or they don't apply.

`init`, `config`, `gain`, `cc-economics`, `discover`, `session`, `telemetry`, `learn`,
`run`, `proxy`, `pipe`, `trust`, `untrust`, `verify`, `hook`, `hook-audit`, `rewrite`,
`help`.

Mapping notes:

- `trust`/`untrust`/`verify` → lowfat `trusted.toml` (per-plugin name, **not** content
  hash — security regression to design around).
- `gain`/`discover`/`session`/`cc-economics` → lowfat `stats`/`history` (analytics parity
  is Tier-3 at best).
- `hook`/`hook-audit`/`rewrite`/`init` → lowfat shell/agent integration setup.
- `run`/`proxy`/`pipe` → lowfat passthrough + `lowfat pipe` equivalents.
