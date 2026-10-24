"""Self-check of `formula_update.update`: the four url and sha256 lines move to the tag, and a missing archive fails."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from formula_check import check
from formula_update import UpdateError, update

PLATFORMS = ["darwin-arm64", "darwin-amd64", "linux-arm64", "linux-amd64"]
CHECKSUMS = {f"demo-v2.0.0-{platform}.tar.gz": f"{index:x}" * 64 for index, platform in enumerate(PLATFORMS, 1)}
FORMULA = "class Demo < Formula\n" + "".join(
    f'  url "https://github.com/roselabs-io/demo/releases/download/v1.0.0/demo-v1.0.0-{platform}.tar.gz"\n'
    f'  sha256 "{"0" * 64}"\n'
    for platform in PLATFORMS
) + "end\n"


class UpdateTest(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.path = Path(directory.name) / "demo.rb"
        self.path.write_text(FORMULA, encoding="utf-8")

    def test_url_and_sha256_lines_move_to_the_tag(self) -> None:
        self.path.write_text(update(self.path, "v2.0.0", CHECKSUMS), encoding="utf-8")
        findings, entries = check(self.path)
        self.assertEqual(findings, [])
        self.assertEqual({url["archive"]: sha256 for _, url, sha256 in entries}, CHECKSUMS)

    def test_missing_archive_fails(self) -> None:
        checksums = dict(CHECKSUMS)
        del checksums["demo-v2.0.0-linux-arm64.tar.gz"]
        with self.assertRaisesRegex(UpdateError, "linux-arm64"):
            update(self.path, "v2.0.0", checksums)


if __name__ == "__main__":
    unittest.main()
