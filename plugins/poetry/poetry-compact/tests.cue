// Golden-file drift tests for poetry-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/poetry/poetry-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/poetry/poetry-compact/tests.cue     # re-lock intentionally
// nameParts keys by sample+sub to match the committed lock.
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/poetry/poetry-compact"
	name: "poetry-compact"
	nameParts: ["sample", "sub"]
	cases: [
		{sample: "samples/poetry-install.txt", sub: "install", args: "install --no-root", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/poetry-lock.txt", sub: "lock", args: "lock", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/poetry-fail.txt", sub: "lock", args: "lock", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/poetry-show-json.txt", sub: "show", args: "show -f json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
