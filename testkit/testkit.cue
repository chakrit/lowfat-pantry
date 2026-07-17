// Shared smoke golden-test scaffold for the pantry. Each plugin's tests.cue
// imports this, supplies dir/name/cases, and exposes config+tests. The case
// matrix and command template live here once instead of in all 64 specs.
// See docs/guides/smoke-golden-tests.md.
package testkit

import "strings"

// #Case validates one filter invocation. Required (`!`) + closed, so a typo'd or
// wrong-typed field fails at cue eval instead of producing a broken command.
#Case: {
	sample!: string
	sub!:    string
	args!:   string
	exit!:   int
	levels!: [...string]
}

// #Suite expands cases × levels into the two-commands-per-case matrix (raw filter
// output + measure.py size metrics) under one named group, matching the smoke
// #Test shape. Consumers expose only config+tests; dir/name/cases stay off the
// closed top level via the importing file's hidden `_suite`.
#Suite: {
	dir!:   string
	name!:  string
	cases!: [...#Case]
	// Case fields joined (space-separated) into each leaf test name. Defaults to
	// keying by sample; a spec that reuses a sample across cases overrides (e.g.
	// ["sample", "sub", "args"]) to keep names unique and avoid smoke exit 65.
	nameParts: [...string] | *["sample"]

	// `let` aliases dodge CUE scope-shadowing: a bare `name`/`dir` inside a struct
	// that has those field names self-references and stays non-concrete.
	let _name = name
	let _dir = dir

	config: {
		interpreter: "/bin/sh"
		timeout:     "10s"
	}
	tests: [{
		name: _name
		checks: ["stdout", "exitcode"]
		tests: [
			for c in cases for l in c.levels {
				let base = "lowfat filter \(_dir)/filter.lf --sub=\(c.sub) --args='\(c.args)' --exit=\(c.exit) --level=\(l) < \(_dir)/\(c.sample)"
				let leaf = strings.Join([for p in nameParts {c[p]}], " ")
				name: "\(leaf) \(l)"
				commands: [base, "\(base) | scripts/measure.py"]
			},
		]
	}]
}
