# Homebrew tap recipes of the command contract. `check` and `gate` are what the local preflight runs.
# `up` is listed under `checks.recipes.not_applicable` in pipeline.yaml.
# `down` is listed under `checks.recipes.not_applicable` in pipeline.yaml.
# `logs` is listed under `checks.recipes.not_applicable` in pipeline.yaml.

# brew must not update itself, clean the Cellar or print hints while a recipe runs.
export HOMEBREW_NO_AUTO_UPDATE := "1"
export HOMEBREW_NO_INSTALL_CLEANUP := "1"
export HOMEBREW_NO_ENV_HINTS := "1"

# Style check of the formulae.
check:
    brew style Formula

# `brew audit --strict` of each formula of this checkout. `brew audit` reads formulae by name from a tap, not by
# path. When the tap `roselabs-io/tools` is this checkout (CI, `Homebrew/actions/setup-homebrew`), it is audited
# directly. Otherwise the checkout is symlinked into the Taps directory as `roselabs-io/tools-gate` for the run and
# the link is removed on exit; an installed `roselabs-io/tools` tap is not changed.
test:
    #!/usr/bin/env bash
    set -euo pipefail
    here="$(pwd -P)"
    taps="$(brew --repository)/Library/Taps/roselabs-io"
    if [ -e "$taps/homebrew-tools" ] && [ "$(cd "$taps/homebrew-tools" && pwd -P)" = "$here" ]; then
        brew audit --strict --tap roselabs-io/tools
        exit 0
    fi
    link="$taps/homebrew-tools-gate"
    if [ -e "$link" ] || [ -L "$link" ]; then echo "test: $link exists; remove it" >&2; exit 1; fi
    mkdir -p "$taps"
    ln -s "$here" "$link"
    trap 'rm -f "$link"' EXIT
    brew audit --strict --tap roselabs-io/tools-gate

# The deterministic gate CI runs.
gate: check test

# Apply the style fixes.
fix:
    brew style --fix Formula

# Switch to main and fast-forward it from origin; refuses local changes or a diverged main.
ff:
    #!/usr/bin/env sh
    set -eu
    if [ -n "$(git status --porcelain)" ]; then echo "ff: the working tree has changes" >&2; exit 1; fi
    git switch main
    git fetch origin main
    git merge --ff-only origin/main
