// Golden-file drift tests for env-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/env/env-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/env/env-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/env/env-compact"
	name: "env-compact"
	cases: [
		{sample: "samples/env-dump.txt", sub: "", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/printenv-small.txt", sub: "", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
