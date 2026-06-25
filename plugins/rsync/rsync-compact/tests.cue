// Golden-file drift tests for rsync-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/rsync/rsync-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/rsync/rsync-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/rsync/rsync-compact"
	name: "rsync-compact"
	cases: [
		{sample: "samples/rsync-transfer.txt", sub: "", args: "-av src/ host:/dst/", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rsync-error.txt", sub: "", args: "-av /missing/ host:/dst/", exit: 23, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
