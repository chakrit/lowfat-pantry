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

## Anatomy of a capture

Three readable pieces, no shell programs:

- **`base.dockerfile`** — `alpine:3` plus what toolchain *installers* need (TLS roots,
  curl, grep). The one place the distro is named.
- **`<stack>.dockerfile`** — `FROM lowfat-capture-base`, then the toolchain, installed by
  hand. No vendor tool images: `python:3-alpine` and friends hide their toolchain behind
  someone else's layer decisions, and a sample's provenance should be readable in one file.
- **`fixtures/<sample>/`** — the failing project as ordinary committed files. A broken
  `pom.xml` you can open beats the same XML escaped inside a shell string.

`capture.sh` then copies the fixture to a scratch directory, mounts it at `/w`, and runs
**one command**: `docker run --rm -v <scratch>:/w -w /w <image> <tool> <args>`. The scratch
copy exists because poetry, maven and dotnet all write build state into the working
directory, and a capture must leave nothing behind in the repo.

Images are always rebuilt, never skipped on tag-exists — an image that no longer matches
its Dockerfile produces exactly the unprovenanced sample this rig exists to prevent.
Docker's layer cache makes an unchanged rebuild nearly free.

## Use

    capture/capture.sh                 # every stack (builds, then captures)
    capture/capture.sh python ruby     # just these
    capture/capture.sh --list          # what each stack covers

Captured files land in `plugins/<cmd>/<cmd>-compact/samples/` and are **reviewed by hand**
before committing — a capture that didn't actually fail the intended way is worse than no
sample, because it locks a golden that proves nothing.

Recipes name the sample the spec already expects, so a re-capture overwrites in place and
the lock diff tells you whether real output matches what was there before. Re-run any
capture twice before committing: merging stdout and stderr into one file is racy, and a
run that glues an error line onto the tail of another (`Building dependency tree...E:
Unable to locate…`) is an artifact, not the shape the tool normally emits.

## Stacks

| stack    | base                  | covers                              |
|----------|-----------------------|-------------------------------------|
| `alpine` | `lowfat-capture-base` | apk, deno                           |
| `python` | `lowfat-capture-base` | poetry, black, ansible-playbook     |
| `ruby`   | `lowfat-capture-base` | rspec                               |
| `jvm`    | `lowfat-capture-base` | mvn                                 |
| `php`    | `lowfat-capture-base` | composer                            |
| `dotnet` | `lowfat-capture-base` | dotnet build, dotnet test           |
| `debian` | `debian:stable-slim`  | apt                                 |
| `fedora` | `fedora:latest`       | dnf                                 |

`debian` and `fedora` are the only stacks off the shared base, and the exemption is
principled rather than residual: the tool under test **is** that distro's package manager,
so `apt` on alpine would not be apt. They sit on minimal distro bases, not vendor tool
images, so the no-vendor-images rule still holds.

## Samples that carry noise

`dnf-install-missing` is not byte-stable run to run: dnf's three repo-meter lines vary in
transfer rate, elapsed time, payload size (Fedora's updates repo grows), and ordering
(concurrent downloads finish in whatever order). The error block itself is identical every
time, and `dnf-compact`'s failure branch drops all the meter lines before anything is
locked — so the churn reaches the sample file but never the golden. Re-capture it only
when the error block is what you're checking, and don't commit a diff that is only meter
noise.

## Not covered

**pulumi** — the CLI pulls a ~200 MB toolchain and wants a logged-in backend to fail
interestingly. It stays unexercised until someone wants the sample badly enough to pay for
the pull; this line says so rather than implying coverage that isn't there.

The dotnet stack is the expensive one, which is why it carries two recipes rather than
one: the toolchain install is per *stack*, so a second sample off the same image is nearly
free. Both recipes name the failure *class* the sample is for — a compile diagnostic with
a warning beside it, and one failing test among passing ones. An unparseable `.csproj`
also fails `dotnet build`, but as an MSB4025 from the project loader, which exercises none
of the keep-rules the sample exists to test.
