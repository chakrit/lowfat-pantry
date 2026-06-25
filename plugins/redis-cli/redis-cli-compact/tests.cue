// Golden-file drift tests for redis-cli-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/redis-cli/redis-cli-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/redis-cli/redis-cli-compact/tests.cue     # re-lock intentionally
// nameParts keys by sample+sub+args: two cases reuse redis-cli-info.txt (info vs
// INFO), so sample+level alone collides — a duplicate test name (smoke exit 65).
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/redis-cli/redis-cli-compact"
	name: "redis-cli-compact"
	nameParts: ["sample", "sub", "args"]
	cases: [
		{sample: "samples/redis-cli-info.txt", sub: "info", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/redis-cli-info.txt", sub: "INFO", args: "", exit: 0, levels: ["full"]},
		{sample: "samples/redis-cli-scan.txt", sub: "--scan", args: "--scan", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/redis-cli-keys.txt", sub: "keys", args: "keys user:*", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/redis-cli-slowlog.txt", sub: "slowlog", args: "slowlog get 10", exit: 0, levels: ["full", "ultra"]},
		{sample: "samples/redis-cli-memory-stats.txt", sub: "memory", args: "memory stats", exit: 0, levels: ["full", "ultra"]},
		{sample: "samples/redis-cli-client-list.txt", sub: "client", args: "client list", exit: 0, levels: ["full"]},
		{sample: "samples/redis-cli-get.txt", sub: "get", args: "get user:1:profile", exit: 0, levels: ["full", "ultra"]},
		{sample: "samples/redis-cli-err-unknown.txt", sub: "gett", args: "gett foo", exit: 0, levels: ["full", "ultra"]},
		{sample: "samples/redis-cli-err-conn.txt", sub: "-p", args: "-p 9999 ping", exit: 1, levels: ["full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
