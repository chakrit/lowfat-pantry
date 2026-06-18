// Golden-file drift tests for npx-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/npx/npx-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/npx/npx-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/npx/npx-compact"
_cases: [
	{sample: "samples/npx-eslint.txt", sub: "eslint", args: "eslint src", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/npx-eslint.txt", sub: "-y", args: "-y eslint src", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/npx-prettier-check.txt", sub: "prettier", args: "prettier --check src", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/npx-create.txt", sub: "create-vite", args: "create-vite demo", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/npx-error.txt", sub: "tsc", args: "tsc --noEmit", exit: 2, levels: ["lite", "full", "ultra"]},
	// recovery hint: a capped generic `npx <tool>` body announces "... (N lines total)".
	{sample: "samples/npx-generic-capped.txt", sub: "mytool", args: "mytool --build", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "npx-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			// include args: two cases reuse npx-eslint.txt (eslint vs -y), so
			// sample+level alone collides — a duplicate test name (smoke exit 65).
			name: "\(c.sample) \(c.args) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
