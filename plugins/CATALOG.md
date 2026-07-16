# Pantry catalog — all 64 plugins

What each plugin actually does beyond a dumb head-cap, and the gotchas to know before
trusting it. Grouped by area; every plugin scales across `ultra`/`full`/`lite` and ships
samples + a `tests.cue` smoke golden spec. Conventions and layout: [README.md](README.md). Bundled lowfat
plugins (git, docker, grep, find, ls, tree) are not listed here.

## VCS / forges

- **rg** — caps recursive match lists (piped rg emits one `path:line:text` per line).
  Gotcha: exit 1 means *no matches*, not failure — you get a "no matches" verdict, while
  exit 2 (bad regex/path) passes the error through raw. `--json` (ndjson stream) passes
  byte-exact (invariant 1).
- **gh** — compacts list tables and view/log bodies; one rule covers all resource
  subcommands (`pr`/`issue`/`run`/…). Gotchas: `--json` passes byte-exact; CI `--log`
  is tail-anchored (failures sit at the end); non-zero exits stay raw.
- **glab** — sibling of `gh` for GitLab. Same invariants: `-F json`/`--output json`
  byte-exact; `glab ci trace` tails, not heads.

## Rust

- **cargo** — drops per-crate `Compiling`/`Downloading` progress; keeps diagnostics with
  their `-->` location and `help:`/`note:` context, `Finished`, test failures +
  `test result:`. Gotcha: `cargo run` output is your program's stdout — only capped,
  never keyword-filtered. `--message-format json` and `metadata` pass byte-exact
  (invariant 1; `--message-format short`/`human` still compact).

## TypeScript / JavaScript

- **tsc** — keeps `path:line:col - error TSxxxx` lines, `Found N errors`, and the
  `--pretty` per-file table; drops the code-frame (source line + `~~~~` underline).
  Gotcha: a clean `--noEmit` run prints nothing — you get a clean verdict, not silence.
- **eslint** — drops blank separators and head-caps stylish output. Gotcha: deliberately
  does NOT keyword-filter — exit guards can't tell 1 (problems) from 2 (config crash),
  and a filtered crash would read as "clean". `--format json` passes byte-exact.
- **prettier** — compacts only `--check`/`--write` status lists. Gotcha: bare
  `prettier <file>` prints the formatted file itself — that passes through untouched
  (capping would corrupt code).
- **npm** — drops install progress (`npm http`/`notice`/`timing`); keeps
  added/removed/audited counts, funding/vulnerability totals, and all warn/error lines.
  `--json` passes byte-exact on any subcommand (invariant 1).
- **pnpm** / **yarn** — same shape as npm for their own progress formats. Gotcha (yarn):
  `run`/`test` bodies are your script's output — only the `$ <cmd>` echo is dropped,
  failures tail (errors land at the end). pnpm `--json` (`ls`/`audit`/`outdated`) passes
  byte-exact (invariant 1).
- **bun** — install keeps the `N packages installed` summary over the `+ pkg@ver` list;
  test keeps failing specs + tallies, drops `✓` lines at ultra. `run`/`build`/`x` bodies
  are never keyword-filtered. (No `--json` guard: bun ignores `--json` on these and emits
  text — verified, not applicable.)
- **npx** — wrapper-aware (like `uv`): strips npm install/fetch preamble, detects the
  wrapped tool from args (handling `-y`, `-p typescript`), and dispatches — eslint/prettier/
  tsc logic **ported** from their standalone filters under a drift contract (filter header).
  Bare `npx prettier <file>` and `-f json` pass through raw (no code/JSON corruption);
  unknown tools (`create-*`, etc.) get a conservative cap. Gotcha: the ported bodies drift
  if the originals change — real fix is wrapper-unwrap in lowfat-core (proposed upstream).
- **next** — keeps build warnings/errors and summaries; trims the route table at ultra.
- **prisma** — strips banner/box art; keeps migration progress, client-generation
  markers, and `Error:` lines.
- **playwright** — keeps failing specs, diagnostics, and the run summary. `--reporter=json`
  /`junit` passes byte-exact (invariant 1; a reporter set in playwright.config isn't
  visible to the filter — residual).
- **deno** — test keeps `FAILED`/`failures:`/`test result:` and assertion lines, drops
  per-test `... ok`; `run`/`task` bodies only capped, tail on failure. `--json`
  (`lint --json`, `info --json`) passes byte-exact (invariant 1).
