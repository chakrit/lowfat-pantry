# The `.lf` filter DSL — author's reference (v0.6.8)

Build-grade spec for authoring `.lf` filter files. Derived exhaustively from
`lowfat-core/src/lf.rs` (parser + executor + tests). Citations are `lf.rs:N`.

A `.lf` file is the modern lowfat plugin entrypoint. It maps a command's
`(subcommand, level, exit-code, args)` context to a chain of line-oriented
text-transform ops applied to the command's combined stdout+stderr.

## Execution model in one paragraph

`execute` selects the **first** rule matching `(sub, level)`; if none match, the
input passes through unchanged (`lf.rs:1232-1238`). The matched rule's ops run
left-to-right, each consuming the previous op's output as its input
(`run_ops`, `lf.rs:1353-1366`). Non-empty output is guaranteed a trailing
newline (`lf.rs:1240-1245`). Any execution error → the runner degrades to
passthrough of the raw input (it never errors out the command).

## File shape

```
#!/usr/bin/env lowfat-filter      # optional shebang — it's a comment, ignored
# comments start with #
                                  # blank lines ignored

define helper:                    # zero or more macro definitions
    drop /noise/

status:                           # rules: selector ':' then a body
    keep /^M /
    head 10
```

- **Line-oriented, indentation-sensitive.** The parser works on `(indent, text)`
  pairs — no INDENT/DEDENT tokens (`lf.rs:152-182`). Indent is the count of
  leading whitespace characters; a child is *strictly* more-indented than its
  parent. Any consistent indent works (4 spaces is convention); blocks compare
  indent by `>` / `<=`, not a fixed step.
- **Comments / blanks** ("meta" lines) are skipped by the structural parser
  (`lf.rs:172`). Inside `shell:`/`python:` block bodies they are preserved
  verbatim (so `# /// script` PEP-723 headers survive — `lf.rs:683-687`).
- Top-level constructs must sit at indent 0 (`lf.rs:274-275`).
- A rule with an empty body is an error (`rule has no ops`, `lf.rs:342`).

## Selectors and rules

Rule header: `<sub-pattern>[, <level-pattern>]:` (`lf.rs:861-891`).

- `status:` — subcommand `status`, any level.
- `*:` — any subcommand, any level (the catch-all).
- `diff, ultra:` — subcommand `diff` only at level `ultra`.
- `*, ultra:` — any subcommand at `ultra`.
- `build|check, ultra:` — alternation: `build` **or** `check`, at `ultra`. Alts
  are `|`-separated (`lf.rs:873-881`). An empty alt is an error.
- Omitting the level part defaults to `*` (any level) (`lf.rs:868`).

**Subcommand glob** (`glob_match`, `lf.rs:896-913`): a pattern containing `*`
matches any run of characters (including empty); no other metacharacters. With
no `*` it's an exact compare. So `apply*:` matches `apply`, `apply-set`, etc.
The `*` here is glob, distinct from the bare `*` catch-all selector.

**First-match-wins.** Rules are tried top-to-bottom; the first whose sub- and
level-pattern both match is selected, and **only that rule runs**
(`lf.rs:125-127, 134-146`). Order your specific rules before the catch-all:

```
diff, ultra:   head 5      # matched for diff+ultra
diff:          head 20     # matched for diff at other levels
*:             head 30     # everything else
```

