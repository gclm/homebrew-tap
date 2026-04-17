# typed: false
# frozen_string_literal: true

class Securefox < Formula
  desc "Local-first password manager with Git sync"
  homepage "https://github.com/gclm/securefox"
  version "1.0.6"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/gclm/securefox/releases/download/v1.0.6/securefox-macos-arm64.tar.gz"
      sha256 "7470f6a416c3954e7f7b8828695c71ce4ef1c16b772d0a6c7b0366885e5d28c9"
    else
      url "https://github.com/gclm/securefox/releases/download/v1.0.6/securefox-macos-x64.tar.gz"
      sha256 "6621f45a0155973a71b8d57eab87b769d743e639b8e3686ea2c2f01492c7a1a9"
    end
  end

  def install
    bin.install "securefox"
  end

  service do
    run [opt_bin/"securefox", "--vault", "#{ENV["HOME"]}/.securefox", "service", "run", "--timeout", "1800"]
    keep_alive true
    working_dir "#{ENV["HOME"]}/.securefox"
    log_path "#{ENV["HOME"]}/.securefox/service.log"
    error_log_path "#{ENV["HOME"]}/.securefox/service.err"
  end

  test do
    assert_match "SecureFox", shell_output("#{bin}/securefox version")
  end
end
