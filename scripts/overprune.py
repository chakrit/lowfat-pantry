#!/usr/bin/env python3
"""overprune.py — no filter may swallow a non-empty stream whole.

Every filter is a keep-list built from output shapes its author had seen. Tools reword
their lines, ship new formats, get run under a different locale — and a keep-list that
matches nothing turns a page of output into *silence*, which the agent reads as "the
command printed nothing". That is the over-prune-to-empty failure, and it's why 33 rules
carry an `or-shell:`/`or` fallback.

Goldens can't cover those arms: a sample the filter recognizes never reaches them, so they
sit UNCHANGED forever without once being executed. This drives the opposite input — lines
no keep-list can match — through every filter at every level, on both a clean and a failed
exit, and asserts something came back.

Not a golden: there is nothing to re-lock, and a failure here is a filter bug.
"""
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

LEVELS = ("ultra", "full", "lite")
EXITS = (0, 1)
ROOT = Path(__file__).resolve().parent.parent

# Deliberately unrecognizable: the shape a filter meets when a tool reworded its output.
# Long enough to exceed every fallback's cap, so the marker path runs too.
UNRECOGNIZED = "".join(f"qqzz unrecognized payload line {n:04d}\n" for n in range(1, 121))


def run(filter_path, sub, exit_code, level):
    return subprocess.run(
        ["lowfat", "filter", str(filter_path),
         f"--sub={sub}", f"--args={sub}", f"--exit={exit_code}", f"--level={level}"],
        input=UNRECOGNIZED.encode(), capture_output=True,
    )


SUBCOMMAND = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def subcommands(plugin_dir):
    """The rule heads worth probing: every named rule, plus the catch-all.

    A head is `sub`, `a|b|c`, or `sub, <level>` — the level suffix is dropped here
    because every probe already runs all three levels.
    """
    heads = {""}
    for line in (plugin_dir / "filter.lf").read_text().splitlines():
        if not line or line[0].isspace() or line.startswith("#"):
            continue
        if line.rstrip().endswith(":") and not line.startswith("define"):
            head = line.rstrip()[:-1].split(",")[0]
            if head == "*":
                continue
            heads.update(part for part in head.split("|") if SUBCOMMAND.match(part))
    return sorted(heads)


def probe(job):
    spec, sub, exit_code, level = job
    result = run(spec, sub, exit_code, level)

    name = f"{spec.parent.name} sub={sub or '*'} exit={exit_code} {level}"
    if result.returncode != 0:
        return name, f"filter errored: {result.stderr.decode().strip()[:120]}"
    if not result.stdout.strip():
        return name, "swallowed the whole stream"
    return None


def main():
    specs = sorted(ROOT.glob("plugins/*/*/filter.lf"))
    jobs = [(spec, sub, exit_code, level)
            for spec in specs
            for sub in subcommands(spec.parent)
            for exit_code in EXITS
            for level in LEVELS]

    if len(specs) < 50:
        print(f"overprune.py: only {len(specs)} filters found — expected the whole pantry",
              file=sys.stderr)
        return 2

    # Each probe is a process spawn doing almost nothing; serially that is 20s of
    # waiting on fork, which is 20s nobody will keep paying on every test run.
    with ThreadPoolExecutor(max_workers=16) as pool:
        failures = [f for f in pool.map(probe, jobs) if f]
    checked = len(jobs)

    failures.sort()
    for name, why in failures:
        print(f"OVER-PRUNED {name} — {why}", file=sys.stderr)

    if failures:
        print(f"overprune.py: {len(failures)} of {checked} probes returned nothing; give "
              f"those rules a fallback", file=sys.stderr)
        return 1

    print(f"NO OVER-PRUNE — {checked} probes across {len(specs)} filters all kept "
          f"something")
    return 0


sys.exit(main())
