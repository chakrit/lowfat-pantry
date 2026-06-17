#!/usr/bin/env python3
"""measure.py — emit deterministic size metrics of stdin, for smoke to lock.

Pure measurement, never a gate: prints metrics and exits 0 no matter what.
smoke owns pass/fail via drift on the locked numbers. A filter regression —
over-prune to empty, unexpected growth — shows up as a changed value in the
lock, i.e. as drift. Keep this script judgment-free; the lock + a human review
the numbers, not this code.

Usage (inside a smoke command):
  lowfat filter <f.lf> ... < sample | scripts/measure.py
"""
import sys

data = sys.stdin.buffer.read()
lines = data.count(b"\n") + (1 if data and not data.endswith(b"\n") else 0)
print(f"lines {lines}")
print(f"bytes {len(data)}")
