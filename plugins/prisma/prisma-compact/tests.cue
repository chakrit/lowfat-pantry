// Golden-file drift tests for prisma-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/prisma/prisma-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/prisma/prisma-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/prisma/prisma-compact"
	name: "prisma-compact"
	cases: [
		{sample: "samples/prisma-generate.txt", sub: "generate", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/prisma-migrate.txt", sub: "migrate", args: "deploy", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/prisma-error.txt", sub: "migrate", args: "dev", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
