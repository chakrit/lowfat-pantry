// Golden-file drift tests for docker-compose-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/docker-compose/docker-compose-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/docker-compose/docker-compose-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/docker-compose/docker-compose-compact"
_cases: [
	{sample: "samples/docker-compose-up.txt", sub: "up", args: "up", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/docker-compose-logs.txt", sub: "logs", args: "logs api", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/docker-compose-ps.txt", sub: "ps", args: "ps", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/docker-compose-build-error.txt", sub: "build", args: "build api", exit: 1, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "docker-compose-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
