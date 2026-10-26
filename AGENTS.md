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
| `CLAUDE.md` | the line `@AGENTS.md`, which Claude Code expands to the content of this file |
| `.gemini/settings.json` | sets `context.fileName` to `AGENTS.md`, the context file Gemini CLI reads (no `GEMINI.md` exists); Codex and OpenCode read `AGENTS.md` natively |
| `README.md` | install, platforms, the tools, the manual formula update |
| `.secrets.baseline` | the detect-secrets findings `just secrets` accepts: the twelve `sha256` values of the formulae, and sixteen `Secret Keyword` findings on the lines of the `secrets` recipe body in `justfile` |
| `.github/workflows/homebrewtools-ci.yml` | `validate` (PR metadata) and `gate` (`just gate`) |
| `.github/workflows/homebrewtools-pm.yml` | the issue and board sync of Governor |
| `.github/workflows/homebrewtools-formula.yml` | on a `repository_dispatch` event `formula-update` (`tool`, `tag`), runs `tools/formula_update.py`, regenerates `.secrets.baseline`, opens a pull request with the formula and the baseline with `HOMEBREW_TAP_TOKEN`, read from Bitwarden Secrets Manager with `bws run`, and enables squash auto-merge on it |
| `pipeline.yaml` | the Governor dispatcher's config for this repository; `checks.commands.secrets` runs `just secrets` |
| `.gitignore` | lists `.data/` |
| Governor's package preflight (`tools/local_preflight.py` of the Governor package, run by the dispatcher; this repository keeps no copy) | the local check the dispatcher runs: `just check`, then `just gate` |
| `tools/formula_check.py` | the check of each formula's `url` and `sha256` lines that `just formulae` and `just checksums` run |
| `tools/tests/test_formula_check.py` | the self-check of `tools/formula_check.py` that `just test` runs: a valid formula has no finding, each malformed one has one |
| `tools/formula_update.py` | rewrites the four `url` and four `sha256` lines of `Formula/<tool>.rb` for a tag `v<X.Y.Z>` from the release's `checksums.txt`; fails when it lacks one of the four archives |
| `tools/tests/test_formula_update.py` | the self-check of `tools/formula_update.py` that `just test` runs |

A formula has no `version` line: `brew audit --strict` reports it as redundant, and Homebrew reads
the version from the `url` (`.../download/v<version>/<tool>-v<version>-<os>-<arch>.tar.gz`). A
version change edits the four `url` lines and the four `sha256` lines.

## Commands

| Recipe | Runs |
|---|---|
| `just formulae` | `tools/formula_check.py`, offline: each formula has four `url` lines of one version covering darwin and linux, amd64 and arm64, each followed by a `sha256` line of 64 lowercase hex characters |
| `just checksums` | `formulae`, then compares each `sha256` with the release's `checksums.txt`; downloads it, so it is not part of the gate |
| `just check` | `brew style` of the checkout's tap |
| `just secrets` | `detect-secrets scan --no-verify` of the tracked files, compared with `.secrets.baseline` |
| `just test` | `tools/tests/test_formula_check.py` and `tools/tests/test_formula_update.py`, the self-checks of the two scripts, then `brew audit --strict` of each formula of the checkout |
| `just gate` | `formulae`, `check`, `secrets`, then `test`; the deterministic gate CI runs |
| `just fix` | `brew style --fix` of the checkout's tap |
| `just ff` | switches to `main` and fast-forwards it from `origin`; refuses local changes or a diverged `main` |

`up`, `down` and `logs` are not applicable (`checks.recipes.not_applicable` of `pipeline.yaml`):
there is no local stack. `just`, Homebrew, `python3` and detect-secrets 1.5.0 on `PATH`
(`pipx install detect-secrets==1.5.0`) are required. The recipes set
`HOMEBREW_NO_AUTO_UPDATE`, `HOMEBREW_NO_INSTALL_CLEANUP`, `HOMEBREW_NO_ENV_HINTS` and
`HOMEBREW_NO_BOOTSNAP`; with bootsnap, `brew style` of a symlinked tap exits with "deadlock; recursive
locking" (Homebrew 7.0.4, macOS).

