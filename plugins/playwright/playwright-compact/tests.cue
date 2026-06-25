// Golden-file drift tests for playwright-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/playwright/playwright-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/playwright/playwright-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/playwright/playwright-compact"
	name: "playwright-compact"
	cases: [
		{sample: "samples/playwright-pass.txt", sub: "test", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/playwright-fail.txt", sub: "test", args: "--project=chromium", exit: 1, levels: ["lite", "full", "ultra"]},
		// invariant 1: --reporter=json is byte-exact machine output; the guard must pass it raw.
		{sample: "samples/playwright-json.txt", sub: "test", args: "test --reporter=json", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
