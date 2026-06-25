// Golden-file drift tests for gh-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/gh/gh-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/gh/gh-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/gh/gh-compact"
	name: "gh-compact"
	cases: [
		{sample: "samples/gh-pr-list.txt", sub: "pr", args: "list", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/gh-run-view.txt", sub: "run", args: "view 994203", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/gh-run-log.txt", sub: "run", args: "view 994203 --log", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/gh-pr-json.txt", sub: "pr", args: "view 12 --json number,state,title", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
