// Golden-file drift tests for pip-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/pip/pip-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/pip/pip-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/pip/pip-compact"
	name: "pip-compact"
	cases: [
		{sample: "samples/pip-install.txt", sub: "install", args: "install requests", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pip-install-error.txt", sub: "install", args: "install nonexistent-package-xyz", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pip-list.txt", sub: "list", args: "list", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pip-list-json.txt", sub: "list", args: "list --format json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
