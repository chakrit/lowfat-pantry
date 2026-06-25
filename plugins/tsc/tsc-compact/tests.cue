// Golden-file drift tests for tsc-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/tsc/tsc-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/tsc/tsc-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/tsc/tsc-compact"
	name: "tsc-compact"
	cases: [
		{sample: "samples/tsc-errors.txt", sub: "", args: "--noEmit", exit: 2, levels: ["lite", "full", "ultra"]},
		{sample: "samples/tsc-clean.txt", sub: "", args: "--noEmit", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
