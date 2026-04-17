# typed: false
# frozen_string_literal: true

class Securefox < Formula
  desc "Local-first password manager with Git sync"
  homepage "https://github.com/gclm/securefox"
  version "0.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/gclm/securefox/releases/download/v0.0.0/securefox-macos-arm64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    else
      url "https://github.com/gclm/securefox/releases/download/v0.0.0/securefox-macos-x64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  def install
    bin.install "securefox"
  end

  service do
    run [opt_bin/"securefox", "--vault", ENV["HOME"]/.securefox, "service", "run", "--timeout", "1800"]
    keep_alive true
    working_dir ENV["HOME"]/.securefox
    log_path ENV["HOME"]/.securefox/service.log
    error_log_path ENV["HOME"]/.securefox/service.err
  end

  test do
    assert_match "SecureFox", shell_output("#{bin}/securefox version")
  end
end
