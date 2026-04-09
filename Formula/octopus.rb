# typed: false
# frozen_string_literal: true

class Octopus < Formula
  desc "Simple, beautiful, and elegant LLM API aggregation & load balancing service"
  homepage "https://github.com/gclm/octopus"
  version "1.0.1"
  license "AGPL-3.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+(?:-gclm\.\d+)?)$/i)
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/gclm/octopus/releases/download/v1.0.1/octopus-darwin-arm64.zip"
      sha256 "af36de4d8138b59e0704b3f9941c03b3d7b6bfba2ff6b25fbacee044439ee116"
    else
      url "https://github.com/gclm/octopus/releases/download/v1.0.1/octopus-darwin-x86_64.zip"
      sha256 "b2e5865b7727b48c2835d2e9351a6d6cff88b4218749ece7ed55348f56fe5998"
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