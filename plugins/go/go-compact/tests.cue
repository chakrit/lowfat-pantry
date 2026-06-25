// Golden-file drift tests for go-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/go/go-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/go/go-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/go/go-compact"
	name: "go-compact"
	cases: [
		{sample: "samples/go-test-fail.txt", sub: "test", args: "./...", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/go-build-error.txt", sub: "build", args: "./cmd/api", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/go-mod-download.txt", sub: "mod", args: "download", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/go-test-pass.txt", sub: "test", args: "test -v ./...", exit: 0, levels: ["lite", "full", "ultra"]},
		// invariant 1: -json is byte-exact machine output; the guard must pass it raw.
		{sample: "samples/go-test-json.txt", sub: "test", args: "test -json ./...", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/go-list-json.txt", sub: "list", args: "list -json ./...", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
