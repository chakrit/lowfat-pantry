// Golden-file drift tests for go-compact, run by chakrit/smoke (>= v0.3.0).
// Invoke from the REPO ROOT — smoke executes commands in the invocation cwd,
// and each command cd's into this plugin dir. The committed golden is
// tests.lock.yml; regenerate intentionally with `smoke -c plugins/go/go-compact/tests.cue`.
//
// `_`-prefixed fields are CUE-hidden: dropped on export, so smoke's closed
// schema never sees them. They template the case x level matrix below.
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
	name:   "go-compact"
	// stdout = compacted output (the golden); exitcode = filter-didn't-crash
	// sentinel (catches a corrupt filter.lf -> nonzero). lowfat's stderr is
	// always empty, so it's omitted to keep the lock lean.
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in _levels {
			name: "\(c.sample) \(l)"
			commands: [
				"cd \(_dir) && lowfat filter filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < samples/\(c.sample)",
			]
		},
	]
}]
