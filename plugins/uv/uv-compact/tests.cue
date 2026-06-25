// Golden-file drift tests for uv-compact, run by chakrit/smoke (>= v0.5.0).
// Cases below; the suite scaffold + #Case schema live in the shared `testkit`
// cue.mod package. Invoke from the REPO ROOT:
//   scripts/smoke.sh plugins/uv/uv-compact/tests.cue        # UNCHANGED/0 = no drift
//   scripts/smoke.sh -c plugins/uv/uv-compact/tests.cue     # re-lock intentionally
import "github.com/chakrit/lowfat-pantry/testkit"

_suite: testkit.#Suite & {
	dir:  "plugins/uv/uv-compact"
	name: "uv-compact"
	cases: [
		{sample: "samples/uv-run-pytest-fail.txt", sub: "run", args: "run pytest tests/", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/uv-run-ruff.txt", sub: "ruff", args: "ruff check src/", exit: 1, levels: ["lite", "full", "ultra"]},
		{sample: "samples/uv-sync.txt", sub: "sync", args: "sync", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/uv-run-app.txt", sub: "run", args: "run uvicorn app:api", exit: 0, levels: ["lite", "full", "ultra"]},
		// invariant 1: native `uv pip list --format json` and the wrapped `uvx ruff
		// --output-format json` (drift-copy) must both pass raw.
		{sample: "samples/uv-pip-list-json.txt", sub: "pip", args: "pip list --format json", exit: 0, levels: ["lite", "full", "ultra"]},
		{sample: "samples/uv-ruff-json-clean.txt", sub: "ruff", args: "ruff check --output-format json .", exit: 0, levels: ["lite", "full", "ultra"]},
		// recovery hint: a capped `uv run <prog>` body announces "... (N lines total)".
		{sample: "samples/uv-run-capped.txt", sub: "run", args: "run myapp", exit: 0, levels: ["lite", "full", "ultra"]},
	]
}

config: _suite.config
tests:  _suite.tests
