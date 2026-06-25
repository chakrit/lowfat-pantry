// Golden-file drift tests for yarn-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/yarn/yarn-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/yarn/yarn-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/yarn/yarn-compact"
	name: "yarn-compact"
	cases: [
		{sample: "samples/yarn-install.txt", sub: "install", args: "install", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/yarn-install-error.txt", sub: "install", args: "install", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/yarn-test.txt", sub: "test", args: "test", exit: 1, levels: ["lite", "full", "ultra"]},
		// recovery hint: a capped `yarn run` script body announces "... (N lines total)".
		{sample: "samples/yarn-run-capped.txt", sub: "run", args: "run build", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