- **jest** / **vitest** — test-runner shape (like pytest): passing runs collapse to a
  one-line tally (`jest: N passed, N total`), failures keep the failing-test block + final
  summary, drop per-suite `PASS ` noise; ultra trims to `FAIL` headers + assertion lines.
  jest `--json`/`--outputFile` and vitest `--reporter=json|junit`/`--outputFile` pass
  byte-exact (invariant 1). Gotcha: ultra matchers are ASCII-only — a non-ASCII literal in
  a `.lf` macro body is mangled by lowfat 0.6.8's `$N` arg-expansion (fix proposed upstream);
  full/lite keep the block wholesale so glyph lines survive via passthrough.

## Python

- **pytest** — keeps the FAILURES/ERRORS sections and short-summary lines; passing runs
  collapse to a one-line `pytest: N passed` verdict. Ultra trims to failure headers +
  assertion (`E `) lines.
- **ruff** — keeps default text findings, caps long lists, clean runs get a verdict.
  `--output-format json`/`--format` passes byte-exact (invariant 1; without it a clean
  `--output-format json` run collapsed `[]` to "ruff: clean").
- **mypy** — keeps errors and the final summary; drops `note:` lines at ultra only.
- **black** — keeps which files changed + the summary. Gotcha: exit 1 just means
  `--check` found unformatted files; exit 123 (parse error) is guarded so it's never
  hidden by the keep-list.
- **pip** — drops resolver chatter (`Collecting`, `Downloading`, `Requirement already
  satisfied`); keeps `Successfully installed`/`Installing collected` and errors.
  Gotcha: a fully-cached install can compact to just `pip: ok`. `--format json` (e.g.
  `pip list --format json`) passes byte-exact (invariant 1).
- **uv** (also `uvx`) — wrapper-aware: parses the arg string to find the wrapped tool
  (`uv run pytest`, `uvx ruff`, `uv tool run`, `python -m`, skipping value-flags like
  `--with X`) and applies that tool's compaction — pytest/ruff logic is **copied** from
  their standalone filters under a drift contract (filter header). uv's own
  `sync`/`lock`/`pip`/`add` collapse to the install summary (`+ pkg==ver`, `Resolved`/
  `Installed`/`Audited`); arbitrary `uv run <prog>` is head-capped, never keyword-filtered.
  `uv pip list --format json` and wrapped `uvx ruff --output-format json` pass byte-exact
  (invariant 1; the ruff guard is mirrored into the drift-copy per the contract).
  Gotcha: the copied bodies drift if pytest/ruff change — the real fix is wrapper-unwrap in
  lowfat-core. `npx` chose generic-cap instead of dispatch.
- **poetry** — installer shape (like pip): drops per-package `- Installing/Updating/Removing`
  chatter, keeps the `Package operations:` tally + `Writing lock file` + warnings; failed
  resolve keeps the solver/`Because` block, tail recovery. `poetry show -f json`/`--format json`
  passes byte-exact (invariant 1).

## PHP

- **composer** — installer shape: drops per-package `Locking`/`Downloading`/`Installing`
  chatter + `N/M [====]` progress bars, keeps `Lock file operations:`/`Package operations:`
  tally + autoload + warnings; failed resolve keeps the conflict block, tail recovery.
  `--format json`/`--format=json` passes byte-exact (invariant 1). Gotcha: a failed resolve
  exits 2 (not 1) and composer emits progress bars to the pipe even without a TTY.

## Ruby

- **rspec** — passing runs collapse to the real tally line (`N examples, 0 failures`);
  on failure keeps the `Failures:` section, the rerun list and the summary, dropping the
  progress dots and `Finished in` timing. Ultra trims to failure titles + `Failure/Error`
  lines + tally + rerun. Load errors (no `Failures:` header) are kept via their
  `LoadError`/`An error occurred` markers. Any explicit `--format`/`-f` (json, html, a
  custom formatter) passes byte-exact — only the default progress format is compacted.
- **rubocop** — keeps offense lines (`path:line:col: S: Cop: msg`) and the inspected/
  offenses tally; drops the source-frame + caret pair under each offense and the
  `SuggestExtensions` "Tip:" block. Clean run → `rubocop: clean`. Gotcha: exit 2 with no
  offense lines (bad path) falls back to raw so the diagnostic survives — exit code alone
  isn't trusted. Any explicit `--format`/`-f` (json, junit, sarif) passes byte-exact — the
  extraction only fits the default offense format.
