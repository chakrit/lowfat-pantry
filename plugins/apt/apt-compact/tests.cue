// Golden-file drift tests for apt-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/apt/apt-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/apt/apt-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/apt/apt-compact"
	name: "apt-compact"
	cases: [
		{sample: "samples/apt-install.txt", sub: "install", args: "install -y --no-install-recommends jq", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/apt-install-error.txt", sub: "install", args: "install -y nosuchpkg123", exit: 100, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
