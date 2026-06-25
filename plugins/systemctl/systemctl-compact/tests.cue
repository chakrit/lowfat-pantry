// Golden-file drift tests for systemctl-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/systemctl/systemctl-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/systemctl/systemctl-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/systemctl/systemctl-compact"
	name: "systemctl-compact"
	cases: [
		{sample: "samples/systemctl-status.txt", sub: "status", args: "status nginx", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/systemctl-list-units.txt", sub: "list-units", args: "list-units --type=service", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/systemctl-is-active.txt", sub: "is-active", args: "is-active nginx", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/systemctl-status-failed.txt", sub: "status", args: "status checkout-worker", exit: 3, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
