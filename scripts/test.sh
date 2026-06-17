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
set -e
cd "$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
exec smoke "$@" $(find plugins -name tests.cue | sort)
