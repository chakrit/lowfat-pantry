// Golden-file drift tests for rake-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/rake/rake-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/rake/rake-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/rake/rake-compact"
	name: "rake-compact"
	cases: [
		{sample: "samples/rake-build.txt", sub: "build", args: "build", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rake-fail.txt",  sub: "boom", args: "boom", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rake-list.txt",  sub: "-T", args: "-T", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
