# typed: false
# frozen_string_literal: true

class Octopus < Formula
  desc "Simple, beautiful, and elegant LLM API aggregation & load balancing service"
  homepage "https://github.com/gclm/octopus"
  version "0.9.28"
  license "AGPL-3.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+(?:-gclm\.\d+)?)$/i)
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/gclm/octopus/releases/download/v0.9.28/octopus-darwin-arm64.zip"
      sha256 "62e646ac8556c481a921e15d124ca4be4fea964454fe46aabc501a9821022f66"
    else
      url "https://github.com/gclm/octopus/releases/download/v0.9.28/octopus-darwin-x86_64.zip"
      sha256 "423aa868aa419f5f7096dbf9fe502026885ba7bcd76578cce43aae5d2bcffc95"
    end
  end

  def install
    bin.install "octopus"
  end

  def post_install
    (var/"lib/octopus").mkpath
    (var/"log/octopus").mkpath

    config_dir = etc/"octopus"
    config_dir.mkpath
    config_path = config_dir/"config.json"

    unless config_path.exist?
      config_path.write <<~JSON
        {
          "listen": "0.0.0.0:8080",
          "database": {
            "type": "sqlite",
            "path": "#{var}/lib/octopus/octopus.db"
          }
        }
      JSON
    end
  end

  service do
    run [opt_bin/"octopus", "start", "--config", etc/"octopus/config.json"]
    keep_alive true
    working_dir var/"lib/octopus"
    log_path var/"log/octopus/output.log"
    error_log_path var/"log/octopus/error.log"
  end

  def caveats
    <<~EOS
      Config file: #{etc}/octopus/config.json
      Data directory: #{var}/lib/octopus

      Default credentials (please change after first login):
        Username: admin
        Password: admin

      Start the service:
        brew services start gclm/tap/octopus
    EOS
  end

  test do
    assert_match "octopus", shell_output("#{bin}/octopus --help", 1)
  end
end