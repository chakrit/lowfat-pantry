// Golden-file drift tests for curl-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/curl/curl-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/curl/curl-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/curl/curl-compact"
	name: "curl-compact"
	cases: [
		{sample: "samples/curl-verbose-json.txt", sub: "", args: "-v https://api.example.test/v1/users", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/curl-headers-body.txt", sub: "", args: "-i https://example.test/", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/curl-error.txt", sub: "", args: "-v https://missing.example.test/", exit: 6, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
