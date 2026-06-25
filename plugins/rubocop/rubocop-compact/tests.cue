// Golden-file drift tests for rubocop-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/rubocop/rubocop-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/rubocop/rubocop-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/rubocop/rubocop-compact"
	name: "rubocop-compact"
	cases: [
		{sample: "samples/rubocop-clean.txt",    sub: "", args: "lib/", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rubocop-findings.txt", sub: "", args: "lib/", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rubocop-error.txt",    sub: "", args: "lib/nonexistent_file.rb", exit: 2, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rubocop-json.txt",     sub: "", args: "--format json", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
