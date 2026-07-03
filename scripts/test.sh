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

rc=0
for spec in $specs; do
    scripts/smoke.sh "$@" "$spec"
    st=$?
    if [ "$st" -gt "$rc" ]; then
        rc=$st
    fi
done
exit $rc
