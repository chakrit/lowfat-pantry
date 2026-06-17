// Golden-file drift tests for go-compact, run by chakrit/smoke (>= v0.3.0).
// Invoke from the REPO ROOT — smoke executes commands in the invocation cwd,
// so paths here are root-relative and scripts/measure.py resolves. The
// committed golden is tests.lock.yml; re-lock intentionally with
//   smoke -c plugins/go/go-compact/tests.cue
//
// `_`-prefixed fields are CUE-hidden: dropped on export, so smoke's closed
// schema never sees them. They template the case x level matrix below.
//
// Each case locks TWO commands:
//   1. the raw filter output  -> the literal golden (catches any content drift)
//   2. piped through measure.py -> size metrics (lines/bytes); a regression
//      like over-prune-to-empty surfaces as a changed number = drift.
// smoke is the sole judge; measure.py never decides pass/fail.
_dir: "plugins/go/go-compact"
_cases: [
	{sample: "go-test-fail.txt", sub:   "test", args: "./...", exit:        1},
	{sample: "go-build-error.txt", sub: "build", args: "./cmd/api", exit:    1},
	{sample: "go-mod-download.txt", sub: "mod", args:   "download", exit:    0},
	{sample: "go-test-pass.txt", sub:   "test", args: "test -v ./...", exit: 0},
]
_levels: ["lite", "full", "ultra"]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "go-compact"
	// stdout = compacted golden / metrics; exitcode = filter-didn't-crash
	// sentinel. lowfat's stderr is always empty, so it's omitted.
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in _levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/samples/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [
				base,
				"\(base) | scripts/measure.py",
			]
		},
	]
}]
