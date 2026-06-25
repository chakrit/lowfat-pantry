// Golden-file drift tests for mypy-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/mypy/mypy-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/mypy/mypy-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/mypy/mypy-compact"
	name: "mypy-compact"
	cases: [
		{sample: "samples/mypy-errors.txt", sub: "", args: "src tests", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/mypy-clean.txt", sub: "", args: "src", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/mypy-error-exit.txt", sub: "", args: "--config-file missing.ini src", exit: 2, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
