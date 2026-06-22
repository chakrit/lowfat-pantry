// Golden-file drift tests for bundle-compact, run by chakrit/smoke (>= v0.4.0).
// Invoke from the REPO ROOT:
//   smoke plugins/bundle/bundle-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/bundle/bundle-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach smoke's
// closed schema. Each case locks the raw filter output (literal golden) and the
// same piped through scripts/measure.py (size metrics); smoke is the sole judge.
_dir: "plugins/bundle/bundle-compact"
_cases: [
	{sample: "samples/bundle-install.txt", sub: "install", args: "install", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/bundle-error.txt",   sub: "install", args: "install", exit: 7, levels: ["lite", "full", "ultra"]},
	{sample: "samples/bundle-list.txt",    sub: "list", args: "list", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "bundle-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
