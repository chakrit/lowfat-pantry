// Golden-file drift tests for bundle-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/bundle/bundle-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/bundle/bundle-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/bundle/bundle-compact"
	name: "bundle-compact"
	cases: [
		{sample: "samples/bundle-install.txt", sub: "install", args: "install", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/bundle-error.txt",   sub: "install", args: "install", exit: 7, levels: ["lite", "full", "ultra"]},
		{sample: "samples/bundle-list.txt",    sub: "list", args: "list", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
