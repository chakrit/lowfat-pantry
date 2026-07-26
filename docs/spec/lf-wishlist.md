# lowfat engine wishlist

Engine/CLI capabilities the **upstream** lowfat would need for the pantry to stop working
around its limits. Not pantry features — these live in `zdk/lowfat`
(<https://github.com/zdk/lowfat>), the Rust crates (`lowfat-core`/`lowfat-plugin`/
`lowfat-runner`/`lowfat`) that the `.lf` DSL and run path come from.

Each item: the problem, what the pantry does *instead* (the workaround we carry), and the
proposed shape. **This file is the log; issues are filed upstream only on request.** When
one is, link it under that item; otherwise the `Upstream issue` field stays empty.

Context (checked **2026-06-16**): `zdk/lowfat` had 0 open / 1 closed issue (#9, an unrelated
git-compact `Broken pipe`) and 1 open PR (#8, MCP server) — none of these items exist there.

**Re-checked 2026-07-26 against the v0.8.0 sources.** #1 is **delivered** — closed
upstream and shipped. #2, #3 and #4 are still absent: no runner table or unwrap
anywhere in the tree, the subprocess env block still exports exactly
`level`/`sub`/`exit`/`args` (`lf.rs:1765-1768`), and `lowfat filter` still takes a path
only. #5 survives but was **mis-scoped** — see the item for the corrected trigger.

---

## 1. `include` / `import` for `.lf` files (filter composition) — ✅ DELIVERED in v0.8.0

**Status.** Shipped upstream, essentially as proposed: `include <relative-path>` merges
the included file's `define`s at parse time, rules excluded. Transitive, cycle-checked,
diamond-safe, local-define-wins. Full semantics in `docs/vendor/lowfat-filter-dsl.md §
include`. **Adopted 2026-07-26** for the truncation macros: they live once in
`plugins/lib/truncation.lf` and every filter includes `../../lib/truncation.lf`. The
distribution question — absolute paths are rejected and plugins sync per-plugin into
`<LOWFAT_HOME>/plugins/<cat>/<name>/` — resolved because the install tree mirrors the
pantry layout, with the sync linking `plugins/lib` alongside.

The wrapper duplication below is **still open**: `include` fits it (rules are excluded, so
a wrapper can pull `../../pytest/pytest-compact/filter.lf` for its macros alone), but no
pass has done it.

**Problem** (as originally filed). Macros are file-local (`collect_macro_names` runs per
file; no include op), so a `.lf` filter can't reuse another's logic. A wrapper filter that
wants the wrapped tool's compaction must **copy** that tool's macro body verbatim.

**Workaround in pantry.** `uv-compact` and `npx-compact` each copy their wrapped tools'
bodies (pytest/ruff into uv; eslint/prettier/tsc into npx) under a "drift contract" comment.
The copies rot whenever the standalone originals change. See backlog → "Wrapper commands".

**Proposed shape.** An `include path/to/lib.lf` (or `use`) directive that pulls another
file's `define`d macros into the current namespace at parse time. Lets shared tool logic
live once in a library `.lf` that both the standalone filter and any wrapper `include`s.

**Upstream issue.** <https://github.com/zdk/lowfat/issues/14> — closed; landed in v0.8.0.

## 2. Wrapper-unwrap (runner-prefix re-resolution) — the cleanest fix

**Problem.** Filter selection keys on the **first token** (`commands = [...]` matched against
the command word). So `uv run pytest`, `uvx ruff`, `npx eslint`, `poetry run mypy` select on
the *runner* (`uv`/`npx`/…), and the wrapped tool's own filter never fires. `lowfat rewrite
uv run pytest` returns the command verbatim — no unwrap exists in 0.6.8.

**Workaround in pantry.** Per-runner dispatcher plugins (`uv-compact`, `npx-compact`) that
re-implement tool detection from `$args` and duplicate each wrapped tool's compaction (see
#1). One dispatcher per runner; the wrapped-tool sets are disjoint (uv→Python, npx→Node) so
they share nothing.

**Proposed shape.** A known-runner table (`uv run`, `uvx`, `uv tool run`, `npx`, `bunx`,
`poetry run`, `pnpm exec`/`dlx`, `pdm run`, `hatch run`, `nix run`, …). When the command
word is a runner, strip the prefix to the inner command word + args, then re-resolve the
filter against the inner word with re-derived `$sub`/`$args`. Covers the whole class in core
**once**, lets `uv-compact`/`npx-compact` drop their dispatch entirely, and routes
`uv run pytest` → `pytest-compact` with zero duplication. Supersedes #1 for this use case.

**Upstream issue.** _none filed yet_

## 3. Expose the command word to filters (`$cmd` / `$0`)

**Problem.** Filters receive `$sub` (=`$args[0]`), `$args`, `$exit`, `$level` — but **not**
the command word. `pytest tests/` passes `args=["tests/"]`, nothing identifying pytest; the
standalone filter works only because lowfat already routed by command word. So a single
content-blind dispatcher symlinked across plugins can't self-identify (and `uv sync` vs
`npx sync` is genuinely ambiguous without it).

**Workaround in pantry.** None possible — we keep one filter per command and rely on routing.

**Proposed shape.** Export the matched command word as `$cmd` (and/or `$0`) to
`shell:`/`python:`/`or-shell:` subprocesses, alongside the existing four. Cheap, and unblocks
content-blind shared dispatchers.

**Upstream issue.** _none filed yet_

## 4. `lowfat filter --plugin <name>` (run a discovered plugin's filter on stdin)

**Problem.** `lowfat filter <path.lf>` runs a `.lf` against stdin, but only by **path**. A
wrapper that wanted to delegate to a tool's real filter via a `shell:` op would have to
hardcode the install path (`<home>/plugins/<cat>/<name>/filter.lf`), which varies with home
resolution and runs under a scrubbed env — too brittle to use.

**Workaround in pantry.** We don't delegate; we copy (#1). Brittle shell-out was rejected.

**Proposed shape.** `lowfat filter --plugin pytest-compact` resolves the named plugin through
normal discovery and runs its filter against stdin, with `--sub/--args/--exit/--level`
forwarded. Gives wrappers a stable delegation target without path-hardcoding — a lighter-
weight alternative to #1/#2 if those are too invasive.

**Upstream issue.** _none filed yet_

## 5. Non-ASCII literals corrupted inside `define` macro bodies (`$N` arg-expansion bug)

**Problem.** A literal multibyte glyph (`●`, `❯`, `×`, `→`, `⎯`) inside the
`shell:`/`python:`/`or-shell:` body of a macro **that takes parameters** is mangled by the
`$N` arg-expansion pass, so a match on that glyph silently never fires (no crash). Cause:
`expand_args` walks the body byte-wise and re-emits each byte as a `char`
(`out.push(c as char)`, `lf.rs:1748`), which shreds every multibyte UTF-8 sequence.
Still present in v0.8.0, unchanged.

**Scope correction (2026-07-26).** This item — and the DSL reference — previously claimed
the bug also hit `keep`/`drop` regexes in macros. **It does not.** `expand_args` is
applied at exactly three call sites, all string-valued ops (`lf.rs:1570, 1591, 1595`);
regexes are compiled at parse time and never pass through it. It also early-returns the
body untouched when the macro has no parameters (`lf.rs:1726-1728`). Verified empirically
at 0.8.0: `keep /●/` inside `define g(n)` matches correctly; the same glyph in that
macro's `python:` body does not. So the trigger needs all three of: parameters, a
shell/python body, and a non-ASCII literal.

**Workaround in pantry.** `jest`/`vitest` matchers are ASCII-only — the `ultra` keep-list is
bounded by ASCII text (`FAIL`, `Expected/Received`, `AssertionError`) instead of the runners'
glyph lines. `full`/`lite` keep the failure block wholesale, so glyph lines survive via
passthrough; no signal loss. Given the correction above this workaround is **stricter than
required** (those are `keep` regexes, which were never at risk); it is harmless and stays
until someone has a reason to touch those filters.

**Proposed shape.** Make `$N` arg-expansion operate on a decoded string (or only on
`$`-prefixed tokens), not raw bytes, so multibyte literals in macro bodies round-trip
unchanged. Until then, the DSL spec should warn: don't key matches on non-ASCII glyphs
inside a `define`.

**Upstream issue.** _none filed yet_
