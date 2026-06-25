// Golden-file drift tests for pytest-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/pytest/pytest-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/pytest/pytest-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/pytest/pytest-compact"
	name: "pytest-compact"
	cases: [
		{sample: "samples/pytest-fail.txt", sub: "", args: "tests/", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pytest-pass.txt", sub: "", args: "tests/", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pytest-error.txt", sub: "", args: "tests/test_config.py", exit: 2, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
