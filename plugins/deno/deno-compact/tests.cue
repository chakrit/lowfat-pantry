// Golden-file drift tests for deno-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/deno/deno-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/deno/deno-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/deno/deno-compact"
	name: "deno-compact"
	cases: [
		{sample: "samples/deno-test-fail.txt", sub: "test", args: "test", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/deno-check-clean.txt", sub: "check", args: "check main.ts", exit: 0, levels: ["lite", "full", "ultra"]},
		// invariant 1: --json is byte-exact machine output; the guard must pass it raw.
		{sample: "samples/deno-lint-json.txt", sub: "lint", args: "lint --json mod.ts", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/deno-info-json.txt", sub: "info", args: "info --json mod.ts", exit: 0, levels: ["lite", "full", "ultra"]},
		// recovery hint: a capped `deno run` program body announces "... (N lines total)".
		{sample: "samples/deno-run-capped.txt", sub: "run", args: "run server.ts", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
