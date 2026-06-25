// Golden-file drift tests for glab-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/glab/glab-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/glab/glab-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/glab/glab-compact"
	name: "glab-compact"
	cases: [
		{sample: "samples/glab-mr-list.txt", sub: "mr", args: "list", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/glab-ci-trace.txt", sub: "ci", args: "trace --trace", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/glab-mr-json.txt", sub: "mr", args: "view 214 -F json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
