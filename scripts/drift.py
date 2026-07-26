#!/usr/bin/env python3
"""drift.py — enforce the wrapper filters' drift contract.

`uv-compact` and `npx-compact` re-implement their wrapped tools' compaction as
Python branches inside one dispatch macro: the runner prefix keeps `uv run
pytest` from ever reaching `pytest-compact`, and `include` can't help — it
carries `.lf` macros, which a `python:` body cannot call. The copies are
deliberate; what was missing is a check that they still agree.

For every pair below, the wrapped tool's own sample goes through both filters at
every level and the outputs must match byte-for-byte. Edit an original without
mirroring it into the wrapper and this fails, naming the pair.
"""
import subprocess
import sys
from pathlib import Path

LEVELS = ("ultra", "full", "lite")
ROOT = Path(__file__).resolve().parent.parent

# (wrapper plugin, wrapper args) ⇄ (original plugin, original args), over the
# original's samples. Samples stay flag-free so both sides take the compacting
# branch — the guard arms are each filter's own business, not the contract's.
PAIRS = (
    ("uv/uv-compact", "run pytest tests/", "pytest/pytest-compact", "tests/",
     (("pytest/pytest-compact/samples/pytest-pass.txt", 0),
      ("pytest/pytest-compact/samples/pytest-fail.txt", 1),
      ("pytest/pytest-compact/samples/pytest-error.txt", 1))),

    ("uv/uv-compact", "run ruff check src/", "ruff/ruff-compact", "check src/",
     (("ruff/ruff-compact/samples/ruff-clean.txt", 0),
      ("ruff/ruff-compact/samples/ruff-findings.txt", 1),
      ("ruff/ruff-compact/samples/ruff-error.txt", 2))),

    ("npx/npx-compact", "eslint src", "eslint/eslint-compact", "src",
     (("eslint/eslint-compact/samples/eslint-clean.txt", 0),
      ("eslint/eslint-compact/samples/eslint-problems.txt", 1),
      ("eslint/eslint-compact/samples/eslint-many.txt", 1))),

    ("npx/npx-compact", "prettier --check .", "prettier/prettier-compact", "--check .",
     (("prettier/prettier-compact/samples/prettier-check-clean.txt", 0),
      ("prettier/prettier-compact/samples/prettier-check-issues.txt", 1))),

    ("npx/npx-compact", "tsc --noEmit", "tsc/tsc-compact", "--noEmit",
     (("tsc/tsc-compact/samples/tsc-clean.txt", 0),
      ("tsc/tsc-compact/samples/tsc-errors.txt", 2))),
)


def filtered(plugin, args, sample, exit_code, level):
    """Output of one filter over one sample — the observable the contract binds."""
    run = subprocess.run(
        ["lowfat", "filter", str(ROOT / "plugins" / plugin / "filter.lf"),
         f"--sub={args.split()[0]}", f"--args={args}",
         f"--exit={exit_code}", f"--level={level}"],
        stdin=(ROOT / "plugins" / sample).open("rb"),
        capture_output=True,
    )
    if run.returncode != 0:
        raise SystemExit(f"drift.py: {plugin} failed on {sample}: "
                         f"{run.stderr.decode().strip()}")
    return run.stdout


def main():
    mismatches = []
    for wrapper, wrapper_args, original, original_args, samples in PAIRS:
        for sample, exit_code in samples:
            for level in LEVELS:
                wrapped = filtered(wrapper, wrapper_args, sample, exit_code, level)
                direct = filtered(original, original_args, sample, exit_code, level)
                if wrapped != direct:
                    mismatches.append((wrapper, original, sample, level))

    for wrapper, original, sample, level in mismatches:
        print(f"DRIFTED {wrapper} vs {original} — {Path(sample).name} @ {level}",
              file=sys.stderr)

    if mismatches:
        print(f"drift.py: {len(mismatches)} mismatch(es); mirror the original's "
              f"change into the wrapper's branch", file=sys.stderr)
        return 1

    print(f"IN SYNC — {sum(len(p[4]) for p in PAIRS) * len(LEVELS)} wrapper/original "
          f"comparisons across {len(PAIRS)} pairs")
    return 0


sys.exit(main())
