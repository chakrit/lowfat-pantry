// Golden-file drift tests for ls-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/ls/ls-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/ls/ls-compact/tests.cue     # re-lock intentionally
//
// ls-long-listing is the regression guard: 146 entries must survive ultra intact,
// because the bundled filter this one shadows cut them to 40 with no marker.
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/ls/ls-compact"
	name: "ls-compact"
	cases: [
		{sample: "samples/ls-multi-dir.txt", sub: "", args: "-l alpha beta", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/ls-long-listing.txt", sub: "", args: "/usr/bin", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/ls-missing-path.txt", sub: "", args: "/no/such/path", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
