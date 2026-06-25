// Golden-file drift tests for dnf-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/dnf/dnf-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/dnf/dnf-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/dnf/dnf-compact"
	name: "dnf-compact"
	cases: [
		{sample: "samples/dnf-install.txt", sub: "install", args: "install -y jq", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/dnf-install-error.txt", sub: "install", args: "install -y nosuchpkg123", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
