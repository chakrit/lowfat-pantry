// Golden-file drift tests for bun-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/bun/bun-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/bun/bun-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/bun/bun-compact"
	name: "bun-compact"
	cases: [
		{sample: "samples/bun-install.txt", sub: "add", args: "add react", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/bun-test-fail.txt", sub: "test", args: "test", exit: 1, levels: ["lite", "full", "ultra"]},
		// recovery hint: a capped `bun run` program body announces "... (N lines total)".
		{sample: "samples/bun-run-capped.txt", sub: "run", args: "run build", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
