class Sshca < Formula
  desc "SSH-only certificate authority and management CLI"
  homepage "https://github.com/roselabs-io/sshca"
  version "0.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/roselabs-io/sshca/releases/download/v0.1.0/sshca-v0.1.0-darwin-arm64.tar.gz"
      sha256 "122400bfd10e27ea43b1c68218194d9ab67f41e4bcc8b9a67508580ce044e603"
    else
      url "https://github.com/roselabs-io/sshca/releases/download/v0.1.0/sshca-v0.1.0-darwin-amd64.tar.gz"
      sha256 "c9514d64e3899f7a710129e78f0ed818c8e3d72fc7dd52ec50606dd45bcde4b6"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/roselabs-io/sshca/releases/download/v0.1.0/sshca-v0.1.0-linux-arm64.tar.gz"
      sha256 "37680eac7038fc2b005d324325af7715455cff7b0a3ad30077fd328566df0bba"
    else
      url "https://github.com/roselabs-io/sshca/releases/download/v0.1.0/sshca-v0.1.0-linux-amd64.tar.gz"
      sha256 "9ef219ac056683b6820a4032f6872021469bb7263a18ce00e3fee70156f5ba62"
    end
  end

  def install
    bin.install "sshca"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sshca --version")
  end
end
