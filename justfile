# Homebrew tap recipes of the command contract. `check` and `gate` are what the local preflight runs.
# `up` is listed under `checks.recipes.not_applicable` in pipeline.yaml.
# `down` is listed under `checks.recipes.not_applicable` in pipeline.yaml.
# `logs` is listed under `checks.recipes.not_applicable` in pipeline.yaml.

# brew must not update itself, clean the Cellar or print hints while a recipe runs.
export HOMEBREW_NO_AUTO_UPDATE := "1"
export HOMEBREW_NO_INSTALL_CLEANUP := "1"
export HOMEBREW_NO_ENV_HINTS := "1"
# With bootsnap, `brew style <tap>` on a symlinked tap exits with "deadlock; recursive locking" (Homebrew 7.0.4, macOS).
export HOMEBREW_NO_BOOTSNAP := "1"

# Offline check of each formula's url and sha256 lines: one version, four platforms, 64-hex checksums.
formulae:
    python3 tools/formula_check.py Formula/*.rb

# Compares each formula's sha256 lines with its release's checksums.txt. Needs the network; not part of the gate.
checksums:
    python3 tools/formula_check.py --checksums Formula/*.rb

# Runs `brew <command> <tap>` on the tap of this checkout. `brew style` and `brew audit` read the formulae through a
# tap: `brew style Formula` under a path with a hidden directory applies RuboCop's generic cops instead of Homebrew's
# formula cops, and `brew audit` reads formulae by name, not by path. When the tap `roselabs-io/tools` is this
# checkout (CI, `Homebrew/actions/setup-homebrew`), it is used directly. Otherwise the checkout is symlinked into the
# Taps directory as `roselabs-io/tools-gate` for the run and the link is removed on exit; an installed
# `roselabs-io/tools` tap is not changed.
[private]
with-tap command:
    #!/usr/bin/env bash
    set -euo pipefail
    here="$(pwd -P)"
    taps="$(brew --repository)/Library/Taps/roselabs-io"
    if [ -e "$taps/homebrew-tools" ] && [ "$(cd "$taps/homebrew-tools" && pwd -P)" = "$here" ]; then
        brew {{command}} roselabs-io/tools
        exit 0
    fi
    link="$taps/homebrew-tools-gate"
    if [ -e "$link" ] || [ -L "$link" ]; then echo "with-tap: $link exists; remove it" >&2; exit 1; fi
    mkdir -p "$taps"
    ln -s "$here" "$link"
    trap 'rm -f "$link"' EXIT
    brew {{command}} roselabs-io/tools-gate

# Style check of the formulae.
check: (with-tap "style")

# Self-checks of tools/formula_check.py and tools/formula_update.py, then `brew audit --strict` of each formula of this checkout.
test: && (with-tap "audit --strict --tap")
    python3 -B -m unittest discover -s tools -p 'test_*.py'

# The deterministic gate CI runs.
gate: formulae check test

# Apply the style fixes.
fix: (with-tap "style --fix")

# Switch to main and fast-forward it from origin; refuses local changes or a diverged main.
ff:
    #!/usr/bin/env sh
    set -eu
    if [ -n "$(git status --porcelain)" ]; then echo "ff: the working tree has changes" >&2; exit 1; fi
    git switch main
    git fetch origin main
    git merge --ff-only origin/main
