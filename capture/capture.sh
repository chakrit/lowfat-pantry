#!/bin/sh
# capture.sh — record real failure output from tools this machine doesn't have.
#
# One image per stack (see README.md), one recipe per tool. Each recipe provokes a
# genuine failure inside the container and writes the combined stream verbatim to the
# plugin's samples/ — no wrapper text, no annotations, byte-faithful.
#
#   capture/capture.sh                 # every stack
#   capture/capture.sh python ruby     # only these
#   capture/capture.sh --list          # what each stack covers
#
# Nothing here runs during the test suite. Review every captured file before committing:
# a capture that didn't fail the way it was meant to locks a golden that proves nothing.
unset CDPATH
cd "$(dirname "$0")/.." || exit 2

STACKS='alpine debian fedora python ruby jvm php dotnet'

usage() {
    echo "usage: capture/capture.sh [--list] [stack...]   (stacks: $STACKS)" >&2
}

# stack → the tools it captures, as "<tool> <plugin-dir> <sample-name>" rows
recipes_for() {
    case "$1" in
        alpine) echo 'apk apk/apk-compact apk-add-error
deno deno/deno-compact deno-run-error' ;;
        debian) printf '%s\n' 'apt apt/apt-compact apt-install-error' ;;
        fedora) printf '%s\n' 'dnf dnf/dnf-compact dnf-install-missing' ;;
        python) echo 'poetry poetry/poetry-compact poetry-broken-pyproject
black black/black-compact black-syntax-error
ansible-playbook ansible-playbook/ansible-playbook-compact ansible-playbook-syntax-error' ;;
        ruby)   printf '%s\n' 'rspec rspec/rspec-compact rspec-boot-crash' ;;
        jvm)    printf '%s\n' 'mvn mvn/mvn-compact mvn-broken-pom' ;;
        php)    printf '%s\n' 'composer composer/composer-compact composer-broken-json' ;;
        dotnet) echo 'dotnet-build dotnet/dotnet-compact dotnet-build-error
dotnet-test dotnet/dotnet-compact dotnet-test-fail' ;;
        *)      return 1 ;;
    esac
}

# The failure each tool is asked to produce, as a shell script run inside the container.
# Every one is a real error path — a missing package, an unparseable manifest, a file
# that isn't there — never a printf of something error-shaped.
recipe_script() {
    case "$1" in
        apk)    printf '%s\n' 'apk add --no-cache nosuchpkg123' ;;
        deno)   printf '%s\n' 'cd /tmp && deno run --allow-read does-not-exist.ts' ;;
        apt)    printf '%s\n' 'apt-get install -y nosuchpkg123' ;;
        dnf)    printf '%s\n' 'dnf install -y definitely-not-a-real-package-9z' ;;
        poetry) printf '%s\n' 'mkdir -p /w && cd /w && printf "[tool.poetry\nname = broken\n" > pyproject.toml && poetry install' ;;
        black)  printf '%s\n' 'mkdir -p /w && cd /w && printf "def f(:\n    return 1\n" > broken.py && black --check broken.py' ;;
        ansible-playbook) printf '%s\n' 'mkdir -p /w && cd /w && printf -- "- hosts: all\n  tasks:\n    - name: broken\n      command: echo hi\n     bad_indent: yes\n" > play.yml && ansible-playbook play.yml' ;;
        rspec)  printf '%s\n' 'mkdir -p /w/spec && cd /w && printf "require \"nope_not_a_gem\"\n" > spec/spec_helper.rb && printf "require \"spec_helper\"\n" > spec/a_spec.rb && rspec' ;;
        mvn)    printf '%s\n' 'mkdir -p /w && cd /w && printf "<project><modelVersion>4.0.0</modelVersion>\n" > pom.xml && mvn -B compile' ;;
        composer) printf '%s\n' 'mkdir -p /w && cd /w && printf "{ \"require\": { \"nope/nope\": \"^1.0\" \n" > composer.json && composer install --no-interaction' ;;
        # A C# *compile* error with a warning alongside it — the diagnostic shape the
        # filter keeps. An unparseable .csproj also fails the build, but as MSB4025 from
        # the project loader, which exercises none of the same keep-rules.
        dotnet-build) printf '%s\n' 'cd /tmp && dotnet new console -o app >/dev/null && cd app && printf "class P {\n    static void M(string s) { System.Console.WriteLine(s.Length); }\n    static void Main() { string? x = null; M(x); System.Console.WriteLine(orderTotal); }\n}\n" > Program.cs && dotnet build' ;;
        # Failing test among passing ones — a run that fails every test tells the filter
        # nothing about whether it keeps the failure and drops the passes.
        dotnet-test)  printf '%s\n' 'cd /tmp && dotnet new xunit -o t >/dev/null && cd t && printf "using Xunit;\npublic class CheckoutTests {\n    [Fact] public void Totals_add_up() { Assert.Equal(2, 1 + 1); }\n    [Fact] public void Totals_subtract() { Assert.Equal(0, 1 - 1); }\n    [Fact] public void Checkout_totals_round_tax() { Assert.Equal(10.82, 10.80); }\n}\n" > UnitTest1.cs && dotnet test' ;;
        *)      return 1 ;;
    esac
}

image_for() { echo "lowfat-capture-$1"; }

build_stack() {
    image=$(image_for "$1")
    if docker image inspect "$image" >/dev/null 2>&1; then
        echo "  image $image already built"
        return 0
    fi

    echo "  building $image from capture/$1.dockerfile"
    docker build -q -t "$image" -f "capture/$1.dockerfile" capture >/dev/null || return 1
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
    echo "$rows" | while read -r tool plugin sample; do
        [ -n "$tool" ] || continue
        out="plugins/$plugin/samples/$sample.txt"
        script=$(recipe_script "$tool") || {
            echo "  no recipe for $tool" >&2
            echo x >> "$failed"
            continue
        }

        docker run --rm "$image" sh -c "$script" > "$out" 2>&1
        status=$?
        lines=$(grep -c '' < "$out")

        if [ "$status" -eq 0 ]; then
            echo "  !! $tool exited 0 — that is not a failure; review $out" >&2
            echo x >> "$failed"
        fi
        echo "  $tool -> $out (exit $status, $lines lines)"
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
