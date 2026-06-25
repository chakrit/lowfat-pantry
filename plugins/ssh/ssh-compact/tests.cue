// Golden-file drift tests for ssh-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/ssh/ssh-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/ssh/ssh-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/ssh/ssh-compact"
	name: "ssh-compact"
	cases: [
		{sample: "samples/ssh-verbose.txt", sub: "", args: "-v web1.prod", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/ssh-error.txt", sub: "", args: "-v web9.prod", exit: 255, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
