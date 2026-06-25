// Golden-file drift tests for diff-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/diff/diff-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/diff/diff-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/diff/diff-compact"
	name: "diff-compact"
	cases: [
		{sample: "samples/diff-unified.txt", sub: "", args: "-u old.txt new.txt", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/diff-context-heavy.txt", sub: "", args: "-u before.py after.py", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/diff-error.txt", sub: "", args: "-u missing.txt new.txt", exit: 2, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
