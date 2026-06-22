// Golden-file drift tests for kubectl-compact, run by chakrit/smoke (>= v0.4.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/kubectl/kubectl-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/kubectl/kubectl-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/kubectl/kubectl-compact"
_cases: [
	{sample: "samples/kubectl-get-pods.txt", sub: "get", args: "pods -A", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/kubectl-describe-pod.txt", sub: "describe", args: "pod checkout-7d9b8f6f6f-2kq9x", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/kubectl-logs.txt", sub: "logs", args: "deploy/api --tail=200", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/kubectl-apply-rollout.txt", sub: "apply", args: "-f k8s/", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/kubectl-get-noserver.txt", sub: "get", args: "pods", exit: 1, levels: ["full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "kubectl-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
