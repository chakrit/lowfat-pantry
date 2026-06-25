// Golden-file drift tests for helm-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/helm/helm-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/helm/helm-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/helm/helm-compact"
	name: "helm-compact"
	cases: [
		{sample: "samples/helm-install.txt", sub: "install", args: "api ./chart -n production", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/helm-list.txt", sub: "list", args: "-A", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/helm-upgrade-error.txt", sub: "upgrade", args: "api ./chart -n production --install", exit: 1, levels: ["lite", "full", "ultra"]},
		// invariant 1: -o json/-o yaml is byte-exact; the guard must pass it raw.
		{sample: "samples/helm-install-json.txt", sub: "install", args: "api ./mychart -n production -o json", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/helm-install-yaml.txt", sub: "install", args: "api ./mychart -n production -o yaml", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
