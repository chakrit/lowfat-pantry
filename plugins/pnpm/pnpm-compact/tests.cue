// Golden-file drift tests for pnpm-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/pnpm/pnpm-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/pnpm/pnpm-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/pnpm/pnpm-compact"
	name: "pnpm-compact"
	cases: [
		{sample: "samples/pnpm-install.txt", sub: "install", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pnpm-test.txt", sub: "test", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pnpm-error.txt", sub: "install", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
		// invariant 1: --json is byte-exact machine output; the guard must pass it raw.
		{sample: "samples/pnpm-ls-json.txt", sub: "ls", args: "ls --json --depth=Infinity", exit: 0, levels: ["lite", "full", "ultra"]},
		// recovery hint: a capped `pnpm run` script body announces "... (N lines total)".
		{sample: "samples/pnpm-run-capped.txt", sub: "run", args: "run build", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
