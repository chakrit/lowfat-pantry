// Golden-file drift tests for sqlite3-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/sqlite3/sqlite3-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/sqlite3/sqlite3-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/sqlite3/sqlite3-compact"
	name: "sqlite3-compact"
	cases: [
		{sample: "samples/sqlite3-rows.txt", sub: "", args: "app.db 'select * from orders'", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/sqlite3-error.txt", sub: "", args: "app.db 'select totl from orders'", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
