// Golden-file drift tests for wrangler-compact, run by chakrit/smoke (>= v0.3.0).
// Source of truth: the smoke golden spec for this plugin.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/wrangler/wrangler-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/wrangler/wrangler-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/wrangler/wrangler-compact"
_cases: [
	{sample: "samples/wrangler-deploy-dryrun.txt", sub: "deploy", args: "deploy --dry-run --outdir dist", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/wrangler-deploy-err.txt", sub: "deploy", args: "deploy --dry-run --outdir dist", exit: 1, levels: ["lite", "full", "ultra"]},
	{sample: "samples/wrangler-deploy-noauth.txt", sub: "deploy", args: "deploy", exit: 1, levels: ["full", "ultra"]},
	{sample: "samples/wrangler-kv-noauth.txt", sub: "kv", args: "kv namespace list", exit: 1, levels: ["full"]},
	{sample: "samples/wrangler-types.txt", sub: "types", args: "types", exit: 0, levels: ["full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "wrangler-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
