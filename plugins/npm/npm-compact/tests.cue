// Golden-file drift tests for npm-compact, run by chakrit/smoke (>= v0.3.0).
// Migrated once from tests.yml; this file is now the source of truth.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/npm/npm-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/npm/npm-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/npm/npm-compact"
_cases: [
	{sample: "samples/npm-install.txt", sub: "install", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/npm-test.txt", sub: "test", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/npm-error.txt", sub: "install", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "npm-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
