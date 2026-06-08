#!/usr/bin/env bash
# validate.sh — run every plugin's filter.lf against its samples, purely.
#
# Uses `lowfat filter` (the standalone .lf runner): no plugin install, no trust,
# no global-state mutation. Reports parse success and line-reduction per
# (sample × level). Reads each plugin's tests.yml for sub/args context when
# present; otherwise infers `sub` from the sample filename (<cmd>-<sub>-<lvl>).
#
# Usage:
#   scripts/validate.sh                # all plugins under plugins/
#   scripts/validate.sh plugins/rg     # one plugin (dir or category)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEVELS=(lite full ultra)
fail=0

command -v lowfat >/dev/null || { echo "lowfat not on PATH" >&2; exit 127; }

# Find plugin dirs (those holding a filter.lf).
if [[ $# -gt 0 ]]; then
  roots=("$@")
else
  roots=("$ROOT/plugins")
fi

lfs=$(for r in "${roots[@]}"; do find "$r" -name filter.lf 2>/dev/null; done | sort -u)
[[ -z "$lfs" ]] && { echo "no filter.lf found under: ${roots[*]}" >&2; exit 1; }

while IFS= read -r lf; do
  [[ -z "$lf" ]] && continue
  dir="$(dirname "$lf")"
  rel="${dir#"$ROOT"/}"
  printf '\n=== %s ===\n' "$rel"
  shopt -s nullglob
  samples=("$dir"/samples/*.txt)
  shopt -u nullglob
  if [[ ${#samples[@]} -eq 0 ]]; then
    echo "  (no samples)"
    continue
  fi
  for s in "${samples[@]}"; do
    base="$(basename "$s" .txt)"
    # infer subcommand: <cmd>-<sub>[-<level>] -> field 2, unless it's a level word
    sub="$(awk -F- '{print $2}' <<<"$base")"
    case "$sub" in lite|full|ultra|"") sub="" ;; esac
    in_lines=$(wc -l <"$s" | tr -d ' ')
    for lvl in "${LEVELS[@]}"; do
      out=$(lowfat filter "$lf" --sub="$sub" --level="$lvl" <"$s" 2>/tmp/lf-err)
      rc=$?
      if [[ $rc -ne 0 ]]; then
        echo "  FAIL  $base  sub=$sub  $lvl  -> exit $rc: $(head -1 /tmp/lf-err)"
        fail=1
        continue
      fi
      out_lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
      printf '  ok    %-28s sub=%-8s %-5s  %4s -> %-4s lines\n' "$base" "${sub:-—}" "$lvl" "$in_lines" "$out_lines"
    done
  done
done <<EOF
$lfs
EOF

exit $fail
