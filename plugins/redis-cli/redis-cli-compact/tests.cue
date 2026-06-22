// Golden-file drift tests for redis-cli-compact, run by chakrit/smoke (>= v0.4.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/redis-cli/redis-cli-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/redis-cli/redis-cli-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/redis-cli/redis-cli-compact"
_cases: [
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

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "redis-cli-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			// include sub+args: two cases reuse redis-cli-info.txt (info vs INFO),
			// so sample+level alone collides — a duplicate test name (smoke exit 65).
			name: "\(c.sample) \(c.sub) \(c.args) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
