// Golden-file drift tests for next-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/next/next-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/next/next-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/next/next-compact"
	name: "next-compact"
	cases: [
		{sample: "samples/next-build.txt", sub: "build", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/next-build-warning.txt", sub: "build", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/next-build-error.txt", sub: "build", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
