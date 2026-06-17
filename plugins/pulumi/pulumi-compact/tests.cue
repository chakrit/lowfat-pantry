// Golden-file drift tests for pulumi-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/pulumi/pulumi-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/pulumi/pulumi-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/pulumi/pulumi-compact"
_cases: [
	{sample: "samples/pulumi-up.txt", sub: "up", args: "up --yes", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/pulumi-up-change.txt", sub: "up", args: "up --yes", exit: 0, levels: ["full", "ultra"]},
	{sample: "samples/pulumi-preview.txt", sub: "preview", args: "", exit: 0, levels: ["full", "ultra"]},
	{sample: "samples/pulumi-preview-diff.txt", sub: "preview", args: "preview --diff", exit: 0, levels: ["full"]},
	{sample: "samples/pulumi-preview-err.txt", sub: "preview", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/pulumi-destroy.txt", sub: "destroy", args: "destroy --yes", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/pulumi-stack.txt", sub: "stack", args: "stack", exit: 0, levels: ["full", "ultra"]},
	{sample: "samples/pulumi-stack-ls.txt", sub: "stack", args: "stack ls", exit: 0, levels: ["full"]},
	{sample: "samples/pulumi-stack-output.txt", sub: "stack", args: "stack output", exit: 0, levels: ["full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "pulumi-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
