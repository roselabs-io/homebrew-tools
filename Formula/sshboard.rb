class Sshboard < Formula
  desc "Operator console for sshca + bastionhub (HTMX + Go)"
  homepage "https://github.com/roselabs-io/sshboard"
  version "0.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/roselabs-io/sshboard/releases/download/v0.1.0/sshboard-v0.1.0-darwin-arm64.tar.gz"
      sha256 "d15be777af5c0da4f165fd35dc045ad0dbff82525f46287e32639ce17530cfc5"
    else
      url "https://github.com/roselabs-io/sshboard/releases/download/v0.1.0/sshboard-v0.1.0-darwin-amd64.tar.gz"
      sha256 "5808879c92a6539354d3993432aeae47ec38b717aca571522841e411e7efd5a0"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/roselabs-io/sshboard/releases/download/v0.1.0/sshboard-v0.1.0-linux-arm64.tar.gz"
      sha256 "9626c82e6072de48b1914bae998273553b3208f7925df82717a03fa426d93a9d"
    else
      url "https://github.com/roselabs-io/sshboard/releases/download/v0.1.0/sshboard-v0.1.0-linux-amd64.tar.gz"
      sha256 "e2fb4524b286003259d9f50819c338769f557cc944db927d111775031c39168e"
    end
  end

  # sshboard reads sshca's audit log + shells out to it for cert actions.
  depends_on "roselabs-io/tools/sshca" => :recommended

  # sshboard reads bastionhub's endpoints.yaml + shells out for live status
  # and the click-to-copy SSH command.
  depends_on "roselabs-io/tools/bastionhub" => :recommended

  def install
    bin.install "sshboard"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sshboard --version")
  end
end
