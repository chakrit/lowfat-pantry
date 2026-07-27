# apt — native to the base; nothing to install.
#
# The index is, though. A stock debian image ships `/var/lib/apt/lists/` empty, and
# against an empty index apt-get answers "Unable to locate package" for *every* name —
# `curl` as readily as `nosuchpkg123`. That output is an unconfigured-apt artifact
# wearing the same words as the error the sample is for, so the index is fetched here,
# at build time, and the capture then provokes a genuine missing-package failure.
FROM debian:stable-slim
RUN apt-get update
