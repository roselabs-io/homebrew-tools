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

# Secret scan of the tracked files with detect-secrets 1.5.0, without the network (`--no-verify`). Each finding
# whose file, hashed secret and type `.secrets.baseline` does not hold is printed as `path:line: type` and fails the
# recipe; line numbers are not compared. The recipe writes nothing. Untracked files and Git history are not scanned.
secrets:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$(detect-secrets --version 2>/dev/null)" != "1.5.0" ]; then
        echo "secrets: detect-secrets 1.5.0 is required: pipx install detect-secrets==1.5.0" >&2
        exit 1
    fi
    scan="$(detect-secrets scan --no-verify --exclude-files '^\.secrets\.baseline$')"
    SCAN="$scan" python3 -c '
    import json, os, sys
    def secrets(report):
        return [(path, s) for path, found in report["results"].items() for s in found]
    with open(".secrets.baseline") as file:
        accepted = {(path, s["hashed_secret"], s["type"]) for path, s in secrets(json.load(file))}
    new = [(path, s) for path, s in secrets(json.loads(os.environ["SCAN"])) if (path, s["hashed_secret"], s["type"]) not in accepted]
    for path, s in new:
        print("{}:{}: {}".format(path, s["line_number"], s["type"]))
    sys.exit("secrets: {} findings not in .secrets.baseline".format(len(new)) if new else 0)
    '

# The deterministic gate CI runs.
gate: check secrets test

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
