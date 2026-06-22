// Golden-file drift tests for eslint-compact, run by chakrit/smoke (>= v0.4.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/eslint/eslint-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/eslint/eslint-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/eslint/eslint-compact"
_cases: [
	{sample: "samples/eslint-problems.txt", sub: "", args: ".", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/eslint-clean.txt", sub: "", args: ".", exit: 0, levels: ["lite", "full", "ultra"]},
	// recovery hint: a capped findings list announces "... (N lines total)" (the
	// `✖ N problems` summary can't be keyword-kept, so the hint is the only signal).
	{sample: "samples/eslint-many.txt", sub: "", args: "src", exit: 1, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "eslint-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
