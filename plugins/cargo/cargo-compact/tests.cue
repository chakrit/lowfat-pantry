// Golden-file drift tests for cargo-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/cargo/cargo-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/cargo/cargo-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/cargo/cargo-compact"
	name: "cargo-compact"
	cases: [
		{sample: "samples/cargo-build-full.txt", sub: "build", args: "", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/cargo-build-error.txt", sub: "build", args: "", exit: 101, levels: ["lite", "full", "ultra"]},
		{sample: "samples/cargo-test-error.txt", sub: "test", args: "", exit: 101, levels: ["lite", "full", "ultra"]},
		// invariant 1: --message-format json (ndjson) and metadata (JSON) pass raw.
		{sample: "samples/cargo-build-json.txt", sub: "build", args: "build --message-format json", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/cargo-metadata-json.txt", sub: "metadata", args: "metadata --format-version 1", exit: 0, levels: ["lite", "full", "ultra"]},
		// recovery hint: a capped `cargo run` program body announces "... (N lines total)".
		{sample: "samples/cargo-run.txt", sub: "run", args: "run", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
