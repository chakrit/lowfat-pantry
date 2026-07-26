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
		// OpenTofu rebrands the plan header ("OpenTofu will perform..."); guards the alternation
		// in compact-plan so a fork of that keep back to Terraform-only is caught.
		{sample: "samples/tofu-plan.txt", sub: "plan", args: "-out=tfplan", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/terraform-apply.txt", sub: "apply", args: "-auto-approve tfplan", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/terraform-init-error.txt", sub: "init", args: "-upgrade", exit: 1, levels: ["lite", "full", "ultra"]},
		// invariant 1: -json is byte-exact ndjson/JSON; the guard must pass it raw.
		{sample: "samples/terraform-plan-json.txt", sub: "plan", args: "-json -out=tfplan", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/terraform-output-json.txt", sub: "output", args: "output -json", exit: 0, levels: ["lite", "full", "ultra"]},
		// invariant 2 (issue #1): inventory listings are one load-bearing identifier per line,
		// nothing redundant to compact. 36 resources in, 36 out at every level — a short
		// `state list` must never be indistinguishable from a truncated one.
		{sample: "samples/tofu-state-list.txt", sub: "state", args: "state list", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
