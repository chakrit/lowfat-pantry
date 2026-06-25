// Golden-file drift tests for golangci-lint-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/golangci-lint/golangci-lint-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/golangci-lint/golangci-lint-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/golangci-lint/golangci-lint-compact"
	name: "golangci-lint-compact"
	cases: [
		{sample: "samples/golangci-issues.txt", sub: "run", args: "run ./...", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/golangci-clean.txt", sub: "run", args: "run ./...", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/golangci-configerr.txt", sub: "run", args: "run ./...", exit: 3, levels: ["lite", "full", "ultra"]},
		// invariant 1: v2 --output.json.path is machine output; the guard must pass it raw.
		{sample: "samples/golangci-json.txt", sub: "run", args: "run --output.json.path stdout ./...", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
