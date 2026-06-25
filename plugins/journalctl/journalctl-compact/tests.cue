// Golden-file drift tests for journalctl-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/journalctl/journalctl-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/journalctl/journalctl-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/journalctl/journalctl-compact"
	name: "journalctl-compact"
	cases: [
		{sample: "samples/journalctl-unit.txt", sub: "-u", args: "-u checkout-api", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/journalctl-json.txt", sub: "-u", args: "-u checkout-api -o json", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/journalctl-error.txt", sub: "-u", args: "-u checkout-api", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
