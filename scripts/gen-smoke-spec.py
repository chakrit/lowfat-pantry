#!/usr/bin/env python3
"""gen-smoke-spec.py — one-time migration: a plugin's tests.yml -> tests.cue.

Translates the legacy tests.yml case list into a smoke CUE spec (the new
source of truth). Run once per plugin during the smoke-harness rollout; the
emitted tests.cue is hand-maintained thereafter, not regenerated.

  scripts/gen-smoke-spec.py plugins/go/go-compact      # writes tests.cue

The spec drives chakrit/smoke (>= v0.3.0). See plugins/go/go-compact/tests.cue
for the annotated reference.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def parse_tests_yml(path):
    """Minimal parser for the pantry's (now-retired) tests.yml schema:
    top-level `command:` plus a `cases:` list of sample/sub/args/exit/levels."""
    command = None
    cases = []
    cur = None
    with open(path) as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            indent = len(line) - len(line.lstrip())
            if indent == 0 and stripped.startswith("command:"):
                command = stripped.split(":", 1)[1].strip().strip('"')
                continue
            if stripped.startswith("- "):
                if cur:
                    cases.append(cur)
                cur = {}
                stripped = stripped[2:].strip()
                if not stripped:
                    continue
            if cur is not None and ":" in stripped:
                k, v = stripped.split(":", 1)
                cur[k.strip()] = v.split("#", 1)[0].strip().strip('"')
        if cur:
            cases.append(cur)
    return command, cases


def levels_of(case):
    raw = case.get("levels", "lite full ultra")
    return raw.strip("[]").replace(",", " ").split() or ["lite", "full", "ultra"]


def cue_str(s):
    """Quote a value for a CUE string literal."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def emit(plugin_dir):
    rel = os.path.relpath(plugin_dir, ROOT)
    command, cases = parse_tests_yml(os.path.join(plugin_dir, "tests.yml"))
    if not cases:
        raise SystemExit(f"{rel}: no cases in tests.yml")

    name = os.path.basename(plugin_dir)
    lines = [
        f"// Golden-file drift tests for {name}, run by chakrit/smoke (>= v0.3.0).",
        "// Migrated once from tests.yml; this file is now the source of truth.",
        "// Invoke from the REPO ROOT (smoke runs commands in the invocation cwd):",
        f"//   smoke {rel}/tests.cue        # UNCHANGED/0 = no drift",
        f"//   smoke -c {rel}/tests.cue     # re-lock intentionally",
        "//",
        "// `_`-hidden fields template the case x level matrix and never reach",
        "// smoke's closed schema. Each case locks the raw filter output (literal",
        "// golden) and the same piped through scripts/measure.py (size metrics);",
        "// smoke is the sole judge, measure.py only emits.",
        f"_dir: {cue_str(rel)}",
        "_cases: [",
    ]
    for c in cases:
        lv = "[" + ", ".join(cue_str(x) for x in levels_of(c)) + "]"
        lines.append(
            "\t{"
            f"sample: {cue_str(c.get('sample', ''))}, "
            f"sub: {cue_str(c.get('sub', ''))}, "
            f"args: {cue_str(c.get('args', ''))}, "
            f"exit: {c.get('exit', '0')}, "
            f"levels: {lv}"
            "},"
        )
    lines += [
        "]",
        "",
        "config: {",
        "\tinterpreter: \"/bin/sh\"",
        "\ttimeout:     \"10s\"",
        "}",
        "tests: [{",
        f"\tname: {cue_str(name)}",
        "\tchecks: [\"stdout\", \"exitcode\"]",
        "\ttests: [",
        "\t\tfor c in _cases for l in c.levels {",
        "\t\t\tlet base = \"lowfat filter \\(_dir)/filter.lf --sub=\\(c.sub) --args='\\(c.args)' --exit=\\(c.exit) --level=\\(l) < \\(_dir)/\\(c.sample)\"",
        "\t\t\tname: \"\\(c.sample) \\(l)\"",
        "\t\t\tcommands: [base, \"\\(base) | scripts/measure.py\"]",
        "\t\t},",
        "\t]",
        "}]",
        "",
    ]
    out = os.path.join(plugin_dir, "tests.cue")
    with open(out, "w") as fh:
        fh.write("\n".join(lines))
    return out


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: gen-smoke-spec.py <plugin-dir>")
    pdir = sys.argv[1]
    pdir = pdir if os.path.isabs(pdir) else os.path.join(ROOT, pdir)
    print(emit(pdir))


if __name__ == "__main__":
    main()
