// Golden-file drift tests for wrangler-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/wrangler/wrangler-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/wrangler/wrangler-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/wrangler/wrangler-compact"
	name: "wrangler-compact"
	cases: [
		{sample: "samples/wrangler-deploy-dryrun.txt", sub: "deploy", args: "deploy --dry-run --outdir dist", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/wrangler-deploy-err.txt", sub: "deploy", args: "deploy --dry-run --outdir dist", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/wrangler-deploy-noauth.txt", sub: "deploy", args: "deploy", exit: 1, levels: ["full", "ultra"]},
		{sample: "samples/wrangler-kv-noauth.txt", sub: "kv", args: "kv namespace list", exit: 1, levels: ["full"]},
		{sample: "samples/wrangler-types.txt", sub: "types", args: "types", exit: 0, levels: ["full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
