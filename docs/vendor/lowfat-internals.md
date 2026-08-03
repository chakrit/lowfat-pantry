# lowfat internals (v0.8.0)

Engineer-facing reference for what the `lowfat` tool *is*, derived from the
v0.8.0 crate sources. Citations are `file:line` into the unpacked crates
(`lowfat`, `lowfat-compress`, `lowfat-core`, `lowfat-plugin`, `lowfat-runner`),
re-anchored on 2026-07-26.

**Delta from v0.6.8**, the version this file previously tracked: a fifth crate
(`lowfat-compress`) and the `post-read` hook that uses it; `include` in the `.lf`
DSL (see the DSL reference); everything else is refactor and reflow. The two
things the pantry depends on are unchanged — `level.rs` is byte-identical
(15/30/60), and `lowfat hook` still auto-approves.

## What and why

`lowfat` is a token-aware command-output filter for LLM coding environments.
It wraps a shell command (`lowfat git status`), runs the real binary, captures
combined stdout+stderr, pipes that through a filter chosen by command name, and
prints the compacted result — shrinking the tokens an agent spends reading
routine command output. It is the successor to **RTK** (Rust Token Killer):
same job (intercept-run-compact), but filters are now authored as data in a
small DSL (`.lf` files) rather than baked-in Rust, so new commands ship as
plugins without recompiling the binary. The SQLite schema is explicitly "same
schema as the bash version" (`db.rs:5`), confirming the lineage.

The core invariant throughout: **a filter never makes output worse than no
filter at all.** Parse errors, exec errors, and runtime errors all degrade to
passthrough (`lf_filter.rs:51-64`, `run.rs:125-128`).

## Architecture: the crate split

Five crates, clean layering (lower crates never depend on higher):

- **`lowfat-core`** — the engine, no I/O orchestration. Owns the `.lf` DSL
  parser+executor (`lf.rs`), intensity `Level` (`level.rs`), `.lowfat` config
  resolution (`config.rs`), the built-in pipeline processors and pipeline
  model (`pipeline.rs`), secret redaction (`redact.rs`), token estimation
  (`tokens.rs`), the SQLite tracking DB (`db.rs`), and failure-tee (`tee.rs`).
- **`lowfat-plugin`** — the plugin model. Owns the `lowfat.toml` manifest
  schema (`manifest.rs`), disk+embedded discovery and precedence
  (`discovery.rs`), the trust/security model (`security.rs`), the six bundled
  reference filters (`embedded.rs` + `embedded/`), and the `FilterPlugin`
  trait + `FilterInput`/`FilterOutput` types (`plugin.rs`).
- **`lowfat-runner`** — execution glue. `HybridRunner::load` turns a discovered
  plugin into a runnable `Box<dyn FilterPlugin>` (`runner.rs`), `LfFilter` runs
  `.lf` rulesets in-process (`lf_filter.rs`), `ProcessFilter` runs legacy
  `filter.sh` plugins as subprocesses (`process.rs`), and `execute_pipeline`
  chains stages (`runner.rs:70`).
- **`lowfat-compress`** *(new in v0.8.0)* — content-aware compression of **file
  text**, not command output, and deliberately standalone: "no dependency on
  lowfat internals" (`lowfat-compress/src/lib.rs:4`), with its own `Level` enum mirroring
  `lowfat-core`'s. `compress(content, file_path, level)` routes by detected
  `ContentType` — `Code(LangId)` / `Markdown` / `Html` / `Data` / `Lock` /
  `Unknown` — to a per-type module (`code.rs`, `markdown.rs`, `html.rs`,
  `data.rs`, `lock.rs`, `text.rs`). Two guardrails worth copying: it returns the
  **original** if compression would yield empty output, and again if it saved
  less than 10% (`lowfat-compress/src/lib.rs:28-56`).
- **`lowfat`** (the CLI) — `clap` surface (`main.rs`), the filter run path
  (`commands/run.rs`), and all subcommand handlers (`commands/`).

## The plugin model

### Manifest schema (`manifest.rs`)

`lowfat.toml` (or legacy `init.toml`) — every field:

