// Golden-file drift tests for prettier-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/prettier/prettier-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/prettier/prettier-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/prettier/prettier-compact"
	name: "prettier-compact"
	cases: [
		{sample: "samples/prettier-check-issues.txt", sub: "", args: "--check .", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/prettier-check-clean.txt", sub: "", args: "--check .", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/prettier-write.txt", sub: "", args: "--write .", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
