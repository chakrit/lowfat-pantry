#!/usr/bin/env python3
"""validate.py — tests.yml-aware filter validation.

Runs each plugin's filter.lf against the cases declared in its tests.yml, using
the REAL per-case sub/args/exit (unlike validate.sh, which always assumes exit 0).
Purely via `lowfat filter` — no install, no trust, no global-state mutation.

For every (case x level) it reports input->output line reduction and flags:
  PARSE   filter failed to parse / lowfat errored
  EMPTY   non-error case (exit 0) produced empty output (likely over-prune)
  NOSHRINK ultra output >= input for a sizeable input (filter isn't compacting)

Usage:
  scripts/validate.py                 # all plugins
  scripts/validate.py plugins/mvn     # one plugin dir (or category dir)

Exit code is nonzero if any PARSE failure is seen.
"""
import os
import subprocess
import sys

LEVELS = ("lite", "full", "ultra")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def parse_tests_yml(path):
    """Minimal parser for the pantry's uniform tests.yml schema.

    Recognizes top-level `command:` and a `cases:` list whose items carry
    `sample/sub/args/exit/levels`. Not a general YAML parser — just our shape.
    """
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


def run_filter(filter_lf, sub, args, exit_code, level, sample):
    with open(sample, "rb") as fh:
        data = fh.read()
    proc = subprocess.run(
        ["lowfat", "filter", filter_lf, f"--sub={sub}", f"--args={args}",
         f"--exit={exit_code}", f"--level={level}"],
        input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    return proc.returncode, proc.stdout.decode("utf-8", "replace"), proc.stderr.decode("utf-8", "replace")


def find_plugins(roots):
    out = []
    for r in roots:
        for dirpath, _dirs, files in os.walk(r):
            if "filter.lf" in files:
                out.append(dirpath)
    return sorted(set(out))


def main():
    roots = sys.argv[1:] or [os.path.join(ROOT, "plugins")]
    roots = [r if os.path.isabs(r) else os.path.join(ROOT, r) for r in roots]
    plugins = find_plugins(roots)
    if not plugins:
        print(f"no filter.lf found under: {roots}", file=sys.stderr)
        return 1

    parse_fail = 0
    flags = 0
    for pdir in plugins:
        rel = os.path.relpath(pdir, ROOT)
        filter_lf = os.path.join(pdir, "filter.lf")
        tests = os.path.join(pdir, "tests.yml")
        print(f"\n=== {rel} ===")
        if not os.path.exists(tests):
            print("  (no tests.yml)")
            continue
        _cmd, cases = parse_tests_yml(tests)
        if not cases:
            print("  (no cases)")
            continue
        for c in cases:
            sample = c.get("sample", "")
            spath = os.path.join(pdir, sample)
            if not os.path.exists(spath):
                print(f"  MISS  {sample} (sample not found)")
                flags += 1
                continue
            sub = c.get("sub", "")
            args = c.get("args", "")
            exit_code = c.get("exit", "0")
            with open(spath) as fh:
                in_lines = sum(1 for _ in fh)
            for level in c.get("levels", "lite full ultra").strip("[]").replace(",", " ").split() or LEVELS:
                rc, out, err = run_filter(filter_lf, sub, args, exit_code, level, spath)
                if rc != 0:
                    print(f"  PARSE {os.path.basename(sample):28s} {level:5s} -> rc {rc}: {err.strip().splitlines()[-1] if err.strip() else ''}")
                    parse_fail += 1
                    continue
                out_lines = out.count("\n") + (1 if out and not out.endswith("\n") else 0)
                tag = "ok   "
                if exit_code == "0" and out_lines == 0 and in_lines > 0:
                    tag, flags = "EMPTY", flags + 1
                elif level == "ultra" and in_lines >= 40 and out_lines >= in_lines:
                    tag, flags = "NOSHR", flags + 1
                print(f"  {tag} {os.path.basename(sample):28s} exit={exit_code:3s} {level:5s} {in_lines:4d} -> {out_lines:4d}")

    print(f"\n{'='*40}\nPARSE failures: {parse_fail}   flags: {flags}")
    return 1 if parse_fail else 0


if __name__ == "__main__":
    sys.exit(main())
