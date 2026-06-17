// Golden-file drift tests for jq-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/jq/jq-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/jq/jq-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/jq/jq-compact"
_cases: [
	{sample: "samples/jq-array.txt", sub: "", args: ".", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/jq-raw.txt", sub: "", args: "-r .name", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/jq-error.txt", sub: "", args: ".", exit: 4, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "jq-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
