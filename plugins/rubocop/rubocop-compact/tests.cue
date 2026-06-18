// Golden-file drift tests for rubocop-compact, run by chakrit/smoke (>= v0.3.0).
// Invoke from the REPO ROOT:
//   smoke plugins/rubocop/rubocop-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/rubocop/rubocop-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach smoke's
// closed schema. Each case locks the raw filter output (literal golden) and the
// same piped through scripts/measure.py (size metrics); smoke is the sole judge.
_dir: "plugins/rubocop/rubocop-compact"
_cases: [
	{sample: "samples/rubocop-clean.txt",    sub: "", args: "lib/", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/rubocop-findings.txt", sub: "", args: "lib/", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/rubocop-error.txt",    sub: "", args: "lib/nonexistent_file.rb", exit: 2, levels: ["lite", "full", "ultra"]},
	{sample: "samples/rubocop-json.txt",     sub: "", args: "--format json", exit: 1, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "rubocop-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
