# lowfat engine wishlist

Engine/CLI capabilities the **upstream** lowfat would need for the pantry to stop working
around its limits. Not pantry features — these live in `zdk/lowfat`
(<https://github.com/zdk/lowfat>), the Rust crates (`lowfat-core`/`lowfat-plugin`/
`lowfat-runner`/`lowfat`) that the `.lf` DSL and run path come from.

Each item: the problem, what the pantry does *instead* (the workaround we carry), and the
proposed shape. **This file is the log; issues are filed upstream only on request.** When
one is, link it under that item; otherwise the `Upstream issue` field stays empty.

**This is the single home for upstream asks** (2026-07-27) — nothing upstream is tracked in
the session ledger any more. A `zdk/smoke` section sits at the end so one read covers every
"should we file this?" question.

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

The wrapper duplication below is **not** fixed by it, contrary to the original filing:
`include` moves `.lf` *macros*, while a wrapper dispatches on `$args` at runtime inside a
shell body, which cannot call a macro. It was solved another way — the wrappers now
**delegate**, re-invoking `lowfat filter` on the wrapped tool's own filter (2026-07-26),
so the duplication is gone without waiting for #2. `scripts/drift.py` guards the dispatch.

**Problem** (as originally filed). Macros are file-local (`collect_macro_names` runs per
file; no include op), so a `.lf` filter can't reuse another's logic. A wrapper filter that
wants the wrapped tool's compaction must **copy** that tool's macro body verbatim.

**Resolved in pantry without upstream** (2026-07-26). `uv-compact` and `npx-compact` used
to copy their wrapped tools' bodies (pytest/ruff into uv; eslint/prettier/tsc into npx)
under a "drift contract"; the copies are gone. Each wrapper resolves the wrapped tool,
probes `$LOWFAT_HOME`/`~/.lowfat`/`~/.config/lowfat`/`$PWD` for that plugin, and `exec`s
`lowfat filter` on it — byte-identical to invoking the wrapped filter directly, with a
marked generic cap when the plugin isn't installed. Wrapper-unwrap (#2) would still be
better: it would retire the dispatch code itself. See backlog → "Wrapper commands".

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

**Problem.** `lowfat filter <path.lf>` runs a `.lf` against stdin, but only by **path**, so
a wrapper delegating to a tool's real filter has to reconstruct the install path
(`<home>/plugins/<cat>/<name>/filter.lf`), which varies with home resolution.

**Workaround in pantry.** The wrappers *do* delegate (2026-07-26): they probe
`$LOWFAT_HOME`, `~/.lowfat`, `~/.config/lowfat` and `$PWD` for the sibling plugin and
`exec lowfat filter` on it, falling back to a marked cap when it isn't installed. This was
previously called off as "brittle shell-out under a scrubbed env" — the env claim was
wrong: `shell:` bodies inherit the full parent environment at v0.8.0, `$HOME` included.
What remains brittle is the probe list itself, which is exactly what this ask retires.

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

## 6. `.lf` `head`/`tail` cut silently (no marker)

**Problem.** The `.lf` ops `head`/`tail` drop lines with nothing to say they did
(`take_head`/`take_tail`, `lf.rs:1683-1691`), so a truncated stream is byte-identical to a
genuinely short one and a reader acts on a *confident wrong answer*. The identically named
**pipeline** processor is fine — `proc_truncate` appends `... (N lines truncated)`. The two
paths just never converged. This is the root cause of pantry issue #1 (`tofu state list`
returned 15 of 36 resources with no marker). **Re-verified unchanged at v0.8.0.**

**Workaround in pantry.** The whole visible-truncation regime: `plugins/lib/truncation.lf`
provides marked replacements (`head-marked`, `head-auto-marked`, `tail-marked`,
`tail-auto-marked`, `cap`) and **no pantry filter uses a bare `head`/`tail` op any more**
(2026-07-27 sweep, completed 2026-07-28 — the first pass left 42 ops written inline after a
match-arm label, which the lint gate could not see). Ruling and radius:
`docs/decisions/2026-07-26-visible-truncation.md`.

