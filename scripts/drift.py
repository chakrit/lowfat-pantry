#!/usr/bin/env python3
"""drift.py — check that the wrappers still reach their wrapped tools' filters.

`uv-compact` and `npx-compact` don't compact pytest/ruff/eslint/prettier/tsc
themselves: they resolve the wrapped tool out of `$args` and re-invoke `lowfat
filter` on that plugin's own filter. Nothing in their locks can tell you that
dispatch still works — a wrong args mapping, a probe that stops finding the
sibling plugin, a renamed directory, and the wrapper quietly falls back to its
generic cap while its own golden stays UNCHANGED.

For every pair below, the wrapped tool's own sample goes through both filters at
every level and the outputs must match byte-for-byte.
"""
import subprocess
import sys
from pathlib import Path

LEVELS = ("ultra", "full", "lite")
ROOT = Path(__file__).resolve().parent.parent

# (wrapper plugin, wrapper args) ⇄ (original plugin, original args), over the
# original's samples. Samples stay flag-free so both sides take the compacting
# branch — the guard arms are each filter's own business, not this check's.
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
    """Output of one filter over one sample — the observable both sides must share."""
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
        print(f"drift.py: {len(mismatches)} mismatch(es); the wrapper stopped reaching "
              f"the wrapped tool's filter", file=sys.stderr)
        return 1

    print(f"IN SYNC — {sum(len(p[4]) for p in PAIRS) * len(LEVELS)} wrapper/original "
          f"comparisons across {len(PAIRS)} pairs")
    return 0


sys.exit(main())
