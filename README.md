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

When a new release is tagged in a tool's repo, the formula here gets a corresponding update:

1. Fetch the new release's `checksums.txt` from `https://github.com/roselabs-io/<tool>/releases/download/v<X.Y.Z>/checksums.txt`
2. Update `version`, the four `url` lines (one per platform), and the four `sha256` lines in `Formula/<tool>.rb`
3. Commit + push

Not currently automated.
