// Golden-file drift tests for vitest-compact, run by chakrit/smoke (>= v0.4.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/vitest/vitest-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/vitest/vitest-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/vitest/vitest-compact"
_cases: [
	{sample: "samples/vitest-fail.txt", sub: "", args: "run", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/vitest-pass.txt", sub: "", args: "run", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/vitest-json.txt", sub: "", args: "run --reporter=json", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/vitest-junit.txt", sub: "", args: "run --reporter=junit", exit: 1, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "vitest-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
