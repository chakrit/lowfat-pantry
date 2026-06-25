// Golden-file drift tests for npx-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/npx/npx-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/npx/npx-compact/tests.cue     # re-lock intentionally
// nameParts keys by sample+args: two cases reuse npx-eslint.txt (eslint vs -y),
// so sample+level alone collides — a duplicate test name (smoke exit 65).
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/npx/npx-compact"
	name: "npx-compact"
	nameParts: ["sample", "args"]
	cases: [
		{sample: "samples/npx-eslint.txt", sub: "eslint", args: "eslint src", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/npx-eslint.txt", sub: "-y", args: "-y eslint src", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/npx-prettier-check.txt", sub: "prettier", args: "prettier --check src", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/npx-create.txt", sub: "create-vite", args: "create-vite demo", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/npx-error.txt", sub: "tsc", args: "tsc --noEmit", exit: 2, levels: ["lite", "full", "ultra"]},
		// recovery hint: a capped generic `npx <tool>` body announces "... (N lines total)".
		{sample: "samples/npx-generic-capped.txt", sub: "mytool", args: "mytool --build", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
