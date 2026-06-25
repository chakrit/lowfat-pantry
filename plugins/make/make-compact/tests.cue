// Golden-file drift tests for make-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/make/make-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/make/make-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/make/make-compact"
	name: "make-compact"
	cases: [
		{sample: "samples/make-success.txt", sub: "", args: "release", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/make-failure.txt", sub: "", args: "release", exit: 2, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
