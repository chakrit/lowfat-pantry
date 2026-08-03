# The pantry overrides lowfat's bundled `ls-compact`

**Date:** 2026-08-03 · **Status:** accepted

`ls` is the first bundled filter the pantry replaces. An override is wholesale — lowfat
merges nothing, a disk plugin shadows the bundled one of the same name — so it is not a
thing to do casually. This one is earned: the bundled filter produces a confident wrong
answer, which is the exact failure the truncation ruling
([2026-07-26](2026-07-26-visible-truncation.md)) exists to stop.

## What the bundled filter does

Upstream `lowfat-plugin` 0.8.0, `embedded/ls/ls-compact/filter.lf`, in full:

    define strip-noise:
        drop /^total /
        drop /^$/

    *, ultra:
        strip-noise
        shell: awk '{print $NF}'
        head 40

    *, lite:
        strip-noise
        head 40

    *:
        strip-noise
        compact-long-form
        head 40

Two failures compound. `head 40` cuts without a marker at every level, so a 200-entry
directory returns 40 entries that are byte-indistinguishable from a directory holding 40
files. And `drop /^$/` removes the blank line that separates the sections of a
multi-directory listing — the shape `ls a b` emits:

    a:
    one.txt
    two.txt

    b:
    README.md

With the blank gone and the tail cut, `ls a b` reads as a complete listing of `a` and `b`
is simply absent. Nothing in the output says a second directory was ever asked for.

## The ruling

A directory listing is an **inventory listing**: one load-bearing name per row, nothing
redundant, and the whole value is completeness. Invariant 6 already covers it — rows are
never dropped, only column-squeezed, the same treatment `kubectl get` and `helm list`
already get. So the override is four lines over `squeeze-columns`, with non-zero exit
passing raw.

The cost is real and accepted: `ls` on a huge directory now passes through whole. That is
the same trade every other inventory listing in the pantry makes, and it is the safe
direction — a long listing costs tokens, a silently truncated one costs a wrong answer.

## Evidence

`plugins/ls/ls-compact/samples/` holds three captures from the `alpine` stack
(`capture/capture.sh alpine`): a two-directory `ls -l`, a 146-entry listing, and a missing
path. The 146-entry sample is the regression guard — its golden asserts 146 lines at
`ultra`, where the bundled filter returned 40.

Recording success-path output is new for `capture/`, which was built for failure shapes.
Recipes now carry the exit they exist to record (`ok` / `fail`), because for these samples
a non-zero exit is the broken capture.
