// Golden-file drift tests for diff-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/diff/diff-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/diff/diff-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/diff/diff-compact"
_cases: [
	{sample: "samples/diff-unified.txt", sub: "", args: "-u old.txt new.txt", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/diff-context-heavy.txt", sub: "", args: "-u before.py after.py", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/diff-error.txt", sub: "", args: "-u missing.txt new.txt", exit: 2, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "diff-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
