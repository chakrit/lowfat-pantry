// Golden-file drift tests for gh-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/gh/gh-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/gh/gh-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/gh/gh-compact"
_cases: [
	{sample: "samples/gh-pr-list.txt", sub: "pr", args: "list", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/gh-run-view.txt", sub: "run", args: "view 994203", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/gh-run-log.txt", sub: "run", args: "view 994203 --log", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/gh-pr-json.txt", sub: "pr", args: "view 12 --json number,state,title", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "gh-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
