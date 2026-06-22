// Golden-file drift tests for glab-compact, run by chakrit/smoke (>= v0.4.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/glab/glab-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/glab/glab-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/glab/glab-compact"
_cases: [
	{sample: "samples/glab-mr-list.txt", sub: "mr", args: "list", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/glab-ci-trace.txt", sub: "ci", args: "trace --trace", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/glab-mr-json.txt", sub: "mr", args: "view 214 -F json", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "glab-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
