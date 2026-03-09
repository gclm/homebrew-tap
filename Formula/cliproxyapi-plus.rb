# typed: false
# frozen_string_literal: true

require "securerandom"

class CliproxyapiPlus < Formula
  desc "OpenAI-compatible proxy with third-party provider support"
  homepage "https://github.com/router-for-me/CLIProxyAPIPlus"
  version "6.8.49-0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/v6.8.49-0/CLIProxyAPIPlus_6.8.49-0_darwin_arm64.tar.gz"
      sha256 "8204333d08d99a8245290536383d4938a3a9cd119f222b00225bd4c64695a516"
    else
      url "https://github.com/router-for-me/CLIProxyAPIPlus/releases/download/v6.8.49-0/CLIProxyAPIPlus_6.8.49-0_darwin_amd64.tar.gz"
      sha256 "6f16f3c445fe0133f182419b4b2f855c6c08f4f4a671073237c4469c9713bd5a"
    end
  end

  def install
    bin.install "cli-proxy-api-plus"

    config_dir = etc/"cliproxyapi-plus"
    config_dir.mkpath
    config_path = config_dir/"config.yaml"

    state_dir = var/"lib/cliproxyapi-plus"
    state_dir.mkpath
    info_path = state_dir/"install-info"

    (var/"log/cliproxyapi-plus").mkpath

    unless config_path.exist?
      token = SecureRandom.hex(16)
      rendered = minimal_config_template.gsub("__MANAGEMENT_TOKEN__", token)
      config_path.write(rendered)
      info_path.write(install_info(port: configured_port_from(rendered), token: token))
    end
  end

  service do
    run [opt_bin/"cli-proxy-api-plus", "-config", etc/"cliproxyapi-plus/config.yaml"]
    keep_alive true
    working_dir var/"lib/cliproxyapi-plus"
    log_path var/"log/cliproxyapi-plus/output.log"
    error_log_path var/"log/cliproxyapi-plus/error.log"
  end

  def caveats
    config_path = etc/"cliproxyapi-plus/config.yaml"
    info = read_install_info
    port = configured_port_from(config_path.exist? ? config_path.read : minimal_config_template)
    management_url = "http://127.0.0.1:#{port}/management.html"

    output = []
    output << "Config file: #{config_path}"
    output << "Auth directory: ~/.cli-proxy-api"
    output << "Management URL: #{management_url}"

    if info["management_token"] && !info["management_token"].empty?
      output << "Management token: #{info["management_token"]}"
    else
      output << "Management token: preserved from existing config (not re-generated)"
    end

    output << ""
    output << "Start the service:"
    output << "  brew services start gclm/tap/cliproxyapi-plus"
    output << ""
    output << "If you update the config manually, restart the service:"
    output << "  brew services restart gclm/tap/cliproxyapi-plus"

    output.join("\n")
  end

  test do
    assert_match "CLIProxyAPI Version", shell_output("#{bin}/cli-proxy-api-plus --help")
  end

  private

  def minimal_config_template
    <<~YAML
      host: '127.0.0.1'
      port: 8917

      remote-management:
        allow-remote: false
        secret-key: '__MANAGEMENT_TOKEN__'
        disable-control-panel: false
        panel-github-repository: 'https://github.com/router-for-me/Cli-Proxy-API-Management-Center'

      auth-dir: '~/.cli-proxy-api'

      api-keys:
        - 'local-dev-api-key'
    YAML
  end

  def install_info(port:, token:)
    <<~TEXT
      management_url=http://127.0.0.1:#{port}/management.html
      management_token=#{token}
    TEXT
  end

  def read_install_info
    info_path = var/"lib/cliproxyapi-plus/install-info"
    return {} unless info_path.exist?

    info_path.each_line.with_object({}) do |line, acc|
      key, value = line.strip.split("=", 2)
      acc[key] = value if key && value
    end
  end

  def configured_port_from(content)
    match = content.match(/^port:\s*(\d+)\s*$/)
    match ? match[1] : "8917"
  end
end
