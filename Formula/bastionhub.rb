class Bastionhub < Formula
  desc "Self-hosted SSH bastion + reverse-tunnel substrate (pairs with sshca)"
  homepage "https://github.com/roselabs-io/bastionhub"
  version "0.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/roselabs-io/bastionhub/releases/download/v0.1.0/bastionhub-v0.1.0-darwin-arm64.tar.gz"
      sha256 "78efe96e5a509c67be95b89fb83fd9ca8498afa9c40d82b172871b85592609ed"
    else
      url "https://github.com/roselabs-io/bastionhub/releases/download/v0.1.0/bastionhub-v0.1.0-darwin-amd64.tar.gz"
      sha256 "b10cc5bb16ccaacef930ea2a407398cdcc5b5fbfe0b4374d5613ce4ba96f0cea"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/roselabs-io/bastionhub/releases/download/v0.1.0/bastionhub-v0.1.0-linux-arm64.tar.gz"
      sha256 "19d9d70d07b75b637f38e70423c097abd9575d858374b3cc8fb281900989cbae"
    else
      url "https://github.com/roselabs-io/bastionhub/releases/download/v0.1.0/bastionhub-v0.1.0-linux-amd64.tar.gz"
      sha256 "59114552a6a0cde1f9383c256a342b791b465b229b9d4fc35651cd8d25000a25"
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