```toml
[plugin]
name        = "git-compact"   # required; identity for trust + shadowing
version     = "1.2.0"         # optional
description = "..."           # optional
author      = "..."           # optional
category    = "git"           # optional (in manifest); but see note below
commands    = ["git"]         # required; which commands this plugin intercepts
subcommands = ["status","diff"] # optional; limits in_scope tracking, not matching
bin         = "kubectl"       # optional; real binary to exec for shorthand cmds

[runtime]
entry    = "filter.lf"        # optional; auto-detected if omitted
requires = { python = ">=3.10" } # optional; checked by `plugin doctor`

[hooks]                        # optional; lifecycle commands
on_install = "chmod +x filter.sh"
on_update  = "..."
on_remove  = "..."

[pipeline]                     # optional; pre/post built-in processors
pre  = ["strip-ansi"]
post = ["truncate"]
```

Notes that bite:
- `category` is a field on `PluginMeta` (`manifest.rs:23`), but for **disk**
  plugins the effective category is the *directory name*, not this field —
  `scan_plugin_dir` sets `category` from the filesystem path
  (`discovery.rs:112,155`). For **embedded** plugins it comes from the
  `EmbeddedPlugin.category` const (`embedded.rs:29`). The manifest field is
  largely vestigial on disk.
- `bin` lets `commands = ["kubectl","k"]` exec the real `kubectl` even when
  invoked as the shell alias `k` (`manifest.rs:25-28`, used at `run.rs:36-39`).
- `subcommands` does **not** gate filter selection — selection is by `commands`
  only. It only feeds `in_scope` history accounting (`run.rs:147-150`,
  `known_subcommands`). Subcommand *matching* happens inside the `.lf` file.

### Entrypoint resolution (`manifest.rs:50-53`)

`RuntimeConfig::resolve_entry`:
1. explicit `runtime.entry` always wins;
2. else `filter.lf` if it exists on disk (the modern format);
3. else `filter.sh` (legacy shell plugins keep loading without a manifest edit).

`HybridRunner::load` then dispatches by extension: `.lf` → in-process `LfFilter`;
anything else → `ProcessFilter` spawning `sh <entry>` (`runner.rs:35-40`).
Embedded plugins are always `.lf`, loaded from the in-memory string.

## Discovery and precedence

### Where disk plugins live — confirmed

`plugin_dir = home_dir.join("plugins")` (`config.rs:50`). The contested part is
`home_dir`, resolved by `resolve_home_dir` (`config.rs:197-205`) with this
precedence, **highest first**:

