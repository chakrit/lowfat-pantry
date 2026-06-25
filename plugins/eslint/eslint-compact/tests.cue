// Golden-file drift tests for eslint-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/eslint/eslint-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/eslint/eslint-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/eslint/eslint-compact"
	name: "eslint-compact"
	cases: [
		{sample: "samples/eslint-problems.txt", sub: "", args: ".", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/eslint-clean.txt", sub: "", args: ".", exit: 0, levels: ["lite", "full", "ultra"]},
		// recovery hint: a capped findings list announces "... (N lines total)" (the
		// `✖ N problems` summary can't be keyword-kept, so the hint is the only signal).
		{sample: "samples/eslint-many.txt", sub: "", args: "src", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
