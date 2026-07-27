#!/usr/bin/env python3
"""lint.py — the pantry's standing rulings, checked instead of remembered.

Each rule here was a decision that cost a sweep across every filter. Documentation alone
doesn't hold them: the next filter is written by pattern-matching an existing one, and a
single `head 40` or a `python:` body reintroduces a class the pantry already paid to
remove. Static, so it costs nothing to run.

  banned interpreter  a filter needing python3 doesn't degrade without it, it dies
  banned awk          repo-wide ban
  bare head/tail      cuts without a marker; a truncated stream reads as a short one,
                      whether the op stands alone or trails a match-arm label
  marker form         one sentence, pantry-wide, so an agent learns it once
  missing include     a macro from plugins/lib/ used without pulling the library in
  manifest drift      name/category/commands must agree with the directory, or the
                      plugin installs under a name lowfat then can't route to
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "plugins" / "lib"

MARKER = re.compile(
    r"\[lowfat\] \+%d [a-z ]+ dropped \(level=%s\) -- output truncated, "
    r"re-run raw for the full list")
# An op may sit alone on its line or inline after the label of the arm that selects it
# (`ultra: tail 40`, `shell: head -$1`). Both forms cut; a rule that only sees the first
# leaves the second free to reintroduce the class, which is how 42 of them survived a sweep.
ARM = r"(?:[a-z*|-]+:[ \t]+)?"
COUNT = r"(?:auto|-?(?:[0-9]+|\$[0-9]+))"
BARE_CUT = re.compile(rf"^\s*{ARM}(head|tail) ({COUNT})\s*$")
DEFINE = re.compile(r"^define ([\w-]+)")
CALL = re.compile(rf"^\s+{ARM}([a-z][\w-]*)(?: {COUNT})?\s*$")


def library_macros():
    macros = {}
    for lib in sorted(LIB.glob("*.lf")):
        for line in lib.read_text().splitlines():
            found = DEFINE.match(line)
            if found:
                macros[found.group(1)] = f"../../lib/{lib.name}"
    return macros


MANIFEST_FIELD = r'^{}\s*=\s*"([^"]*)"'


def check_manifest(toml):
    """name/category/commands vs. the path they live at."""
    text = toml.read_text()
    category, name = toml.parts[-3], toml.parts[-2]

    def field(key):
        found = re.search(MANIFEST_FIELD.format(key), text, re.M)
        return found.group(1) if found else None

    commands = re.search(r"^commands\s*=\s*\[([^\]]*)\]", text, re.M)
    commands = [c.strip().strip('"') for c in commands.group(1).split(",")
                if c.strip()] if commands else []

    problems = []
    if field("name") != name:
        problems.append((0, f"manifest name {field('name')!r} != directory {name!r}"))
    if field("category") != category:
        problems.append((0, f"manifest category {field('category')!r} != {category!r}"))
    if category not in commands:
        problems.append((0, f"manifest commands {commands} does not claim {category!r}"))
    return problems


def check(spec, macros):
    text = spec.read_text()
    lines = text.splitlines()
    local = {DEFINE.match(l).group(1) for l in lines if DEFINE.match(l)}
    included = {l.split()[1] for l in lines if l.startswith("include ")}
    problems = []

    if "python:" in text:
        problems.append((0, "python: body — filters are POSIX sh only"))
    if re.search(r"\bawk\b", text):
        problems.append((0, "awk — banned repo-wide"))

    for n, line in enumerate(lines, 1):
        if BARE_CUT.match(line):
            problems.append((n, f"bare cut `{line.strip()}` — use the marked macro"))

        # only what a filter actually emits; prose may name the marker in shorthand
        if "[lowfat]" in line and not line.lstrip().startswith("#"):
            if not MARKER.search(line):
                problems.append((n, "marker text drifts from the house form"))

        call = CALL.match(line)
        if call:
            name = call.group(1)
            if name in macros and name not in local and macros[name] not in included:
                problems.append((n, f"calls `{name}` without `include {macros[name]}`"))

    return problems


def main():
    macros = library_macros()
    if not macros:
        print("lint.py: no library macros found under plugins/lib/", file=sys.stderr)
        return 2

    specs = sorted(ROOT.glob("plugins/*/*/filter.lf"))
    if len(specs) < 50:
        print(f"lint.py: only {len(specs)} filters found — expected the whole pantry",
              file=sys.stderr)
        return 2

    failures = 0
    for spec in specs:
        findings = check(spec, macros)
        manifest = spec.parent / "lowfat.toml"
        if manifest.exists():
            findings += check_manifest(manifest)
        else:
            findings.append((0, "no lowfat.toml beside filter.lf"))

        for line_no, why in findings:
            where = f"{spec.relative_to(ROOT)}:{line_no}" if line_no else spec.relative_to(ROOT)
            print(f"LINT {where} — {why}", file=sys.stderr)
            failures += 1

    if failures:
        print(f"lint.py: {failures} standing-ruling violation(s)", file=sys.stderr)
        return 1

    print(f"CONVENTIONS HOLD — {len(specs)} filters, {len(macros)} library macros")
    return 0


sys.exit(main())
