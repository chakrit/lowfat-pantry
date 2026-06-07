# lowfat-pantry — Plugin Backlog

Source: RTK `0.42.0` command surface (`rtk --help`), sorted into pantry plugin
candidates. Priority is a rough first pass on frequency × school-stack fit × filtering
payoff. **You drive final prioritization** — these tiers are a starting proposal, not a
commitment.

Legend:

- **bundled** — lowfat `v0.6.8` already ships a plugin; work is *enhance/verify*, not build.
- **build** — no lowfat coverage; net-new plugin.
- **fold** — likely collapses into another plugin rather than standing alone.

## Tier 0 — Universal, every session, high bloat

| Command | Status   | Notes                                                                 |
| ------- | -------- | --------------------------------------------------------------------- |
| `git`   | bundled  | Only 4 subcommands specialized; rest hit 30-line cap. Top enhance.    |
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
