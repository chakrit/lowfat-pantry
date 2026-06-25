# Pantry output philosophy

What the pantry's plugins keep, what they cut, and why. The keep-vs-cut theory was
inherited from two ancestors — RTK (`rtk-ai/rtk`) and lowfat upstream (`zdk/lowfat`) — and
refined in practice across the built plugins. Use this as the audit yardstick for existing
filters and the spec for new ones. Operational mechanics (the `.lf` skeleton, the authoring
decision tree) live in `SKILL.md` → *Authoring a pantry plugin*; this is the rationale
above them.

## Inherited principles

From RTK's design philosophy (`CONTRIBUTING.md` → Design Philosophy) and lowfat's filter
contract (`docs/PLUGINS.md`):

- **Correctness over savings.** Flag-aware. Explicitly-requested detail (`ls -la`,
  `cargo test -- --nocapture`, `--json`) is the caller asking for the bytes — pass it
  through. Compress *default* output; when in doubt, keep more. (RTK)
- **Transparency.** Filtered output is a *subset* of the real command's output, not a new
  format. An agent that parses the raw output must parse the filtered output unchanged. No
  invented headers or markers in default output. (RTK)
- **Never block.** A filter that can't run falls back to raw — never errors, never eats the
  command. Every filter has a fallback arm. (RTK)
- **Recovery hint on truncation.** A capped list *or passthrough body* must say what it
  hid (`... (N lines total)`, "use `LOWFAT_LEVEL=lite` for the rest") so the agent can
  recover it. This bites hardest on bodies that *look complete* — a curl JSON response or
  a `<tool> run` program body head-capped silently reads as the whole output; the agent
  acts on partial data without knowing. Every length-cap of such content emits the hint
  (the shared `cap(N)` awk macro); only deliberate noise-drops the agent expects (logs
  `tail`, test pass-noise) may stay silent. (RTK)
- **Level contract.** `ultra` = verdict line(s) only · `full` = strip chatter, keep
  diffs/errors/structure · `lite` = gentle trim, higher caps · `exit≠0` = conservative,
  preserve error blocks · empty = passthrough. Target ≥80% savings at `full` on noisy
  commands while keeping every actionable line. (lowfat)

RTK's four compaction strategies name the *how*: strip noise, group similar items,
truncate redundancy, dedup repeated lines.

## Pantry invariants

Where the pantry is stricter than, or extends, the inherited principles. These are hard
rules — a violation is a bug, not a style nit.

1. **Structured output is byte-exact.** `--json` / `-o yaml` / env dumps and any
   machine-readable path are `raw`, never `keep`/`head`/`tail`. A *subset* of JSON is
   corrupt JSON — transparency for structured output means byte-identical, full stop. This
   is the highest-leverage rule; the most damaging bug class is a violation of it.
2. **Passthrough bodies are capped, never keyword-filtered.** When a command's output is
   *someone else's* output — `cargo run`, a `yarn test` script body, `ssh <remote-cmd>`, a
   `make` recipe, a `curl` response body — only length-cap it. Keyword-filtering it would
   silently drop the payload.
3. **Never hide an error.** Error and diagnostic lines survive at every level. A keep-list
   that could empty on a crash gets a raw-head fallback (`or-shell: tail N`). Failure is
   when compaction matters *most* — pull `[ERROR]` out of 500 progress lines — not a reason
   to skip filtering.
4. **Exit code is a signal, not a failure proxy.** `rg`/`diff`/`black` exit non-zero as
   *information* (no match / files differ / unformatted); `redis-cli`/`sqlite3` errors exit
   *zero*. Branch on output shape, not on `$exit` alone — a naive `if exit failed: raw`
   mishandles both ends.
5. **Over-prune is drift too.** Pruning to empty or near-empty is as much a regression as
   bloat. The golden harness (`scripts/measure.py` + smoke locks) catches it
   bidirectionally — a size change in either direction surfaces as a locked-value diff.

## Guarding structured output (the recipe)

Invariant 1 in practice. `.lf` has no top-level pre-filter and a macro can't wrap a rule's
op-cascade, so the guard **repeats in every rule that compacts**. Branch on flag **and
value**, not mere presence — `-o wide` / `--output table` must still compact:

    get:
        if exit failed: raw
        elif -o json:   raw
        elif -o yaml:   raw
        else:           <existing compaction>

Copy `aws` / `az` — the reference filters. `aws` raws on `exit failed`, compacts only
`--output table`/`text`, and lets every other shape (default JSON included) fall to `raw`;
`az` compacts only `-o table`/`tsv` + `--help`, default JSON → `raw`. Per-plugin flags worth
guarding: `-o json`/`-o yaml` (kubectl/helm), `-json` (terraform), `--format json`
(pip/golangci-lint), `--json` (npm/pulumi), `--message-format json` (cargo). Where a tool
emits the compactable shape only on the no-flag default, invert the cascade: `if --format:
raw / elif -f: raw / else: <compact>` (rspec/rubocop).

## The ultra exception

`ultra` deliberately breaks transparency: it emits verdict lines (`pytest: N passed`),
synthesized clean-states (`git status: clean`), and truncation markers (`lowfat_truncated`,
trailing counts). That is the point of the tier — a decision-grade summary, not a subset.
The constraint: **`ultra` must mark what it dropped** (invariant: recovery hint), and its
output is explicitly *not* guaranteed re-pipeable. Transparency as the ancestors defined it
holds at `full` and `lite`; `ultra` trades it for density, on the record.

## Signal vs noise

| Keep (signal)                                  | Cut (noise)                                    |
| ---------------------------------------------- | ---------------------------------------------- |
| Errors, warnings, diagnostics with location    | Progress meters, spinners, `\r` artifacts      |
| Final verdicts, summaries, tallies, counts     | Download / transfer / resolver chatter         |
| Structured / machine output (byte-exact)       | Per-item success lines (`✓`, `ok:`, `Compiling`) |
| Program / content bodies (cap only)            | Banners, box art, telemetry, log-path boilerplate |
| State changes (`changed:`, `created`, `+pkg`)  | Blank separators, debug verbosity (`debug1:`)  |
| Tail-anchored summary blocks (stats, recap)    | Source code-frames / carets under a diagnostic |

## What earns a plugin

In scope: text output, typically 100+ tokens, compressible 60%+ without losing actionable
information — test runners, linters, builds, VCS/forge CLIs, package managers, infra tools,
data-store clients.

Out of scope: interactive TUIs (not batch output), binary output (nothing to filter),
already-terse commands (overhead exceeds savings), and structured-only output that must
stay byte-exact anyway (pass it through — no plugin needed).

Build demand-driven: add or deepen a plugin on *observed* session bloat, not on a planning
pass. See `docs/spec/pantry-plugin-backlog.md` → Build posture.

## See also

- `SKILL.md` → *Authoring a pantry plugin — fast path* — the operational decision tree and
  `.lf` skeleton; this doc is its rationale.
- `docs/spec/lowfat-filter-dsl.md` — `.lf` authoring reference.
- `docs/spec/smoke-golden-tests.md` — how the golden harness enforces invariant 5.
- `plugins/CATALOG.md` — per-plugin behavior and the gotchas these invariants generalize.
