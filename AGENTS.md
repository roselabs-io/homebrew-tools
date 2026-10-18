# AGENTS.md

Instructions for agent sessions working in this repository. `pipeline.yaml` names this file for
`docs.agents`, `docs.contract`, `docs.review_posture` and `docs.operating_model`.

## Repository

The Homebrew tap `roselabs-io/tools`. A push to `main` publishes a formula: `brew update` fetches
the tap's default branch. The rules for the formulae and their update are in Governor
`governor/docs/org/roselabs-io/go-cli-posture.md` (The Homebrew tap).

| Path | Content |
|---|---|
| `Formula/sshca.rb`, `Formula/bastionhub.rb`, `Formula/sshboard.rb` | one formula per CLI: `desc`, `homepage`, `license`, one `url` and one `sha256` per platform (macOS and Linux, amd64 and arm64), `depends_on`, `install`, and a `test do` that runs `<tool> --version` |
| `README.md` | install, platforms, the tools, the manual formula update |
| `.secrets.baseline` | the detect-secrets findings `just secrets` accepts: the twelve `sha256` values of the formulae |
| `.github/workflows/homebrewtools-ci.yml` | `validate` (PR metadata) and `gate` (`just gate`) |
| `.github/workflows/homebrewtools-pm.yml` | the issue and board sync of Governor |
| `pipeline.yaml` | the Governor dispatcher's config for this repository |
| `tools/local_preflight.py` | the local check the dispatcher runs: `just check`, then `just gate` |

A formula has no `version` line: `brew audit --strict` reports it as redundant, and Homebrew reads
the version from the `url` (`.../download/v<version>/<tool>-v<version>-<os>-<arch>.tar.gz`). A
version change edits the four `url` lines and the four `sha256` lines.

## Commands

| Recipe | Runs |
|---|---|
| `just check` | `brew style Formula` |
| `just test` | `brew audit --strict` of each formula of the checkout |
| `just secrets` | `detect-secrets scan --no-verify` of the tracked files, compared with `.secrets.baseline` |
| `just gate` | `check`, `secrets`, then `test`; the deterministic gate CI runs |
| `just fix` | `brew style --fix Formula` |
| `just ff` | switches to `main` and fast-forwards it from `origin`; refuses local changes or a diverged `main` |

`up`, `down` and `logs` are not applicable (`checks.recipes.not_applicable` of `pipeline.yaml`):
there is no local stack. `just`, Homebrew, `python3` and detect-secrets 1.5.0 on `PATH`
(`pipx install detect-secrets==1.5.0`) are required. The recipes set
`HOMEBREW_NO_AUTO_UPDATE`, `HOMEBREW_NO_INSTALL_CLEANUP` and `HOMEBREW_NO_ENV_HINTS`.

`brew audit` reads formulae by name from a tap. When the tap `roselabs-io/tools` is the checkout
(CI), `just test` audits it. Otherwise it links the checkout into Homebrew's Taps directory as
`roselabs-io/tools-gate` for the run and removes the link on exit; an installed `roselabs-io/tools`
tap is not changed.

`brew style` is a developer command: its first run turns on Homebrew's developer mode, installs
Homebrew's style gems, and installs `shellcheck` and `actionlint` with `brew install`.

`just secrets` exits 1 with `secrets: detect-secrets 1.5.0 is required` when another version or none
is on `PATH`. It prints each finding whose file, hashed secret and type `.secrets.baseline` does not
hold as `path:line: type` and exits 1; line numbers are not compared, so a moved line passes. It
writes nothing. A new `sha256` value is a finding: a version change regenerates the baseline with

```sh
detect-secrets scan --no-verify --exclude-files '^\.secrets\.baseline$' > .secrets.baseline
```

and the diff of the baseline is reviewed. The detectors are detect-secrets' patterns and entropy
rules, so a secret of an unknown format with low entropy is not found. Untracked files and Git
history are not scanned.

The gate does not download the archives: a wrong `url` or `sha256` is found when `brew install`
fetches the archive.

## CI

All workflows run on GitHub-hosted `ubuntu-latest`. The repository is public; the organization's
self-hosted runners do not serve it. The `gate` job sets up Homebrew with
`Homebrew/actions/setup-homebrew`, which links the checkout as the tap `roselabs-io/tools`. The job
installs detect-secrets 1.5.0 with `pipx` before `just gate`.
`validate` and `homebrewtools-pm.yml` check out the private `roselabs-io/governor` with the
organization secret `GOVERNOR_PM_TOKEN`, which a workflow run from a fork does not receive.

## Pull requests

A PR from a branch `agent/<N>-…` carries exactly one `Homebrewtools-Issue: #N` line; a dispatched
run also requires a `Homebrewtools-Agent` line naming a configured lane. `validate` of
`homebrewtools-ci.yml` checks both. `homebrewtools-pm.yml` moves issue N on the board from that
line. `autonomy: gated`: every merge is left to a person.

A merge into `main` publishes the formula to every user of the tap.

## Finding triage

`docs.operating_model` in `pipeline.yaml` names this file. Each independent-review finding is
triaged before a correction is requested. The dispatcher runs this as a read-only triage session
(Governor `governor/docs/service/finishing.md`, Review triage); an operator correcting by hand
applies the same rules:

Only a CRITICAL finding requests changes; a review with WARNING and INFO findings only approves, and
its WARNINGs are triaged before the merge queue (Governor `governor/docs/postures/pr-review-posture.md`).

1. Open the cited code and confirm the finding against it. A finding that does not hold is answered
   on the PR with the evidence, and no correction is requested for it.
2. Request a correction for every confirmed CRITICAL and for every confirmed WARNING that is a
   boundary finding: security (including credentials, tokens and what the dispatcher pushes,
   merges or deletes), data loss, a formula `url` or `sha256` that does not match the release, or
   the issue's contract or scope.
3. Each other confirmed WARNING is either corrected or dispositioned: a PR comment names the
   follow-up issue and why deferral is safe, and the follow-up issue is opened.

Every later review of the PR receives the dispositions and does not reopen one without new evidence.
