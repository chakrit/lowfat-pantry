# capture/ — real failure output for tools this machine doesn't have

Samples must be byte-faithful to real command output (`plugins/README.md`), which is a
problem for the `or-shell` fallback arms: a fallback only fires when a filter's keep-list
matches *nothing*, and that shape shows up in crashes — a broken build file, a dead
package index, a missing interpreter. Those can't be written by hand, and half the tools
that produce them aren't installed here.

So they're captured in containers, one image **per stack** rather than per tool, and the
resulting `.txt` goes into the plugin's `samples/`. The images are provenance, not part of
the test loop: `scripts/test.sh` never touches Docker, and nothing here runs unless you
run it.

## Use

    capture/capture.sh                 # every stack (builds what's missing, then captures)
    capture/capture.sh python ruby     # just these
    capture/capture.sh --list          # what each stack covers, and image sizes

Captured files land in `plugins/<cmd>/<cmd>-compact/samples/` and are **reviewed by hand**
before committing — a capture that didn't actually fail the intended way is worse than no
sample, because it locks a golden that proves nothing.

Recipes name the sample the spec already expects, so a re-capture overwrites in place and
the lock diff tells you whether real output matches what was there before. Re-run any
capture twice before committing: merging stdout and stderr into one file is racy, and a
run that glues an error line onto the tail of another (`Building dependency tree...E:
Unable to locate…`) is an artifact, not the shape the tool normally emits.

## Stacks

| stack    | base                    | covers                              |
|----------|-------------------------|-------------------------------------|
| `alpine` | `alpine:3`              | apk, deno                           |
| `debian` | `debian:stable-slim`    | apt                                 |
| `fedora` | `fedora:latest`         | dnf                                 |
| `python` | `python:3-alpine`       | poetry, black, ansible-playbook     |
| `ruby`   | `ruby:3-alpine`         | rspec                               |
| `jvm`    | `eclipse-temurin:21-jdk-alpine` | mvn                         |
| `php`    | `php:8-cli-alpine`      | composer                            |

Deliberately absent: **dotnet** (SDK image is ~1.2 GB for one sample) and **pulumi** (CLI
pulls a ~200 MB toolchain and wants a logged-in backend to fail interestingly). Both stay
unexercised until someone wants them badly enough to pay for the pull; the ledger says so
rather than implying coverage that isn't there.
