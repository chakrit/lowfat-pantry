// Golden-file drift tests for az-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/az/az-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/az/az-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/az/az-compact"
	name: "az-compact"
	cases: [
		{sample: "samples/az-vm-create-help.txt", sub: "vm", args: "vm create --help", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/az-storage-help.txt", sub: "storage", args: "storage --help", exit: 0, levels: ["full"]},
		{sample: "samples/az-version.txt", sub: "version", args: "version", exit: 0, levels: ["full", "ultra"]},
		{sample: "samples/az-account-noauth.txt", sub: "account", args: "account show", exit: 1, levels: ["full", "ultra"]},
		{sample: "samples/az-group-noauth.txt", sub: "group", args: "group list", exit: 1, levels: ["full"]},
		{sample: "samples/az-err-typo.txt", sub: "gruop", args: "gruop list", exit: 2, levels: ["full", "ultra"]},
		{sample: "samples/az-cloud-list-table.txt", sub: "cloud", args: "cloud list -o table", exit: 0, levels: ["full", "ultra"]},
		{sample: "samples/az-extension-list.txt", sub: "extension", args: "extension list", exit: 0, levels: ["full"]},
	]
}

config: _suite.config
tests:  _suite.tests
