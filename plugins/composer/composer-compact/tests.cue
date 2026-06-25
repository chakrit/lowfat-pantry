// Golden-file drift tests for composer-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/composer/composer-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/composer/composer-compact/tests.cue     # re-lock intentionally
// nameParts keys by sub+sample to match the committed lock (the inline form
// prefixed sub as a duplicate-name guard).
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/composer/composer-compact"
	name: "composer-compact"
	nameParts: ["sub", "sample"]
	cases: [
		{sample: "samples/composer-install.txt", sub: "install", args: "install", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/composer-install-error.txt", sub: "install", args: "install", exit: 2, levels: ["lite", "full", "ultra"]},
		{sample: "samples/composer-show-json.txt", sub: "show", args: "show --format=json", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/composer-outdated-json.txt", sub: "outdated", args: "outdated --format=json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
