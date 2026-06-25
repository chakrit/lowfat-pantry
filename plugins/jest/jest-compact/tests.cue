// Golden-file drift tests for jest-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/jest/jest-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/jest/jest-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/jest/jest-compact"
	name: "jest-compact"
	cases: [
		{sample: "samples/jest-fail.txt", sub: "", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/jest-pass.txt", sub: "", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/jest-json.txt", sub: "", args: "--json", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
