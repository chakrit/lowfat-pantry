// Golden-file drift tests for wget-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/wget/wget-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/wget/wget-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/wget/wget-compact"
	name: "wget-compact"
	cases: [
		{sample: "samples/wget-success.txt", sub: "download", args: "https://example.com/releases/app-1.2.3.tar.gz", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/wget-spider.txt", sub: "--spider", args: "--spider https://example.com/health", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/wget-error.txt", sub: "download", args: "https://downloads.example.invalid/app.tar.gz", exit: 4, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
