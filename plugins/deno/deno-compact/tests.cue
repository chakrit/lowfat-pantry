// Golden-file drift tests for deno-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/deno/deno-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/deno/deno-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/deno/deno-compact"
_cases: [
	{sample: "samples/deno-test-fail.txt", sub: "test", args: "test", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/deno-check-clean.txt", sub: "check", args: "check main.ts", exit: 0, levels: ["lite", "full", "ultra"]},
	// invariant 1: --json is byte-exact machine output; the guard must pass it raw.
	{sample: "samples/deno-lint-json.txt", sub: "lint", args: "lint --json mod.ts", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/deno-info-json.txt", sub: "info", args: "info --json mod.ts", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "deno-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
