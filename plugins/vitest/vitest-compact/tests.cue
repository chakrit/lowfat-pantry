// Golden-file drift tests for vitest-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/vitest/vitest-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/vitest/vitest-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/vitest/vitest-compact"
	name: "vitest-compact"
	cases: [
		{sample: "samples/vitest-fail.txt", sub: "", args: "run", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/vitest-pass.txt", sub: "", args: "run", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/vitest-json.txt", sub: "", args: "run --reporter=json", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/vitest-junit.txt", sub: "", args: "run --reporter=junit", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
