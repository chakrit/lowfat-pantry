// Golden-file drift tests for black-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/black/black-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/black/black-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/black/black-compact"
	name: "black-compact"
	cases: [
		{sample: "samples/black-reformat.txt", sub: "", args: ".", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/black-check.txt", sub: "", args: "--check .", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/black-clean.txt", sub: "", args: ".", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