`brew audit` reads formulae by name from a tap, and `brew style Formula` under a path with a hidden
directory (the dispatcher's worktrees are under `~/.governor`) applies RuboCop's generic cops instead
of Homebrew's formula cops. `check`, `test` and `fix` therefore run `brew` on a tap. When the tap
`roselabs-io/tools` is the checkout (CI), they use it. Otherwise they link the checkout into
Homebrew's Taps directory as `roselabs-io/tools-gate` for the run and remove the link on exit; an
installed `roselabs-io/tools` tap is not changed. Before running `brew`, they run `chmod a+r` on
`Formula/*.rb`: a checkout made under umask 077, as the dispatcher's worktrees are, has the formulae
at mode 0600 while Git records 100644, and `brew style` reports `FormulaAudit/Files: Incorrect file
permissions (600)`. Two runs at once outside CI conflict: the second
exits 1 because the link exists.

`brew style` is a developer command: its first run turns on Homebrew's developer mode, installs
Homebrew's style gems, and installs `shellcheck` and `actionlint` with `brew install`.

`just secrets` exits 1 with `secrets: detect-secrets 1.5.0 is required` when another version or none
is on `PATH`. It prints each finding whose file, hashed secret and type `.secrets.baseline` does not
hold as `path:line: type` and exits 1; line numbers are not compared, so a moved line passes. It
writes nothing. A new `sha256` value is a finding: a version change regenerates the baseline with

```sh
detect-secrets scan --no-verify --exclude-files '^\.secrets\.baseline$' > .secrets.baseline
```

and the diff of the baseline is reviewed. `homebrewtools-formula.yml` regenerates the baseline with this command on its branch and keeps the
baseline's `generated_at` line, so formula pull requests of two tools do not conflict on it. The detectors are detect-secrets' patterns and entropy
rules, so a secret of an unknown format with low entropy is not found. Untracked files and Git
history are not scanned.

detect-secrets' keyword detector reads the `secrets:` recipe header of `justfile` as a keyword and
each line of the recipe body as its value, so each body line is a finding the baseline holds. A new
or edited line of that recipe is a new finding: a change to the recipe regenerates the baseline as a
version change does.

The gate does not download the archives or `checksums.txt`: a `sha256` that does not match the
release is found by `just checksums` or when `brew install` fetches the archive.

## CI

All workflows run on GitHub-hosted `ubuntu-latest`. The repository is public; the organization's
self-hosted runners do not serve it. The `gate` job sets up Homebrew with
`Homebrew/actions/setup-homebrew`, which links the checkout as the tap `roselabs-io/tools`. The job
installs detect-secrets 1.5.0 with `pipx` before `just gate`.
`validate` and `homebrewtools-pm.yml` check out the private `roselabs-io/governor` with
`GOVERNOR_PM_TOKEN`. It and `HOMEBREW_TAP_TOKEN` (`homebrewtools-formula.yml`) are secrets of the shared
Bitwarden Secrets Manager project whose id is the organization variable `BWS_SHARED_PROJECT_ID`. Each
workflow installs `bws` 2.1.0 (x86_64 Linux, checked against its SHA-256) and reads them with `bws run`,
authenticated by `BWS_ACCESS_TOKEN`, the only GitHub Actions secret the workflows read besides
`github.token`. A run from a fork receives no secret: on a fork pull request the PM sync does not run,
and `validate` skips the steps that read `GOVERNOR_PM_TOKEN` and the marker check.

## Pull requests

A PR from a branch `agent/<N>-…` carries exactly one `Homebrewtools-Issue: #N` line; a dispatched
run also requires a `Homebrewtools-Agent` line naming a configured lane. `validate` of
`homebrewtools-ci.yml` checks both. `homebrewtools-pm.yml` moves issue N on the board from that
line. `autonomy: full`: an approved pull request with green CI merges through the merge queue without a
person (Governor `governor/docs/service/merge-queue.md`, Merge policy), except one whose ticket's metadata
block says `merge: manual`. The pull request of a release event merges itself when `validate` and
`Deterministic gate` pass: `homebrewtools-formula.yml` opens it and enables squash auto-merge.

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
