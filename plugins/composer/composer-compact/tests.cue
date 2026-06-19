// Golden-file drift tests for composer-compact, run by chakrit/smoke (>= v0.3.0).
// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):
//   smoke plugins/composer/composer-compact/tests.cue        # UNCHANGED/0 = no drift
//   smoke -c plugins/composer/composer-compact/tests.cue     # re-lock intentionally
//
// `_`-hidden fields template the case x level matrix and never reach smoke's
// closed schema. Case names include sub+sample to dodge the duplicate-name trap
// (duplicate names exit 65 standalone / silently dedup in the suite).
_dir: "plugins/composer/composer-compact"
_cases: [
	{sample: "samples/composer-install.txt", sub: "install", args: "install", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/composer-install-error.txt", sub: "install", args: "install", exit: 2, levels: ["lite", "full", "ultra"]},
	{sample: "samples/composer-show-json.txt", sub: "show", args: "show --format=json", exit: 0, levels: ["lite", "full", "ultra"]},
	{sample: "samples/composer-outdated-json.txt", sub: "outdated", args: "outdated --format=json", exit: 0, levels: ["lite", "full", "ultra"]},
]

config: {
	interpreter: "/bin/sh"
	timeout:     "10s"
}
tests: [{
	name: "composer-compact"
	checks: ["stdout", "exitcode"]
	tests: [
		for c in _cases for l in c.levels {
			let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
			name: "\(c.sub) \(c.sample) \(l)"
			commands: [base, "\(base) | scripts/measure.py"]
		},
	]
}]
