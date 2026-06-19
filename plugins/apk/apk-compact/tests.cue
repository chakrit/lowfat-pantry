// Golden-file drift tests for apk-compact, run by chakrit/smoke (>= v0.3.0).
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/apk/apk-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/apk/apk-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach smoke's
// closed schema. Each case locks the raw filter output and the same piped
// through scripts/measure.py (size metrics); smoke is the sole judge.
_dir: "plugins/apk/apk-compact"
_cases: [
	{sample: "samples/apk-add.txt", sub: "add", args: "add jq", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/apk-add-error.txt", sub: "add", args: "add nosuchpkg123", exit: 1, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "apk-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
