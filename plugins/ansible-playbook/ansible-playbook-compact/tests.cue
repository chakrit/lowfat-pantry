// Golden-file drift tests for ansible-playbook-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/ansible-playbook/ansible-playbook-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/ansible-playbook/ansible-playbook-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/ansible-playbook/ansible-playbook-compact"
	name: "ansible-playbook-compact"
	cases: [
		{sample: "samples/ansible-failure.txt", sub: "", args: "-i prod site.yml", exit: 2, levels: ["lite", "full", "ultra"]},
		{sample: "samples/ansible-success.txt", sub: "", args: "-i prod site.yml", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
