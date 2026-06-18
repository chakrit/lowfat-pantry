// Golden-file drift tests for ruff-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/ruff/ruff-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/ruff/ruff-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/ruff/ruff-compact"
_cases: [
	{sample: "samples/ruff-findings.txt", sub: "check", args: ".", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/ruff-clean.txt", sub: "check", args: ".", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/ruff-error.txt", sub: "check", args: "--config missing.toml .", exit: 2, levels: ["lite", "full", "ultra"]},
	// invariant 1: --output-format json is machine output; the guard must pass it raw.
	{sample: "samples/ruff-json-clean.txt", sub: "check", args: "check --output-format json .", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/ruff-json-issues.txt", sub: "check", args: "check --output-format json .", exit: 1, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "ruff-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
