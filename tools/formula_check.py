#!/usr/bin/env python3
"""Checks the `url` and `sha256` lines of each formula given on the command line.

Without `--checksums` the check is offline. Each formula has four `url` lines, each followed by its
`sha256` line. Each `url` is
`https://github.com/roselabs-io/<tool>/releases/download/v<version>/<tool>-v<version>-<os>-<arch>.tar.gz`,
where `<tool>` is the formula's file name; the four lines carry one version and cover darwin and
linux, amd64 and arm64. Each `sha256` is 64 lowercase hex characters.

With `--checksums` it also downloads each release's `checksums.txt` and compares each `sha256` with
the line of its archive.

Findings are printed as `<file>:<line>: <message>`. Exit 0 when there is none, else 1.
"""

from __future__ import annotations

import argparse
import re
import sys
import urllib.request
from pathlib import Path

URL = re.compile(
    r'^\s*url "(?P<url>https://github\.com/roselabs-io/(?P<tool>[^/"]+)/releases/download/'
    r'v(?P<version>[^/"]+)/(?P<archive>(?P=tool)-v(?P=version)-(?P<os>[a-z]+)-(?P<arch>[a-z0-9]+)\.tar\.gz))"$'
)
SHA256 = re.compile(r'^\s*sha256 "(?P<sha256>[^"]*)"$')
HEX64 = re.compile(r"^[0-9a-f]{64}$")
PLATFORMS = {("darwin", "amd64"), ("darwin", "arm64"), ("linux", "amd64"), ("linux", "arm64")}


def check(path: Path) -> tuple[list[str], list[tuple[int, re.Match, str]]]:
    """Returns the findings of one formula and its (line, url match, sha256) entries."""
    findings: list[str] = []
    entries: list[tuple[int, re.Match, str]] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    for number, line in enumerate(lines, 1):
        if not line.lstrip().startswith("url "):
            continue
        url = URL.match(line)
        if not url or url["tool"] != path.stem:
            findings.append(f"{path}:{number}: url is not a release archive of {path.stem}")
            continue
        sha256 = SHA256.match(lines[number]) if number < len(lines) else None
        if not sha256:
            findings.append(f"{path}:{number + 1}: the line after the url is not a sha256 line")
            continue
        if not HEX64.match(sha256["sha256"]):
            findings.append(f"{path}:{number + 1}: sha256 is not 64 lowercase hex characters")
        entries.append((number, url, sha256["sha256"]))
    if len(entries) != 4 or {(url["os"], url["arch"]) for _, url, _ in entries} != PLATFORMS:
        findings.append(f"{path}: the urls do not cover darwin and linux, amd64 and arm64 once each")
    versions = sorted({url["version"] for _, url, _ in entries})
    if len(versions) > 1:
        findings.append(f"{path}: the urls carry more than one version: {', '.join(versions)}")
    return findings, entries


def compare(path: Path, entries: list[tuple[int, re.Match, str]]) -> list[str]:
    """Compares each sha256 with the release's checksums.txt."""
    findings: list[str] = []
    for release in sorted({url["url"].rsplit("/", 1)[0] for _, url, _ in entries}):
        with urllib.request.urlopen(f"{release}/checksums.txt", timeout=30) as response:
            lines = response.read().decode().split("\n")
        published = {name: sha256 for sha256, name in (line.split() for line in lines if line.strip())}
        for number, url, sha256 in entries:
            if not url["url"].startswith(release + "/"):
                continue
            if url["archive"] not in published:
                findings.append(f"{path}:{number}: {url['archive']} is not in {release}/checksums.txt")
            elif published[url["archive"]] != sha256:
                findings.append(f"{path}:{number + 1}: sha256 differs from {release}/checksums.txt")
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("formulae", nargs="+", type=Path)
    parser.add_argument("--checksums", action="store_true", help="compare with each release's checksums.txt")
    args = parser.parse_args()
    findings: list[str] = []
    for path in args.formulae:
        found, entries = check(path)
        findings += found
        if args.checksums and not found:
            findings += compare(path, entries)
    for finding in findings:
        print(finding)
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