**Proposed shape.** Have the `.lf` ops mark like `proc_truncate` already does — same
`...`-prefixed trailer, with the dropped count — or gate it behind an opt-out for the rare
caller that wants a silent cut. Fixing it upstream covers every plugin *and* the six
bundled filters at once, and would let the pantry retire most of its library.

**Upstream issue.** _none filed yet_

## 7. `lowfat hook` auto-approves every filtered command

**Problem.** The hook returns `permissionDecision: "allow"` alongside the rewritten command
(`hook.rs:31-42`), so every command lowfat has a filter for — `git`, `gh`, `curl`, `docker`,
`kubectl`, … — sails past the agent's permission prompt. Installing a *token compactor*
silently widens the agent's blast radius, which is not a trade a user knowingly made.

**Workaround in pantry.** `SKILL.md` step 5 warns before wiring the hook and defaults the
scope to project-local. That is documentation, not a fix — the permission surface is still
widened for anyone who accepts.

**Proposed shape.** Emit `updatedInput` *without* `permissionDecision`, letting the host
agent apply its normal permission rules to the rewritten command. If auto-approval is
wanted, it belongs behind an explicit opt-in flag, off by default.

**Upstream issue.** _none filed yet_

---

## Other upstream — `zdk/smoke`

Not lowfat, kept here so there is one place to look before filing anything.

**Multi-spec compare skips specs 2..N.** Default compare mode `os.Exit()`s after the first
spec (`process.go:282`), so `smoke a.cue b.cue` silently reports only `a`. Verified and
reported to the smoke agent; the fix waits on a call about exit semantics (what the
aggregate exit code should be when specs disagree). **Workaround:** `scripts/test.sh` loops
one spec per invocation, which we keep anyway for per-plugin attribution.

**Upstream issue.** _none filed yet_

## 8. A fallback that can call a macro (`or-macro` / macro-valued `or-shell`)

**Problem.** `or "text"` takes a literal and `or-shell:` takes a one-line shell command —
neither can call a `define`d macro. The fallback is exactly where a filter most wants one:
it fires on over-pruning, so it must re-truncate the *raw* input and mark what it dropped,
which is precisely what `tail-marked`/`head-marked` already do. Since a macro is
unreachable there, every fallback re-implements the macro inline, on one line, per rule.

**Workaround in pantry.** 33 near-identical `or-shell:` one-liners across 25 filters, each
a hand-inlined copy of `tail-marked <n>`:

    or-shell: s=$(cat); n=$(printf '%s\n' "$s" | wc -l); if [ "$n" -gt 40 ]; then printf '[lowfat] +%d earlier lines dropped (level=%s) -- …\n' "$((n-40))" "${level:-full}"; fi; printf '%s\n' "$s" | tail -40

They drift as a class: a marker-format change means editing all 33 (done twice now), and
`scripts/overprune.py` exists partly because a typo in one of them fails silently. The
`include` work removed this duplication everywhere *except* here, because here it isn't a
macro-sharing problem — the fallback slot simply can't hold a macro call.

**Proposed shape.** Let a fallback name a macro: `or-macro tail-marked 40`, or accept a
macro call wherever `or-shell:` takes a command. Same "fires only when blank, runs against
the raw rule input" semantics — only the callee changes. That collapses 33 inline copies to
33 one-word calls and makes the fallback path share the library everything else already
shares.

**Upstream issue.** _none filed yet_

## 9. `$N` cannot be an op argument, so a parameterized macro can't call a library macro

**Problem.** Macro args reach only `shell:`/`python:`/`or-shell:` bodies; `head $1` is a
hard parse error and `head-marked $1` passes the literal string `$1` through, which the
callee then fails to resolve. A `define compact-x(limit)` that wants to end in a marked
truncation therefore cannot call `head-marked` at all — the one place the shared library
would pay off most.

**Workaround in pantry.** `dotnet`, `npm` and `pnpm` each carry a verbatim copy of
`head-marked`'s body inside their extraction macro, with `$1` in place of the limit. Three
copies of a library macro that exists, for want of one substitution. Sibling of #8: both
are slots the library can't reach.

**Proposed shape.** Substitute `$N` in op arguments too — parse the op's argument after
arg-expansion rather than before — so `head-marked $1` inside a parameterized macro means
what it reads as.

**Upstream issue.** _none filed yet_
