// Golden-file drift tests for gradlew-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/gradlew/gradlew-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/gradlew/gradlew-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/gradlew/gradlew-compact"
	name: "gradlew-compact"
	cases: [
		{sample: "samples/gradlew-build-success.txt", sub: "build", args: "build", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/gradlew-build-downloads.txt", sub: "build", args: "build", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/gradlew-test-failure.txt", sub: "test", args: "test", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
