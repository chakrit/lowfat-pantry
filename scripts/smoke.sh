#!/bin/sh
# The repo's pinned chakrit/smoke, provisioned into a gitignored .bin/ via
# `go install` (needs Go on PATH) and run with all args forwarded. Single entry
# point so the suite (scripts/test.sh) and interactive single-plugin runs use the
# SAME smoke: v0.4 keys lock test-names by the spec BASENAME, and an older `smoke`
# on PATH would mis-key every lock in this repo.
#   scripts/smoke.sh plugins/go/go-compact/tests.cue       # check one plugin
#   scripts/smoke.sh -c plugins/go/go-compact/tests.cue    # re-lock one plugin
#
# Provisioned under a versioned name: bumping SMOKE_VERSION misses the cache and
# reinstalls, an unchanged version is a no-op. smoke runs commands in the cwd and
# the specs use repo-root-relative paths, so this cd's to the repo root first.
SMOKE_VERSION=v0.4.0

unset CDPATH
cd "$(dirname "$0")/.." || exit 2

SMOKE=".bin/smoke-$SMOKE_VERSION"
if [ ! -x "$SMOKE" ]; then
    echo "provisioning smoke $SMOKE_VERSION into .bin/ ..." >&2
    GOBIN="$PWD/.bin" go install "github.com/chakrit/smoke@$SMOKE_VERSION" || exit 2
    mv ".bin/smoke" "$SMOKE" || exit 2
fi

exec "$SMOKE" "$@"
