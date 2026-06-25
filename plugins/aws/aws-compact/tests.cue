// Golden-file drift tests for aws-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/aws/aws-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/aws/aws-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/aws/aws-compact"
	name: "aws-compact"
	cases: [
		{sample: "samples/aws-json.txt", sub: "s3", args: "s3api list-buckets", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/aws-table.txt", sub: "s3", args: "s3api list-buckets --output table", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/aws-error.txt", sub: "s3", args: "s3api list-buckets", exit: 254, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