- **bundle** (also `bundler`) — `install`/`update` collapse Fetching/Resolving chatter to
  the `Bundle complete!` verdict (ultra) or the `Installing` state lines (full); a failed
  resolve drops the giant `* gem-x.y.z` "matching gems" version dump but keeps the
  `Could not find`/conflict error. `exec` is another tool's output — capped only, never
  keyword-filtered.
- **gem** — `install`/`update` keep `Successfully installed`/`N gems installed` and any
  `ERROR`, drop fetch/doc chatter; `list`/`env`/`which` cap rows with a `... (N lines
  total)` recovery hint.
- **rake** — a task's stdout is a passthrough body, so success only caps it; failure keeps
  `rake aborted!`, the error message and the `Tasks:` trailer while dropping the Ruby
  backtrace frames (`:NN:in …`). Gotcha: no fixed subcommands — the task name is `$sub`,
  so branching is on exit + level, not subcommand.

## Go / JVM / .NET

- **go** — build errors raw (already terse); test failures keep `--- FAIL`/panic/
  location lines; passing verbose runs collapse to `ok` lines. `-json` (`go test -json`,
  `go list -json`, `go mod … -json`, `go vet -json`) passes byte-exact (invariant 1;
  without it `go test -json` on a passing run collapsed to "go test: ok").
- **golangci-lint** — keeps `file:line:col: message (linter)` lines, drops the source/
  caret bloat at ultra. Gotcha: a config error empties the keep-list, so a raw-head
  fallback fires — the error is never hidden. `--output.json.path` (v2) / `--out-format`
  (v1) pass byte-exact to the raw path by design (invariant 1); other v2
  `--output.<fmt>.path` machine formats are residual.
- **mvn** — drops transfer/plugin noise; extraction runs on failure too (a failed build
  is exactly when `[ERROR]` needs pulling out of hundreds of progress lines).
- **gradlew** — drops task/download progress; failures run an awk state machine that
  extracts the `FAILURE:`/`What went wrong:` block, with a capped tail fallback.
