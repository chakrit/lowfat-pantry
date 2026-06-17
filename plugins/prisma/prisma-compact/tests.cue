// Golden-file drift tests for prisma-compact, run by chakrit/smoke (>= v0.3.0).
// Migrated once from tests.yml; this file is now the source of truth.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/prisma/prisma-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/prisma/prisma-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/prisma/prisma-compact"
_cases: [
	{sample: "samples/prisma-generate.txt", sub: "generate", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/prisma-migrate.txt", sub: "migrate", args: "deploy", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/prisma-error.txt", sub: "migrate", args: "dev", exit: 1, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "prisma-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
