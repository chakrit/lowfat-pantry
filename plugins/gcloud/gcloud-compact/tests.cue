// Golden-file drift tests for gcloud-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/gcloud/gcloud-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/gcloud/gcloud-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/gcloud/gcloud-compact"
	name: "gcloud-compact"
	cases: [
		{sample: "samples/gcloud-list.txt", sub: "compute", args: "compute instances list", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/gcloud-json.txt", sub: "compute", args: "compute instances describe web-01 --format json", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/gcloud-error.txt", sub: "compute", args: "compute instances describe nope", exit: 1, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
