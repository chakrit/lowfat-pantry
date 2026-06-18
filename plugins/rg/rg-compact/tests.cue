// Golden-file drift tests for rg-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/rg/rg-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/rg/rg-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/rg/rg-compact"
_cases: [
	{sample: "samples/rg-search-full.txt", sub: "", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/rg-numbered-full.txt", sub: "", args: "-n", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/rg-count-full.txt", sub: "", args: "--count", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/rg-files-full.txt", sub: "", args: "-l", exit: 0, levels: ["lite", "full", "ultra"]},
	// invariant 1: --json is a byte-exact ndjson stream; the guard must pass it raw.
	{sample: "samples/rg-json.txt", sub: "", args: "--json raw", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "rg-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
