// Golden-file drift tests for rake-compact, run by chakrit/smoke (>= v0.3.0).
// Invoke from the REPO ROOT:
//   smoke plugins/rake/rake-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/rake/rake-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach smoke's
// closed schema. Each case locks the raw filter output (literal golden) and the
// same piped through scripts/measure.py (size metrics); smoke is the sole judge.
_dir: "plugins/rake/rake-compact"
_cases: [
	{sample: "samples/rake-build.txt", sub: "build", args: "build", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/rake-fail.txt",  sub: "boom", args: "boom", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/rake-list.txt",  sub: "-T", args: "-T", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "rake-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
