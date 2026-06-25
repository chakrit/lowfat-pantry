// Golden-file drift tests for rg-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/rg/rg-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/rg/rg-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/rg/rg-compact"
	name: "rg-compact"
	cases: [
		{sample: "samples/rg-search-full.txt", sub: "", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rg-numbered-full.txt", sub: "", args: "-n", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rg-count-full.txt", sub: "", args: "--count", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rg-files-full.txt", sub: "", args: "-l", exit: 0, levels: ["lite", "full", "ultra"]},
		// invariant 1: --json is a byte-exact ndjson stream; the guard must pass it raw.
		{sample: "samples/rg-json.txt", sub: "", args: "--json raw", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
