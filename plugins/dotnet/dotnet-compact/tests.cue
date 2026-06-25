// Golden-file drift tests for dotnet-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/dotnet/dotnet-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/dotnet/dotnet-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/dotnet/dotnet-compact"
	name: "dotnet-compact"
	cases: [
		{sample: "samples/dotnet-build-warning.txt", sub: "build", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/dotnet-test-fail.txt", sub: "test", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/dotnet-build-error.txt", sub: "build", args: "", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/dotnet-publish.txt", sub: "publish", args: "-c Release", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/dotnet-pack.txt", sub: "pack", args: "-c Release", exit: 0, levels: ["lite", "full", "ultra"]},
		// invariant 1: `list --format json` is byte-exact; the guard must pass it raw.
		{sample: "samples/dotnet-list-json.txt", sub: "list", args: "list package --format json", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
