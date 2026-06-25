// Golden-file drift tests for psql-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/psql/psql-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/psql/psql-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/psql/psql-compact"
	name: "psql-compact"
	cases: [
		{sample: "samples/psql-select.txt", sub: "", args: "-c \\\"select * from orders\\", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/psql-dt.txt", sub: "", args: "-c \\\"\\\\dt\\", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/psql-error.txt", sub: "", args: "-c \\\"select id, totl from orders\\", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
