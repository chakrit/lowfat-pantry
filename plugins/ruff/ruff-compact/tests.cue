// Golden-file drift tests for ruff-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/ruff/ruff-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/ruff/ruff-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/ruff/ruff-compact"
	name: "ruff-compact"
	cases: [
		{sample: "samples/ruff-findings.txt", sub: "check", args: ".", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/ruff-clean.txt", sub: "check", args: ".", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/ruff-error.txt", sub: "check", args: "--config missing.toml .", exit: 2, levels: ["lite", "full", "ultra"]},
		// invariant 1: --output-format json is machine output; the guard must pass it raw.
		{sample: "samples/ruff-json-clean.txt", sub: "check", args: "check --output-format json .", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/ruff-json-issues.txt", sub: "check", args: "check --output-format json .", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
