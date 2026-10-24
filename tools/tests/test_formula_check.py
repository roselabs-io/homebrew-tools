"""Self-check of `formula_check.check`: a valid formula has no finding, each malformed one has one."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from formula_check import check

SHA = "0" * 64
PLATFORMS = [("darwin", "arm64"), ("darwin", "amd64"), ("linux", "arm64"), ("linux", "amd64")]


def formula(entries: list[tuple[str, str, str, str | None]], tool: str = "demo") -> str:
    """A formula of `tool` with one `url` and `sha256` line per (url tool, version, platform, sha256) entry."""
    lines = [f"class {tool.capitalize()} < Formula"]
    for url_tool, version, platform, sha256 in entries:
        archive = f"{url_tool}-v{version}-{platform}.tar.gz"
        lines.append(f'  url "https://github.com/roselabs-io/{url_tool}/releases/download/v{version}/{archive}"')
        if sha256 is not None:
            lines.append(f'  sha256 "{sha256}"')
    lines.append("end")
    return "\n".join(lines) + "\n"


def valid() -> list[tuple[str, str, str, str | None]]:
    return [("demo", "1.0.0", f"{os}-{arch}", SHA) for os, arch in PLATFORMS]


def replaced(index: int, **changes: str) -> list[tuple[str, str, str, str | None]]:
    entries = valid()
    tool, version, platform, sha256 = entries[index]
    entry = {"tool": tool, "version": version, "platform": platform, "sha256": sha256, **changes}
    entries[index] = (entry["tool"], entry["version"], entry["platform"], entry["sha256"])
    return entries


class CheckTest(unittest.TestCase):
    def findings(self, text: str) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "demo.rb"
            path.write_text(text, encoding="utf-8")
            return check(path)[0]

    def test_valid_formula_has_no_finding(self) -> None:
        self.assertEqual(self.findings(formula(valid())), [])

    def test_malformed_formula_has_a_finding(self) -> None:
        cases = {
            "two versions": replaced(3, version="1.0.1"),
            "short sha256": replaced(0, sha256="0" * 8),
            "uppercase sha256": replaced(0, sha256="A" * 64),
            "missing platform": valid()[:3],
            "repeated platform": replaced(3, platform="linux-arm64"),
            "url of another tool": replaced(1, tool="other"),
            "url without sha256 line": replaced(2, sha256=None),
        }
        for name, entries in cases.items():
            with self.subTest(name):
                self.assertNotEqual(self.findings(formula(entries)), [])


if __name__ == "__main__":
    unittest.main()
