// Golden-file drift tests for apk-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/apk/apk-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/apk/apk-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/apk/apk-compact"
	name: "apk-compact"
	cases: [
		{sample: "samples/apk-add.txt", sub: "add", args: "add jq", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/apk-add-error.txt", sub: "add", args: "add nosuchpkg123", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
