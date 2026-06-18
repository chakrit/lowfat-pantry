// Golden-file drift tests for terraform-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/terraform/terraform-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/terraform/terraform-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/terraform/terraform-compact"
_cases: [
	{sample: "samples/terraform-plan.txt", sub: "plan", args: "-out=tfplan", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/terraform-apply.txt", sub: "apply", args: "-auto-approve tfplan", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/terraform-init-error.txt", sub: "init", args: "-upgrade", exit: 1, levels: ["lite", "full", "ultra"]},
	// invariant 1: -json is byte-exact ndjson/JSON; the guard must pass it raw.
	{sample: "samples/terraform-plan-json.txt", sub: "plan", args: "-json -out=tfplan", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/terraform-output-json.txt", sub: "output", args: "output -json", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "terraform-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
