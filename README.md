# roselabs-io/homebrew-tools

Homebrew tap for Roselabs tools.

## Install

```sh
brew tap roselabs-io/tools
brew trust roselabs-io/tools   # recent Homebrew refuses third-party taps otherwise
brew install sshca       # SSH certificate authority and management CLI
brew install bastionhub  # SSH bastion and reverse-tunnel manager
brew install sshboard    # Web interface over sshca and bastionhub
```

`bastionhub` declares `sshca` as a required dependency. `sshboard` declares both
as recommended: it installs without them, but each view requires the
corresponding binary on `PATH`.

## Supported platforms

| | macOS | Linux (Linuxbrew) |
|---|---|---|
| amd64 | ✓ | ✓ |
| arm64 | ✓ | ✓ |

This tap ships no Windows binaries. On Windows, build from source or download
from each tool's GitHub Releases page.

## Tools

| Formula | Repo | Description |
|---|---|---|
| `sshca` | [roselabs-io/sshca](https://github.com/roselabs-io/sshca) | SSH certificate authority and management CLI. Wraps `ssh-keygen`; adds an issuance log, KRL revocation and renewal. |
| `bastionhub` | [roselabs-io/bastionhub](https://github.com/roselabs-io/bastionhub) | SSH bastion and reverse-tunnel manager. Delegates certificate operations to `sshca`. |
| `sshboard` | [roselabs-io/sshboard](https://github.com/roselabs-io/sshboard) | Web interface over the other two. Reads sshca's issuance log and bastionhub's `endpoints.yaml`, and runs both binaries for actions. |

## Updating formulae

### From a release event

The workflow `.github/workflows/homebrewtools-formula.yml` runs on a `repository_dispatch` event of type
`formula-update`:

```sh
gh api repos/roselabs-io/homebrew-tools/dispatches \
  -f event_type=formula-update -F 'client_payload[tool]=sshca' -F 'client_payload[tag]=v0.2.0'
```

1. `tools/formula_update.py <tool> <tag>` downloads `https://github.com/roselabs-io/<tool>/releases/download/<tag>/checksums.txt`
   and rewrites the four `url` lines and the four `sha256` lines of `Formula/<tool>.rb`; Homebrew reads the version from the `url`
2. The job commits the formula on the branch `formula/<tool>-<tag>`, opens a pull request into `main` and enables squash auto-merge on it

| Condition | Result |
|---|---|
| `tool` is not a formula of `Formula/` | the job fails |
| `tag` is not `v<X.Y.Z>` (a prerelease tag) | the job fails |
| `checksums.txt` lacks one of the four `.tar.gz` archives, or does not exist | the job fails; the formula is not written |
| the formula is already at the tag | no pull request |
| the branch `formula/<tool>-<tag>` exists | the push fails |

The token that sends the event needs write access to this repository's contents. The job pushes the
branch with the job's `github.token`, then opens the pull request and enables auto-merge with the
organization secret `HOMEBREW_TAP_TOKEN` (contents and pull-requests write), so that
`homebrewtools-ci.yml` runs on the pull request. The secret is set only in that last step. GitHub
merges the pull request into `main` when the required checks (`validate`, `Deterministic gate`) pass,
and `brew update` then serves the new formula. Only the pull request this workflow opens is merged
this way; other pull requests are merged by a person. The repository setting "Allow auto-merge" must
stay on.

The workflow also regenerates `.secrets.baseline` with detect-secrets 1.5.0 (installed with `pipx`) and
commits it with the formula, so `just secrets` accepts the new `sha256` values. It keeps the
`generated_at` line of the committed baseline, which detect-secrets rewrites on every scan, so the
pull requests of two tools change different lines of the baseline and the second merges after the
first without a conflict. The pull request merges without a person reading the baseline's diff; `validate` and
`Deterministic gate` (which includes `just secrets`) are the checks.

### By hand

1. Run `python3 tools/formula_update.py <tool> v<X.Y.Z>`, or fetch the release's `checksums.txt` and update the four `url` lines and the four `sha256` lines of `Formula/<tool>.rb`
2. Regenerate the secret-scan baseline, which holds the `sha256` values and the keyword detector's findings on the `secrets` recipe of `justfile`: `detect-secrets scan --no-verify --exclude-files '^\.secrets\.baseline$' > .secrets.baseline` (detect-secrets 1.5.0)
3. Run `just checksums` (compares the `sha256` lines with each release's `checksums.txt`) and `just gate` (the `url` and `sha256` line check, `brew style`, the secret scan, `brew audit --strict`), then open a pull request
