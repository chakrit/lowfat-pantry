// Golden-file drift tests for aws-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/aws/aws-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/aws/aws-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/aws/aws-compact"
_cases: [
	{sample: "samples/aws-json.txt", sub: "s3", args: "s3api list-buckets", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/aws-table.txt", sub: "s3", args: "s3api list-buckets --output table", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/aws-error.txt", sub: "s3", args: "s3api list-buckets", exit: 254, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "aws-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
