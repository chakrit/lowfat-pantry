# lowfat engine wishlist

Engine/CLI capabilities the **upstream** lowfat would need for the pantry to stop working
around its limits. Not pantry features — these live in `zdk/lowfat`
(<https://github.com/zdk/lowfat>), the Rust crates (`lowfat-core`/`lowfat-plugin`/
`lowfat-runner`/`lowfat`) that the `.lf` DSL and run path come from.

Each item: the problem, what the pantry does *instead* (the workaround we carry), and the
proposed shape. **This file is the log — nothing is filed upstream.** If an item ever does
get an issue, link it under that item; otherwise the `Upstream issue` field stays empty.

Context (checked **2026-06-16**): `zdk/lowfat` had 0 open / 1 closed issue (#9, an unrelated
git-compact `Broken pipe`) and 1 open PR (#8, MCP server) — none of these items exist there.

---

## 1. `include` / `import` for `.lf` files (filter composition)

**Problem.** Macros are file-local (`collect_macro_names` runs per file; no include op), so
a `.lf` filter can't reuse another's logic. A wrapper filter that wants the wrapped tool's
compaction must **copy** that tool's macro body verbatim.

**Workaround in pantry.** `uv-compact` and `npx-compact` each copy their wrapped tools'
bodies (pytest/ruff into uv; eslint/prettier/tsc into npx) under a "drift contract" comment.
The copies rot whenever the standalone originals change. See backlog → "Wrapper commands".

**Proposed shape.** An `include path/to/lib.lf` (or `use`) directive that pulls another
file's `define`d macros into the current namespace at parse time. Lets shared tool logic
live once in a library `.lf` that both the standalone filter and any wrapper `include`s.

**Upstream issue.** _none filed yet_

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
