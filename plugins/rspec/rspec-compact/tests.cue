// Golden-file drift tests for rspec-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/rspec/rspec-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/rspec/rspec-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/rspec/rspec-compact"
	name: "rspec-compact"
	cases: [
		{sample: "samples/rspec-pass.txt",  sub: "", args: "spec/", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rspec-fail.txt",  sub: "", args: "spec/", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rspec-error.txt", sub: "", args: "spec/broken_spec.rb", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/rspec-json.txt",  sub: "", args: "--format json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
