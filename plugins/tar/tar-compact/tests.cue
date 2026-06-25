// Golden-file drift tests for tar-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/tar/tar-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/tar/tar-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/tar/tar-compact"
	name: "tar-compact"
	cases: [
		{sample: "samples/tar-list.txt", sub: "", args: "-tvf archive.tar", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/tar-error.txt", sub: "", args: "-tvf missing.tar", exit: 2, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