- **dotnet** — strips restore/project chatter; keeps compiler `error CS…` diagnostics,
  build verdicts, and vstest failure blocks (test name + Error Message/Stack Trace).
  Extraction runs on failure too. `publish`/`pack` share the build output shape and route
  through the same extraction (`pack`'s `Successfully created package` verdict is kept).
  `dotnet list … --format json` passes byte-exact in the `*` arm (invariant 1).

## OS packages

- **apt** (also `apt-get`) — installer shape: drops `Get:`/`Selecting`/`Unpacking`/`(Reading
  database`/`debconf:` chatter, keeps the `NEW packages will be installed` decision, the
  `N upgraded, M newly installed` summary, `Setting up`/`Processing triggers`, errors;
  failure keeps the `E:` block, tail recovery. Capture from `apt-get` (clean line output);
  no JSON path → no invariant-1 guard. Gotcha: not-found exits 100.
- **apk** — drops `(N/M) Installing`/`Executing` rows, keeps the `OK: N MiB in N packages`
  summary + warnings; failure keeps the `ERROR: unable to select packages` block. No JSON path.
- **dnf** (also `yum`) — drops repo-loading meters, `[N/M] … 100% |` progress rows, the
  `---` rule; keeps the `Installing:`/dependencies plan, the `Transaction Summary:` block,
  `Total size`, `Complete!`; failure keeps `No match for argument`/`Failed to resolve`. dnf5
  output shape; no JSON path.

## Infra / ops

- **kubectl** — compacts get/describe/logs/apply/rollout per subcommand shape. `-o json`/
  `-o yaml` pass byte-exact (invariant 1; without the guard the get/describe awk shredded
  structured output). `-o jsonpath`/`go-template` are residual, not yet guarded.
- **helm** — preserves release metadata; caps bulky NOTES/tables. `-o json`/`-o yaml`
  (+ `--output` long form) pass byte-exact in every compacting rule (invariant 1; without
  the guard the summary/table awk collapsed their whitespace). The `list` rule's guard is
  mechanical — its `-o json` needs a live cluster, so the golden is install-based.
- **terraform** (+ **`tofu`**/OpenTofu) — keeps plan/apply signal, drops repetitive
  diff/progress lines. One filter serves both binaries (OpenTofu is a fork with
  format-identical output; the plan-header keep alternates `Terraform|OpenTofu` since
  OpenTofu rebrands UI strings). `-json` passes byte-exact in plan/apply/init/*
  (invariant 1; without the guard `compact-plan` matched none of the ndjson stream →
  empty output).
- **ansible-playbook** — drops per-host `ok:`/`skipping:` chatter and `TASK [...]`
  banners; keeps `changed:`/`fatal:` and the `PLAY RECAP` tallies. Gotcha: failed runs
  tail to the recap — the recap block is the anchor, not the head of the stream.
- **docker-compose** — compacts up/logs/ps/build (legacy v1 output format).
- **systemctl** — status keeps identity lines (Loaded/Active/Main PID) and a
  level-scaled journal tail; ultra shows identity only, zero journal lines.
- **journalctl** — tail-anchored (newest/error lines are last). `-o json` byte-exact.
- **ssh** — drops `debug1:`–`debug3:` spam from `-v` modes. Gotcha: the remote
  command's output is only capped, never keyword-filtered.
- **rsync** — tail-anchored at every level: the `sent/received`/`speedup` stats block
  sits at the END; the per-file transfer list is the bloat.

## Cloud / deploy

- **aws** — default/JSON output byte-exact; only `--output table`/`text` is compacted.
- **gcloud** — same contract: `--format json|yaml` byte-exact, tables capped,
  failures raw.
- **az** — branches on flags, not subcommands: default output is JSON (byte-exact),
  errors are terse one-liners, and the real bloat is `--help` (1.3k lines for
  `az vm create --help` → section headers + flag names + Examples).
- **pulumi** — tail-anchored: the verdict (Outputs/Resources counts, Duration,
  Diagnostics) sits at the END, and `up` emits TWO `Resources:` sections (preview +
  update phase). Gotcha: errors surface in Diagnostics even on exit 1, so failures are
  compacted too, never raw. `--json` passes byte-exact in the up/preview/destroy/refresh
  rules and `*` (invariant 1; without the guard the tail-cap truncated multi-line JSON).
- **wrangler** — strips the uniform banner/telemetry/log-path boilerplate (~8 lines per
  invocation); the payload is already terse. esbuild ERROR blocks survive untouched.

## Data stores

- **psql** — strips ASCII table borders, unwraps rows, appends an `(N rows)` trailer.
  SQL errors are never hidden.
- **sqlite3** — caps big SELECTs; pipe-delimited default mode is already compact.
  Gotcha: a bad query can print `Error:` while exiting 0 — error lines are preserved.
- **redis-cli** — INFO compacts 224→~36 lines via metric keep-lists; listings
  (SCAN/KEYS/SLOWLOG) get a level-scaled cap with an `... (N lines total)` trailer.
  Gotcha: `ERR` replies exit 0 — errors survive by line shape, not exit code.
- **env** — masks secret-looking values (`*key*`/`*token*`/`*password*`/credential
  URIs) BEFORE sorting/capping. Gotcha: masking is deliberately over-eager; don't use
  the filtered output to copy real values.

## Net / files / misc

- **curl** — strips progress meters and `\r` artifacts; keeps the HTTP exchange
  (`>`/`<`/headers) and a capped body. Response bodies are the point — capped, never
  keyword-filtered. CAVEAT (invariant 1, open design-call): a multi-line JSON body IS
  truncated by the body cap, and there's no flag to key on — proposed fix is sniffing
  the body for JSON before capping.
- **wget** — strips progress bars/dots; keeps connection, HTTP status, and the final
  `saved` line (tail-anchored).
- **jq** / **json** — full/lite pass JSON byte-exact; ultra summarizes huge arrays via
  a python op that emits an explicit `lowfat_truncated` marker. Gotcha: ultra output is
  NOT valid input for further piping — look for the marker.
- **diff** — keeps hunk headers and changed lines. Gotcha: exit 1 means "files differ"
  (signal, not failure); exit 2 (real error) passes raw.
- **tar** — `-v` listings: ultra shows first entries + a total-count footer; errors
  (non-zero exit) raw.
- **make** — tail-caps only. Gotcha: recipe output is arbitrary child-command output,
  so it is deliberately never keyword-filtered — pair with per-tool plugins instead.
