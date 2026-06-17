// Golden-file drift tests for az-compact, run by chakrit/smoke (>= v0.3.0).
// Migrated once from tests.yml; this file is now the source of truth.
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/az/az-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/az/az-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach
// smoke's closed schema. Each case locks the raw filter output (literal
// golden) and the same piped through scripts/measure.py (size metrics);
// smoke is the sole judge, measure.py only emits.
_dir: "plugins/az/az-compact"
_cases: [
	{sample: "samples/az-vm-create-help.txt", sub: "vm", args: "vm create --help", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/az-storage-help.txt", sub: "storage", args: "storage --help", exit: 0, levels: ["full"]},
	{sample: "samples/az-version.txt", sub: "version", args: "version", exit: 0, levels: ["full", "ultra"]},
	{sample: "samples/az-account-noauth.txt", sub: "account", args: "account show", exit: 1, levels: ["full", "ultra"]},
	{sample: "samples/az-group-noauth.txt", sub: "group", args: "group list", exit: 1, levels: ["full"]},
	{sample: "samples/az-err-typo.txt", sub: "gruop", args: "gruop list", exit: 2, levels: ["full", "ultra"]},
	{sample: "samples/az-cloud-list-table.txt", sub: "cloud", args: "cloud list -o table", exit: 0, levels: ["full", "ultra"]},
	{sample: "samples/az-extension-list.txt", sub: "extension", args: "extension list", exit: 0, levels: ["full"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "az-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
