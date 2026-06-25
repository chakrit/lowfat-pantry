// Golden-file drift tests for pulumi-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/pulumi/pulumi-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/pulumi/pulumi-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/pulumi/pulumi-compact"
	name: "pulumi-compact"
	cases: [
		{sample: "samples/pulumi-up.txt", sub: "up", args: "up --yes", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pulumi-up-change.txt", sub: "up", args: "up --yes", exit: 0, levels: ["full", "ultra"]},
		{sample: "samples/pulumi-preview.txt", sub: "preview", args: "", exit: 0, levels: ["full", "ultra"]},
		{sample: "samples/pulumi-preview-diff.txt", sub: "preview", args: "preview --diff", exit: 0, levels: ["full"]},
		{sample: "samples/pulumi-preview-err.txt", sub: "preview", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pulumi-destroy.txt", sub: "destroy", args: "destroy --yes", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pulumi-stack.txt", sub: "stack", args: "stack", exit: 0, levels: ["full", "ultra"]},
		{sample: "samples/pulumi-stack-ls.txt", sub: "stack", args: "stack ls", exit: 0, levels: ["full"]},
		{sample: "samples/pulumi-stack-output.txt", sub: "stack", args: "stack output", exit: 0, levels: ["full", "ultra"]},
		// invariant 1: --json is byte-exact multi-line JSON; the guard must pass it raw.
		{sample: "samples/pulumi-preview-json.txt", sub: "preview", args: "preview --json", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/pulumi-stack-output-json.txt", sub: "stack", args: "stack output --json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
