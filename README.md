# roselabs-io/homebrew-tools

Homebrew tap for Roselabs tools.

## Install

```sh
brew tap roselabs-io/tools
brew install sshca       # SSH-only cert/CA management CLI
brew install bastionhub  # Self-hosted SSH bastion + reverse-tunnel substrate
```

`bastionhub` declares `sshca` as a dependency, so installing it also installs `sshca`.

## Supported platforms

| | macOS | Linux (Linuxbrew) |
|---|---|---|
| amd64 | ✓ | ✓ |
| arm64 | ✓ | ✓ |

Windows users: install from source or download pre-built binaries from each tool's GitHub Releases page (this tap doesn't ship Windows binaries — Homebrew is the wrong distribution channel on Windows).

## Tools

| Formula | Repo | Description |
|---|---|---|
| `sshca` | [roselabs-io/sshca](https://github.com/roselabs-io/sshca) | SSH-only certificate authority and management CLI. Bus-factor-zero design. |
| `bastionhub` | [roselabs-io/bastionhub](https://github.com/roselabs-io/bastionhub) | Self-hosted SSH bastion + reverse-tunnel substrate. Pairs with sshca for cert auth. |

## Updating formulae

When a new release is tagged in a tool's repo, the formula here gets a corresponding update:

1. Fetch the new release's `checksums.txt` from `https://github.com/roselabs-io/<tool>/releases/download/v<X.Y.Z>/checksums.txt`
2. Update `version`, the four `url` lines (one per platform), and the four `sha256` lines in `Formula/<tool>.rb`
3. Commit + push

Automating this is on the backlog; until then, manual updates per release.
