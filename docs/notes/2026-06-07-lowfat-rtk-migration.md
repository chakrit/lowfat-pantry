# Lowfat as an RTK Replacement

Research date: 2026-06-07

Upstream projects:

- lowfat: <https://github.com/zdk/lowfat>
- RTK: <https://github.com/rtk-ai/rtk>

Versions reviewed:

- lowfat `v0.6.8`, released 2026-06-05
- RTK `v0.42.3`, released 2026-06-05
- Locally installed RTK: `0.42.0`

## Summary

Lowfat can replace RTK for this repository, but it is not a drop-in binary replacement.
RTK is a broad, batteries-included command wrapper. Lowfat is a smaller interception and
filtering framework with six bundled command plugins and a substantially more expressive
extension system.

Full RTK surface parity is technically possible only by treating the work as a maintained
plugin distribution, potentially with lowfat core contributions. The practical target
should be workload parity: cover commands actually used by ACE agents and subscribing
projects, then expand from measured history.

Do not remove RTK before the required lowfat plugins have been built, benchmarked, and
exercised through an agent integration.

## Bundled Coverage

Lowfat `v0.6.8` bundles plugins for:

- `git`
- `docker`
- `grep`
- `find`
- `ls`
- `tree`

Its bundled git plugin specializes only:

- `git status`
- `git diff`
- `git log`
- `git show`

Other sufficiently large git output falls through a generic 30-line cap. That behavior
needs evaluation before school-wide adoption.

RTK currently has specialized implementations for more than 100 command workflows,
including:

- GitHub and GitLab CLIs
- Cargo, Go, Python, Ruby, JavaScript, and.NET tooling
- Test runners and linters
- Package managers
- Docker and Kubernetes
- AWS and database clients
- JSON, environment, log, file-reading, and HTTP workflows

The most immediate lowfat coverage gap for this school is `rg`. The engineering
instructions explicitly prefer `rg`, while lowfat's bundled grep plugin claims only the
`grep` command.

## Configuration Comparison

| Capability            | RTK                                        | lowfat                                     |
| --------------------- | ------------------------------------------ | ------------------------------------------ |
| Project configuration | `.rtk/filters.toml`                        | nearest ancestor `.lowfat`                 |
| Custom matching       | full-command regex                         | command pipelines or plugin selectors      |
| Basic filtering       | replace, keep/drop, limits, ANSI stripping | composable in-process pipeline processors  |
| Complex filtering     | dedicated Rust handlers                    | `.lf`, POSIX shell, or Python              |
| Conditions            | output matching                            | exit, empty, large, level, and flag guards |
| Compression levels    | global flags                               | `lite`, `full`, and `ultra`                |
| Global filtering      | user-global TOML filters                   | plugins and `pipeline.*`                   |
| Secret redaction      | command-specific masking                   | configurable `redact-secrets` processor    |
| Failure tee           | configurable                               | built in with fixed thresholds             |
| Hook exclusions       | command and subcommand patterns            | command-level disable only                 |
| Tracking controls     | enablement, retention, and DB path         | data path and manual history pruning       |
| Display controls      | colors, emoji, and width                   | none                                       |
| Filter tests          | inline tests and `rtk verify`              | samples, `filter --explain`, bench, doctor |
| Trust                 | project filter content hash                | per-plugin name                            |
| Agent integrations    | approximately 14 agents                    | Claude Code, OpenCode, shell, and Pi       |
| Telemetry             | optional                                   | none                                       |

## Lowfat Configuration Surface

### Project `.lowfat`

Lowfat walks upward from the current directory and uses the nearest `.lowfat` file.

```ini
level=full
disable=command-a,command-b
filters=git,docker

pipeline.deploy = strip-ansi | grep:^(Deploy|ERROR|FAIL) | head:20
pipeline.deploy.error = strip-ansi | head:80
pipeline.deploy.empty = passthrough
pipeline.deploy.large = grep:ERROR|FAIL | token-budget:500

pipeline.* = redact-secrets
```

`disable` is a blacklist. `filters` enables whitelist mode. They should not be used
together.

Available pipeline processors:

- `grep:<regex>`
- `grep-v:<regex>`
- `head:<lines>`
- `truncate:<lines>`
- `cut:<fields>`
- `strip-ansi`
- `token-budget:<tokens>`
- `dedup-blank`
- `normalize`
- `redact-secrets`
- `passthrough`

Conditional suffixes:

- `.error`: command exited non-zero
- `.empty`: output was empty
- `.large`: output exceeded approximately 1,000 tokens

### Environment

| Variable          | Purpose                                                  |
| ----------------- | -------------------------------------------------------- |
| `LOWFAT_LEVEL`    | Override `lite`, `full`, or `ultra`                      |
| `LOWFAT_DISABLE`  | Disable comma-separated command filters                  |
| `LOWFAT_HOME`     | Override plugin and configuration home                   |
| `XDG_CONFIG_HOME` | Select `$XDG_CONFIG_HOME/lowfat` as configuration home   |
| `LOWFAT_DATA`     | Override history database and failure tee data directory |
| `LOWFAT_ENABLE`   | Force shell integration outside detected agent shells    |

### Plugin Formats

A plugin lives beneath:

```text
~/.lowfat/plugins/<category>/<plugin>/
```

It contains:

```text
lowfat.toml
filter.lf
samples/
```

`filter.sh` is also supported as a legacy or escape-hatch implementation.

The `.lf` DSL supports:

- subcommand selectors and globs
- first-match rule ordering
- `keep`, `drop`, `head`, `tail`, `or`, `raw`, and `split`
- reusable `define` macros
- conditions on exit status, compression level, and command flags
- inline shell processors
- inline Python, including PEP 723 dependencies executed through `uv`

