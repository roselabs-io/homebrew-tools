#!/usr/bin/env python3
"""Rewrites `Formula/<tool>.rb` for a release tag `v<X.Y.Z>` of `roselabs-io/<tool>`.

Downloads the release's `checksums.txt`, then sets each of the formula's four `url` lines to the
tag's archive of its platform and the `sha256` line after it to that archive's checksum. A formula
has no `version` line; Homebrew reads the version from the `url`.

Exits 1 without writing when the formula fails `formula_check.check`, when the tag is not
`v<X.Y.Z>` (a prerelease tag does not update a formula), or when `checksums.txt` lacks one of the
four archives. The failure is printed on stderr.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from formula_check import check, published

FORMULA_DIR = Path(__file__).resolve().parents[1] / "Formula"
TOOL = re.compile(r"^[a-z0-9-]+$")
TAG = re.compile(r"^v[0-9]+\.[0-9]+\.[0-9]+$")


class UpdateError(Exception):
    pass


def update(path: Path, tag: str, checksums: dict[str, str]) -> str:
    """Returns the text of the formula at `path` with its url and sha256 lines set for `tag`."""
    findings, entries = check(path)
    if findings:
        raise UpdateError("\n".join(findings))
    tool = path.stem
    lines = path.read_text(encoding="utf-8").splitlines()
    missing: list[str] = []
    for number, url, sha256 in entries:
        archive = f"{tool}-{tag}-{url['os']}-{url['arch']}.tar.gz"
        if archive not in checksums:
            missing.append(archive)
            continue
        lines[number - 1] = lines[number - 1].replace(
            url["url"], f"https://github.com/roselabs-io/{tool}/releases/download/{tag}/{archive}"
        )
        lines[number] = lines[number].replace(sha256, checksums[archive])
    if missing:
        raise UpdateError(f"checksums.txt of {tool} {tag} lacks {', '.join(missing)}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("tool", help="the formula's name, as in Formula/<tool>.rb")
    parser.add_argument("tag", help="the release tag, v<X.Y.Z>")
    args = parser.parse_args()
    path = FORMULA_DIR / f"{args.tool}.rb"
    if not TOOL.match(args.tool) or not path.is_file():
        print(f"formula_update: no formula {args.tool}", file=sys.stderr)
        return 1
    if not TAG.match(args.tag):
        print(f"formula_update: tag {args.tag} is not v<X.Y.Z>", file=sys.stderr)
        return 1
    try:
        text = update(path, args.tag, published(f"https://github.com/roselabs-io/{args.tool}/releases/download/{args.tag}"))
    except UpdateError as error:
        print(f"formula_update: {error}", file=sys.stderr)
        return 1
    path.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
