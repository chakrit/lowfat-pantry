# The `.lf` filter DSL — author's reference (v0.8.0)

Build-grade spec for authoring `.lf` filter files. Derived exhaustively from
`lowfat-core/src/lf.rs` (parser + executor + tests). Citations are `lf.rs:N`,
re-anchored to the v0.8.0 sources on 2026-07-26.

**What changed since v0.6.8** (the version this file previously tracked): the op
set is byte-for-byte identical — the only DSL addition is `include` (§ below).
`head auto`'s 15/30/60 limits are unchanged
(`level.rs` is identical between the two releases), and `head`/`tail` still cut
silently. Everything else in the 0.6.8→0.8.0 delta is `rustfmt` reflow plus a
`run_filter_child` refactor that moved the env-export block out of `run_shell`.

A `.lf` file is the modern lowfat plugin entrypoint. It maps a command's
`(subcommand, level, exit-code, args)` context to a chain of line-oriented
text-transform ops applied to the command's combined stdout+stderr.

## Execution model in one paragraph

`execute` selects the **first** rule matching `(sub, level)`; if none match, the
input passes through unchanged (`lf.rs:1418-1424`). The matched rule's ops run
left-to-right, each consuming the previous op's output as its input
(`run_ops`, `lf.rs:1535-1546`). Non-empty output is guaranteed a trailing
newline (`lf.rs:1426-1429`). Any execution error → the runner degrades to
passthrough of the raw input (it never errors out the command).

## File shape

```
#!/usr/bin/env lowfat-filter      # optional shebang — it's a comment, ignored
# comments start with #
                                  # blank lines ignored

include lib/shared.lf             # zero or more includes, at indent 0

define helper:                    # zero or more macro definitions
    drop /noise/

status:                           # rules: selector ':' then a body
    keep /^M /
    head 10
```

- **Line-oriented, indentation-sensitive.** The parser works on `(indent, text)`
  pairs — no INDENT/DEDENT tokens (`lf.rs:154-163`). Indent is the count of
  leading whitespace characters; a child is *strictly* more-indented than its
  parent. Any consistent indent works (4 spaces is convention); blocks compare
  indent by `>` / `<=`, not a fixed step.
- **Comments / blanks** ("meta" lines) are skipped by the structural parser
  (`lf.rs:174`). Inside `shell:`/`python:` block bodies they are preserved
  verbatim (so `# /// script` PEP-723 headers survive — `lf.rs:878-882`).
- Top-level constructs must sit at indent 0 (`lf.rs:471-472`).
- A rule with an empty body is an error (`rule has no ops`, `lf.rs:519`).

## Selectors and rules

Rule header: `<sub-pattern>[, <level-pattern>]:` (`lf.rs:1056-1060`).

- `status:` — subcommand `status`, any level.
- `*:` — any subcommand, any level (the catch-all).
- `diff, ultra:` — subcommand `diff` only at level `ultra`.
- `*, ultra:` — any subcommand at `ultra`.
- `build|check, ultra:` — alternation: `build` **or** `check`, at `ultra`. Alts
  are `|`-separated (`lf.rs:1068-1073`). An empty alt is an error.
- Omitting the level part defaults to `*` (any level) (`lf.rs:1063`).

**Subcommand glob** (`glob_match`, `lf.rs:1088-1099`): a pattern containing `*`
matches any run of characters (including empty); no other metacharacters. With
no `*` it's an exact compare. So `apply*:` matches `apply`, `apply-set`, etc.
The `*` here is glob, distinct from the bare `*` catch-all selector.

**First-match-wins.** Rules are tried top-to-bottom; the first whose sub- and
level-pattern both match is selected, and **only that rule runs**
(`lf.rs:127-129, 136-147`). Order your specific rules before the catch-all:

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
  (`lf.rs:1559`). Regex is line-by-line `is_match` (unanchored unless you
  anchor it).
- **`drop /re/`** — drop lines matching; keep the rest (`lf.rs:1560`).

Regex literal: `/.../ `, with `\/` escaping a literal slash inside
(`lf.rs:1241-1245`). Trailing input after the closing `/` on a non-inline line
is an error.