`sub` is matched against `$sub` (the command's first arg, the subcommand). For
commands without subcommands (ls/find/grep/tree) `$sub` is empty, so those
filters use a single `*:` rule.

## Levels

The three intensity values are `ultra`, `full`, `lite` (`level.rs`). Use them in:
- level-patterns on rule headers (`diff, ultra:`),
- `level <lvl>` guard atoms,
- `match level:` arms,
- `*` for "any level" in a rule header.

`full` is the default level. Level parsing is case-insensitive but write
lowercase by convention.

## Ops — complete reference

Each op transforms the current text. Syntax is the leading keyword; ops live one
per line in a body, or chained inline after a rule header's `:`.

### Line filters

- **`keep /re/`** — keep lines matching the regex; drop the rest
  (`lf.rs:1377`). Regex is line-by-line `is_match` (unanchored unless you
  anchor it).
- **`drop /re/`** — drop lines matching; keep the rest (`lf.rs:1378`).

Regex literal: `/.../ `, with `\/` escaping a literal slash inside
(`lf.rs:1043-1086`). Trailing input after the closing `/` on a non-inline line
is an error.

### Truncation

- **`head N`** — keep the first N lines (`lf.rs:1379, 1504`).
- **`tail N`** — keep the last N lines (`lf.rs:1380, 1508`).
- **`head auto` / `tail auto`** — N resolves to `level.head_limit(30)` →
  **ultra 15 / full 30 / lite 60** (`lf.rs:1490-1495, 1143-1155`). Use `auto`
  when you want level-scaled truncation without hardcoding per-level rules.

### Fallbacks (fire only when the stream is empty)

- **`or "text"`** / **`else "text"`** — if the current text is blank
  (whitespace-only), replace it with the literal `text`; otherwise leave it.
  `or` and `else` are exact synonyms (`lf.rs:602-605, 1381-1385, 2472-2477`).
  String literal supports `\n \t \r \\ \"` escapes (`lf.rs:1116-1127`).
- **`or-shell: <cmd>`** / **`else-shell: <cmd>`** — if blank, run `<cmd>` (one
  line) over the **raw** rule input via `sh -c` and use its stdout; else leave
  the stream (`lf.rs:606-612, 1386-1393`). Synonyms. The classic use is "keep
  matched lines, else fall back to a softer truncation of the original":

```
diff:
    compact-diff 200
    or-shell: awk 'NF' | head -50
```

Note `or-shell` runs against `raw` (the rule's original input), not the
post-keep empty stream (`lf.rs:1386-1389`) — it's a *recovery from over-pruning*,
not a transform of the empty output.

### Identity

- **`raw`** (canonical) / **`passthrough`** (legacy alias) — emit the current
  text unchanged (`lf.rs:613-614, 1394, 2453-2461`). Used in cascade arms to opt
  a case out of filtering (e.g. `if exit failed: raw`).

### Shell / Python escape hatches

- **`shell: <one-line cmd>`** — inline form; runs the rest of the line via
  `sh -c`, piping the current text to stdin, using stdout (`lf.rs:615-620,
  1408-1411, 1575-1605`).
- **`shell: |`** then an indented block — block form; the dedented block body is
  the command. Internal blank lines and relative indentation are preserved
  (`lf.rs:659-718`). Lets you embed multi-line `awk`/`sed` state machines.
- **`python: <one-line>`** / **`python: |` block** — same two forms, runs via
  `python3 -c` (`lf.rs:621-626, 1412-1415, 1607-1648`).
- **PEP 723**: if the python body contains a `# /// script` header line, it's
  written to a temp file and run via `uv run --script`, so inline
  `dependencies = [...]` resolve (`lf.rs:1615-1697`). Detection is any line
  trimming to start with `# /// script` (`lf.rs:1615-1618`).

Non-zero exit from a shell/python op is a hard error → the whole filter degrades
to passthrough (`lf.rs:1596-1604`). Keep escape-hatch commands robust.

## `define` — macros

```
define strip-trailers:                 # no params
    drop /^(Signed-off-by|Co-authored-by):/

define compact(limit):                 # one param
    shell: |
        awk -v lim=$1 '{ ... }'
```

- Header: `define <name>[(<p1>, <p2>, …)]:` (`lf.rs:1005-1028`). One-line bodies
  are **not** supported — the body must be the indented block below
  (`lf.rs:304-310`). Empty body is an error.
- **Invocation**: bare name plus args — `compact 30`, `strip-trailers`
  (`lf.rs:643-650`). A name is recognized as a macro call only if it was
  collected as a define name in a pre-pass (`collect_macro_names`,
  `lf.rs:218-235`) — so a macro must be *defined somewhere in the file* (order
  within the file doesn't matter for recognition, but the define must exist).
- **Args** are positional. Inside the macro body, `$1`..`$9` substitute the
  call's args (`expand_args`, `lf.rs:1543-1573`). **Substitution is by position
  (`$1`), not by param name** — the names in the `(limit)` header are
  documentation only; the executor never binds `$limit`. Other `$NAME` tokens
  (`$level`, `$sub`, …) are left intact so the shell expands them from env.
- Arg count must match the param count exactly, checked at execution
  (`lf.rs:1420-1427`); mismatch is an error.
- Args are parsed as numbers when they parse as `usize`, else as strings; quoted
  `"..."` is always a string (`lf.rs:1157-1175`).
- A macro's ops run as a sub-chain over the current stream
  (`lf.rs:1416-1428`). Macros may call other macros and appear inside
  `split` branches.

## `match <dim>:` — single-dimension cascade sugar

```
log:
    match level:
        ultra: head 10
        lite:  head 50
        else:  head 25
```

`match` switches on one dimension and desugars to an `if/elif/else` cascade
(`lf.rs:497-547`). Allowed dimensions: **`level`** and **`exit`** only
(`lf.rs:966-983`). Flags are *not* a match dimension (their presence is binary,
no values to enumerate) — use the full `if --flag:` form for those.

- `match level:` arms are `ultra:`/`full:`/`lite:`/`else:`.
- `match exit:` arms are `ok:`/`failed:`/`else:`.
- `else:` is the catch-all; it ends the match (later arms ignored,
  `lf.rs:536-540`).
- The `match` header takes **no** inline ops — `match level: head 1` is an error
  (`lf.rs:512-518, 2608-2617`).
- An arm body may itself be a nested `if`/`match` cascade or a plain pipeline
  (`parse_arm_body`, `lf.rs:464-488`) — nesting is supported.

How it differs from per-rule level selectors: a level **selector** (`diff,
ultra:`) picks *which rule* runs and is subject to first-match-wins across
rules; `match level:` lives *inside one rule's body* and branches the op-chain
after that rule is already selected. Use selectors to split unrelated
sub/level combos into separate rules; use `match` to vary a few ops within one
logical rule without duplicating the selector.

## `if` / `elif` / `else` — full cascade

```
diff:
    if exit failed:
        raw
    elif level ultra and --stat:
        head 1
    else:
        compact-diff 200
```

Cascade arms share one indent level; the **first** arm whose guard holds runs,
and only that arm (`parse_cascade`, `lf.rs:392-432`; `apply_op`,
`lf.rs:1395-1407`). With no matching arm and no `else`, the stream passes through
untouched (`lf.rs:1405-1406, 2447-2451`). Structural rules:

- Must open with `if`; `elif`/`else` without a leading `if` is an error; a
  second `if` in an open cascade is an error (`lf.rs:415-423`).
- `else` takes no guard and is always the last arm (`lf.rs:425-429, 446-450`).
- Inline ops after `:` force a pipeline body; otherwise the body may be an
  indented pipeline or a nested cascade (`lf.rs:464-488`).

### Guards — grammar

A guard is an **AND of atoms** joined by the literal ` and ` (with surrounding
spaces) (`parse_guard`, `lf.rs:915-929`). Atoms (`parse_atom`, `lf.rs:931-961`):

- **`exit ok`** — true when exit code == 0.
- **`exit failed`** — true when exit code != 0 (covers *any* non-zero, e.g.
  grep's 1=no-match and 2=error both) (`lf.rs:1458-1459`).
- **`level ultra` / `level full` / `level lite`** — true when the current level
  matches.
- **flag atom** — any token starting with `-` is a flag guard (`lf.rs:933-935`).

Exactly one keyword + value per non-flag atom; `if exit boom` and extra words
are errors (`lf.rs:940-959`).

### Flag atoms — matching semantics (`flag_matches`, `lf.rs:1476-1488`)

Matched against `$args` (the full arg list). Two shapes:

- **Presence** — `--stat` / `-o`: true if any arg equals it, in bare
  (`--stat`) or `--flag=value` form (`--output=json` matches `--output`).
  Split is on `=`, so `--stat` does **not** match `--statistics`
  (`lf.rs:2419-2425`).
- **Flag + value** — `-o yaml` / `--output json`: true when the flag carries
  that value, written as two tokens (`-o yaml`), glued (`-o=yaml`), or — for
  2-char short flags only — concatenated (`-oyaml`) (`lf.rs:1481-1486,
  2428-2444`). So `if -o yaml: …` prunes YAML output while `-o json` falls
  through byte-exact — the canonical "don't corrupt structured output for jq"
  pattern.

## `split /re/` with `pre:` / `post:`

```
show:
    split /^diff /
    pre:
        keep /^(commit |Author:|Date:|    )/
        abbrev-hash
    post:
        compact-diff 100
    head 100
```

`split` cuts the stream at the **first** line matching the regex; that matching
line and everything after go to `post`, everything before to `pre`
(`split_at_first_match`, `lf.rs:1517-1532`). If no line matches, everything is
`pre` and `post` is empty (`lf.rs:2236-2250`). Each half runs its own op
sub-chain (an empty `pre:`/`post:` passes that half through), then the halves
are rejoined with a newline (`join_nonempty`, `lf.rs:1430-1447, 1534-1541`).

- At least one of `pre:`/`post:` is required (`lf.rs:631-636`).
- `pre:`/`post:` blocks sit at the same indent as `split`'s op line's children
  and are consumed as siblings (`lf.rs:722-745`).
- **Ops after the split compose normally** — the trailing `head 100` above runs
  on the *rejoined* `pre+post` output, because it's just the next op in the
  rule's chain (`lf.rs:1903-1920` shows `head 100` as `ops[1]` after the
  `Split` `ops[0]`).
- `split` cannot appear inline after a rule header — it needs its block
  (`lf.rs:812-817`).

## Variables available to shell / python / regex

The executor exports these env vars to every `shell:`/`python:`/`or-shell:`
subprocess (`run_shell`, `lf.rs:1575-1582`; same set for python):

| var      | holds                                                        |
|----------|--------------------------------------------------------------|
| `$level` | current level — `ultra` / `full` / `lite`                    |
| `$sub`   | the subcommand (`$args[0]`); empty if none                   |
| `$exit`  | original command's exit code, as a string                    |
| `$args`  | full arg list, space-joined                                  |

Plus macro positional args `$1`..`$9`, substituted **before** the shell sees the
string (`expand_args`, `lf.rs:1546-1573`) — so `$1` is textual interpolation at
parse-expand time, while `$level`/`$sub`/`$exit`/`$args` are real env vars the
shell expands at runtime. The current text is delivered on **stdin**, not via a
variable.

Regexes (`keep`/`drop`/`split`) only see the line text; they have no access to
these variables.

## Regex flavor

The Rust `regex` crate (`lf.rs:11`). Consequences for authors:

- **No backreferences, no lookaround** (`\1`, `(?=…)`, `(?<=…)` are unsupported
  and will fail to compile → parse error). If you need them, drop to a `shell:`
  `sed`/`perl`/`awk` op.
- POSIX classes work: `[[:space:]]`, `[[:alnum:]]`, etc. (used in the bundled
  git filter, `embedded/git/git-compact/filter.lf`).
- Inline flags via `(?i)`, `(?s)`, `(?m)` are available.
- Patterns are unanchored; anchor with `^`/`$` explicitly. Matching is per-line,
  so `^`/`$` bind to line edges as expected.
- A regex that fails to compile is a **parse-time** error (`lf.rs:1077-1078`),
  surfacing before the filter ever runs.

## Cookbook — idiomatic patterns

Distilled from the six bundled filters
(`lowfat-plugin/embedded/<cat>/<name>/filter.lf`).

**1. Level-scaled truncation with an empty-output verdict** (git status):
```
status:
    match level:
        ultra:
            keep /^(\t|[ MADRCU?!]{2} )/
            head 15
            or "git status: clean"
        else:
            keep /^(\t|[ MADRCU?!]{2} |## |On branch|Changes|Untracked)/
            head 30
            or "git status: clean"
```

**2. Preserve raw output on failure; compact on success** (find/grep/tree):
```
*:
    if exit failed:
        raw
    else:
        match level:
            ultra: head 20
            lite:  head 200
            else:  head 60
```

**3. exit-failed → raw, with a no-match verdict** (grep — exit 1 is empty, 2 is
an error; `raw` carries the error, `or` fills the no-match case):
```
*:
    if exit failed:
        raw
        or "grep: no matches"
    else:
        head 60
```

**4. keep + head + or-shell fallback** (git diff — prune to changed lines, but
if that empties the stream, fall back to a soft truncation of the original):
```
diff:
    if exit failed:
        raw
    else:
        compact-diff 200
        or-shell: awk 'NF' | head -50
```

**5. State-machine via a `shell: |` awk block in a macro** (git diff
compaction — drops context lines, abbreviates `@@` tails at ultra):
```
define compact-diff(limit):
    shell: |
        awk -v lim=$1 -v lvl=$level '
          BEGIN { in_hunk=0; n=0 }
          n>=lim { exit }
          /^diff / { in_hunk=0; print; n++; next }
          /^@@ /  { in_hunk=1; print; n++; next }
          lvl=="ultra" { next }
          in_hunk && /^[+-]/ { print; n++ }
        '
```
Note `$1` (macro arg) is interpolated literally; `$level` is read as an env var
inside awk's `-v`.

**6. split pre/post — separate chains for header vs body** (git show at full):
```
show:
    split /^diff /
    pre:
        keep /^(commit |Merge:|Author:|Date:|    )/
        strip-trailers
        abbrev-hash
    post:
        compact-diff 100
    head 100
```

**7. Column extraction at ultra, column-collapse otherwise** (docker ps —
`printf` a header, then reshape with awk; the prepended header survives):
```
ps:
    match level:
        ultra:
            shell: |
                printf 'NAME STATUS\n'
                tail -n +2 | awk '{print $NF, $(NF-2)}'
            head 20
        else:
            shell: sed 's/  */ /g'
            head 40
```

**8. Comma-list selector + per-level one-liners** (docker logs):
```
logs, ultra:    tail 10
logs, full:     tail 30
logs:           tail 60
```

**9. Drop-noise macro then compact** (ls — strip `total`/blank lines, collapse
long-form to `<type> <size> <name>`):
```
define strip-noise:
    drop /^total /
    drop /^$/

*, ultra:
    strip-noise
    shell: awk '{print $NF}'
    head 40
```

**10. Inline op chain after the rule header** (terse one-liners):
```
build, ultra:  keep /^(Successfully|ERROR)/  tail 3  else "docker build: ok"
```

## Gotchas / parser constraints (from the lf.rs tests)

- **First-match-wins is absolute** — a later rule never runs if an earlier one
  matched. Put `*:` last (`lf.rs:1924-1943`).
- **`match` header rejects inline ops** — `match level: head 1` errors; arms must
  be on their own indented lines (`lf.rs:2608-2617`).
- **`split` can't be inline** — it requires `pre:`/`post:` blocks
  (`lf.rs:812-817`).
- **`define` has no one-line body** — `define x: head 1` errors; use the indented
  block (`lf.rs:304-310`).
- **Macro recognition needs a prior `define`** — calling an undefined name yields
  `unknown op` at parse, or `undefined macro` at run (`lf.rs:643-651,
  1417-1419`). Arg-count mismatch is a **runtime** error, not parse-time
  (`lf.rs:2253-2265`).
- **`or-shell` / `shell:` value-empty checks** — an empty command after the
  keyword errors (`lf.rs:608-610, 759-761`).
- **Unterminated `/regex/` or `"string"`** — hard parse errors
  (`lf.rs:1985-1988`).
- **Flag matching splits on `=`** so `--stat` ≠ `--statistics`; rely on this for
  precise flag guards (`lf.rs:2419-2425`).
- **Shell/python non-zero exit aborts the filter** (→ passthrough). Guard your
  pipelines (`awk 'NF'` etc.) so they exit 0 (`lf.rs:1596-1604`).
- **`or`/`else` test is "blank after trim"** — whitespace-only counts as empty,
  triggering the fallback (`lf.rs:1381-1382`).
- **`head auto` uses base 30** (15/30/60), **not** the base-40 head_limit that
  legacy single-filter plugins see — don't conflate the two baselines
  (`lf.rs:1493` vs `run.rs:113`).
- **`split` with no delimiter match** routes everything to `pre`; design `pre:`
  to be safe on the whole stream (`lf.rs:2236-2250`).
- Subprocess ops run with a **scrubbed env** (allowlist only) — don't rely on
  arbitrary inherited env vars inside `shell:`/`python:` (see security.rs in the
  internals doc).

## Authoring pitfalls (from building the pantry)

Practical anti-patterns that cost real debugging time while building the 39
pantry plugins — distinct from the parser/engine gotchas above:

1. **Alternation is `|`, not comma.** `build|check|clippy:` means "build OR check
   OR clippy". A comma is `sub, level` (`logs, ultra:`), so `build, check:` parses
   as sub=`build`, level=`check` → error (`check` isn't a level).
2. **A body is EITHER a flat pipeline OR a cascade — never a flat op then a
   `match`/`if`.** `drop-progress` *then* `match level:` fails to parse. Push the
   shared flat op INTO each arm (macros-in-arms is fine, as `cargo`/`git` do).
3. **`raw` on failure defeats compaction when the failure IS the bloat.** A naive
   `if exit failed: raw` is right for grep/find (short errors) but WRONG for noisy
   builds (mvn/gradle/tsc): a failed build is exactly when you want `[ERROR]`
   extracted from hundreds of transfer/progress lines. Run the extraction on
   failure too, with `or-shell: tail`/`head` as the over-prune fallback.
4. **`or-shell:` runs against the RAW input, not the pruned stream.** It's
   over-prune *recovery* (fires when your pipeline emptied the stream), not a
   post-transform. Use it to fall back to a raw head/tail when a keyword `keep`
   matched nothing (e.g. a crash with none of your expected markers).
5. **Never keyword-filter passthrough output.** For `<tool> run`/`exec`/bare
   `prettier <file>`/`cargo run`, the body is the program's own stdout or
   formatted code — keyword-filtering it hides results or corrupts code. Select
   those subcommands separately and only head/tail-cap them.
6. **Guard structured output through byte-exact.** JSON/env/formatted output must
   not be lossily capped. Branch on the flag (`if --json: raw`, `elif -F json:
   raw`, `elif -o json:`) — `--output json` matches `--output`, and flag+value
   `-o yaml` matches only that value, so you can prune YAML while passing JSON.
7. **Exit-code granularity is binary in guards.** You only get `exit ok|failed`,
   not specific codes. If 1 and 2 mean different things (eslint: 1=problems,
   2=crash), prefer a robust non-keyword approach (drop-blanks + head) so a crash
   is never silently dropped to "clean".
8. **Samples must be byte-faithful.** No inline `# synthetic:` annotations — they
   leak into filtered output and distort line counts. Record synthetic-ness in
   `tests.yml` (`synthetic: true`).
