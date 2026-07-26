#!/usr/bin/env python3
"""passthrough.py — a filter that claims a structured-output flag must not touch the bytes.

Invariant 1: JSON, ndjson and porcelain modes are machine-readable, and a compactor that
drops a line from them doesn't degrade the output, it corrupts it — the consumer parses
what's left and gets a wrong answer, or fails on a truncated document. Every filter that
recognizes such a flag guards it with `raw`.

The guards are easy to write and easy to *half*-write: one level covered and another not,
a flag matched in its `--flag json` spelling but not `--flag=json`. Goldens only catch the
combinations someone thought to add a sample for.

So this reads each filter's own flag guards out of its `.lf`, and for every one, pushes a
JSON document through the filter with that flag set — at every level, on a clean and a
failed exit — and requires the output back byte-identical.
"""
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

LEVELS = ("ultra", "full", "lite")
EXITS = (0, 1)
ROOT = Path(__file__).resolve().parent.parent

# Big enough to trip every cap in the pantry, and a shape a keep-list would shred.
PAYLOAD = ("[\n" + ",\n".join(
    f'  {{"id": {n}, "name": "item-{n}", "state": "ok", "detail": "line {n} of payload"}}'
    for n in range(1, 121)) + "\n]\n").encode()

# The guard is replayed **exactly as written** — `--format=json` and `--format json` are
# different args to lowfat, and re-spelling one as the other tests a flag the filter never
# claimed.
FLAG_GUARD = re.compile(r"^\s*(?:if|elif)\s+(-\S+(?: [A-Za-z0-9-]+)?)\s*:")
RULE_HEAD = re.compile(r"^([A-Za-z0-9*][^:]*):\s*$")


def guarded_rules(spec):
    """(subcommand, flag) for every structured-output guard, under the rule that holds it.

    The subcommand matters: a guard on `pr|issue|run:` says nothing about what the
    catch-all does with the same flag, and it's the catch-all that meets the subcommand
    nobody enumerated.
    """
    found = set()
    sub = ""
    for line in spec.read_text().splitlines():
        if line.startswith("define"):
            sub = None                       # macro body: not a rule
            continue
        head = RULE_HEAD.match(line)
        if head and not line[0].isspace():
            name = head.group(1).split(",")[0].split("|")[0]
            sub = "" if name == "*" else name
            continue
        if sub is None:
            continue

        guard = FLAG_GUARD.match(line)
        if guard and ("json" in guard.group(1).lower()
                      or "porcelain" in guard.group(1).lower()):
            found.add((sub, guard.group(1)))
    return sorted(found)


def probe(job):
    spec, sub, flag, exit_code, level = job
    run = subprocess.run(
        ["lowfat", "filter", str(spec), f"--sub={sub}", f"--args={sub} {flag}".strip(),
         f"--exit={exit_code}", f"--level={level}"],
        input=PAYLOAD, capture_output=True,
    )

    name = f"{spec.parent.name} {sub or '*'} '{flag}' exit={exit_code} {level}"
    if run.returncode != 0:
        return name, f"filter errored: {run.stderr.decode().strip()[:120]}"
    if run.stdout != PAYLOAD:
        kept = len(run.stdout.splitlines())
        sent = len(PAYLOAD.splitlines())
        return name, f"payload altered ({sent} lines in, {kept} out)"
    return None


def main():
    jobs = [(spec, sub, flag, exit_code, level)
            for spec in sorted(ROOT.glob("plugins/*/*/filter.lf"))
            for sub, flag in guarded_rules(spec)
            for exit_code in EXITS
            for level in LEVELS]

    if not jobs:
        print("passthrough.py: no structured-output guards found", file=sys.stderr)
        return 2

    with ThreadPoolExecutor(max_workers=16) as pool:
        failures = [f for f in pool.map(probe, jobs) if f]

    failures.sort()
    for name, why in failures:
        print(f"CORRUPTED {name} — {why}", file=sys.stderr)

    if failures:
        print(f"passthrough.py: {len(failures)} of {len(jobs)} guarded probes did not come "
              f"back byte-identical", file=sys.stderr)
        return 1

    print(f"BYTE-EXACT — {len(jobs)} structured-output probes across "
          f"{len({j[0] for j in jobs})} filters")
    return 0


sys.exit(main())
