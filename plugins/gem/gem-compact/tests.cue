// Golden-file drift tests for gem-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/gem/gem-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/gem/gem-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/gem/gem-compact"
	name: "gem-compact"
	cases: [
		{sample: "samples/gem-install.txt", sub: "install", args: "install tty-spinner", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/gem-error.txt",   sub: "install", args: "install this-gem-does-not-exist-xyz123", exit: 2, levels: ["lite", "full", "ultra"]},
		{sample: "samples/gem-list.txt",    sub: "list", args: "list", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
