// Golden-file drift tests for json-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/json/json-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/json/json-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/json/json-compact"
	name: "json-compact"
	cases: [
		{sample: "samples/json-array.txt", sub: "pretty", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/json-object.txt", sub: "compact", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