1. `$LOWFAT_HOME` — explicit override.
2. `$XDG_CONFIG_HOME/lowfat` — if `XDG_CONFIG_HOME` is set (used even if the
   dir doesn't exist yet).
3. `~/.config/lowfat` — only if that directory **already exists**.
4. `~/.lowfat` — fallback otherwise.

So the real answer to "`~/.lowfat` vs `~/.config/lowfat`?" is **both are real,
and it's resolution-order dependent.** On a machine with no XDG env and no
pre-existing `~/.config/lowfat/`, plugins live at
`~/.lowfat/plugins/<category>/<name>/`. If `~/.config/lowfat/` exists (or
`XDG_CONFIG_HOME` is set), it's `~/.config/lowfat/plugins/...`. When both
`~/.config/lowfat/` and `~/.lowfat/` exist, XDG wins and a one-shot stderr
warning fires (`config.rs:224-236`).

The doc comments in `discovery.rs:8` and `embedded.rs:7` hardcode `~/.lowfat/`;
those are simplifications — `config.rs` is authoritative. Note also `~/.lowfat`
is overloaded: as a **directory** it's the plugin home; as a **file** it's the
`.lowfat` pipeline config discovered by walking up from cwd (`config.rs:164-170`).
`resolve_home_dir` only treats it as home when it's a directory.

Data dir is separate: `$LOWFAT_DATA` > `$XDG_DATA_HOME/lowfat` >
`~/.local/share/lowfat` (`config.rs:41-48`) — that's where the SQLite DB and
failure-tee live.

### Layout and shadowing

Disk layout: `plugin_dir/<category>/<plugin-name>/lowfat.toml` (or `init.toml`).
`scan_plugin_dir` walks two levels (category dir, then plugin dir), takes the
first manifest per plugin dir, and `break`s — one plugin per dir
(`discovery.rs:101-111`).

`discover_plugins` merges disk + embedded: it scans disk first, then appends
each embedded plugin **only if its name isn't already taken by a disk plugin**
(`discovery.rs:59-73`). **Disk wins on name collision** — drop a `git-compact`
into `<home>/plugins/git/git-compact/` and it shadows the bundled one.

`resolve_plugins` builds the `command → plugin` map; if two plugins claim the
same command, **last one wins** (`discovery.rs:162-167`) — and since embedded
are appended after disk, a disk plugin claiming the same command also wins here.

## Trust / security model (`security.rs`)

Trust is **name-based, not content-hash.** `trusted.toml` lives at
`home_dir/trusted.toml` (`security.rs:123-125`) and is a flat list of trusted
plugin *names* (one per line; `is_trusted` does a line-equality check,
`security.rs:127-133`). `lowfat plugin trust <name>` appends the name;
`untrust` removes it. There is no hashing — re-trusting is unnecessary after the
plugin's content changes, which is a deliberately loose model.

Where trust actually gates (`run.rs:182-194`, `resolve_filter`):
- A trusted external plugin **overrides a same-named builtin**. This is the only
  thing trust unlocks — replacing a bundled/native filter.
- An *untrusted* external plugin may still apply **when there is no builtin for
  that command** (no shadowing involved, so no trust needed).
- For all six bundled commands (git/docker/ls/find/grep/tree) a builtin exists,
  so a user plugin for those commands needs trust to take effect.

Load-time security checks, independent of trust, run for every disk plugin
(`runner.rs:44`, `security.rs:21-25`):
- **Path-traversal**: `entry` must be relative, no `..`, and canonicalize to a
  path inside the plugin dir (`security.rs:28-33`).
- **Dangerous-hook scan**: rejects `rm -rf /`, `curl … | bash`, fork bombs, etc.
  in `on_install`/`on_update`/`on_remove` (`security.rs:59-106`).
- **Env sanitization**: `ProcessFilter` — the legacy `filter.sh`-style disk
  plugin path — runs with a scrubbed env, only an allowlist passing
  (`sanitized_env`, `security.rs:189`; applied at `process.rs:22` behind
  `env_clear()`). **`.lf` `shell:`/`python:` ops do not go through it**: they
  inherit the full parent env (`run_shell`, `lf.rs:1804-1808`). Corrected
  2026-07-26 — the two paths were previously described as one, which is what
  made cross-filter delegation look impossible.

## Levels (`level.rs`)

Three intensities; **`full` is the default** (`level.rs:11`). Resolution order:
`$LOWFAT_LEVEL` > `.lowfat` `level=` line > default (`config.rs:52,114-119`).

The numeric mechanism is `Level::head_limit(base)` (`level.rs:19-24`):

| level | factor          | base 40 | base 30 | base 200 |
|-------|-----------------|---------|---------|----------|
| lite  | `base * 2`      | 80      | 60      | 400      |
| full  | `base`          | 40      | 30      | 200      |
| ultra | `max(base/2,5)` | 20      | 15      | 100      |

Baselines in use:
- `.lf` `head auto` / `tail auto` → `level.head_limit(30)` → **15 / 30 / 60**
  (`lf.rs:1675`).
- The single-filter `FilterInput.head_limit` passed to plugins →
  `level.head_limit(40)` → **20 / 40 / 80** (`run.rs:120`). (Note: `.lf`
  filters ignore this field and use their own `head N` / `head auto`; it's only
  meaningful to legacy `filter.sh` plugins, exposed there as no env var — they
  read `$LOWFAT_LEVEL` and decide themselves.)
- Built-in pipeline processors: `head` base 40 (20/40/80), `truncate` base 200
  (100/200/400), `token-budget` 2000/1000/500 tokens (`pipeline.rs:414-427`).

## Execution pipeline

The happy path (`commands/run.rs:16-25`):

1. `RunfConfig::resolve()` — load `.lowfat` config, level, plugin/data dirs,
   install the redaction ruleset (`config.rs:30-68`).
2. If the command is disabled / not whitelisted → `passthrough` (still tracked).
3. Discover external plugins; compute `exec_bin` (honoring `bin`).
4. Run the real command via `exec_command`, capturing combined stdout+stderr
   and exit code (`runner.rs:121-130`).
5. **Tiny-output short-circuit**: if estimated tokens < 128, skip filtering
   entirely — overhead would exceed any savings (`run.rs:51-66`).
6. `resolve_filter` picks the filter name + external flag (trust logic above).
7. `resolve_pipeline` builds the stage chain (below).
8. Build the `plugin_map` (builtins + any needed external plugins), construct
   `FilterInput`, run `execute_pipeline`.
9. Track metrics + usage history into SQLite; tee raw output on failure; print
   filtered text; return the **original command's exit code** (`run.rs:171-172`).

### Pipeline resolution and stages

A `Pipeline` is an ordered list of `PipelineStage`s, each either `Builtin`
(in-process) or `Plugin` (`pipeline.rs:56-65`). `resolve_base_pipeline`
(`run.rs:235-248`) picks, in order: a `.lowfat` conditional pipeline → the
plugin manifest's `[pipeline]` pre/post → a single-filter pipeline → bare
`passthrough`. `resolve_pipeline` then **prepends** the wildcard
`pipeline.* = …` stages so always-on processors (e.g. `redact-secrets`) fire on
every command without clobbering per-command config (`run.rs:208-228`).

Conditional pipelines (`.lowfat` `pipeline.<cmd>.<cond>`) select by result:
`error` (exit≠0) → `empty` (no output) → `large` (>1000 est. tokens) → default
(`pipeline.rs:24-30, 145-159`).

`execute_pipeline` (`runner.rs:70-87`) walks stages: a plugin with the same
name as a stage wins (lets users override any builtin); else `apply_builtin`
runs the in-process processor; unknown plugin stages are skipped (passthrough).
A final `proc_normalize` trims trailing whitespace and collapses blank runs.

Built-in processors (`pipeline.rs:209-212, 390-428`): `strip-ansi`, `truncate`,
`head`, `token-budget`, `dedup-blank`, `normalize`, `redact-secrets`, `grep`,
`grep-v`, `cut`, `passthrough`. Stage params use `name:param` syntax
(`truncate:100`, `grep:^error`) (`pipeline.rs:178-189`).

### Redaction (`redact.rs`)

`redact-secrets` is a **trusted in-process Rust** processor, deliberately not a
plugin — a plugin degrades to passthrough on error, and for redaction that
means *leaking* (`redact.rs:8-12`). Patterns layer: built-in defaults <
`<home>/redact.conf` < project `redact.conf` beside `.lowfat`
(`redact.rs:3-7`, installed at `config.rs:121-125`). Defaults cover AWS keys,
GitHub/GitLab/Slack tokens, bearer tokens, JWTs, PEM private keys, basic-auth
URLs, etc. (`redact.rs:44-80`). Custom rules use `<regex> => <replacement>`;
`!no-defaults` drops the baseline (`redact.rs:93-105`).

## Claude Code integration

Three mechanisms. Two rewrite commands through one canonical rewrite function;
the third compresses file reads and shares nothing with them:

- **`lowfat hook`** — a PreToolUse hook (`commands/hook.rs`). Reads the hook
  JSON from stdin, and only for `tool_name == "Bash"` rewrites
  `tool_input.command` via `rewrite_command`, emitting a `PreToolUse` /
  `permissionDecision: allow` / `updatedInput.command` response
  (`hook.rs:31-42`). Non-Bash or no-filter cases pass through untouched.
- **`lowfat shell-init <shell>`** — prints an `eval`-able init script
  (`commands/shell_init.rs`). When `$CLAUDECODE==1` / `$CODEX_ENV` set /
  `$LOWFAT_ENABLE==1`, it queries `lowfat filters --commands` and defines a
  wrapper function per filtered command so `git …` transparently becomes
  `lowfat git …`. Supports bash/zsh (POSIX) and fish.
- **`lowfat post-read`** *(new in v0.8.0)* — a **PostToolUse** hook for the
  `Read` tool (`commands/post_read.rs`). Reads the hook JSON from stdin, pulls
  `tool_response.file.content`, and runs it through `lowfat-compress` at the
  configured level. Anything that isn't non-empty text content — image reads,
  notebook payloads, a missing `file_path` — returns early and passes through
  untouched. Note this compacts what the agent *reads from disk*, a separate
  axis from the command-output filtering the rest of this document describes;
  the pantry's `.lf` plugins have no bearing on it.

`rewrite_command` (`commands/rewrite.rs:8-14`) is the single source of truth,
shared by the hook, the `lowfat rewrite` CLI, and the OpenCode plugin. It
returns `Some("lowfat <cmd>")` iff a builtin, a discovered plugin, a
`pipeline.<cmd>` config, **or** a `pipeline.*` wildcard applies — and `None`
(pass through) otherwise. It refuses to double-wrap (`lowfat`/`lf` prefixes).

It also does no shell parsing at all — the return is `format!("lowfat {command}")`
over the whole string, and the decision keys on `command.split_whitespace().next()`.
So every trailing shell construct ends up bound to *lowfat's* stdout rather than the
tool's: `pnpm test > /tmp/t.txt 2>&1` rewrites to `lowfat pnpm test > /tmp/t.txt 2>&1`
and the file receives the compacted stream, truncation marker included. A trailing
`| grep …` is filtered before grep sees it, the same way. Capture-then-read is the
workflow this breaks — the file exists precisely to hold what a compact read drops,
and nothing downstream can recover it. Keying on the first word cuts the other way
too: `command pnpm test`, `env FOO=1 pnpm test`, and `FOO=1 pnpm test` are all left
unwrapped, which is where the escape hatch comes from.

`lowfat opencode install|uninstall` manages an OpenCode plugin at
`~/.config/opencode/plugins/lowfat.ts` (`main.rs:218-223`).

## Token accounting, stats, history (`tokens.rs`, `db.rs`)

Token estimate is the cheap `(len + 3) / 4` heuristic (~4 chars/token,
`tokens.rs:3`) — matches the old bash `(len+3)/4`. Not a real tokenizer; it's a
proxy for savings reporting and the large-output threshold.

Every run records two things into SQLite (`run.rs:133-165`):
- a `TrackRecord` (original vs lowfat command, raw/filtered text, exec time,
  project path) powering `stats` savings reports;
- an `InvocationRecord` (command, normalized subcommand, raw/filtered tokens,
  `had_plugin`, `in_scope`, `reduced`, `is_external_plugin`, exit code)
  powering `history` and plugin-candidate ranking.

The `invocations` table is capped at 10,000 rows (oldest evicted,
`db.rs:78`). `history prune` selectively deletes by age / usage / plugin-covered
/ all (`db.rs:80-92`, `main.rs:168-186`) without touching lifetime gain totals.
`history candidates` ranks `(command, subcommand)` groups as plugin candidates
by run count and token volume (`candidates.rs`); subcommand normalization for
grouping is heuristic unless the plugin declares `subcommands`
(`run.rs:297-300`).

## CLI surface (`main.rs`)

One line each:

- **`info [cmd] [--config]`** — status badge + active filters; per-command
  pipeline with `cmd`; full resolved config with `--config`.
- **`stats [--audit] [--audit-limit N]`** — token-savings summary, or recent
  plugin executions with `--audit`.
- **`history [candidates|export|prune] …`** — local usage history; `candidates`
  ranks plugin candidates, `export` dumps JSON, `prune` deletes selectively.
- **`level [lite|full|ultra]`** — get or set intensity.
- **`hook`** — Claude Code PreToolUse hook (reads JSON from stdin).
- **`post-read`** — Claude Code PostToolUse hook for `Read`; compresses file
  content via `lowfat-compress`.
- **`rewrite <cmd…>`** — print the lowfat-wrapped form (or the command
  unchanged if no filter applies).
- **`opencode install|uninstall`** — manage the OpenCode integration.
- **`shell-init [bash|zsh|fish]`** — print the shell init script for `eval`.
- **`plugin list|doctor|info|trust|untrust|bench|new`** — plugin management.
- **`filter <path.lf> [--sub --level --args --exit --explain]`** — run a `.lf`
  file against stdin standalone (the plugin-author test harness; `--explain`
  prints per-stage diagnostics).
- Hidden back-compat aliases route to the new commands: `config`→`info --config`,
  `status`→`info`, `pipeline <cmd>`→`info <cmd>`, `filters [--commands]`,
  `gain`→`stats`, `audit`→`stats --audit` (`main.rs:119-129, 283-297`).
- Bare `lowfat <cmd> <args…>` (no subcommand) is the filter run path
  (`main.rs:300-307`).
