# typed: false
# frozen_string_literal: true

class Octopus < Formula
  desc "Simple, beautiful, and elegant LLM API aggregation & load balancing service"
  homepage "https://github.com/gclm/octopus"
  version "V1.0.8"
  license "AGPL-3.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+(?:-gclm\.\d+)?)$/i)
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/gclm/octopus/releases/download/V1.0.8/octopus-darwin-arm64.zip"
      sha256 "a49f50385380b8d309c1c08f34c0da50f97f594750647c24f6c27ceaa677d475"
    else
      url "https://github.com/gclm/octopus/releases/download/V1.0.8/octopus-darwin-x86_64.zip"
      sha256 "8b83a8f2312acc385116c23925ce7be0ae75acfd7d89b04a7b8941d4108ed6e1"
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
          "server": {
            "host": "0.0.0.0",
            "port": 8080
          },
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