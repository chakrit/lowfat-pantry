// Golden-file drift tests for jq-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/jq/jq-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/jq/jq-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/jq/jq-compact"
	name: "jq-compact"
	cases: [
		{sample: "samples/jq-array.txt", sub: "", args: ".", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/jq-raw.txt", sub: "", args: "-r .name", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/jq-error.txt", sub: "", args: ".", exit: 4, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
