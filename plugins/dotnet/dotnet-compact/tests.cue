// Golden-file drift tests for dotnet-compact, run by chakrit/smoke (>= v0.4.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/dotnet/dotnet-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/dotnet/dotnet-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/dotnet/dotnet-compact"
_cases: [
	{sample: "samples/dotnet-build-warning.txt", sub: "build", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/dotnet-test-fail.txt", sub: "test", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/dotnet-build-error.txt", sub: "build", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/dotnet-publish.txt", sub: "publish", args: "-c Release", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/dotnet-pack.txt", sub: "pack", args: "-c Release", exit: 0, levels: ["lite", "full", "ultra"]},
	// invariant 1: `list --format json` is byte-exact; the guard must pass it raw.
	{sample: "samples/dotnet-list-json.txt", sub: "list", args: "list package --format json", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "dotnet-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
