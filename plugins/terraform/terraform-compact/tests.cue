// Golden-file drift tests for terraform-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/terraform/terraform-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/terraform/terraform-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/terraform/terraform-compact"
	name: "terraform-compact"
	cases: [
		{sample: "samples/terraform-plan.txt", sub: "plan", args: "-out=tfplan", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/terraform-apply.txt", sub: "apply", args: "-auto-approve tfplan", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/terraform-init-error.txt", sub: "init", args: "-upgrade", exit: 1, levels: ["lite", "full", "ultra"]},
		// invariant 1: -json is byte-exact ndjson/JSON; the guard must pass it raw.
		{sample: "samples/terraform-plan-json.txt", sub: "plan", args: "-json -out=tfplan", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/terraform-output-json.txt", sub: "output", args: "output -json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
