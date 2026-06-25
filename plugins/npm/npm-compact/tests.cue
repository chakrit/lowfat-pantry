// Golden-file drift tests for npm-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/npm/npm-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/npm/npm-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/npm/npm-compact"
	name: "npm-compact"
	cases: [
		{sample: "samples/npm-install.txt", sub: "install", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/npm-test.txt", sub: "test", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/npm-error.txt", sub: "install", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/npm-install-json.txt", sub: "install", args: "install --json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