### Truncation

- **`head N`** — keep the first N lines (`lf.rs:1561, 1683`).
- **`tail N`** — keep the last N lines (`lf.rs:1562, 1687`).
- **`head auto` / `tail auto`** — N resolves to `level.head_limit(30)` →
  **ultra 15 / full 30 / lite 60** (`lf.rs:1672-1676, 1333-1337`). Use `auto`
  when you want level-scaled truncation without hardcoding per-level rules.

🚨 **The `.lf` ops cut silently — the identically-named pipeline processor does
not.** `head`/`truncate` as *pipeline stages* run `proc_truncate`
(`lowfat-core/src/pipeline.rs`), which appends `... (N lines truncated)`. The
`.lf` ops above are a separate code path in `lf.rs` and emit nothing, so a
truncated stream is byte-indistinguishable from a genuinely short one. Same
name, different contract — re-verified against upstream at **v0.8.0**:
`take_head`/`take_tail` are still a bare `lines().take(n)` / tail slice with no
marker (`lf.rs:1683-1691`), and the bundled `git-compact` marker text is
unchanged. v0.8.0 does **not** fix this.

Marking is otherwise lowfat's own house style: the bundled `git-compact`
reference filter prints `... [git-compact: truncated; %d more files, %d more
lines omitted - use LOWFAT_LEVEL=lite for the full diff]`, and `tree-compact`
keeps totals "even when the body is truncated". The pantry therefore uses no bare
`head`/`tail` anywhere — not just in catch-alls — and reaches for the marked
macros in `plugins/lib/truncation.lf` instead. See `plugins/README.md §
Truncation conventions` and `docs/decisions/2026-07-26-visible-truncation.md`.

### Fallbacks (fire only when the stream is empty)

- **`or "text"`** / **`else "text"`** — if the current text is blank
  (whitespace-only), replace it with the literal `text`; otherwise leave it.
  `or` and `else` are exact synonyms (`lf.rs:803-806, 1563-1567, 2692-2703`).
  String literal supports `\n \t \r \\ \"` escapes (`lf.rs:1252-1258`).
- **`or-shell: <cmd>`** / **`else-shell: <cmd>`** — if blank, run `<cmd>` (one
  line) over the **raw** rule input via `sh -c` and use its stdout; else leave
  the stream (`lf.rs:807-811, 1568-1574`). Synonyms. The classic use is "keep
  matched lines, else fall back to a softer truncation of the original":

```
diff:
    compact-diff 200
    or-shell: awk 'NF' | head -50
```

