// Golden-file drift tests for docker-compose-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/docker-compose/docker-compose-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/docker-compose/docker-compose-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/docker-compose/docker-compose-compact"
	name: "docker-compose-compact"
	cases: [
		{sample: "samples/docker-compose-up.txt", sub: "up", args: "up", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/docker-compose-logs.txt", sub: "logs", args: "logs api", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/docker-compose-ps.txt", sub: "ps", args: "ps", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/docker-compose-build-error.txt", sub: "build", args: "build api", exit: 1, levels: ["lite", "full", "ultra"]},
		// invariant 1: --format json is byte-exact machine output; the guard must pass it raw.
		{sample: "samples/compose-config-json.txt", sub: "config", args: "config --format json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
