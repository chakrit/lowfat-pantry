#!/usr/bin/env python3
"""levels.py — ultra must not be bigger than full, nor full bigger than lite.

The three levels are a promise about *budget*: ultra is the tightest view of a command's
output, lite the most generous. Nothing enforces that. A level-specific rule that forgets
one of its siblings' `drop`s inverts the order — pulumi's ultra kept the "running" lines
that full drops and came out longer than full, i.e. the tightest level was the most
expensive one.

Goldens lock each level separately and never compare them, so the inversion sits in three
UNCHANGED locks. This replays each spec's own cases across all three levels and compares
the line counts.

A tie is fine (nothing to cut at that size); a *decrease* going up a level is not.
"""
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ORDER = ("ultra", "full", "lite")
CASE = re.compile(
    r'\{sample:\s*"([^"]+)",\s*sub:\s*"([^"]*)",\s*args:\s*"([^"]*)",\s*exit:\s*(\d+)')


def cases():
    for spec in sorted(ROOT.glob("plugins/*/*/tests.cue")):
        for sample, sub, args, exit_code in CASE.findall(spec.read_text()):
            yield spec.parent, sample, sub, args, int(exit_code)


def probe(case):
    plugin, sample, sub, args, exit_code = case
    sizes = {}
    for level in ORDER:
        run = subprocess.run(
            ["lowfat", "filter", str(plugin / "filter.lf"), f"--sub={sub}",
             f"--args={args}", f"--exit={exit_code}", f"--level={level}"],
            stdin=(plugin / sample).open("rb"), capture_output=True,
        )
        if run.returncode != 0:
            return (f"{plugin.name} {Path(sample).name} exit={exit_code}",
                    f"filter errored at {level}")
        sizes[level] = len(run.stdout.splitlines())

    ordered = [sizes[level] for level in ORDER]
    if ordered != sorted(ordered):
        return (f"{plugin.name} {Path(sample).name} exit={exit_code}",
                " > ".join(f"{level}={sizes[level]}" for level in ORDER))
    return None


def main():
    jobs = list(cases())
    if len(jobs) < 100:
        print(f"levels.py: only {len(jobs)} cases parsed out of ~250 — the spec format "
              f"changed and this gate is checking almost nothing", file=sys.stderr)
        return 2

    with ThreadPoolExecutor(max_workers=16) as pool:
        failures = [f for f in pool.map(probe, jobs) if f]

    failures.sort()
    for name, why in failures:
        print(f"INVERTED {name} — {why}", file=sys.stderr)

    if failures:
        print(f"levels.py: {len(failures)} of {len(jobs)} cases put a tighter level above a "
              f"looser one", file=sys.stderr)
        return 1

    print(f"LEVELS ORDERED — {len(jobs)} cases, ultra <= full <= lite")
    return 0


sys.exit(main())