Note `or-shell` runs against `raw` (the rule's original input), not the
post-keep empty stream (`lf.rs:1568-1571`) — it's a *recovery from over-pruning*,
not a transform of the empty output.

### Identity

- **`raw`** (canonical) / **`passthrough`** (legacy alias) — emit the current
  text unchanged (`lf.rs:814-815, 1576, 2461-2475`). Used in cascade arms to opt
  a case out of filtering (e.g. `if exit failed: raw`).

### Shell / Python escape hatches

- **`shell: <one-line cmd>`** — inline form; runs the rest of the line via
  `sh -c`, piping the current text to stdin, using stdout (`lf.rs:816-818,
  1590-1593, 1804-1808`).
- **`shell: |`** then an indented block — block form; the dedented block body is
  the command. Internal blank lines and relative indentation are preserved
  (`lf.rs:854-869`). Lets you embed multi-line `awk`/`sed` state machines.
- **`python: <one-line>`** / **`python: |` block** — same two forms, runs via
  `python3 -c` (`lf.rs:819-821, 1594-1597, 1607-1648`).
- **PEP 723**: if the python body contains a `# /// script` header line, it's
  written to a temp file and run via `uv run --script`, so inline
  `dependencies = [...]` resolve (`lf.rs:1818-1821`). Detection is any line
  trimming to start with `# /// script` (`lf.rs:1818-1821`).

Non-zero exit from a shell/python op is a hard error → the whole filter degrades
to passthrough (`lf.rs:1793-1801`). Keep escape-hatch commands robust.

## `define` — macros

```
define strip-trailers:                 # no params
    drop /^(Signed-off-by|Co-authored-by):/

define compact(limit):                 # one param
    shell: |
        awk -v lim=$1 '{ ... }'
```

- Header: `define <name>[(<p1>, <p2>, …)]:` (`lf.rs:1203-1211`). One-line bodies
  are **not** supported — the body must be the indented block below
  (`lf.rs:511-517`). Empty body is an error.
- **Invocation**: bare name plus args — `compact 30`, `strip-trailers`
  (`lf.rs:838-845`). A name is recognized as a macro call only if it was
  collected as a define name in a pre-pass (`collect_macro_names`,
  `lf.rs:235-240`) — so a macro must be *defined somewhere in the file* (order
  within the file doesn't matter for recognition, but the define must exist).
- **Args** are positional. Inside the macro body, `$1`..`$9` substitute the
  call's args (`expand_args`, `lf.rs:1722-1728`). **Substitution is by position
  (`$1`), not by param name** — the names in the `(limit)` header are
  documentation only; the executor never binds `$limit`. Other `$NAME` tokens
  (`$level`, `$sub`, …) are left intact so the shell expands them from env.
- 🚨 **`$N` reaches only `shell:` / `python:` / `or-shell:` bodies** — the three
  string-valued ops `expand_args` is applied to (`lf.rs:1570, 1591, 1595`). It is
  **not** an op-argument mechanism: `head $1` / `tail $1` is a hard *parse* error
  (`parse_head_arg` takes a number or `auto` and nothing else,
  `lf.rs:1341-1353`), and `keep`/`drop`/`split` regexes are compiled at parse
  time, long before any arg exists. To parameterize a truncation limit, put the
  limit inside a `shell:`/`python:` body — or write one macro per level. True in
  0.6.8 and 0.8.0 alike.
- Arg count must match the param count exactly, checked at execution
  (`lf.rs:1602-1609`); mismatch is an error.
- Args are parsed as numbers when they parse as `usize`, else as strings; quoted
  `"..."` is always a string (`lf.rs:1343-1358`).
- A macro's ops run as a sub-chain over the current stream
  (`lf.rs:1598-1610`). Macros may call other macros and appear inside
  `split` branches.
- 🚨 **No non-ASCII literals in an *arg-taking* macro's `shell:`/`python:`/
  `or-shell:` body.** `expand_args` walks the body byte-wise and re-emits each
  byte as a `char` (`out.push(c as char)`, `lf.rs:1748`), so every multibyte
  glyph (`●`, `❯`, `×`, `→`, `⎯`) is silently rewritten to mojibake and a match
  on it never fires — no crash, no error.

  The blast radius is narrower than it looks, and narrower than this file
  claimed before 2026-07-26. `expand_args` returns the body untouched when the
  macro takes no args (`lf.rs:1726-1728`), and it is only ever applied to the
  three string-valued ops — so **`keep`/`drop`/`split` regexes are never
  affected at all**, in a macro or out of it, because they are compiled at parse
  time. Verified empirically at 0.8.0: `keep /●/` inside `define g(n)` matches
  correctly, while the same glyph in that macro's `python:` body does not.

  Trigger conditions, all three required: a `define` **with parameters**, a
  `shell:`/`python:`/`or-shell:` body, and a non-ASCII literal in it. Drop any
  one and you are safe. (`docs/spec/lf-wishlist.md` #5.)

## `include` — sharing macros across files

**New in v0.8.0** (upstream `zdk/lowfat#14`). Pulls another `.lf` file's
**macros** into the current file at parse time:

```
include lib/shared.lf             # bare path
include "lib/shared.lf"           # or quoted — one layer of quotes is stripped

*:
    head-auto-marked              # macro defined in lib/shared.lf
```

Semantics, from `collect_includes` / `Loader::load_file_inner`
(`lf.rs:282-308, 344-409`):

- **Macros only.** The included file's **rules are ignored** — only its
  `define`s cross the boundary (`lf.rs:408`). This is deliberate: the library
  file may double as a runnable filter in its own right.
- **Indent 0, and only there.** A line is an include if it is unindented, is not
  a comment, and reads `include` or starts with `include ` (`lf.rs:276-278,
  285`). Indented `include` lines are silently *not* directives.
- **Resolved before the body parses.** Includes are collected in a pre-pass so
  the parser knows the full macro vocabulary before it sees any call
  (`lf.rs:382-394`) — an included macro is callable anywhere in the file, and
  order does not matter.
- **Relative paths only**, resolved against the *including* file's directory
  (`base.join(...)`, `lf.rs:380, 385`). An absolute path is a hard error
  (`include path must be relative`, `lf.rs:295-301`) — deliberately, so an
  include can't escape the plugin tree. `../` is allowed and works.
- **Transitive**, with a per-load cache, and **cycles are a hard error** naming
  the chain (`lf.rs:349-360`).
- **Diamonds are fine; genuine collisions are not.** The same macro reached by
  two paths is deduped by canonical origin; the same *name* from two *different*
  files is an error telling you to rename or override (`merge_inherited`,
  `lf.rs:415-429`).
- **A local `define` overrides an inherited one** of the same name
  (`lf.rs:399-406`) — the shadowing hook for per-plugin tweaks.
- **A missing include file is a hard parse error**, not a warning
  (`lf.rs:377-378, 386-388`).
- `import` is **not** a synonym — it parses as an unknown op.
- Only the file-loading entrypoint resolves includes. A `.lf` parsed from a
  string rather than a path rejects `include` outright
  (`bare_parse_rejects_include`, `lf.rs:3021`) — irrelevant to `lowfat filter
  <path>`, which goes through `load`.

**Pantry use.** Shared macros live in `plugins/lib/*.lf` and filters pull them in
with `include ../../lib/truncation.lf`. Plugins are synced *individually* into
`<LOWFAT_HOME>/plugins/<category>/<name>/`, which mirrors the pantry layout, so
the same relative path resolves in both trees — provided the sync also links
`plugins/lib` into the lowfat home (SKILL.md § 4c). Verified at v0.8.0 through an
installed-plugin symlink: `..` walks back out through the symlink, so a library
reached via `../../lib/` resolves either way.

## `match <dim>:` — single-dimension cascade sugar

```
log:
    match level:
        ultra: head 10
        lite:  head 50
        else:  head 25
```

`match` switches on one dimension and desugars to an `if/elif/else` cascade
(`lf.rs:698-719`). Allowed dimensions: **`level`** and **`exit`** only
(`lf.rs:1164-1168`). Flags are *not* a match dimension (their presence is binary,
no values to enumerate) — use the full `if --flag:` form for those.

- `match level:` arms are `ultra:`/`full:`/`lite:`/`else:`.
- `match exit:` arms are `ok:`/`failed:`/`else:`.
- `else:` is the catch-all; it ends the match (later arms ignored,
  `lf.rs:631-635`).
- The `match` header takes **no** inline ops — `match level: head 1` is an error
  (`lf.rs:512-517, 2871-2877`).
- An arm body may itself be a nested `if`/`match` cascade or a plain pipeline
  (`parse_arm_body`, `lf.rs:670-690`) — nesting is supported.

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
and only that arm (`parse_cascade`, `lf.rs:598-607`; `apply_op`,
`lf.rs:1577-1585`). With no matching arm and no `else`, the stream passes through
untouched (`lf.rs:1587-1588, 2667-2671`). Structural rules:

- Must open with `if`; `elif`/`else` without a leading `if` is an error; a
  second `if` in an open cascade is an error (`lf.rs:621-627`).
- `else` takes no guard and is always the last arm (`lf.rs:631-635, 652-656`).
- Inline ops after `:` force a pipeline body; otherwise the body may be an
  indented pipeline or a nested cascade (`lf.rs:670-690`).

### Guards — grammar

A guard is an **AND of atoms** joined by the literal ` and ` (with surrounding
spaces) (`parse_guard`, `lf.rs:1107-1114`). Atoms (`parse_atom`, `lf.rs:1123-1128`):

- **`exit ok`** — true when exit code == 0.
- **`exit failed`** — true when exit code != 0 (covers *any* non-zero, e.g.
  grep's 1=no-match and 2=error both) (`lf.rs:1640-1641`).
- **`level ultra` / `level full` / `level lite`** — true when the current level
  matches.
- **flag atom** — any token starting with `-` is a flag guard (`lf.rs:1125-1127`).

Exactly one keyword + value per non-flag atom; `if exit boom` and extra words
are errors (`lf.rs:1132-1157`).

### Flag atoms — matching semantics (`flag_matches`, `lf.rs:1658-1668`)

Matched against `$args` (the full arg list). Two shapes:

- **Presence** — `--stat` / `-o`: true if any arg equals it, in bare
  (`--stat`) or `--flag=value` form (`--output=json` matches `--output`).
  Split is on `=`, so `--stat` does **not** match `--statistics`
  (`lf.rs:2629-2640`).
- **Flag + value** — `-o yaml` / `--output json`: true when the flag carries
  that value, written as two tokens (`-o yaml`), glued (`-o=yaml`), or — for
  2-char short flags only — concatenated (`-oyaml`) (`lf.rs:1663-1668,
  2643-2663`). So `if -o yaml: …` prunes YAML output while `-o json` falls
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
(`split_at_first_match`, `lf.rs:1696-1703`). If no line matches, everything is
`pre` and `post` is empty (`lf.rs:2410-2424`). Each half runs its own op
sub-chain (an empty `pre:`/`post:` passes that half through), then the halves
are rejoined with a newline (`join_nonempty`, `lf.rs:1612-1629, 1713-1719`).

- At least one of `pre:`/`post:` is required (`lf.rs:826-831`).
- `pre:`/`post:` blocks sit at the same indent as `split`'s op line's children
  and are consumed as siblings (`lf.rs:917-926`).
- **Ops after the split compose normally** — the trailing `head 100` above runs
  on the *rejoined* `pre+post` output, because it's just the next op in the
  rule's chain (`lf.rs:2031-2074` shows `head 100` as `ops[1]` after the
  `Split` `ops[0]`).
- `split` cannot appear inline after a rule header — it needs its block
  (`lf.rs:822-831`).

## Variables available to shell / python / regex

The executor exports these env vars to every `shell:`/`python:`/`or-shell:`
subprocess (`run_shell`, `lf.rs:1758-1768`; same set for python):

| var      | holds                                                        |
|----------|--------------------------------------------------------------|
| `$level` | current level — `ultra` / `full` / `lite`                    |
| `$sub`   | the subcommand (`$args[0]`); empty if none                   |
| `$exit`  | original command's exit code, as a string                    |
| `$args`  | full arg list, space-joined                                  |

Plus macro positional args `$1`..`$9`, substituted **before** the shell sees the
string (`expand_args`, `lf.rs:1725-1728`) — so `$1` is textual interpolation at
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
- A regex that fails to compile is a **parse-time** error (`lf.rs:1271-1272`),
  surfacing before the filter ever runs.

## Cookbook — idiomatic patterns

Distilled from the six bundled filters
(`lowfat-plugin/embedded/<cat>/<name>/filter.lf`), quoted as upstream wrote them.

🚨 **Two of these shapes are banned in pantry filters** and `scripts/lint.py`
rejects them: bare `head`/`tail` (use the marked macros in
`plugins/lib/truncation.lf`) and `awk` in a `shell:`/`or-shell:` body (POSIX
`grep -E`/`sed -nE` only). They stay printed here because this file documents
what the DSL and upstream's own filters do, not what our house rules allow —
`plugins/README.md § Truncation conventions` is the authority on the latter.

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
  matched. Put `*:` last (`lf.rs:2078-2097`).
- **`match` header rejects inline ops** — `match level: head 1` errors; arms must
  be on their own indented lines (`lf.rs:2871-2877`).
- **`split` can't be inline** — it requires `pre:`/`post:` blocks
  (`lf.rs:822-831`).
- **`define` has no one-line body** — `define x: head 1` errors; use the indented
  block (`lf.rs:511-517`).
- **Macro recognition needs a prior `define`** — calling an undefined name yields
  `unknown op` at parse, or `undefined macro` at run (`lf.rs:838-846,
  1599-1601`). Arg-count mismatch is a **runtime** error, not parse-time
  (`lf.rs:2427-2439`).
- **`or-shell` / `shell:` value-empty checks** — an empty command after the
  keyword errors (`lf.rs:809-811, 954-956`).
- **Unterminated `/regex/` or `"string"`** — hard parse errors
  (`lf.rs:2139-2142`).
- **Flag matching splits on `=`** so `--stat` ≠ `--statistics`; rely on this for
  precise flag guards (`lf.rs:2629-2640`).
- **Shell/python non-zero exit aborts the filter** (→ passthrough). Guard your
  pipelines (`awk 'NF'` etc.) so they exit 0 (`lf.rs:1793-1801`).
- **`or`/`else` test is "blank after trim"** — whitespace-only counts as empty,
  triggering the fallback (`lf.rs:1563-1564`).
- **`head auto` uses base 30** (15/30/60), **not** the base-40 head_limit that
  legacy single-filter plugins see — don't conflate the two baselines
  (`lf.rs:1675` vs `run.rs:120`).
- **`split` with no delimiter match** routes everything to `pre`; design `pre:`
  to be safe on the whole stream (`lf.rs:2410-2424`).
- **`include` brings macros, never rules** — including a working filter gives you
  its `define`s and silently drops its rules (`lf.rs:408`). Absolute paths are
  rejected and a missing file is a hard parse error, so a broken include fails
  loudly rather than degrading.
- **`$N` is not an op argument** — `head $1` is a parse error; `$N` substitutes
  only inside `shell:`/`python:`/`or-shell:` bodies (`lf.rs:1570, 1591, 1595`).
- `.lf` subprocess ops inherit the **full parent environment** — `run_shell`
  builds `Command::new("sh")` with no `env_clear()` and no `sanitized_env()`
  (`lf.rs:1804-1808`), so `$HOME`, `$PWD`, `$LOWFAT_HOME` and everything else
  are visible inside `shell:`/`python:`. (Corrected 2026-07-26: this said
  "scrubbed env, allowlist only" — that applies to legacy `filter.sh` process
  plugins, not to `.lf` ops. Verified by probe and at source.) Secrets are
  therefore *not* stripped on this path; a filter must never echo the
  environment.

## Authoring pitfalls (from building the pantry)

Practical anti-patterns that cost real debugging time while building the 64
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
   failure too, with a marked `or-shell:` tail as the over-prune fallback.
4. **`or-shell:` runs against the RAW input, not the pruned stream.** It's
   over-prune *recovery* (fires when your pipeline emptied the stream), not a
   post-transform. Use it to fall back to a marked cap of the raw stream when a
   keyword `keep` matched nothing (e.g. a crash with none of your expected
   markers) — the fallback cuts too, so it owes the same dropped-count marker.
5. **Never keyword-filter passthrough output.** For `<tool> run`/`exec`/bare
   `prettier <file>`/`cargo run`, the body is the program's own stdout or
   formatted code — keyword-filtering it hides results or corrupts code. Select
   those subcommands separately and only cap them, with the marker.
6. **Guard structured output through byte-exact.** JSON/env/formatted output must
   not be lossily capped. Branch on the flag (`if --json: raw`, `elif -F json:
   raw`, `elif -o json:`) — `--output json` matches `--output`, and flag+value
   `-o yaml` matches only that value, so you can prune YAML while passing JSON.
7. **Exit-code granularity is binary in guards.** You only get `exit ok|failed`,
   not specific codes. If 1 and 2 mean different things (eslint: 1=problems,
   2=crash), prefer a robust non-keyword approach (drop-blanks + a marked cap) so
   a crash is never silently dropped to "clean".
8. **Samples must be byte-faithful.** No inline `# synthetic:` annotations — they
   leak into filtered output and distort line counts. A sample's provenance lives
   in the rig that produced it — a stack Dockerfile plus a fixture directory under
   `capture/` — not in the sample or the test spec.
