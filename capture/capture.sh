#!/bin/sh
# capture.sh — record real failure output from tools this machine doesn't have.
#
# A sample is evidence, so every part of how it was produced is readable: a stack
# Dockerfile holding only a toolchain, a fixture directory holding the failing
# project as ordinary files, and one command line. Nothing is a shell program.
#
#   capture/capture.sh                 # every stack
#   capture/capture.sh python ruby     # only these
#   capture/capture.sh --list          # what each stack covers
#
# Nothing here runs during the test suite. Review every captured file before
# committing: a capture that didn't fail the way it was meant to locks a golden
# that proves nothing.
unset CDPATH
cd "$(dirname "$0")/.." || exit 2

BASE_IMAGE=lowfat-capture-base
STACKS='alpine debian fedora node python ruby jvm php dotnet'

usage() {
    echo "usage: capture/capture.sh [--list] [stack...]   (stacks: $STACKS)" >&2
}

# Recipes, one per sample: "<sample> <plugin-dir> <fixture-or-none> <command…>".
# The command runs as-is against the fixture, so what provokes the failure is the
# fixture's content — a broken manifest, a missing import — not an argument that
# only looks error-shaped.
recipes_for() {
    case "$1" in
        alpine) echo 'apk-add-error apk/apk-compact none apk add --no-cache nosuchpkg123
deno-run-error deno/deno-compact none deno run --allow-read does-not-exist.ts' ;;
        debian) echo 'apt-install-error apt/apt-compact none apt-get install -y nosuchpkg123' ;;
        fedora) echo 'dnf-install-missing dnf/dnf-compact none dnf install -y definitely-not-a-real-package-9z' ;;
        node)   echo 'yarn-install-error yarn/yarn-compact yarn-install-error yarn install
npm-error npm/npm-compact npm-error npm install
pnpm-error pnpm/pnpm-compact pnpm-error pnpm install' ;;
        python) echo 'poetry-broken-pyproject poetry/poetry-compact poetry-broken-pyproject poetry install
black-syntax-error black/black-compact black-syntax-error black --check broken.py
ansible-playbook-syntax-error ansible-playbook/ansible-playbook-compact ansible-playbook-syntax-error ansible-playbook play.yml' ;;
        ruby)   echo 'rspec-boot-crash rspec/rspec-compact rspec-boot-crash rspec' ;;
        jvm)    echo 'mvn-broken-pom mvn/mvn-compact mvn-broken-pom mvn -B compile' ;;
        php)    echo 'composer-broken-json composer/composer-compact composer-broken-json composer install --no-interaction' ;;
        dotnet) echo 'dotnet-build-error dotnet/dotnet-compact dotnet-build-error dotnet build
dotnet-test-fail dotnet/dotnet-compact dotnet-test-fail dotnet test' ;;
        *)      return 1 ;;
    esac
}

# The alpine base is the only one; debian and fedora are exempt because the tool
# under test *is* that distro's package manager (capture/README.md).
needs_base() {
    case "$1" in
        debian|fedora) return 1 ;;
        *)             return 0 ;;
    esac
}

image_for() { echo "lowfat-capture-$1"; }

# Always build. Skipping when the tag already exists is the obvious optimization and
# it silently serves a stale toolchain after a Dockerfile edit — a sample captured
# from an image that no longer matches its Dockerfile is exactly the unprovenanced
# evidence this rig exists to stop producing. Docker's own layer cache already makes
# an unchanged rebuild nearly free.
build_image() {
    image=$1
    dockerfile=$2

    echo "  building $image from $dockerfile"
    docker build -q -t "$image" -f "$dockerfile" capture >/dev/null
}

build_stack() {
    if needs_base "$1"; then
        build_image "$BASE_IMAGE" capture/base.dockerfile || return 1
    fi

    build_image "$(image_for "$1")" "capture/$1.dockerfile"
}

# The fixture is copied to a scratch directory before mounting: poetry, maven and
# dotnet all write build state into the working directory, and a capture must not
# leave anything behind in the repo.
run_recipe() {
    fixture=$1
    out=$2
    shift 2

    work=$(mktemp -d) || return 2
    [ "$fixture" = none ] || cp -R "capture/fixtures/$fixture/." "$work/" || return 2

    docker run --rm -v "$work:/w" -w /w "$image" "$@" > "$out" 2>&1
    status=$?

    rm -rf "$work"
    return $status
}

capture_stack() {
    stack=$1
    rows=$(recipes_for "$stack") || { echo "capture.sh: unknown stack '$stack'" >&2; return 2; }

    echo "stack $stack"
    build_stack "$stack" || { echo "  BUILD FAILED — skipping $stack" >&2; return 1; }

    image=$(image_for "$stack")
    failed=$(mktemp)
    trap 'rm -f "$failed"' EXIT

    # `while` in a pipeline runs in a subshell, so a flag file carries the verdict
    # back out — a stack whose recipes all no-op should not report success.
    echo "$rows" | while read -r sample plugin fixture command; do
        [ -n "$sample" ] || continue
        out="plugins/$plugin/samples/$sample.txt"

        # shellcheck disable=SC2086  # the recipe's command is a deliberate word list
        run_recipe "$fixture" "$out" $command
        status=$?
        lines=$(grep -c '' < "$out")

        if [ "$status" -eq 0 ]; then
            echo "  !! $sample exited 0 — that is not a failure; review $out" >&2
            echo x >> "$failed"
        fi
        echo "  $sample -> $out (exit $status, $lines lines)"
    done

    [ ! -s "$failed" ]
}

case "${1:-}" in
    --list)
        for s in $STACKS; do
            printf '%-8s %s\n' "$s" "$(recipes_for "$s" | cut -d' ' -f1 | tr '\n' ' ')"
        done
        exit 0
        ;;
    -h|--help) usage; exit 0 ;;
esac

command -v docker >/dev/null 2>&1 || { echo "capture.sh: docker not on PATH" >&2; exit 2; }

# shellcheck disable=SC2086  # STACKS is a deliberate word list, not one argument
[ $# -gt 0 ] || set -- $STACKS

rc=0
for stack in "$@"; do
    capture_stack "$stack" || rc=1
done
exit $rc
