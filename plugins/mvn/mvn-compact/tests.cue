// Golden-file drift tests for mvn-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/mvn/mvn-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/mvn/mvn-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/mvn/mvn-compact"
	name: "mvn-compact"
	cases: [
		{sample: "samples/mvn-test-success.txt", sub: "test", args: "test", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/mvn-reactor-success.txt", sub: "install", args: "install", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/mvn-test-failure.txt", sub: "test", args: "test", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
