class Bastionhub < Formula
  desc "SSH bastion and reverse-tunnel manager"
  homepage "https://github.com/roselabs-io/bastionhub"
  version "0.2.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/roselabs-io/bastionhub/releases/download/v0.2.0/bastionhub-v0.2.0-darwin-arm64.tar.gz"
      sha256 "82e1a21fef35c135e68c75a5d53ac3c8043dbe6d91947086486cc9710883414b"
    else
      url "https://github.com/roselabs-io/bastionhub/releases/download/v0.2.0/bastionhub-v0.2.0-darwin-amd64.tar.gz"
      sha256 "6d612581431e33c2c0982422b67b79813f4a9af31f45629bbfe2097dbf2dfd74"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/roselabs-io/bastionhub/releases/download/v0.2.0/bastionhub-v0.2.0-linux-arm64.tar.gz"
      sha256 "936880adf5907f6115f912d940542ada8ca0679b3b1b48bc0a1b10aec987d5e8"
    else
      url "https://github.com/roselabs-io/bastionhub/releases/download/v0.2.0/bastionhub-v0.2.0-linux-amd64.tar.gz"
      sha256 "5700ea080a1a4c695e1d10d45361176c785843bfa5131fc724f4a7d3d5a81dd5"
    end
  end

  # bastionhub endpoint enroll shells out to `sshca cert sign`.
  depends_on "roselabs-io/tools/sshca"

  def install
    bin.install "bastionhub"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bastionhub --version")
  end
end
