// Golden-file drift tests for kubectl-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/kubectl/kubectl-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/kubectl/kubectl-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/kubectl/kubectl-compact"
	name: "kubectl-compact"
	cases: [
		{sample: "samples/kubectl-get-pods.txt", sub: "get", args: "pods -A", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/kubectl-describe-pod.txt", sub: "describe", args: "pod checkout-7d9b8f6f6f-2kq9x", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/kubectl-logs.txt", sub: "logs", args: "deploy/api --tail=200", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/kubectl-apply-rollout.txt", sub: "apply", args: "-f k8s/", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/kubectl-get-noserver.txt", sub: "get", args: "pods", exit: 1, levels: ["full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
