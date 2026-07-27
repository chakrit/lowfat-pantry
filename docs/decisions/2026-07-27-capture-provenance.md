# A sample's provenance is readable: our own base, fixtures as files, one command

**Date:** 2026-07-27 · **Status:** accepted

## Ruling

1. **No vendor tool images.** Every capture stack builds `FROM lowfat-capture-base`, which
   is the one place `alpine:3` is named, and installs its toolchain by hand. The exception
   is a stack whose tool under test *is* another distro's package manager — `apt` needs
   debian, `dnf` needs fedora — and it is named in `capture/README.md`, not inferred.
2. **A fixture is files, not a string.** The failing project lives at
   `capture/fixtures/<sample>/` as ordinary committed files.
3. **A capture is one command.** `docker run --rm -v <scratch>:/w -w /w <image> <tool>
   <args>`, against a scratch copy of the fixture. No `sh -c`, no setup welded to the
   invocation.
4. **Images are always rebuilt**, never skipped because the tag exists.

## Why this goes against the obvious default

The obvious default is what the rig shipped with, and every part of it is locally
reasonable. Use the vendor's image — they know how to install their own toolchain. Write
the fixture inline — it is four lines of YAML. Skip the build when the tag is already
there — it is the same image.

Each of those quietly severs a sample from its own provenance. A sample is not test input;
it is **evidence about what a tool prints**, and evidence is only worth what its chain of
custody is worth. `FROM python:3-alpine` means the toolchain is whatever that tag pointed
at on the day someone ran it. An escaped `printf` inside a shell string means the fixture
can only be read by mentally unescaping it. And a build that skips on tag-exists means the
image can silently stop matching the Dockerfile beside it — which is not a hypothetical:
it happened on the first run of this very change, on five stacks at once.

## What the change caught

Rebuilding the rig immediately exposed a sample that had been wrong since it was captured.
`apt-install-error` was produced on a stock `debian:stable-slim`, which ships an **empty**
package index. Against an empty index `apt-get install` answers `E: Unable to locate
package` for every name — including real ones:

    $ docker run --rm debian:stable-slim apt-get install -y curl
    E: Unable to locate package curl

So the committed sample was an unconfigured-apt artifact wearing the same words as the
missing-package error it claimed to be. The golden locked on it proved nothing about the
filter. The fix is one `apt-get update` at image build time; the captured bytes did not
change, only whether they meant anything.

That is the argument for the whole ruling in one case: the output looked right, the golden
was green, and the evidence was hollow. Nothing but re-deriving the sample from a readable
chain would have surfaced it.

## Cost accepted

Alpine's python, ruby, php and jvm builds are not the vendors' builds, so re-captured
samples can differ in version strings and, in principle, wording. Every one has to be read
and its golden re-locked. In this sweep the damage was smaller than expected — python and
apt byte-identical, ruby differing only in an elapsed-time line the filter already drops,
composer by one character of parse-excerpt window, deno by the mount path — but the review
is the cost, and it is charged on every re-capture, not just the first.

Always rebuilding also charges a docker build per stack per run. Layer caching makes an
unchanged rebuild nearly free, which is why the correctness is affordable.

## Alternatives rejected

**A `--rebuild` flag.** Keeps the fast path and makes staleness opt-out. But the failure it
guards against is silent and the flag is remembered by exactly the person who already knows
about the problem. A guard nobody trips is not a guard.

**Pinning vendor image digests instead of hand-installing.** Fixes reproducibility without
fixing readability: the toolchain is still assembled by someone else's Dockerfile, and
answering "what produced this line?" still means going and reading it.

**Mounting the fixture directly, read-write.** Simpler, and poetry, maven and dotnet would
write build state into the repo. The scratch copy costs one `cp -R`.

## Consequences

- `capture/base.dockerfile` is where the distro is chosen. Changing it changes every stack,
  which is the point.
- Samples now encode `/w` as the working directory, so tools that print absolute paths
  (deno, poetry, ansible) show `/w/...`. That is stable across machines, which the previous
  `/tmp` was not.
- `dnf-install-missing` carries run-varying repo-meter lines that never reach the golden;
  `capture/README.md` records why it churns and when not to commit it.