Plugin manifests can declare:

- command names and aliases
- supported subcommands
- an alternate real executable
- Python and `uv` runtime requirements
- installation hooks
- pipeline pre- and post-processors

Plugins are checked with:

```sh
lowfat plugin doctor
lowfat plugin bench <plugin>
lowfat filter --explain <filter.lf> --sub=<subcommand> --level=<level>
```

## RTK Features Without Direct Parity

The following require plugins, lowfat core changes, or separate integration work:

- RTK's broad set of specialized command parsers
- intelligent source-file reading and signature extraction
- structured JSON, environment, dependency, and HTTP summaries
- agent integrations beyond Claude Code, OpenCode, shell, and Pi
- subcommand-specific automatic rewrite exclusions
- configurable failure tee modes, directory, and rotation
- tracking enablement and automatic retention settings
- output color, emoji, and width settings
- RTK session adoption and missed-rewrite analysis
- project filter trust tied to content changes

Lowfat does save raw output for failed commands, despite this being less visible in its
user documentation. In `v0.6.8`, it saves output when:

- the command exits non-zero
- raw output is at least 500 characters
- a maximum of 20 files is retained

The files are stored under `$LOWFAT_DATA/tee`.

## Security Notes

Lowfat external plugins can execute shell or Python code. Trust is recorded by plugin name
in `trusted.toml`; it is not tied to a content hash. A trusted plugin can therefore change
without requiring another trust review.

Lowfat does:

- prevent plugin entry path traversal
- reject a small set of dangerous installation hook patterns
- sanitize the environment passed to plugin processes
- omit common credential variables from plugin environments

Project `.lowfat` pipelines are not trust-gated. Pipelines can reference plugins, so
repository-controlled configuration and installed plugins should be reviewed together.

## Current School Repository Migration Scope

The current `.rtk/filters.toml` contains only a commented template. There are no active
project-specific RTK filters to translate.

A migration would need to address:

- `skills/rtk/SKILL.md`
- the RTK section in `CLAUDE.md`
- `RTK.md`
- `.rtk/filters.toml`
- the `rtk` skill entry in `ace.toml`
- the explicit RTK bypass in `skills/ace-connect/SKILL.md`

The lowfat replacement skill should cover:

- installation detection and supported installation methods
- project `.lowfat` detection
- shell or agent integration setup
- plugin directory and trust state
- project pipeline validation
- plugin health and benchmarks
- measured command coverage
- removal or coexistence of RTK hooks

## Suggested Plugin Baseline

The first plugin set should be based on school and ACE workflows rather than RTK's entire
catalog.

Priority 1:

- `rg`
- `gh`
- `git` coverage beyond the four bundled subcommands
- `cargo`
- generic test execution
- generic lint and format execution

Priority 2:

- `npm`, `pnpm`, and `npx`
- `pytest`
- Go build and test
- `curl`
- JSON inspection
- environment inspection with secret masking
- `kubectl`

Priority 3:

- remaining RTK language ecosystems and infrastructure tools
- additional agent integrations
- source-aware file reading
- session adoption and missed-rewrite analytics

## Proposed Migration

1. Install lowfat without removing RTK.
2. Start with direct `lowfat <command>` usage.
3. Add a project `.lowfat` using `level=full`.
4. Enable `pipeline.* = redact-secrets` only after checking its behavior on structured
   output.
5. Build `rg`, `gh`, and generic test/build plugins.
6. Capture representative output in plugin sample directories.
7. Test all three compression levels and non-zero exit paths.
8. Benchmark plugins and verify that actionable diagnostics remain.
9. Run lowfat and RTK side by side on actual ACE sessions.
10. Compare `lowfat stats/history` against `rtk gain/discover`.
11. Enable transparent shell or agent rewriting after coverage is sufficient.
12. Replace school instructions and remove RTK artifacts last.

## Definition of Workload Parity

Lowfat is ready to replace RTK for the school when:

- common ACE commands are transparently rewritten
- `rg`, `gh`, git, build, test, lint, and format workflows are covered
- failures preserve enough diagnostic context or expose saved raw output
- no command silently loses machine-readable output
- plugins have captured samples and repeatable benchmarks
- shell commands used by `ace-connect` remain unfiltered where required
- installation and trust instructions work across supported environments
- measured token savings are comparable to RTK on real sessions
- RTK can be removed without relying on undocumented user-global state

## Full Parity Estimate

Covering RTK's complete surface is possible, but it is a software product rather than a
configuration exercise. It requires:

- dozens of command-family plugins
- fixtures for success, failure, warnings, and structured output
- compatibility testing across tool versions and operating systems
- benchmarks at all three lowfat levels
- agent-specific interception adapters
- maintenance as upstream command output changes
- likely changes to lowfat core for missing runtime and configuration controls

The recommended implementation goal is a reusable `lowfat-pantry` plugin pack, expanded from
measured usage. Attempting feature-for-feature RTK parity before deployment would create a
large maintenance burden without proving that the unused command surface provides value.

## Sources

- lowfat README: <https://github.com/zdk/lowfat/blob/main/README.md>
- lowfat configuration: <https://github.com/zdk/lowfat/blob/main/docs/CONFIG.md>
- lowfat plugin system: <https://github.com/zdk/lowfat/blob/main/docs/PLUGINS.md>
- RTK README: <https://github.com/rtk-ai/rtk/blob/master/README.md>
- RTK configuration:
  <https://github.com/rtk-ai/rtk/blob/master/docs/guide/getting-started/configuration.md>
- RTK custom filter reference:
  <https://github.com/rtk-ai/rtk/blob/master/src/filters/README.md>
