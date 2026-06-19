#!/bin/sh
# Run the full smoke golden-test suite over every plugin's tests.cue.
#
# smoke executes each spec's commands in the INVOCATION cwd, and the specs use
# repo-root-relative paths — so this always cd's to the repo root first. Extra
# args pass through to smoke:
#   scripts/test.sh           # UNCHANGED/0 = no drift across all plugins
#   scripts/test.sh -c        # re-lock everything (review the diff before commit)
#   scripts/test.sh -v        # verbose
#
# Needs chakrit/smoke >= v0.3.0 on PATH (go install github.com/chakrit/smoke@latest).
#
# One smoke invocation PER spec, not `smoke <spec1> <spec2> ...`: in smoke's
# default compare mode `compareResults()` calls os.Exit() after the FIRST spec
# (zdk/smoke process.go:282), so a single multi-spec call silently skips specs
# 2..N — the suite would read green while 56 of 57 specs went unchecked.
# (--commit/-c is unaffected — it returns instead of exiting — but we loop
# uniformly so verify and re-lock behave the same.) Aggregate the worst exit.
unset CDPATH
cd "$(dirname "$0")/.." || exit 2

rc=0
for spec in $(find plugins -name tests.cue | sort); do
    smoke "$@" "$spec"
    st=$?
    if [ "$st" -gt "$rc" ]; then
        rc=$st
    fi
done
exit $rc
