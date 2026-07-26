#!/bin/sh
# Run the full smoke golden-test suite over every plugin's tests.cue, through the
# repo's pinned smoke wrapper (scripts/smoke.sh — provisions chakrit/smoke v0.5
# into .bin/). Args pass through to smoke:
#   scripts/test.sh           # UNCHANGED/0 = no drift across all plugins
#   scripts/test.sh -c        # re-lock everything (review the diff before commit)
#   scripts/test.sh -v        # verbose
#
# One invocation PER spec so each plugin gets its own verdict; the worst exit
# across all specs is aggregated below. (v0.4 also aggregates a single multi-spec
# call correctly, but per-spec keeps attribution obvious and re-lock uniform.)
unset CDPATH
cd "$(dirname "$0")/.." || exit 2

specs=$(find plugins -name tests.cue | sort)
if [ -z "$specs" ]; then
    echo "test.sh: no tests.cue specs found under plugins/" >&2
    exit 2
fi

# One smoke run per spec, but several at a time: each spec is an independent set
# of subprocess invocations against its own lock file, so the only shared thing is
# the pinned binary — provisioned once, below, before any of them start. Output is
# buffered per spec and replayed in order, so a parallel run reads exactly like a
# serial one. JOBS=1 to serialize while debugging.
scripts/smoke.sh --version >/dev/null 2>&1

out_dir=$(mktemp -d)
trap 'rm -rf "$out_dir"' EXIT

slot() { echo "$out_dir/$(echo "$1" | tr / _)"; }

running=0
for spec in $specs; do
    (
        scripts/smoke.sh "$@" "$spec" > "$(slot "$spec")" 2>&1
        echo $? > "$(slot "$spec").status"
    ) &

    running=$((running + 1))
    if [ "$running" -ge "${JOBS:-4}" ]; then
        wait
        running=0
    fi
done
wait

# Replay in spec order and aggregate the worst exit, exactly as the serial loop did —
# smoke's codes carry meaning (1 CHANGED, 3 NEW, 64/65 spec errors) that a boolean
# pass/fail would throw away.
rc=0
for spec in $specs; do
    cat "$(slot "$spec")"
    st=$(cat "$(slot "$spec").status" 2>/dev/null || echo 2)
    if [ "$st" -gt "$rc" ]; then
        rc=$st
    fi
done

# Two gates goldens structurally cannot provide, both skipped under `-c` because
# neither is re-lockable — a failure in either is a real bug:
#   drift.py     — the wrappers delegate to other plugins' filters; nothing in
#                  their own locks notices when that dispatch breaks.
#   overprune.py — a sample a filter recognizes never reaches its fallback, so
#                  the arms that catch reworded output sit unexecuted forever.
#   passthrough.py — a structured-output guard is only as good as the flag
#                  spellings and levels someone wrote a sample for.
#   lint.py      — the standing rulings (no python:, no awk, no bare cut, one
#                  marker form, no library macro without its include), checked
#                  rather than remembered.
case " $* " in
    *" -c "*) ;;
    *)
        scripts/lint.py || rc=1
        scripts/drift.py || rc=1
        scripts/overprune.py || rc=1
        scripts/passthrough.py || rc=1
        ;;
esac

exit "$rc"
