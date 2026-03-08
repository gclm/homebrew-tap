# typed: false
# frozen_string_literal: true

class CliproxyapiPlus < Formula
  desc "OpenAI-compatible proxy with third-party provider support"
  homepage "https://github.com/router-for-me/CLIProxyAPIPlus"
  version "6.8.48-0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/v6.8.48-0/CLIProxyAPIPlus_6.8.48-0_darwin_arm64.tar.gz"
      sha256 "82d5f98024ca832542f57c4267cad7ff853ac548c421f1c80763c5edbf5dcf07"
    else
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/v6.8.48-0/CLIProxyAPIPlus_6.8.48-0_darwin_amd64.tar.gz"
      sha256 "41574511dc0b575ab98ffda9e7e5a955932f86786916c536a699ddc4bea5d7de"
    end
  end

  def install
    bin.install "cli-proxy-api-plus"

    config_dir = etc/"cliproxyapi-plus"
    config_dir.mkpath
    config_path = config_dir/"config.yaml"
    config_path.write(buildpath/"config.example.yaml".read) unless config_path.exist?

    (var/"lib/cliproxyapi-plus").mkpath
    (var/"log/cliproxyapi-plus").mkpath
  end

  service do
    run [opt_bin/"cli-proxy-api-plus", "-config", etc/"cliproxyapi-plus/config.yaml"]
    keep_alive true
    working_dir var/"lib/cliproxyapi-plus"
    log_path var/"log/cliproxyapi-plus/output.log"
    error_log_path var/"log/cliproxyapi-plus/error.log"
  end

  def caveats
    <<~EOS
      Config file: #{etc}/cliproxyapi-plus/config.yaml
      Auth directory: ~/.cli-proxy-api

      Edit the config file before starting the service:
        #{ENV.fetch("EDITOR", "vi")} #{etc}/cliproxyapi-plus/config.yaml

      Start the service:
        brew services start gclm/tap/cliproxyapi-plus
    EOS
  end

  test do
    assert_match "CLIProxyAPI Version", shell_output("#{bin}/cli-proxy-api-plus --help")
  end
end
